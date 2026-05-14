//
//  AuthService.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import AuthenticationServices
import CryptoKit
import GoogleSignIn

@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var isAuthenticated = false
    @Published var isInitializing = true
    
    private let firestore = FirebaseManager.shared.firestore
    private let storage = Storage.storage()
    private let xpService = XPService.shared
    private var currentNonce: String?
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        // Check cached auth state immediately (synchronous, no network call)
        checkCachedAuthState()
        // Set up listener for future changes
        setupAuthStateListener()
        
        // Fallback: If still initializing after 0.1 seconds, assume not authenticated
        // This prevents the loading screen from staying too long
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            if isInitializing {
                isInitializing = false
                isAuthenticated = false
                currentUser = nil
                print("⚠️ Auth check timeout, assuming not authenticated")
            }
        }
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Authentication State
    
    /// Check cached auth state synchronously (instant, no network delay)
    private func checkCachedAuthState() {
        // Auth.auth().currentUser is available immediately from cache
        // This doesn't require a network call, so it's instant
        // Check immediately - if Firebase isn't ready, currentUser will be nil (which is fine)
        if let firebaseUser = Auth.auth().currentUser {
            // User is cached, mark as authenticated immediately
            isAuthenticated = true
            isInitializing = false
            print("✅ User authenticated (cached): \(firebaseUser.uid)")
            
            // Load user data asynchronously (doesn't block UI)
            Task {
                await loadUserData(userID: firebaseUser.uid)
            }
        } else {
            // No cached user, mark as not authenticated immediately
            currentUser = nil
            isAuthenticated = false
            isInitializing = false
            print("❌ No authenticated user (cached)")
        }
    }
    
    private func setupAuthStateListener() {
        // Set up Firebase Auth state listener for real-time updates
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let firebaseUser = firebaseUser {
                    await self.loadUserData(userID: firebaseUser.uid)
                    self.isAuthenticated = true
                    print("✅ User authenticated: \(firebaseUser.uid)")
                } else {
                    self.currentUser = nil
                    self.isAuthenticated = false
                    print("❌ No authenticated user")
                }
            }
        }
    }
    
    func checkAuthState() async {
        // This method is kept for manual checks, but the listener handles automatic updates
        if let firebaseUser = Auth.auth().currentUser {
            await loadUserData(userID: firebaseUser.uid)
            isAuthenticated = true
            print("✅ User authenticated: \(firebaseUser.uid)")
        } else {
            currentUser = nil
            isAuthenticated = false
            print("❌ No authenticated user")
        }
        
        // Mark initialization as complete
        if isInitializing {
            isInitializing = false
        }
    }
    
    // MARK: - Sign In with Google
    
    func signInWithGoogle(presentingViewController: UIViewController) async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.missingClientID
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.invalidToken
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
        
        let authResult = try await Auth.auth().signIn(with: credential)
        let userID = authResult.user.uid
        
        // Get user info - prefer Google profile name, fallback to Firebase Auth displayName
        let googleProfileName = result.user.profile?.name
        let displayName = googleProfileName ?? authResult.user.displayName ?? "User"
        let email = authResult.user.email
        
        await createOrUpdateUser(
            userID: userID,
            email: email,
            displayName: displayName
        )
        
        await checkAuthState()
    }
    
    // MARK: - Sign In with Apple
    
    func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>, nonce: String?) async throws {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw AuthError.invalidCredential
            }
            
            guard let nonce = nonce ?? currentNonce else {
                throw AuthError.invalidNonce
            }
            
            currentNonce = nil
            
            guard let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                throw AuthError.invalidToken
            }
            
            // Create OAuth credential for Apple Sign In using Swift API
            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )
            let authResult = try await Auth.auth().signIn(with: credential)
            let userID = authResult.user.uid
            
            // Get display name - prefer Apple credential fullName (only available on first sign-in),
            // fallback to Firebase Auth displayName (set on first sign-in)
            var displayName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            
            print("🔍 Apple Sign-In - Extracted displayName: '\(displayName)' (givenName: '\(appleIDCredential.fullName?.givenName ?? "nil")', familyName: '\(appleIDCredential.fullName?.familyName ?? "nil")')")
            
            // If fullName is available (first sign-in), update Firebase Auth displayName for future use
            if !displayName.isEmpty && authResult.user.displayName != displayName {
                print("📝 Updating Firebase Auth displayName to: '\(displayName)'")
                let changeRequest = authResult.user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    changeRequest.commitChanges { error in
                        if let error = error {
                            print("⚠️ Failed to update Firebase Auth displayName: \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                        } else {
                            print("✅ Firebase Auth displayName updated successfully")
                            continuation.resume()
                        }
                    }
                }
            }
            
            // If fullName is empty (subsequent sign-ins), use Firebase Auth displayName
            if displayName.isEmpty {
                displayName = authResult.user.displayName ?? "User"
                print("🔍 Using Firebase Auth displayName: '\(displayName)'")
            }
            
            let email = appleIDCredential.email ?? authResult.user.email
            
            await createOrUpdateUser(
                userID: userID,
                email: email,
                displayName: displayName
            )
            
            await checkAuthState()
            
        case .failure(let error):
            throw error
        }
    }
    
    // MARK: - User Management
    
    /// Generate a base username from display name
    private func generateBaseUsername(from displayName: String) -> String {
        // Remove leading/trailing whitespace
        var base = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If empty, use default
        if base.isEmpty {
            base = "user"
        }
        
        // Convert to lowercase
        base = base.lowercased()
        
        // Replace spaces and common separators with underscores
        base = base.replacingOccurrences(of: " ", with: "_")
        base = base.replacingOccurrences(of: "-", with: "_")
        base = base.replacingOccurrences(of: ".", with: "_")
        
        // Remove invalid characters (keep only alphanumeric and underscore)
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        base = base.unicodeScalars.filter { allowedCharacters.contains($0) }.map(String.init).joined()
        
        // Remove multiple consecutive underscores
        while base.contains("__") {
            base = base.replacingOccurrences(of: "__", with: "_")
        }
        
        // Remove leading/trailing underscores
        base = base.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        
        // Ensure minimum length (pad with random number if too short)
        if base.count < 4 {
            let randomSuffix = Int.random(in: 1000...9999)
            base = "\(base)\(randomSuffix)"
        }
        
        // Truncate to max 15 characters (leave room for suffixes)
        if base.count > 12 {
            base = String(base.prefix(12))
        }
        
        // Remove trailing underscore if any
        base = base.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        
        return base
    }
    
    /// Find a unique username by trying the base and variations
    private func findUniqueUsername(baseUsername: String, excludingUserID: String? = nil) async -> String {
        // First try the base username
        do {
            let isAvailable = try await isUsernameAvailable(baseUsername, excludingUserID: excludingUserID)
            if isAvailable {
                return baseUsername.lowercased()
            }
        } catch {
            print("⚠️ Error checking username availability: \(error.localizedDescription)")
        }
        
        // Try variations with numbers
        for i in 1...999 {
            let variation = "\(baseUsername)\(i)"
            if variation.count > 15 {
                break
            }
            do {
                let isAvailable = try await isUsernameAvailable(variation, excludingUserID: excludingUserID)
                if isAvailable {
                    return variation.lowercased()
                }
            } catch {
                continue
            }
        }
        
        // Try with underscore and numbers
        for i in 1...999 {
            let variation = "\(baseUsername)_\(i)"
            if variation.count > 15 {
                break
            }
            do {
                let isAvailable = try await isUsernameAvailable(variation, excludingUserID: excludingUserID)
                if isAvailable {
                    return variation.lowercased()
                }
            } catch {
                continue
            }
        }
        
        // Last resort: add random suffix
        let randomSuffix = Int.random(in: 1000...9999)
        let fallback = "\(baseUsername)\(randomSuffix)"
        let truncated = fallback.count > 15 ? String(fallback.prefix(15)) : fallback
        return truncated.lowercased()
    }
    
    private func createOrUpdateUser(userID: String, email: String?, displayName: String) async {
        let userRef = firestore.collection("users").document(userID)
        
        do {
            let document = try await userRef.getDocument()
            
            if document.exists {
                // User already exists - update lastLogin and email if missing, don't overwrite displayName
                var updateData: [String: Any] = [
                    "lastLogin": Timestamp(date: Date())
                ]
                
                // Only update email if it's not already set in the document
                if let existingUser = try? document.data(as: AppUser.self) {
                    if existingUser.email == nil && email != nil {
                        updateData["email"] = email as Any
                    }
                } else if email != nil {
                    // If we can't decode the user, still try to update email if provided
                    updateData["email"] = email as Any
                }
                
                // Always update lastLogin
                try await userRef.updateData(updateData)
            } else {
                // Create new user - generate unique username from displayName
                print("👤 Creating new user - displayName: '\(displayName)'")
                let baseUsername = generateBaseUsername(from: displayName)
                print("🔍 Generated base username: '\(baseUsername)'")
                let uniqueUsername = await findUniqueUsername(baseUsername: baseUsername, excludingUserID: userID)
                print("✅ Final unique username: '\(uniqueUsername)'")
                
                let newUser = AppUser(
                    id: userID,
                    email: email,
                    displayName: displayName,
                    username: uniqueUsername,
                    lastLogin: Date()
                )
                try userRef.setData(from: newUser)
                print("✅ Created new user with displayName: '\(displayName)', username: '\(uniqueUsername)'")
            }
        } catch {
            print("⚠️ Error creating/updating user: \(error.localizedDescription)")
        }
    }
    
    private func loadUserData(userID: String) async {
        do {
            let document = try await firestore.collection("users").document(userID).getDocument()
            
            if let user = try? document.data(as: AppUser.self) {
                currentUser = user
                print("✅ User data loaded - recipeCount: \(user.recipeCount), followerCount: \(user.followerCount), followingCount: \(user.followingCount), likesCount: \(user.likesCount)")
            }
        } catch {
            print("⚠️ Error loading user data: \(error.localizedDescription)")
        }
    }
    
    func reloadUserData() async {
        if let userID = Auth.auth().currentUser?.uid {
            await loadUserData(userID: userID)
        }
    }
    
    // MARK: - Profile Updates
    
    /// Check if username is available (not taken by another user)
    func isUsernameAvailable(_ username: String, excludingUserID: String? = nil) async throws -> Bool {
        // Clean username
        let cleanUsername = username.hasPrefix("@") ? String(username.dropFirst()) : username
        let lowercaseUsername = cleanUsername.lowercased()
        
        // Query Firestore for existing username
        let snapshot = try await firestore.collection("users")
            .whereField("username", isEqualTo: lowercaseUsername)
            .limit(to: 1)
            .getDocuments()
        
        // Check if any documents found (excluding current user if provided)
        for document in snapshot.documents {
            if let excludeID = excludingUserID, document.documentID == excludeID {
                continue // Skip current user's own document
            }
            return false // Username is taken
        }
        
        return true // Username is available
    }
    
    /// Generate alternative username suggestions
    func generateUsernameAlternatives(_ baseUsername: String) -> [String] {
        let cleanUsername = baseUsername.hasPrefix("@") ? String(baseUsername.dropFirst()) : baseUsername
        let lowercaseUsername = cleanUsername.lowercased()
        
        var alternatives: [String] = []
        
        // Add numbers
        for i in 1...5 {
            let alt = "\(lowercaseUsername)\(i)"
            if alt.count >= 4 && alt.count <= 15 {
                alternatives.append(alt)
            }
        }
        
        // Add underscore with numbers
        for i in 1...3 {
            let alt = "\(lowercaseUsername)_\(i)"
            if alt.count >= 4 && alt.count <= 15 {
                alternatives.append(alt)
            }
        }
        
        // Add random suffix if still need more
        if alternatives.count < 3 {
            let randomSuffix = String(Int.random(in: 100...999))
            let alt = "\(lowercaseUsername)\(randomSuffix)"
            if alt.count >= 4 && alt.count <= 15 {
                alternatives.append(alt)
            }
        }
        
        return Array(alternatives.prefix(5)) // Return up to 5 alternatives
    }
    
    /// Validate username format and length
    private func validateUsername(_ username: String) throws {
        let cleanUsername = username.hasPrefix("@") ? String(username.dropFirst()) : username
        
        // Check length
        if cleanUsername.count < 4 {
            throw AuthError.usernameTooShort
        }
        
        if cleanUsername.count > 15 {
            throw AuthError.usernameTooLong
        }
        
        // Check for valid characters (alphanumeric and underscore only)
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        if cleanUsername.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            throw AuthError.invalidUsername
        }
    }
    
    func updateProfile(displayName: String?, username: String?, bio: String?) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw AuthError.unauthorized
        }
        
        let userRef = firestore.collection("users").document(userID)
        var updateData: [String: Any] = [
            "updatedAt": Timestamp(date: Date())
        ]
        
        if let displayName = displayName {
            updateData["displayName"] = displayName
        }
        
        if let username = username {
            // Validate username
            try validateUsername(username)
            
            // Remove @ if user added it
            let cleanUsername = username.hasPrefix("@") ? String(username.dropFirst()) : username
            let lowercaseUsername = cleanUsername.lowercased()
            
            // Check if username is available (excluding current user)
            let isAvailable = try await isUsernameAvailable(username, excludingUserID: userID)
            if !isAvailable {
                throw AuthError.usernameTaken
            }
            
            updateData["username"] = lowercaseUsername
        }
        
        if let bio = bio {
            updateData["bio"] = bio
        }
        
        try await userRef.updateData(updateData)
        
        // Note: We don't batch update all recipes here for cost/performance reasons.
        // Instead, we use lazy updates:
        // - Recipe views already fetch fresh user data when displaying (ChefSectionView)
        // - Recipes will be updated with new author info when they are next viewed/edited
        // - This approach is more cost-effective and scales better
        
        // Post notification that user profile was updated (for views that cache user data)
        NotificationCenter.default.post(name: NSNotification.Name("UserProfileUpdated"), object: nil, userInfo: ["userID": userID])
        
        await reloadUserData()
        await awardCompleteProfileIfEligible(userID: userID)
    }
    
    func uploadProfileImage(_ image: UIImage) async throws -> String {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw AuthError.unauthorized
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AuthError.invalidImage
        }
        
        let imageRef = storage.reference().child("profile_images/\(userID).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<StorageMetadata, Error>) in
            imageRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let metadata = metadata {
                    continuation.resume(returning: metadata)
                } else {
                    continuation.resume(throwing: AuthError.invalidImage)
                }
            }
        }
        
        let downloadURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            imageRef.downloadURL { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let url = url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: AuthError.invalidImage)
                }
            }
        }
        
        // Update user document with image URL
        let userRef = firestore.collection("users").document(userID)
        try await userRef.updateData([
            "profileImageURL": downloadURL.absoluteString,
            "updatedAt": Timestamp(date: Date())
        ])
        
        await reloadUserData()
        await awardCompleteProfileIfEligible(userID: userID)
        return downloadURL.absoluteString
    }
    
    func deleteProfileImage() async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw AuthError.unauthorized
        }
        
        let imageRef = storage.reference().child("profile_images/\(userID).jpg")
        
        try await imageRef.delete()
        
        // Update user document to remove image URL
        let userRef = firestore.collection("users").document(userID)
        try await userRef.updateData([
            "profileImageURL": FieldValue.delete(),
            "updatedAt": Timestamp(date: Date())
        ])
        
        await reloadUserData()
    }
    
    // MARK: - Profile Visibility
    
    func toggleProfileVisibility(hidden: Bool) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw AuthError.unauthorized
        }
        
        let userRef = firestore.collection("users").document(userID)
        try await userRef.updateData([
            "isProfileHidden": hidden,
            "updatedAt": Timestamp(date: Date())
        ])
        
        await reloadUserData()
    }
    
    func toggleCompletePrivacy(isPrivate: Bool) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw AuthError.unauthorized
        }
        
        let userRef = firestore.collection("users").document(userID)
        try await userRef.updateData([
            "isCompletelyPrivate": isPrivate,
            "updatedAt": Timestamp(date: Date())
        ])
        
        await reloadUserData()
    }

    private func awardCompleteProfileIfEligible(userID: String) async {
        guard let userDoc = try? await firestore.collection("users").document(userID).getDocument(),
              let data = userDoc.data() else { return }

        let displayName = (data["displayName"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let username = (data["username"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let bio = (data["bio"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let profileImageURL = (data["profileImageURL"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !displayName.isEmpty, !username.isEmpty, !bio.isEmpty, !profileImageURL.isEmpty else { return }

        _ = try? await xpService.awardXPForAction(
            receiverUserId: userID,
            actorUserId: userID,
            actionType: .completeProfile,
            targetId: userID
        )
    }
    
    // MARK: - Account Deletion
    
    func reAuthenticate(email: String, password: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.unauthorized
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.reauthenticate(with: credential)
    }
    
    func reAuthenticateWithGoogle(presentingViewController: UIViewController) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.unauthorized
        }
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.missingClientID
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.invalidToken
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
        try await user.reauthenticate(with: credential)
    }
    
    func reAuthenticateWithApple(result: Result<ASAuthorization, Error>, nonce: String?) async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.unauthorized
        }
        
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw AuthError.invalidCredential
            }
            
            guard let nonce = nonce ?? currentNonce else {
                throw AuthError.invalidNonce
            }
            
            guard let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                throw AuthError.invalidToken
            }
            
            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )
            try await user.reauthenticate(with: credential)
            
        case .failure(let error):
            throw error
        }
    }
    
    func generateNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // Extract storage path from Firebase Storage URL
    private func extractStoragePath(from urlString: String) -> String? {
        // Firebase Storage URLs look like: https://firebasestorage.googleapis.com/v0/b/PROJECT.appspot.com/o/PATH?alt=media&token=TOKEN
        guard let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let pathComponent = components.path.components(separatedBy: "/o/").last else {
            return nil
        }
        // Remove query parameters and decode
        let path = pathComponent.components(separatedBy: "?").first?.removingPercentEncoding
        return path
    }
    
    func deleteAccount() async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw AuthError.unauthorized
        }
        
        let userRef = firestore.collection("users").document(userID)
        
        // 1. Delete user document in Firestore
        print("🗑️ Deleting user document...")
        try await userRef.delete()
        
        // 2. Delete user's recipes and associated images
        print("🗑️ Deleting user recipes...")
        let recipesSnapshot = try await firestore.collection("recipes")
            .whereField("authorID", isEqualTo: userID)
            .getDocuments()
        
        for recipeDoc in recipesSnapshot.documents {
            // Try to decode recipe to get all image URLs
            if let recipe = try? recipeDoc.data(as: Recipe.self) {
                // Delete recipe images (main dish images) from imageURLs array
                for imageURL in recipe.imageURLs {
                    if !imageURL.isEmpty {
                        if let path = extractStoragePath(from: imageURL) {
                            do {
                                let imageRef = storage.reference().child(path)
                                try await imageRef.delete()
                                print("🗑️ Deleted recipe image: \(path)")
                            } catch {
                                print("⚠️ Error deleting recipe image \(path): \(error.localizedDescription)")
                            }
                        }
                    }
                }
                
                // Delete deprecated single image URL (if different from imageURLs)
                if let imageURL = recipe.imageURL, !imageURL.isEmpty {
                    // Only delete if not already in imageURLs array
                    if !recipe.imageURLs.contains(imageURL) {
                        if let path = extractStoragePath(from: imageURL) {
                            do {
                                let imageRef = storage.reference().child(path)
                                try await imageRef.delete()
                                print("🗑️ Deleted deprecated recipe image: \(path)")
                            } catch {
                                print("⚠️ Error deleting deprecated recipe image \(path): \(error.localizedDescription)")
                            }
                        }
                    }
                }
                
                // Delete source images (images used for extraction) from sourceImageURLs array
                for sourceURL in recipe.sourceImageURLs {
                    if !sourceURL.isEmpty {
                        if let path = extractStoragePath(from: sourceURL) {
                            do {
                                let imageRef = storage.reference().child(path)
                                try await imageRef.delete()
                                print("🗑️ Deleted source image: \(path)")
                            } catch {
                                print("⚠️ Error deleting source image \(path): \(error.localizedDescription)")
                            }
                        }
                    }
                }
                
                // Delete deprecated single source image URL (if different from sourceImageURLs)
                if let sourceURL = recipe.sourceImageURL, !sourceURL.isEmpty {
                    // Only delete if not already in sourceImageURLs array
                    if !recipe.sourceImageURLs.contains(sourceURL) {
                        if let path = extractStoragePath(from: sourceURL) {
                            do {
                                let imageRef = storage.reference().child(path)
                                try await imageRef.delete()
                                print("🗑️ Deleted deprecated source image: \(path)")
                            } catch {
                                print("⚠️ Error deleting deprecated source image \(path): \(error.localizedDescription)")
                            }
                        }
                    }
                }
                
                // Delete instruction images and videos
                for instruction in recipe.instructions {
                    if let imageURL = instruction.imageURL, !imageURL.isEmpty {
                        if let path = extractStoragePath(from: imageURL) {
                            do {
                                let imageRef = storage.reference().child(path)
                                try await imageRef.delete()
                                print("🗑️ Deleted instruction image: \(path)")
                            } catch {
                                print("⚠️ Error deleting instruction image \(path): \(error.localizedDescription)")
                            }
                        }
                    }
                    if let videoURL = instruction.videoURL, !videoURL.isEmpty {
                        if let path = extractStoragePath(from: videoURL) {
                            do {
                                let videoRef = storage.reference().child(path)
                                try await videoRef.delete()
                                print("🗑️ Deleted instruction video: \(path)")
                            } catch {
                                print("⚠️ Error deleting instruction video \(path): \(error.localizedDescription)")
                            }
                        }
                    }
                }
            } else {
                // If recipe decoding fails, try to extract image URLs from raw document data
                print("⚠️ Could not decode recipe document, attempting to extract image URLs from raw data...")
                let data = recipeDoc.data()
                
                // Try to get imageURLs array
                if let imageURLs = data["imageURLs"] as? [String] {
                    for imageURL in imageURLs where !imageURL.isEmpty {
                        if let path = extractStoragePath(from: imageURL) {
                            do {
                                let imageRef = storage.reference().child(path)
                                try await imageRef.delete()
                                print("🗑️ Deleted recipe image (from raw data): \(path)")
                            } catch {
                                print("⚠️ Error deleting recipe image \(path): \(error.localizedDescription)")
                            }
                        }
                    }
                }
                
                // Try to get deprecated imageURL
                if let imageURL = data["imageURL"] as? String, !imageURL.isEmpty {
                    if let path = extractStoragePath(from: imageURL) {
                        do {
                            let imageRef = storage.reference().child(path)
                            try await imageRef.delete()
                            print("🗑️ Deleted recipe image (deprecated, from raw data): \(path)")
                        } catch {
                            print("⚠️ Error deleting deprecated recipe image \(path): \(error.localizedDescription)")
                        }
                    }
                }
                
                // Try to get sourceImageURLs array
                if let sourceImageURLs = data["sourceImages"] as? [String] {
                    for sourceURL in sourceImageURLs where !sourceURL.isEmpty {
                        if let path = extractStoragePath(from: sourceURL) {
                            do {
                                let imageRef = storage.reference().child(path)
                                try await imageRef.delete()
                                print("🗑️ Deleted source image (from raw data): \(path)")
                            } catch {
                                print("⚠️ Error deleting source image \(path): \(error.localizedDescription)")
                            }
                        }
                    }
                }
                
                // Try to get deprecated sourceImageURL
                if let sourceImageURL = data["sourceImageURL"] as? String, !sourceImageURL.isEmpty {
                    if let path = extractStoragePath(from: sourceImageURL) {
                        do {
                            let imageRef = storage.reference().child(path)
                            try await imageRef.delete()
                            print("🗑️ Deleted source image (deprecated, from raw data): \(path)")
                        } catch {
                            print("⚠️ Error deleting deprecated source image \(path): \(error.localizedDescription)")
                        }
                    }
                }
            }
            
            // Delete recipe document
            try await recipeDoc.reference.delete()
        }
        
        // 3. Delete user's notes
        print("🗑️ Deleting user notes...")
        let notesSnapshot = try await firestore.collection("recipeNotes")
            .whereField("userID", isEqualTo: userID)
            .getDocuments()
        
        for noteDoc in notesSnapshot.documents {
            try await noteDoc.reference.delete()
        }
        
        // 4. Delete profile image from storage
        print("🗑️ Deleting profile image...")
        let profileImageRef = storage.reference().child("profile_images/\(userID).jpg")
        try? await profileImageRef.delete()
        
        // 5. Delete user's favorites
        print("🗑️ Deleting favorites...")
        let favoritesSnapshot = try await firestore.collection("favorites")
            .whereField("userID", isEqualTo: userID)
            .getDocuments()
        
        for favoriteDoc in favoritesSnapshot.documents {
            try await favoriteDoc.reference.delete()
        }
        
        // 6. Delete follow relationships
        print("🗑️ Deleting follow relationships...")
        let followingSnapshot = try await firestore.collection("follows")
            .whereField("followerID", isEqualTo: userID)
            .getDocuments()
        
        for followDoc in followingSnapshot.documents {
            try await followDoc.reference.delete()
        }
        
        let followersSnapshot = try await firestore.collection("follows")
            .whereField("followingID", isEqualTo: userID)
            .getDocuments()
        
        for followDoc in followersSnapshot.documents {
            try await followDoc.reference.delete()
        }
        
        // 7. Delete user's subscription
        print("🗑️ Deleting subscription...")
        let subscriptionRef = firestore.collection("subscriptions").document(userID)
        try? await subscriptionRef.delete()
        
        // 8. Delete Firebase Auth user LAST (after all data is deleted)
        print("🗑️ Deleting Firebase Auth user...")
        if let user = Auth.auth().currentUser {
            try await user.delete()
        }
        
        // Sign out locally
        try? Auth.auth().signOut()
        isAuthenticated = false
        currentUser = nil
        
        print("✅ Account deletion completed")
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        try Auth.auth().signOut()
        isAuthenticated = false
        currentUser = nil
    }
}

// MARK: - Auth Error

enum AuthError: LocalizedError {
    case invalidCredential
    case invalidNonce
    case invalidToken
    case missingClientID
    case missingViewController
    case unauthorized
    case invalidImage
    case usernameTooShort
    case usernameTooLong
    case invalidUsername
    case usernameTaken
    case requiresRecentLogin
    
    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return LocalizedString("Invalid credential", comment: "Invalid credential error")
        case .invalidNonce:
            return LocalizedString("Invalid nonce", comment: "Invalid nonce error")
        case .invalidToken:
            return LocalizedString("Invalid token", comment: "Invalid token error")
        case .missingClientID:
            return LocalizedString("Missing client ID", comment: "Missing client ID error")
        case .missingViewController:
            return LocalizedString("Missing view controller", comment: "Missing view controller error")
        case .unauthorized:
            return LocalizedString("You are not authorized to perform this action", comment: "Unauthorized error")
        case .invalidImage:
            return LocalizedString("Invalid image", comment: "Invalid image error")
        case .usernameTooShort:
            return LocalizedString("Username must be at least 4 characters", comment: "Username too short error")
        case .usernameTooLong:
            return LocalizedString("Username must be no more than 15 characters", comment: "Username too long error")
        case .invalidUsername:
            return LocalizedString("Username contains invalid characters", comment: "Invalid username error")
        case .usernameTaken:
            return LocalizedString("This username is already taken", comment: "Username taken error")
        case .requiresRecentLogin:
            return LocalizedString("Requires recent login", comment: "Requires recent login error")
        }
    }
}

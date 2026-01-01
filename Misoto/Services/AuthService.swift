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
import AuthenticationServices
import CryptoKit
import GoogleSignIn

@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var isAuthenticated = false
    @Published var isInitializing = true
    
    private let firestore = FirebaseManager.shared.firestore
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
        
        // Get user info
        let displayName = authResult.user.displayName ?? "User"
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
            
            // Create or update user document
            let displayName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            
            let email = appleIDCredential.email
            
            await createOrUpdateUser(
                userID: userID,
                email: email,
                displayName: displayName.isEmpty ? "User" : displayName
            )
            
            await checkAuthState()
            
        case .failure(let error):
            throw error
        }
    }
    
    // MARK: - User Management
    
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
                // Create new user with lastLogin set to now
                let newUser = AppUser(
                    id: userID,
                    email: email,
                    displayName: displayName,
                    lastLogin: Date()
                )
                try await userRef.setData(from: newUser)
            }
        } catch {
            print("Error creating/updating user: \(error.localizedDescription)")
        }
    }
    
    private func loadUserData(userID: String) async {
        do {
            let document = try await firestore.collection("users").document(userID).getDocument()
            
            if let user = try? document.data(as: AppUser.self) {
                currentUser = user
            }
        } catch {
            print("Error loading user data: \(error.localizedDescription)")
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
        await reloadUserData()
    }
    
    func uploadProfileImage(_ image: UIImage) async throws -> String {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw AuthError.unauthorized
        }
        
        let storageService = StorageService()
        let path = "profile_images/\(userID).jpg"
        let imageURL = try await storageService.uploadImage(image, path: path)
        
        // Update user document with new profile image URL
        let userRef = firestore.collection("users").document(userID)
        try await userRef.updateData([
            "profileImageURL": imageURL,
            "updatedAt": Timestamp(date: Date())
        ])
        
        await reloadUserData()
        return imageURL
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    // MARK: - Helper Methods
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
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
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

enum AuthError: LocalizedError, Equatable {
    case invalidCredential
    case invalidNonce
    case invalidToken
    case missingClientID
    case missingViewController
    case unauthorized
    case usernameTooShort
    case usernameTooLong
    case usernameTaken
    case invalidUsername
    
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
        case .usernameTooShort:
            return LocalizedString("Username must be at least 4 characters", comment: "Username too short error")
        case .usernameTooLong:
            return LocalizedString("Username must be no more than 15 characters", comment: "Username too long error")
        case .usernameTaken:
            return LocalizedString("This username is already taken", comment: "Username taken error")
        case .invalidUsername:
            return LocalizedString("Username contains invalid characters", comment: "Invalid username error")
        }
    }
}


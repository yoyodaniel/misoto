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
    
    private let firestore = FirebaseManager.shared.firestore
    private var currentNonce: String?
    
    init() {
        Task {
            await checkAuthState()
        }
    }
    
    // MARK: - Authentication State
    
    func checkAuthState() async {
        if let firebaseUser = Auth.auth().currentUser {
            await loadUserData(userID: firebaseUser.uid)
            isAuthenticated = true
            print("✅ User authenticated: \(firebaseUser.uid)")
        } else {
            currentUser = nil
            isAuthenticated = false
            print("❌ No authenticated user")
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
                // Update existing user
                try await userRef.updateData([
                    "email": email as Any,
                    "displayName": displayName,
                    "updatedAt": Timestamp(date: Date())
                ])
            } else {
                // Create new user
                let newUser = AppUser(
                    id: userID,
                    email: email,
                    displayName: displayName
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

enum AuthError: LocalizedError {
    case invalidCredential
    case invalidNonce
    case invalidToken
    case missingClientID
    case missingViewController
    
    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return NSLocalizedString("Invalid credential", comment: "Invalid credential error")
        case .invalidNonce:
            return NSLocalizedString("Invalid nonce", comment: "Invalid nonce error")
        case .invalidToken:
            return NSLocalizedString("Invalid token", comment: "Invalid token error")
        case .missingClientID:
            return NSLocalizedString("Missing client ID", comment: "Missing client ID error")
        case .missingViewController:
            return NSLocalizedString("Missing view controller", comment: "Missing view controller error")
        }
    }
}


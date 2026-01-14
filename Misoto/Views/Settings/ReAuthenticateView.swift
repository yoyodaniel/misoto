//
//  ReAuthenticateView.swift
//  Misoto
//
//  Created by Daniel Chan on 30.12.2025.
//

import SwiftUI
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import UIKit

struct ReAuthenticateView: View {
    let authService: AuthService
    let onSuccess: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?
    @State private var isAuthenticating = false
    @State private var currentNonce: String?
    
    private var userEmail: String? {
        Auth.auth().currentUser?.email
    }
    
    private var authProvider: String? {
        Auth.auth().currentUser?.providerData.first?.providerID
    }
    
    private var isGoogleProvider: Bool {
        authProvider == "google.com"
    }
    
    private var isAppleProvider: Bool {
        authProvider == "apple.com"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    if let email = userEmail {
                        Text(email)
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                    }
                    
                    if isGoogleProvider {
                        Button(action: {
                            HapticFeedback.buttonTap()
                            Task {
                                await reAuthenticateWithGoogle()
                            }
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                    .font(.system(size: 18))
                                Text(LocalizedString("Continue with Google", comment: "Google sign in button"))
                                    .font(.system(size: 17, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.primary)
                        }
                        .disabled(isAuthenticating)
                    }
                    
                    if isAppleProvider {
                        SignInWithAppleButton(
                            onRequest: { request in
                                let nonce = randomNonceString()
                                currentNonce = nonce
                                request.requestedScopes = [.fullName, .email]
                                request.nonce = sha256(nonce)
                            },
                            onCompletion: { result in
                                Task {
                                    await handleAppleSignIn(result)
                                }
                            }
                        )
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .disabled(isAuthenticating)
                    }
                } header: {
                    Text(LocalizedString("Re-authenticate", comment: "Re-authenticate header"))
                } footer: {
                    Text(LocalizedString("For security, please re-authenticate to confirm account deletion.", comment: "Re-authenticate footer"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(LocalizedString("Re-authenticate", comment: "Re-authenticate title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedString("Cancel", comment: "Cancel button")) {
                        HapticFeedback.buttonTap()
                        dismiss()
                    }
                    .disabled(isAuthenticating)
                }
            }
            .overlay {
                if isAuthenticating {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                }
            }
        }
    }
    
    private func reAuthenticateWithGoogle() async {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = LocalizedString("Unable to re-authenticate. Please try again.", comment: "Re-authenticate error")
            return
        }
        
        isAuthenticating = true
        errorMessage = nil
        
        do {
            try await authService.reAuthenticateWithGoogle(presentingViewController: rootViewController)
            isAuthenticating = false
            onSuccess()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticating = false
            print("⚠️ Google re-authentication error: \(error.localizedDescription)")
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        isAuthenticating = true
        errorMessage = nil
        
        do {
            guard let nonce = currentNonce else {
                throw AuthError.invalidNonce
            }
            try await authService.reAuthenticateWithApple(result: result, nonce: nonce)
            currentNonce = nil
            isAuthenticating = false
            onSuccess()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            currentNonce = nil
            isAuthenticating = false
            print("⚠️ Apple re-authentication error: \(error.localizedDescription)")
        }
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

#Preview {
    ReAuthenticateView(authService: AuthService(), onSuccess: {})
}

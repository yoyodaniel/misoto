//
//  LoginView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import AuthenticationServices
import CryptoKit
import UIKit

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var currentNonce: String?
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "fork.knife")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text(LocalizedString("Misoto", comment: "App name"))
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(LocalizedString("Share and discover amazing recipes", comment: "App tagline"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            VStack(spacing: 16) {
                // Google Sign In Button
                Button(action: {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        Task {
                            await viewModel.signInWithGoogle(presentingViewController: rootViewController)
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "globe")
                            .font(.system(size: 18))
                        Text(LocalizedString("Continue with Google", comment: "Google sign in button"))
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .cornerRadius(8)
                }
                .disabled(viewModel.isLoading)
                
                // Apple Sign In Button
                SignInWithAppleButton(
                    onRequest: { request in
                        let nonce = randomNonceString()
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = sha256(nonce)
                    },
                    onCompletion: { result in
                        Task {
                            await viewModel.handleAppleSignInResult(result, nonce: currentNonce)
                            currentNonce = nil
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal, 40)
            
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            }
            
            Spacer()
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
    LoginView()
}


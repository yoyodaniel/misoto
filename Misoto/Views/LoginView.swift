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
    @Environment(\.dismiss) private var dismiss
    @State private var currentNonce: String?
    @State private var showTermsOfService = false
    @State private var showPrivacyPolicy = false
    
    var body: some View {
        ZStack {
            // Background Image
            Image("misoto")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .offset(x: -15) // Shift image left slightly so bowl centers under title
                .ignoresSafeArea()
            
            // Gradient Overlay for Text Readability
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.0),
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.6)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content
            VStack(spacing: 30) {
                Spacer()
                
                // App Name and Tagline
                VStack(spacing: 8) {
                    Text(LocalizedString("Misoto", comment: "App name"))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(LocalizedString("Share and discover amazing recipes", comment: "App tagline"))
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.horizontal, 40)
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
                        HStack(spacing: 12) {
                            // Google G icon
                            Image(systemName: "globe")
                                .font(.system(size: 18))
                                .foregroundColor(Color(red: 0, green: 0, blue: 0)) // Explicit black, no dark mode adaptation
                            Text(LocalizedString("Continue with Google", comment: "Google sign in button"))
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(Color(red: 0, green: 0, blue: 0)) // Explicit black, no dark mode adaptation
                        }
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 1, green: 1, blue: 1).opacity(0.85)) // Explicit white, no dark mode adaptation
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(red: 0.5, green: 0.5, blue: 0.5).opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, 40)
                    
                    // Apple Sign In Button with transparent background
                    ZStack {
                        // Transparent background - must be behind the button
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0, green: 0, blue: 0).opacity(0.75)) // Explicit black, no dark mode adaptation
                            .frame(height: 50)
                        
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
                        .cornerRadius(12)
                        .opacity(0.95) // Make button itself slightly transparent
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, 40)
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding()
                }
                
                // Terms and Privacy Policy Agreement
                agreementTextView
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showTermsOfService) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .onChange(of: viewModel.isAuthenticated) { _, isAuthenticated in
            // Dismiss the login view when user successfully authenticates
            if isAuthenticated {
                // Use async to ensure dismiss happens on the main thread after state updates
                Task { @MainActor in
                    // Small delay to allow any UI animations to complete
                    try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - View Builders
    
    @ViewBuilder
    private var agreementTextView: some View {
        VStack(spacing: 4) {
            Text(LocalizedString("By signing in, you agree to our", comment: "Agreement base text"))
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            HStack(spacing: 4) {
                Button(action: {
                    HapticFeedback.buttonTap()
                    showTermsOfService = true
                }) {
                    Text(LocalizedString("Terms & Conditions", comment: "Terms link text"))
                        .font(.caption)
                        .foregroundColor(.white)
                        .underline()
                }
                .buttonStyle(PlainButtonStyle())
                
                Text(LocalizedString("and", comment: "And connector"))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Button(action: {
                    HapticFeedback.buttonTap()
                    showPrivacyPolicy = true
                }) {
                    Text(LocalizedString("Privacy Policy", comment: "Privacy link text"))
                        .font(.caption)
                        .foregroundColor(.white)
                        .underline()
                }
                .buttonStyle(PlainButtonStyle())
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
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


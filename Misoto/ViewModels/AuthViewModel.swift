//
//  AuthViewModel.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine
import AuthenticationServices
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: AppUser?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let authService = AuthService()
    
    init() {
        Task {
            await checkAuthState()
        }
    }
    
    func checkAuthState() async {
        await authService.checkAuthState()
        // Update published properties to trigger UI refresh
        isAuthenticated = authService.isAuthenticated
        currentUser = authService.currentUser
        print("Auth state updated: isAuthenticated = \(isAuthenticated)")
    }
    
    func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>, nonce: String?) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.handleAppleSignInResult(result, nonce: nonce)
            print("✅ Apple sign in successful, checking auth state...")
            await checkAuthState()
            print("✅ Auth state check complete. isAuthenticated = \(isAuthenticated)")
        } catch {
            print("❌ Apple sign in error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signInWithGoogle(presentingViewController: UIViewController) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signInWithGoogle(presentingViewController: presentingViewController)
            print("✅ Google sign in successful, checking auth state...")
            await checkAuthState()
            print("✅ Auth state check complete. isAuthenticated = \(isAuthenticated)")
        } catch {
            print("❌ Google sign in error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try authService.signOut()
            // Update state to trigger UI refresh
            isAuthenticated = false
            currentUser = nil
            print("✅ User signed out successfully")
        } catch {
            print("❌ Sign out error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    func reloadUserData() async {
        await authService.reloadUserData()
        currentUser = authService.currentUser
    }
}


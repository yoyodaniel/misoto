//
//  AccountViewModel.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AccountViewModel: ObservableObject {
    @Published var userRecipes: [Recipe] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let recipeService = RecipeService()
    private let authService = AuthService()
    private let firestore = FirebaseManager.shared.firestore
    private var userListener: ListenerRegistration?
    
    init() {
        setupUserListener()
    }
    
    deinit {
        userListener?.remove()
    }
    
    // MARK: - Real-time User Stats Listener
    
    private func setupUserListener() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let userRef = firestore.collection("users").document(userID)
        userListener = userRef.addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening to user updates: \(error.localizedDescription)")
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists else { return }
                
                // Reload user data in AuthService to update currentUser
                // This will trigger the Combine publisher and update AuthViewModel
                await self.authService.reloadUserData()
                print("✅ User data updated from real-time listener")
            }
        }
    }
    
    // MARK: - Recipe Management
    
    func loadUserRecipes() async {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("⚠️ No user ID found")
            return
        }
        
        print("🔍 Loading recipes for user: \(userID)")
        isLoading = true
        errorMessage = nil
        
        do {
            userRecipes = try await recipeService.fetchRecipes(byUserID: userID)
            print("✅ Loaded \(userRecipes.count) recipes")
        } catch {
            print("❌ Error loading recipes: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteRecipe(_ recipe: Recipe) {
        // Optimistic update: Remove from UI immediately (synchronous, no async)
        let recipeID = recipe.id
        userRecipes.removeAll { $0.id == recipeID }
        print("✅ Recipe removed from UI instantly")
        
        // Delete from backend asynchronously in background (don't block UI)
        Task { @MainActor in
            do {
                try await recipeService.deleteRecipe(recipeID: recipeID)
                print("✅ Recipe deleted from backend")
            } catch {
                // If deletion fails, log the error but don't disrupt UI
                print("❌ Error deleting recipe from backend: \(error.localizedDescription)")
                // Could optionally show a toast/alert, but don't re-add to avoid confusion
            }
        }
    }
    
    // MARK: - Profile Updates
    
    func updateProfile(displayName: String?, username: String?, bio: String?) async throws {
        try await authService.updateProfile(displayName: displayName, username: username, bio: bio)
    }
    
    func uploadProfileImage(_ image: UIImage) async throws {
        _ = try await authService.uploadProfileImage(image)
    }
    
    func generateUsernameAlternatives(_ username: String) -> [String] {
        return authService.generateUsernameAlternatives(username)
    }
    
    func checkUsernameAvailability(_ username: String) async throws -> Bool {
        guard let userID = Auth.auth().currentUser?.uid else {
            return false
        }
        return try await authService.isUsernameAvailable(username, excludingUserID: userID)
    }
}


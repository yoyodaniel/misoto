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
    
    private let recipeService = RecipeService.shared
    private let authService = AuthService()
    private let firestore = FirebaseManager.shared.firestore
    private var userListener: ListenerRegistration?
    var authViewModel: AuthViewModel?
    
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
    
    func toggleRecipePrivacy(recipe: Recipe, clearSharedWith: Bool = false) async {
        let recipeID = recipe.id
        let newPrivacyStatus = !recipe.isPrivate
        
        // Optimistic update: Update UI immediately
        if let index = userRecipes.firstIndex(where: { $0.id == recipeID }) {
            let currentSharedWith = userRecipes[index].sharedWith
            userRecipes[index].isPrivate = newPrivacyStatus
            
            // If making private and clearSharedWith is true: Save current sharedWith to preservedSharedWith, then clear sharedWith
            if newPrivacyStatus && clearSharedWith {
                // Save current sharedWith to preservedSharedWith before clearing (if it has users)
                if !currentSharedWith.isEmpty {
                    userRecipes[index].preservedSharedWith = currentSharedWith
                }
                // Always clear sharedWith when making "Private to All" (removes access)
                userRecipes[index].sharedWith = []
            }
            // When making public: Restore preservedSharedWith to sharedWith if it exists
            else if !newPrivacyStatus {
                // Restore preserved sharedWith list if it exists
                if let preserved = userRecipes[index].preservedSharedWith, !preserved.isEmpty {
                    userRecipes[index].sharedWith = preserved
                    userRecipes[index].preservedSharedWith = nil // Clear preserved list after restore
                }
                // If no preserved list, keep current sharedWith as-is
            }
            // When making private with clearSharedWith=false: Preserve sharedWith (for "Private Sharing" flow)
            //   No changes needed - sharedWith is already set correctly
            print("✅ Recipe privacy updated optimistically in UI, sharedWith: \(userRecipes[index].sharedWith.count) users, preserved: \(userRecipes[index].preservedSharedWith?.count ?? 0) users")
        }
        
        // Update backend
        do {
            try await recipeService.toggleRecipePrivacy(recipeID: recipeID, isPrivate: newPrivacyStatus, clearSharedWith: clearSharedWith)
            print("✅ Recipe privacy updated in backend")
        } catch {
            // Revert optimistic update on error
            if let index = userRecipes.firstIndex(where: { $0.id == recipeID }) {
                userRecipes[index].isPrivate = !newPrivacyStatus
                // Restore original sharedWith if reverting
                if newPrivacyStatus && clearSharedWith {
                    userRecipes[index].sharedWith = recipe.sharedWith
                }
            }
            print("❌ Error toggling recipe privacy: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    func updateRecipeSharing(recipe: Recipe, sharedWith: [String]) async {
        let recipeID = recipe.id
        
        // Optimistic update: Update UI immediately
        // Clear preservedSharedWith when user explicitly sets sharing
        if let index = userRecipes.firstIndex(where: { $0.id == recipeID }) {
            userRecipes[index].sharedWith = sharedWith
            // Ensure recipe is private when sharing
            userRecipes[index].isPrivate = true
            // Clear preservedSharedWith when user explicitly sets sharing (they're choosing new users)
            userRecipes[index].preservedSharedWith = nil
            print("✅ Recipe sharing updated optimistically in UI")
        }
        
        // Update backend
        do {
            try await recipeService.updateRecipeSharing(recipeID: recipeID, sharedWith: sharedWith)
            print("✅ Recipe sharing updated in backend")
        } catch {
            // Revert optimistic update on error
            if let index = userRecipes.firstIndex(where: { $0.id == recipeID }) {
                userRecipes[index].sharedWith = recipe.sharedWith
            }
            print("❌ Error updating recipe sharing: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteRecipe(_ recipe: Recipe) {
        // Optimistic update: Remove from UI immediately (synchronous, no async)
        let recipeID = recipe.id
        userRecipes.removeAll { $0.id == recipeID }
        print("✅ Recipe removed from UI instantly")
        
        // Optimistically update recipe count in user object
        if var currentUser = authService.currentUser {
            currentUser.recipeCount = max(0, currentUser.recipeCount - 1)
            authService.currentUser = currentUser
            print("✅ Recipe count updated optimistically: \(currentUser.recipeCount)")
        }
        
        // Delete from backend asynchronously in background (don't block UI)
        Task { @MainActor in
            do {
                // Delete recipe and update Firebase recipe count
                try await recipeService.deleteRecipe(recipeID: recipeID)
                print("✅ Recipe deleted from backend and Firebase recipeCount decremented")
                
                // Post notification to refresh feeds/views
                NotificationCenter.default.post(name: NSNotification.Name("RecipeDeleted"), object: nil, userInfo: ["recipeID": recipeID])
                
                // Explicitly reload user data to ensure UI reflects the updated count from Firebase
                await authService.reloadUserData()
                if let authVM = authViewModel {
                    await authVM.reloadUserData()
                }
                print("✅ User data reloaded - recipe count should now be: \(authService.currentUser?.recipeCount ?? 0)")
            } catch {
                // If deletion fails, log the error but don't disrupt UI
                print("❌ Error deleting recipe from backend: \(error.localizedDescription)")
                // Revert optimistic update if deletion failed
                if var currentUser = authService.currentUser {
                    currentUser.recipeCount += 1
                    authService.currentUser = currentUser
                }
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
    
    // MARK: - Account Management
    
    func toggleProfileVisibility(hidden: Bool) async throws {
        try await authService.toggleProfileVisibility(hidden: hidden)
    }
    
    func toggleCompletePrivacy(isPrivate: Bool) async throws {
        try await authService.toggleCompletePrivacy(isPrivate: isPrivate)
    }
    
    func deleteAccount() async throws {
        try await authService.deleteAccount()
    }
}


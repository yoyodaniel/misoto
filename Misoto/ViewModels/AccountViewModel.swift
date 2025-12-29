//
//  AccountViewModel.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class AccountViewModel: ObservableObject {
    @Published var userRecipes: [Recipe] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let recipeService = RecipeService()
    
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
    
    func deleteRecipe(_ recipe: Recipe) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await recipeService.deleteRecipe(recipeID: recipe.id)
            await loadUserRecipes()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}


//
//  FavoritesViewModel.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class FavoritesViewModel: ObservableObject {
    @Published var favoriteRecipes: [Recipe] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let recipeService = RecipeService()
    
    func loadFavorites() async {
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = LocalizedString("You must be logged in to view favorites", comment: "Not logged in error")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            favoriteRecipes = try await recipeService.fetchFavoriteRecipes(userID: userID)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func removeFavorite(recipeID: String) async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        do {
            try await recipeService.removeFavorite(recipeID: recipeID, userID: userID)
            await loadFavorites()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}


//
//  RecipeService.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

@MainActor
class RecipeService: ObservableObject {
    private let firestore = FirebaseManager.shared.firestore
    private let recipesCollection = "recipes"
    private let favoritesCollection = "favorites"
    
    // MARK: - Create Recipe
    
    func createRecipe(_ recipe: Recipe) async throws {
        let recipeRef = firestore.collection(recipesCollection).document(recipe.id)
        try recipeRef.setData(from: recipe)
        
        // Update user's recipe count
        if let userID = Auth.auth().currentUser?.uid {
            try await updateUserRecipeCount(userID: userID, increment: 1)
        }
    }
    
    // MARK: - Read Recipes
    
    func fetchAllRecipes() async throws -> [Recipe] {
        let snapshot = try await firestore.collection(recipesCollection)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        var recipes: [Recipe] = []
        for document in snapshot.documents {
            do {
                let recipe = try document.data(as: Recipe.self)
                recipes.append(recipe)
            } catch {
                print("⚠️ Failed to decode recipe \(document.documentID): \(error.localizedDescription)")
                print("Document data: \(document.data())")
                // Continue processing other documents instead of failing completely
            }
        }
        
        return recipes
    }
    
    func fetchRecipe(byID recipeID: String) async throws -> Recipe? {
        let document = try await firestore.collection(recipesCollection).document(recipeID).getDocument()
        return try? document.data(as: Recipe.self)
    }
    
    func fetchRecipes(byUserID userID: String) async throws -> [Recipe] {
        let snapshot = try await firestore.collection(recipesCollection)
            .whereField("authorID", isEqualTo: userID)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        var recipes: [Recipe] = []
        for document in snapshot.documents {
            do {
                let recipe = try document.data(as: Recipe.self)
                recipes.append(recipe)
            } catch {
                print("⚠️ Failed to decode recipe \(document.documentID): \(error.localizedDescription)")
                print("Document data: \(document.data())")
                // Continue processing other documents instead of failing completely
            }
        }
        
        return recipes
    }
    
    // MARK: - Update Recipe
    
    func updateRecipe(_ recipe: Recipe) async throws {
        let recipeRef = firestore.collection(recipesCollection).document(recipe.id)
        var updatedRecipe = recipe
        updatedRecipe.updatedAt = Date()
        try recipeRef.setData(from: updatedRecipe, merge: true)
    }
    
    // MARK: - Delete Recipe
    
    func deleteRecipe(recipeID: String) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw RecipeError.unauthorized
        }
        
        // Verify ownership
        guard let recipe = try await fetchRecipe(byID: recipeID),
              recipe.authorID == userID else {
            throw RecipeError.unauthorized
        }
        
        try await firestore.collection(recipesCollection).document(recipeID).delete()
        
        // Update user's recipe count
        try await updateUserRecipeCount(userID: userID, increment: -1)
    }
    
    // MARK: - Favorites
    
    func addFavorite(recipeID: String, userID: String) async throws {
        // Check if already favorited
        let existingFavorites = try await fetchFavorites(userID: userID)
        if existingFavorites.contains(where: { $0.recipeID == recipeID }) {
            return // Already favorited
        }
        
        let favorite = Favorite(userID: userID, recipeID: recipeID)
        try firestore.collection(favoritesCollection).document(favorite.id).setData(from: favorite)
        
        // Increment favorite count
        try await incrementFavoriteCount(recipeID: recipeID, increment: 1)
    }
    
    func removeFavorite(recipeID: String, userID: String) async throws {
        let favorites = try await fetchFavorites(userID: userID)
        if let favorite = favorites.first(where: { $0.recipeID == recipeID }) {
            try await firestore.collection(favoritesCollection).document(favorite.id).delete()
            
            // Decrement favorite count
            try await incrementFavoriteCount(recipeID: recipeID, increment: -1)
        }
    }
    
    func fetchFavorites(userID: String) async throws -> [Favorite] {
        let snapshot = try await firestore.collection(favoritesCollection)
            .whereField("userID", isEqualTo: userID)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: Favorite.self)
        }
    }
    
    func isFavorite(recipeID: String, userID: String) async throws -> Bool {
        let favorites = try await fetchFavorites(userID: userID)
        return favorites.contains(where: { $0.recipeID == recipeID })
    }
    
    func fetchFavoriteRecipes(userID: String) async throws -> [Recipe] {
        let favorites = try await fetchFavorites(userID: userID)
        let recipeIDs = favorites.map { $0.recipeID }
        
        var recipes: [Recipe] = []
        for recipeID in recipeIDs {
            if let recipe = try await fetchRecipe(byID: recipeID) {
                recipes.append(recipe)
            }
        }
        
        return recipes.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Helper Methods
    
    private func incrementFavoriteCount(recipeID: String, increment: Int) async throws {
        let recipeRef = firestore.collection(recipesCollection).document(recipeID)
        try await recipeRef.updateData([
            "favoriteCount": FieldValue.increment(Int64(increment))
        ])
    }
    
    private func updateUserRecipeCount(userID: String, increment: Int) async throws {
        let userRef = firestore.collection("users").document(userID)
        try await userRef.updateData([
            "recipeCount": FieldValue.increment(Int64(increment))
        ])
    }
}

enum RecipeError: LocalizedError {
    case unauthorized
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return LocalizedString("You are not authorized to perform this action", comment: "Unauthorized error")
        case .notFound:
            return LocalizedString("Recipe not found", comment: "Recipe not found error")
        }
    }
}


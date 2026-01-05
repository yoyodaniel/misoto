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
        
        // Filter out recipes from banned users and hidden recipes
        let filteredRecipes = try await filterRecipesFromBannedUsers(recipes: recipes)
        // Also filter recipes with report count >= 10 (defensive check in case isHidden wasn't set)
        return filteredRecipes.filter { !$0.isHidden && $0.reportCount < 10 }
    }
    
    /// Fetch recipes posted today, sorted by favorite count (likes) in descending order
    /// - Parameters:
    ///   - limit: Maximum number of recipes to fetch (default: 20)
    ///   - startAfter: Document snapshot to start after for pagination (optional)
    /// - Returns: Tuple containing recipes and the last document for pagination
    func fetchTodaysRecipes(limit: Int = 20, startAfter: DocumentSnapshot? = nil) async throws -> ([Recipe], DocumentSnapshot?) {
        // Get start and end of today
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        
        let startTimestamp = Timestamp(date: startOfToday)
        let endTimestamp = Timestamp(date: endOfToday)
        
        // Query recipes created today - use createdAt ordering first (no composite index needed)
        // Then sort by favoriteCount in memory
        var query = firestore.collection(recipesCollection)
            .whereField("createdAt", isGreaterThanOrEqualTo: startTimestamp)
            .whereField("createdAt", isLessThan: endTimestamp)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
        
        if let startAfter = startAfter {
            query = query.start(afterDocument: startAfter)
        }
        
        let snapshot = try await query.getDocuments()
        
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
        
        // Sort by favoriteCount (likes) in descending order
        recipes.sort { $0.favoriteCount > $1.favoriteCount }
        
        // Filter out recipes from banned users and hidden recipes
        let filteredRecipes = try await filterRecipesFromBannedUsers(recipes: recipes)
        // Also filter recipes with report count >= 10 (defensive check in case isHidden wasn't set)
        let finalRecipes = filteredRecipes.filter { !$0.isHidden && $0.reportCount < 10 }
        
        // Get the last document for pagination
        let lastDocument = snapshot.documents.last
        
        return (finalRecipes, lastDocument)
    }
    
    func fetchRecipe(byID recipeID: String) async throws -> Recipe? {
        let document = try await firestore.collection(recipesCollection).document(recipeID).getDocument()
        return try? document.data(as: Recipe.self)
    }
    
    func fetchRecipes(byUserID userID: String, includeHidden: Bool = false) async throws -> [Recipe] {
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
        
        // Verify ownership and get recipe data
        guard let recipe = try await fetchRecipe(byID: recipeID),
              recipe.authorID == userID else {
            throw RecipeError.unauthorized
        }
        
        // Delete associated images from Firebase Storage
        let storageService = StorageService()
        
        // Delete recipe images (imageURLs array)
        for imageURL in recipe.imageURLs {
            try? await storageService.deleteFile(from: imageURL)
        }
        
        // Delete deprecated single imageURL if present
        if let imageURL = recipe.imageURL, !imageURL.isEmpty {
            try? await storageService.deleteFile(from: imageURL)
        }
        
        // Delete source images (sourceImageURLs array)
        for sourceImageURL in recipe.sourceImageURLs {
            try? await storageService.deleteFile(from: sourceImageURL)
        }
        
        // Delete deprecated single sourceImageURL if present
        if let sourceImageURL = recipe.sourceImageURL, !sourceImageURL.isEmpty {
            try? await storageService.deleteFile(from: sourceImageURL)
        }
        
        // Delete instruction images and videos
        for instruction in recipe.instructions {
            if let instructionImageURL = instruction.imageURL {
                try? await storageService.deleteFile(from: instructionImageURL)
            }
            if let instructionVideoURL = instruction.videoURL {
                try? await storageService.deleteFile(from: instructionVideoURL)
            }
        }
        
        // Delete recipe document from Firestore
        try await firestore.collection(recipesCollection).document(recipeID).delete()
        
        // Update user's recipe count
        try await updateUserRecipeCount(userID: userID, increment: -1)
    }
    
    // MARK: - Favorites
    
    func addFavorite(recipeID: String, userID: String) async throws {
        // Check if already favorited/liked
        let existingFavorites = try await fetchFavorites(userID: userID)
        if existingFavorites.contains(where: { $0.recipeID == recipeID }) {
            return // Already liked
        }
        
        // Get the recipe to find the author ID
        guard let recipe = try await fetchRecipe(byID: recipeID) else {
            throw NSError(domain: "RecipeService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Recipe not found"])
        }
        let authorID = recipe.authorID
        
        let favorite = Favorite(userID: userID, recipeID: recipeID)
        try firestore.collection(favoritesCollection).document(favorite.id).setData(from: favorite)
        
        // Increment recipe's favorite/like count
        try await incrementFavoriteCount(recipeID: recipeID, increment: 1)
        
        // Increment recipe AUTHOR's total likes count (not the liker's)
        try await incrementUserLikesCount(userID: authorID, increment: 1)
    }
    
    func removeFavorite(recipeID: String, userID: String) async throws {
        let favorites = try await fetchFavorites(userID: userID)
        guard let favorite = favorites.first(where: { $0.recipeID == recipeID }) else {
            return // Not favorited
        }
        
        // Get the recipe to find the author ID
        guard let recipe = try await fetchRecipe(byID: recipeID) else {
            // Recipe might have been deleted, but we should still remove the favorite
            try await firestore.collection(favoritesCollection).document(favorite.id).delete()
            return
        }
        let authorID = recipe.authorID
        
        try await firestore.collection(favoritesCollection).document(favorite.id).delete()
        
        // Decrement recipe's favorite/like count
        try await incrementFavoriteCount(recipeID: recipeID, increment: -1)
        
        // Decrement recipe AUTHOR's total likes count (not the liker's)
        try await incrementUserLikesCount(userID: authorID, increment: -1)
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
        
        // Filter out recipes from banned users and hidden recipes
        let filteredRecipes = try await filterRecipesFromBannedUsers(recipes: recipes.sorted { $0.createdAt > $1.createdAt })
        // Also filter recipes with report count >= 10 (defensive check in case isHidden wasn't set)
        return filteredRecipes.filter { !$0.isHidden && $0.reportCount < 10 }
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
    
    private func incrementUserLikesCount(userID: String, increment: Int) async throws {
        let userRef = firestore.collection("users").document(userID)
        try await userRef.updateData([
            "likesCount": FieldValue.increment(Int64(increment))
        ])
    }
    
    // MARK: - Filter Banned Users
    
    /// Filters out recipes from banned users
    private func filterRecipesFromBannedUsers(recipes: [Recipe]) async throws -> [Recipe] {
        // Get unique author IDs
        let authorIDs = Set(recipes.map { $0.authorID })
        
        // Batch check which users are banned
        var bannedUserIDs: Set<String> = []
        
        await withTaskGroup(of: (String, Bool).self) { group in
            for authorID in authorIDs {
                group.addTask {
                    do {
                        let userDoc = try await self.firestore.collection("users").document(authorID).getDocument()
                        if userDoc.exists, let userData = userDoc.data() {
                            let isBanned = (userData["isBanned"] as? Bool) ?? false
                            return (authorID, isBanned)
                        }
                        return (authorID, false)
                    } catch {
                        print("⚠️ Error checking ban status for user \(authorID): \(error.localizedDescription)")
                        return (authorID, false) // Err on the side of caution - don't filter if we can't verify
                    }
                }
            }
            
            for await (userID, isBanned) in group {
                if isBanned {
                    bannedUserIDs.insert(userID)
                }
            }
        }
        
        // Filter out recipes from banned users
        return recipes.filter { !bannedUserIDs.contains($0.authorID) }
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


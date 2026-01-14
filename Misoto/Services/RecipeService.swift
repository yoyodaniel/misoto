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
    static let shared = RecipeService()
    
    private let firestore = FirebaseManager.shared.firestore
    private let recipesCollection = "recipes"
    private let favoritesCollection = "favorites"
    private let shareService = RecipeShareService.shared
    
    private init() {}
    
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
        // Filter out private recipes from public feeds (unless shared with current user)
        let currentUserID = Auth.auth().currentUser?.uid
        return filteredRecipes.filter { recipe in
            !recipe.isHidden && 
            recipe.reportCount < 10 &&
            (!recipe.isPrivate || recipe.authorID == currentUserID || (currentUserID != nil && recipe.sharedWith.contains(currentUserID ?? ""))) // Allow if public, owner, or shared with user
        }
    }
    
    /// Fetch latest recipes with pagination, ordered by creation date (newest first)
    /// - Parameters:
    ///   - limit: Maximum number of recipes to fetch (default: 10)
    ///   - startAfter: Document snapshot to start after for pagination (optional)
    /// - Returns: Tuple containing recipes and the last document for pagination
    func fetchLatestRecipes(limit: Int = 10, startAfter: DocumentSnapshot? = nil) async throws -> ([Recipe], DocumentSnapshot?) {
        var query = firestore.collection(recipesCollection)
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
        
        // Filter out recipes from banned users and hidden recipes
        let filteredRecipes = try await filterRecipesFromBannedUsers(recipes: recipes)
        // Also filter recipes with report count >= 10 (defensive check in case isHidden wasn't set)
        // Filter out ALL private recipes from public feeds (even if shared with current user)
        // Shared recipes should only be accessible via direct link/search, not public feeds
        let finalRecipes = filteredRecipes.filter { recipe in
            !recipe.isHidden &&
            recipe.reportCount < 10 &&
            !recipe.isPrivate // Exclude all private recipes (including shared ones) from public feeds
        }
        
        // Get the last document for pagination
        let lastDocument = snapshot.documents.last
        
        return (finalRecipes, lastDocument)
    }
    
    /// Fetch recipes posted today, sorted by creation date in descending order (newest first)
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
        
        // Query recipes created today - ordered by createdAt (newest first)
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
        
        // Sort by createdAt (date of creation) in descending order (newest first)
        recipes.sort { $0.createdAt > $1.createdAt }
        
        // Filter out recipes from banned users and hidden recipes
        let filteredRecipes = try await filterRecipesFromBannedUsers(recipes: recipes)
        // Also filter recipes with report count >= 10 (defensive check in case isHidden wasn't set)
        // Filter out ALL private recipes from public feeds (even if shared with current user)
        // Shared recipes should only be accessible via direct link/search, not public feeds
        let finalRecipes = filteredRecipes.filter { recipe in
            !recipe.isHidden &&
            recipe.reportCount < 10 &&
            !recipe.isPrivate // Exclude all private recipes (including shared ones) from public feeds
        }
        
        // Get the last document for pagination
        let lastDocument = snapshot.documents.last
        
        return (finalRecipes, lastDocument)
    }
    
    func fetchRecipe(byID recipeID: String) async throws -> Recipe? {
        let document = try await firestore.collection(recipesCollection).document(recipeID).getDocument()
        
        // Check if document exists
        guard document.exists else {
            print("⚠️ Recipe \(recipeID) does not exist")
            return nil
        }
        
        // Try to decode recipe
        guard let recipe = try? document.data(as: Recipe.self) else {
            print("⚠️ Failed to decode recipe \(recipeID)")
            return nil
        }
        
        // Check if recipe is private and user has access (owner or shared with user)
        let currentUserID = Auth.auth().currentUser?.uid
        print("🔍 fetchRecipe(byID: \(recipeID)) - Current user: \(currentUserID ?? "nil"), Recipe isPrivate: \(recipe.isPrivate), Author: \(recipe.authorID)")
        
        if recipe.isPrivate {
            let isOwner = recipe.authorID == currentUserID
            
            // Check new scalable sharing system first
            var isSharedWithUser = false
            if let userID = currentUserID {
                do {
                    print("🔍 Checking recipeShares collection for recipeID: \(recipeID), userID: \(userID)")
                    isSharedWithUser = try await shareService.isRecipeShared(recipeID: recipeID, with: userID)
                    print("🔍 RecipeShares check result: \(isSharedWithUser)")
                } catch {
                    print("❌ Error checking recipe share: \(error.localizedDescription)")
                    print("❌ Error details: \(error)")
                }
            } else {
                print("⚠️ No authenticated user - cannot check shares")
            }
            
            // Backward compatibility: Also check old sharedWith array if new system doesn't have a share
            if !isSharedWithUser, let userID = currentUserID, !recipe.sharedWith.isEmpty {
                print("🔍 Checking old sharedWith array: \(recipe.sharedWith)")
                isSharedWithUser = recipe.sharedWith.contains(userID)
                print("🔍 Old sharedWith check result: \(isSharedWithUser)")
                // If found in old system, migrate to new system
                if isSharedWithUser {
                    print("🔄 Migrating old sharedWith to new recipeShares collection")
                    do {
                        _ = try await shareService.shareRecipe(recipeID: recipeID, with: [userID])
                        print("✅ Migration successful")
                    } catch {
                        print("❌ Error migrating share: \(error.localizedDescription)")
                    }
                }
            }
            
            print("🔍 Recipe \(recipeID) access check - isPrivate: \(recipe.isPrivate), isOwner: \(isOwner), isSharedWithUser: \(isSharedWithUser)")
            print("🔍 Current user ID: \(currentUserID ?? "nil"), Recipe author: \(recipe.authorID)")
            
            if !isOwner && !isSharedWithUser {
                // Private recipe and user doesn't have access - don't return it
                print("❌ Access denied: User \(currentUserID ?? "nil") cannot access private recipe \(recipeID)")
                print("❌ Recipe author: \(recipe.authorID), isOwner: \(isOwner), isSharedWithUser: \(isSharedWithUser)")
                return nil
            }
        }
        
        print("✅ Recipe \(recipeID) fetched successfully - isPrivate: \(recipe.isPrivate)")
        return recipe
    }
    
    /// Search recipes by query string (searches in title, description, and ingredient names)
    /// - Parameter query: Search query string
    /// - Returns: Array of matching recipes
    func searchRecipes(query: String) async throws -> [Recipe] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return []
        }
        
        // Fetch all recipes (Firestore doesn't support full-text search natively)
        // For better performance with large datasets, consider using Algolia or similar
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
                // Continue processing other documents
            }
        }
        
        // Filter out recipes from banned users and hidden recipes
        let filteredRecipes = try await filterRecipesFromBannedUsers(recipes: recipes)
        // Filter out private recipes from search (unless shared with current user or user is owner)
        // Shared recipes should be searchable by the users they're shared with
        let currentUserID = Auth.auth().currentUser?.uid
        let visibleRecipes = filteredRecipes.filter { recipe in
            !recipe.isHidden &&
            recipe.reportCount < 10 &&
            (!recipe.isPrivate || recipe.authorID == currentUserID || (currentUserID != nil && recipe.sharedWith.contains(currentUserID ?? ""))) // Allow if public, owner, or shared with user
        }
        
        // Perform case-insensitive search with word-based matching
        let searchQuery = query.lowercased().trimmingCharacters(in: .whitespaces)
        let searchTerms = searchQuery.components(separatedBy: .whitespaces)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // If no valid search terms, return empty
        guard !searchTerms.isEmpty else {
            return []
        }
        
        return visibleRecipes.filter { recipe in
            // Helper function to check if text contains all search terms
            func textContainsAllTerms(_ text: String) -> Bool {
                let lowercasedText = text.lowercased()
                // Check if all search terms appear in the text (as substrings)
                return searchTerms.allSatisfy { term in
                    lowercasedText.contains(term)
                }
            }
            
            // Search in title (check all title fields)
            let titleMatch = textContainsAllTerms(recipe.title) ||
                           (recipe.titleEnglish.map(textContainsAllTerms) ?? false) ||
                           (recipe.titleLocal.map(textContainsAllTerms) ?? false) ||
                           (recipe.titleOriginal.map(textContainsAllTerms) ?? false)
            
            // Search in description
            let descriptionMatch = textContainsAllTerms(recipe.description)
            
            // Search in ingredient names (check if any ingredient matches all terms)
            let ingredientMatch = recipe.ingredients.contains { ingredient in
                textContainsAllTerms(ingredient.name)
            }
            
            // Search in cuisine
            let cuisineMatch = (recipe.cuisine.map(textContainsAllTerms) ?? false) ||
                              (recipe.cuisineEnglish.map(textContainsAllTerms) ?? false)
            
            return titleMatch || descriptionMatch || ingredientMatch || cuisineMatch
        }
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
    
    /// Toggle recipe privacy (private recipes are only visible to the owner and shared users)
    /// - Parameters:
    ///   - recipeID: The ID of the recipe
    ///   - isPrivate: The new privacy status
    ///   - clearSharedWith: If true, clear the sharedWith array when making private (default: false, preserves it)
    func toggleRecipePrivacy(recipeID: String, isPrivate: Bool, clearSharedWith: Bool = false) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw RecipeError.unauthorized
        }
        
        // Verify ownership - fetch directly from Firestore without client-side filtering
        let recipeDoc = try await firestore.collection(recipesCollection).document(recipeID).getDocument()
        guard let recipeData = try? recipeDoc.data(as: Recipe.self),
              recipeData.authorID == userID else {
            throw RecipeError.unauthorized
        }
        
        // Get current sharedWith and preservedSharedWith arrays from Firestore
        let currentSharedWith = recipeData.sharedWith
        let currentPreservedSharedWith = recipeData.preservedSharedWith
        
        // Update privacy status
        let recipeRef = firestore.collection(recipesCollection).document(recipeID)
        var updateData: [String: Any] = [
            "isPrivate": isPrivate,
            "updatedAt": Timestamp(date: Date())
        ]
        
        // When making private with clearSharedWith=true: Save current sharedWith to preservedSharedWith, then clear sharedWith
        //   This allows restoring the list when switching back to "Public to All" or opening "Private Sharing"
        if isPrivate && clearSharedWith {
            // Save current sharedWith to preservedSharedWith before clearing (if it has users)
            if !currentSharedWith.isEmpty {
                updateData["preservedSharedWith"] = currentSharedWith
            }
            // Always clear sharedWith when making "Private to All" (removes access)
            updateData["sharedWith"] = []
        }
        // When making public: Restore preservedSharedWith to sharedWith if it exists, then clear preservedSharedWith
        //   This restores the previous sharing list when switching back to public
        else if !isPrivate {
            // Restore preserved sharedWith list if it exists
            if let preserved = currentPreservedSharedWith, !preserved.isEmpty {
                updateData["sharedWith"] = preserved
                updateData["preservedSharedWith"] = FieldValue.delete() // Clear preserved list after restore
            }
            // If no preserved list, keep current sharedWith as-is
        }
        // When making private with clearSharedWith=false: Preserve sharedWith (for "Private Sharing" flow)
        //   No changes needed - sharedWith is already set correctly
        
        try await recipeRef.updateData(updateData)
        
        print("✅ Recipe \(recipeID) privacy set to: \(isPrivate ? "private" : "public"), sharedWith cleared: \(clearSharedWith)")
        
        // Post notification to refresh public feeds (ExploreView, etc.)
        NotificationCenter.default.post(name: NSNotification.Name("RecipePrivacyChanged"), object: nil, userInfo: ["recipeID": recipeID, "isPrivate": isPrivate, "clearSharedWith": clearSharedWith])
    }
    
    /// Update sharedWith array for a recipe (add/remove users who can view the recipe)
    /// This also clears preservedSharedWith since the user is explicitly setting the sharing list
    func updateRecipeSharing(recipeID: String, sharedWith: [String]) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw RecipeError.unauthorized
        }
        
        // Verify ownership
        let recipeDoc = try await firestore.collection(recipesCollection).document(recipeID).getDocument()
        guard let recipeData = try? recipeDoc.data(as: Recipe.self),
              recipeData.authorID == userID else {
            throw RecipeError.unauthorized
        }
        
        // Ensure recipe is private when sharing (can't share public recipes with specific users)
        // Clear preservedSharedWith since user is explicitly setting a new sharing list
        let recipeRef = firestore.collection(recipesCollection).document(recipeID)
        var updateData: [String: Any] = [
            "isPrivate": true, // Must be private to share with specific users
            "sharedWith": sharedWith,
            "updatedAt": Timestamp(date: Date())
        ]
        // Clear preservedSharedWith when user explicitly sets sharing (they're choosing new users)
        updateData["preservedSharedWith"] = FieldValue.delete()
        
        try await recipeRef.updateData(updateData)
        
        print("✅ Recipe \(recipeID) sharing updated. Shared with \(sharedWith.count) user(s)")
        
        // Post notification to refresh views
        NotificationCenter.default.post(name: NSNotification.Name("RecipeSharingChanged"), object: nil, userInfo: ["recipeID": recipeID, "sharedWith": sharedWith])
    }
    
    /// Update a recipe's author info if it's stale (lazy update)
    /// This is called when a recipe is viewed/edited to ensure author info is current
    /// Returns the updated recipe, or the original recipe if no update was needed
    func refreshRecipeAuthorInfoIfNeeded(_ recipe: Recipe) async throws -> Recipe {
        // Fetch current user data
        guard let userDoc = try? await firestore.collection("users").document(recipe.authorID).getDocument(),
              let userData = try? userDoc.data(as: AppUser.self) else {
            return recipe // Can't fetch user data, return original recipe
        }
        
        // Check if author info needs updating
        let needsUpdate = recipe.authorName != userData.displayName ||
                         recipe.authorUsername != userData.username
        
        guard needsUpdate else {
            return recipe // Already up to date
        }
        
        // Update only this recipe (lazy update - only when viewed/edited)
        var updateData: [String: Any] = [
            "authorName": userData.displayName,
            "updatedAt": Timestamp(date: Date())
        ]
        
        if let username = userData.username {
            updateData["authorUsername"] = username
        }
        
        let recipeRef = firestore.collection(recipesCollection).document(recipe.id)
        try await recipeRef.updateData(updateData)
        print("✅ Updated author info for recipe \(recipe.id) (lazy update)")
        
        // Return updated recipe
        var updatedRecipe = recipe
        updatedRecipe.authorName = userData.displayName
        updatedRecipe.authorUsername = userData.username
        updatedRecipe.updatedAt = Date()
        return updatedRecipe
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
        // For favorites, show private recipes if they belong to the current user or are shared with them
        let currentUserID = Auth.auth().currentUser?.uid
        return filteredRecipes.filter { recipe in
            !recipe.isHidden &&
            recipe.reportCount < 10 &&
            (!recipe.isPrivate || recipe.authorID == currentUserID || (currentUserID != nil && recipe.sharedWith.contains(currentUserID!))) // Show if public, owner, or shared with user
        }
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
    
    // MARK: - Filter Banned Users and Private Accounts
    
    /// Filters out recipes from banned users and users with private accounts (isProfileHidden or isCompletelyPrivate)
    /// Note: This works for both authenticated and unauthenticated users
    /// If check fails, recipes are still returned (err on side of caution)
    private func filterRecipesFromBannedUsers(recipes: [Recipe]) async throws -> [Recipe] {
        // Get unique author IDs
        let authorIDs = Set(recipes.map { $0.authorID })
        
        // If no recipes, return early
        guard !authorIDs.isEmpty else {
            return recipes
        }
        
        // Batch check which users are banned or have private accounts
        var filteredUserIDs: Set<String> = []
        
        await withTaskGroup(of: (String, Bool, Bool, Bool).self) { group in
            for authorID in authorIDs {
                group.addTask {
                    do {
                        let userDoc = try await self.firestore.collection("users").document(authorID).getDocument()
                        if userDoc.exists, let userData = userDoc.data() {
                            let isBanned = (userData["isBanned"] as? Bool) ?? false
                            let isProfileHidden = (userData["isProfileHidden"] as? Bool) ?? false
                            let isCompletelyPrivate = (userData["isCompletelyPrivate"] as? Bool) ?? false
                            
                            // Debug logging
                            if isProfileHidden || isCompletelyPrivate {
                                print("🔍 Found private account - authorID: \(authorID), isProfileHidden: \(isProfileHidden), isCompletelyPrivate: \(isCompletelyPrivate)")
                            }
                            
                            return (authorID, isBanned, isProfileHidden, isCompletelyPrivate)
                        }
                        // If document doesn't exist, don't filter (err on side of caution)
                        print("⚠️ User document not found for authorID: \(authorID)")
                        return (authorID, false, false, false)
                    } catch {
                        // If error checking user status (e.g., permission denied for unauthenticated users),
                        // err on the side of caution and don't filter out the recipe
                        // This allows recipes to load even if check fails
                        // IMPORTANT: We return false for all privacy flags, meaning we WON'T filter this recipe
                        print("⚠️ Error checking user status for authorID \(authorID): \(error.localizedDescription)")
                        print("⚠️ Error type: \(type(of: error))")
                        print("⚠️ NOT filtering recipe from \(authorID) due to error - showing recipe to be safe")
                        // Don't filter if we can't check - show the recipe (err on side of caution)
                        return (authorID, false, false, false)
                    }
                }
            }
            
            for await (userID, isBanned, isProfileHidden, isCompletelyPrivate) in group {
                // Filter out if banned, profile hidden, or completely private
                // IMPORTANT: We filter based on the RECIPE AUTHOR's privacy settings, not the current user's
                // This means: if Recipe Author A has isProfileHidden=true, their recipes are hidden from everyone
                // NOT: if Current User B has isProfileHidden=true, then User B can't see anyone's recipes
                if isBanned || isProfileHidden || isCompletelyPrivate {
                    filteredUserIDs.insert(userID)
                    if isProfileHidden || isCompletelyPrivate {
                        print("🔒 Filtering recipes from private account: \(userID) (isProfileHidden: \(isProfileHidden), isCompletelyPrivate: \(isCompletelyPrivate))")
                    }
                }
            }
        }
        
        if !filteredUserIDs.isEmpty {
            print("🔍 Filtered out recipes from \(filteredUserIDs.count) private/banned users: \(Array(filteredUserIDs))")
        }
        
        // Filter out recipes from banned users and private accounts
        let filteredRecipes = recipes.filter { !filteredUserIDs.contains($0.authorID) }
        
        // Debug: Log filtering results
        let filteredCount = recipes.count - filteredRecipes.count
        if filteredCount > 0 {
            print("🔍 Filtered out \(filteredCount) recipe(s) from private/banned accounts")
        }
        print("🔍 Returning \(filteredRecipes.count) recipe(s) out of \(recipes.count) total")
        
        return filteredRecipes
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


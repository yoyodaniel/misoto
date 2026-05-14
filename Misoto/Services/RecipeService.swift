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
import OSLog

@MainActor
class RecipeService: ObservableObject {
    static let shared = RecipeService()
    
    private let firestore = FirebaseManager.shared.firestore
    private let recipesCollection = "recipes"
    private let favoritesCollection = "favorites"
    private let shareService = RecipeShareService.shared
    private let xpService = XPService.shared
    private let searchResultLimit = 120
    private let algoliaSearchService = AlgoliaRecipeSearchService.shared
    
    private init() {}
    
    /// Firestore rules require that a query cannot possibly return documents the user may not read.
    /// Public browse/search uses the same constraints as the public `allow read` recipe rule:
    /// non-private and not hidden (moderation/report filters still applied in Swift afterward).
    private func publicRecipeExploreQuery() -> Query {
        firestore.collection(recipesCollection)
            .whereField("isPrivate", isEqualTo: false)
            .whereField("isHidden", isEqualTo: false)
    }
    
    // MARK: - Create Recipe
    
    func createRecipe(_ recipe: Recipe) async throws {
        var recipeToSave = recipe
        
        // Enrich ingredients with canonical IDs and food categories (on-device, free)
        recipeToSave.ingredients = IngredientDatabase.shared.enrich(recipeToSave.ingredients)
        
        // Estimate nutrition per serving (best-effort, don't block save on failure)
        if !recipe.ingredients.isEmpty {
            do {
                let nutrition = try await OpenAIService.estimateNutrition(
                    title: recipe.title,
                    ingredients: recipe.ingredients,
                    servings: recipe.servings
                )
                recipeToSave.nutritionInfo = nutrition
            } catch {
                print("⚠️ Nutrition estimation failed (recipe will save without it): \(error.localizedDescription)")
            }
        }
        
        if recipeToSave.searchKeywords.isEmpty {
            recipeToSave.searchKeywords = buildSearchKeywords(for: recipeToSave)
        } else {
            recipeToSave.searchKeywords = normalizeExistingKeywords(recipeToSave.searchKeywords)
        }
        
        let recipeRef = firestore.collection(recipesCollection).document(recipeToSave.id)
        try recipeRef.setData(from: recipeToSave)
        
        // Update user's recipe count
        if let userID = Auth.auth().currentUser?.uid {
            try await updateUserRecipeCount(userID: userID, increment: 1)
            await awardRecipePublishXP(recipe: recipeToSave, authorID: userID)
        }
    }
    
    // MARK: - Read Recipes
    
    func fetchAllRecipes() async throws -> [Recipe] {
        let snapshot = try await publicRecipeExploreQuery()
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
        var query = publicRecipeExploreQuery()
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
        var query = publicRecipeExploreQuery()
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
    func fetchRecipesByCuisine(cuisine: String) async throws -> [Recipe] {
        // Query by cuisineEnglish field for exact match
        let snapshot = try await publicRecipeExploreQuery()
            .whereField("cuisineEnglish", isEqualTo: cuisine)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        var recipes: [Recipe] = []
        for document in snapshot.documents {
            do {
                let recipe = try document.data(as: Recipe.self)
                recipes.append(recipe)
            } catch {
                print("⚠️ Failed to decode recipe \(document.documentID): \(error.localizedDescription)")
            }
        }
        
        // Filter out banned/hidden/private
        let filteredRecipes = try await filterRecipesFromBannedUsers(recipes: recipes)
        let currentUserID = Auth.auth().currentUser?.uid
        return filteredRecipes.filter { recipe in
            !recipe.isHidden &&
            recipe.reportCount < 10 &&
            (!recipe.isPrivate || recipe.authorID == currentUserID)
        }
    }
    
    func searchRecipes(query: String) async throws -> [Recipe] {
        if algoliaSearchService.isConfigured {
            do {
                let recipeIDs = try await algoliaSearchService.searchRecipeIDs(
                    query: query,
                    limit: searchResultLimit
                )
                if !recipeIDs.isEmpty {
                    return try await fetchAndFilterRecipesByRankedIDs(recipeIDs)
                }
            } catch is CancellationError {
                return []
            } catch {
                print("⚠️ Algolia search failed, falling back to Firestore search: \(error.localizedDescription)")
            }
        }

        return try await searchRecipesInFirestore(query: query)
    }

    private func searchRecipesInFirestore(query: String) async throws -> [Recipe] {
        let normalizedQuery = normalizedSearchText(query)
        guard !normalizedQuery.isEmpty else {
            return []
        }

        let parsed = parseNaturalLanguageSearchQuery(normalizedQuery)
        guard !parsed.tokens.isEmpty else {
            return []
        }

        // Firestore scalable query: retrieve only recipes that contain at least
        // one search token and then refine locally with weighted relevance scoring.
        let tokenQuery = Array(parsed.firestoreTokens.prefix(10))
        guard !tokenQuery.isEmpty else {
            return []
        }

        let snapshot = try await publicRecipeExploreQuery()
            .whereField("searchKeywords", arrayContainsAny: Array(tokenQuery))
            .limit(to: searchResultLimit)
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
        
        let scored = visibleRecipes.compactMap { recipe -> (recipe: Recipe, score: Int)? in
            let score = scoreRecipeForNaturalLanguageQuery(
                recipe,
                query: normalizedQuery,
                tokens: parsed.tokens,
                ingredientHintTokens: parsed.ingredientHintTokens
            )
            return score > 0 ? (recipe, score) : nil
        }
        
        return scored
            .sorted { lhs, rhs in
                if lhs.score != rhs.score {
                    return lhs.score > rhs.score
                }
                return lhs.recipe.createdAt > rhs.recipe.createdAt
            }
            .map(\.recipe)
    }

    private func fetchAndFilterRecipesByRankedIDs(_ rankedRecipeIDs: [String]) async throws -> [Recipe] {
        let uniqueRankedIDs = orderedUniqueValues(rankedRecipeIDs)
        guard !uniqueRankedIDs.isEmpty else { return [] }

        var recipesByID: [String: Recipe] = [:]
        for chunk in uniqueRankedIDs.chunked(into: 10) {
            do {
                let snapshot = try await firestore.collection(recipesCollection)
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()

                for document in snapshot.documents {
                    if let recipe = try? document.data(as: Recipe.self) {
                        recipesByID[recipe.id] = recipe
                    }
                }
            } catch {
                // If any doc in an "in" query is not readable by Firestore rules,
                // the whole query can fail. Fall back to per-document reads and skip
                // inaccessible docs so search still returns accessible results.
                print("⚠️ Ranked ID batch query failed, falling back to individual fetches: \(error.localizedDescription)")
                for recipeID in chunk {
                    do {
                        let snapshot = try await firestore.collection(recipesCollection)
                            .document(recipeID)
                            .getDocument()
                        guard snapshot.exists, let recipe = try? snapshot.data(as: Recipe.self) else {
                            continue
                        }
                        recipesByID[recipe.id] = recipe
                    } catch {
                        continue
                    }
                }
            }
        }

        let loadedRecipes = uniqueRankedIDs.compactMap { recipesByID[$0] }
        let filteredRecipes = try await filterRecipesFromBannedUsers(recipes: loadedRecipes)

        let currentUserID = Auth.auth().currentUser?.uid
        let visibleRecipes = filteredRecipes.filter { recipe in
            !recipe.isHidden &&
            recipe.reportCount < 10 &&
            (!recipe.isPrivate || recipe.authorID == currentUserID || (currentUserID != nil && recipe.sharedWith.contains(currentUserID ?? "")))
        }

        let visibilityByID = Set(visibleRecipes.map(\.id))
        return uniqueRankedIDs.compactMap { recipeID in
            guard visibilityByID.contains(recipeID) else { return nil }
            return recipesByID[recipeID]
        }
    }
    
    func fetchRecipes(byUserID userID: String, includeHidden: Bool = false) async throws -> [Recipe] {
        let viewerID = Auth.auth().currentUser?.uid
        var query: Query = firestore.collection(recipesCollection)
            .whereField("authorID", isEqualTo: userID)
        
        // Another user's profile: only list recipes that satisfy public-read rules.
        // Own profile: author may read private/hidden recipes per rules.
        if viewerID != userID {
            query = query
                .whereField("isPrivate", isEqualTo: false)
                .whereField("isHidden", isEqualTo: false)
        }
        
        let snapshot = try await query
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
        if updatedRecipe.searchKeywords.isEmpty {
            updatedRecipe.searchKeywords = buildSearchKeywords(for: updatedRecipe)
        } else {
            updatedRecipe.searchKeywords = normalizeExistingKeywords(updatedRecipe.searchKeywords)
        }
        
        // Enrich ingredients with canonical IDs and food categories (on-device, free)
        updatedRecipe.ingredients = IngredientDatabase.shared.enrich(updatedRecipe.ingredients)
        
        // Re-estimate nutrition per serving (best-effort, don't block save on failure)
        if !recipe.ingredients.isEmpty {
            do {
                let nutrition = try await OpenAIService.estimateNutrition(
                    title: recipe.title,
                    ingredients: recipe.ingredients,
                    servings: recipe.servings
                )
                updatedRecipe.nutritionInfo = nutrition
            } catch {
                print("⚠️ Nutrition re-estimation failed (recipe will save with old values): \(error.localizedDescription)")
            }
        }
        
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
    
    // MARK: - Nutrition
    
    /// Persist nutrition info to an existing recipe without re-saving the entire document
    func saveNutritionInfo(recipeID: String, nutritionInfo: NutritionInfo) async throws {
        let recipeRef = firestore.collection(recipesCollection).document(recipeID)
        let encoded = try Firestore.Encoder().encode(nutritionInfo)
        try await recipeRef.updateData([
            "nutritionInfo": encoded,
            "updatedAt": Timestamp(date: Date())
        ])
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
        
        let favorite = Favorite(userID: userID, recipeID: recipeID, recipeAuthorID: authorID)
        try firestore.collection(favoritesCollection).document(favorite.id).setData(from: favorite)
        
        // Increment recipe's favorite/like count
        try await incrementFavoriteCount(recipeID: recipeID, increment: 1)
        
        // Increment recipe AUTHOR's total likes count (not the liker's)
        try await incrementUserLikesCount(userID: authorID, increment: 1)

        // XP awards (idempotent through xpEvents)
        _ = try? await xpService.awardXPForAction(
            receiverUserId: authorID,
            actorUserId: userID,
            actionType: .likeReceived,
            targetId: recipeID
        )
        _ = try? await xpService.awardXPForAction(
            receiverUserId: authorID,
            actorUserId: userID,
            actionType: .saveReceived,
            targetId: recipeID
        )
        _ = try? await xpService.awardXPForAction(
            receiverUserId: userID,
            actorUserId: userID,
            actionType: .recipeSaved,
            targetId: recipeID
        )
    }
    
    func removeFavorite(recipeID: String, userID: String) async throws {
        let favorites = try await fetchFavorites(userID: userID)
        guard let favorite = favorites.first(where: { $0.recipeID == recipeID }) else {
            return // Not favorited
        }
        
        // Determine author ID from favorite cache first; fallback to recipe fetch.
        var authorID = favorite.recipeAuthorID
        if authorID == nil, let recipe = try await fetchRecipe(byID: recipeID) {
            authorID = recipe.authorID
        }
        
        try await firestore.collection(favoritesCollection).document(favorite.id).delete()
        
        // Decrement recipe's favorite/like count
        try await incrementFavoriteCount(recipeID: recipeID, increment: -1)
        
        // Decrement recipe AUTHOR's total likes count (not the liker's) when known.
        if let authorID, !authorID.isEmpty {
            try await incrementUserLikesCount(userID: authorID, increment: -1)
        }

        // Revoke previously awarded XP when like/save is removed.
        if let authorID, !authorID.isEmpty {
            _ = try? await xpService.revokeXPForAction(
                receiverUserId: authorID,
                actorUserId: userID,
                actionType: .likeReceived,
                targetId: recipeID
            )
            _ = try? await xpService.revokeXPForAction(
                receiverUserId: authorID,
                actorUserId: userID,
                actionType: .saveReceived,
                targetId: recipeID
            )
        }
        _ = try? await xpService.revokeXPForAction(
            receiverUserId: userID,
            actorUserId: userID,
            actionType: .recipeSaved,
            targetId: recipeID
        )
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

    private func buildSearchKeywords(for recipe: Recipe) -> [String] {
        var tokens = Set<String>()

        func addToken(_ value: String?, includePrefixes: Bool) {
            guard let value else { return }
            let normalized = normalizedSearchText(value)
            guard !normalized.isEmpty else { return }
            tokens.insert(normalized)

            let separators = CharacterSet.alphanumerics.inverted
            let splitTokens = normalized
                .components(separatedBy: separators)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.count >= 2 }
            splitTokens.forEach { token in
                tokens.insert(token)
                guard includePrefixes, token.count >= 3 else { return }
                let maxPrefix = min(8, token.count)
                for prefixLength in 3...maxPrefix {
                    tokens.insert(String(token.prefix(prefixLength)))
                }
            }

            if splitTokens.count >= 2 {
                for idx in 0..<(splitTokens.count - 1) {
                    tokens.insert("\(splitTokens[idx]) \(splitTokens[idx + 1])")
                }
            }
        }

        addToken(recipe.title, includePrefixes: true)
        addToken(recipe.titleEnglish, includePrefixes: true)
        addToken(recipe.titleLocal, includePrefixes: true)
        addToken(recipe.titleOriginal, includePrefixes: true)
        addToken(recipe.description, includePrefixes: false)
        addToken(recipe.cuisine, includePrefixes: true)
        addToken(recipe.cuisineEnglish, includePrefixes: true)
        addToken(recipe.authorName, includePrefixes: true)
        addToken(recipe.authorUsername, includePrefixes: true)
        recipe.ingredients.forEach { addToken($0.name, includePrefixes: true) }

        return Array(tokens).sorted()
    }

    private func normalizeExistingKeywords(_ keywords: [String]) -> [String] {
        var normalizedSet = Set<String>()
        for keyword in keywords {
            let normalized = normalizedSearchText(keyword)
            if !normalized.isEmpty {
                normalizedSet.insert(normalized)
            }
        }
        return Array(normalizedSet).sorted()
    }

    private struct ParsedNaturalLanguageQuery {
        let tokens: [String]
        let firestoreTokens: [String]
        let ingredientHintTokens: [String]
    }

    private let naturalLanguageStopWords: Set<String> = [
        "a", "an", "and", "are", "at", "be", "for", "from", "how", "i", "in", "is",
        "it", "make", "me", "my", "of", "on", "or", "please", "recipe", "show", "some",
        "something", "that", "the", "this", "to", "want", "with"
    ]

    private let ingredientIntentWords: Set<String> = [
        "add", "containing", "contains", "have", "has", "include", "includes", "ingredient",
        "ingredients", "made", "using", "use", "used", "without"
    ]

    private func normalizedSearchText(_ text: String) -> String {
        text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func tokenizeSearchText(_ text: String) -> [String] {
        text
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func parseNaturalLanguageSearchQuery(_ query: String) -> ParsedNaturalLanguageQuery {
        let rawTokens = tokenizeSearchText(query)
        if rawTokens.isEmpty {
            return ParsedNaturalLanguageQuery(tokens: [], firestoreTokens: [], ingredientHintTokens: [])
        }

        let filteredTokens = rawTokens.filter { token in
            if token.count <= 1 { return false }
            return !naturalLanguageStopWords.contains(token)
        }
        let finalTokens = filteredTokens.isEmpty ? rawTokens : filteredTokens

        let ingredientHintTokens = finalTokens.filter { token in
            ingredientIntentWords.contains(token)
        }

        let uniqueByLength = Array(Set(finalTokens)).sorted {
            if $0.count != $1.count {
                return $0.count > $1.count
            }
            return $0 < $1
        }

        var firestoreTokens = uniqueByLength
        if finalTokens.count >= 2 {
            for idx in 0..<(finalTokens.count - 1) {
                firestoreTokens.append("\(finalTokens[idx]) \(finalTokens[idx + 1])")
            }
        }
        firestoreTokens = Array(Set(firestoreTokens)).sorted {
            if $0.count != $1.count {
                return $0.count > $1.count
            }
            return $0 < $1
        }

        return ParsedNaturalLanguageQuery(
            tokens: finalTokens,
            firestoreTokens: firestoreTokens,
            ingredientHintTokens: ingredientHintTokens
        )
    }

    private func scoreRecipeForNaturalLanguageQuery(
        _ recipe: Recipe,
        query: String,
        tokens: [String],
        ingredientHintTokens: [String]
    ) -> Int {
        var score = 0
        let keywordSet = Set(normalizeExistingKeywords(recipe.searchKeywords))

        let titleFields = [
            recipe.title,
            recipe.titleEnglish ?? "",
            recipe.titleLocal ?? "",
            recipe.titleOriginal ?? ""
        ]
            .map(normalizedSearchText)
            .joined(separator: " ")

        let descriptionField = normalizedSearchText(recipe.description)
        let cuisineField = normalizedSearchText([recipe.cuisine, recipe.cuisineEnglish].compactMap { $0 }.joined(separator: " "))
        let authorField = normalizedSearchText([recipe.authorName, recipe.authorUsername].compactMap { $0 }.joined(separator: " "))
        let ingredientField = normalizedSearchText(recipe.ingredients.map(\.name).joined(separator: " "))

        if !query.isEmpty && titleFields.contains(query) {
            score += 24
        }
        if !query.isEmpty && ingredientField.contains(query) {
            score += 18
        }

        var matchedCoreTokenCount = 0
        for token in tokens {
            var tokenMatched = false

            if keywordSet.contains(token) {
                score += 6
                tokenMatched = true
            }
            if titleFields.contains(token) {
                score += 9
                tokenMatched = true
            } else if ingredientField.contains(token) {
                score += 7
                tokenMatched = true
            } else if cuisineField.contains(token) {
                score += 6
                tokenMatched = true
            } else if descriptionField.contains(token) {
                score += 3
                tokenMatched = true
            } else if authorField.contains(token) {
                score += 2
                tokenMatched = true
            }

            if !tokenMatched {
                if keywordSet.contains(where: { $0.hasPrefix(token) || token.hasPrefix($0) }) {
                    score += 2
                    tokenMatched = true
                }
            }

            if tokenMatched && !ingredientHintTokens.contains(token) {
                matchedCoreTokenCount += 1
            }
        }

        score += matchedCoreTokenCount * 3
        if matchedCoreTokenCount >= max(1, tokens.count - 1) {
            score += 10
        }

        return score
    }

    private func orderedUniqueValues(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for value in values where !value.isEmpty {
            if seen.insert(value).inserted {
                ordered.append(value)
            }
        }
        return ordered
    }

    private func awardRecipePublishXP(recipe: Recipe, authorID: String) async {
        var debugAwardBreakdown: [(XPActionType, Int)] = []
        debugAwardBreakdown.append((.recipePublished, xpService.getXPValueForAction(.recipePublished)))
        
        _ = try? await xpService.awardXPForAction(
            receiverUserId: authorID,
            actorUserId: authorID,
            actionType: .recipePublished,
            targetId: recipe.id
        )

        if recipe.imageURL != nil || !recipe.imageURLs.isEmpty {
            debugAwardBreakdown.append((.mainPhotoAdded, xpService.getXPValueForAction(.mainPhotoAdded)))
            _ = try? await xpService.awardXPForAction(
                receiverUserId: authorID,
                actorUserId: authorID,
                actionType: .mainPhotoAdded,
                targetId: recipe.id
            )
        }

        // Intentionally no publish-time XP for step photos, video, full-recipe, or nutrition.
        // These feature-based bonuses are currently out of scope for Misoto XP.
        
        let debugSummary = debugAwardBreakdown
            .map { "\($0.0.rawValue)=\($0.1)" }
            .joined(separator: ", ")
        let debugTotal = debugAwardBreakdown.reduce(0) { partial, item in
            partial + item.1
        }
        print("🧪 XP DEBUG | publish recipe \(recipe.id) | expected award total=\(debugTotal) | breakdown: [\(debugSummary)]")
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
                    let log = Logger(subsystem: "com.miniadd.Misoto", category: "RecipePrivacyFilter")
                    do {
                        let userDoc = try await self.firestore.collection("users").document(authorID).getDocument()
                        if userDoc.exists, let userData = userDoc.data() {
                            let isBanned = (userData["isBanned"] as? Bool) ?? false
                            let isProfileHidden = (userData["isProfileHidden"] as? Bool) ?? false
                            let isCompletelyPrivate = (userData["isCompletelyPrivate"] as? Bool) ?? false
                            
                            // Debug logging
                            if isProfileHidden || isCompletelyPrivate {
                                log.debug("Found private account authorID=\(authorID, privacy: .public) isProfileHidden=\(isProfileHidden, privacy: .public) isCompletelyPrivate=\(isCompletelyPrivate, privacy: .public)")
                            }
                            
                            return (authorID, isBanned, isProfileHidden, isCompletelyPrivate)
                        }
                        // If document doesn't exist, don't filter (err on side of caution)
                        log.warning("User document not found for authorID=\(authorID, privacy: .public)")
                        return (authorID, false, false, false)
                    } catch {
                        // If error checking user status (e.g., permission denied for unauthenticated users),
                        // err on the side of caution and don't filter out the recipe
                        // This allows recipes to load even if check fails
                        // IMPORTANT: We return false for all privacy flags, meaning we WON'T filter this recipe
                        log.warning("Error checking user status for authorID=\(authorID, privacy: .public): \(error.localizedDescription, privacy: .public)")
                        log.warning("Error type: \(String(describing: type(of: error)), privacy: .public)")
                        log.warning("NOT filtering recipe from \(authorID, privacy: .public) due to error — showing recipe to be safe")
                        // Don't filter if we can't check - show the recipe (err on side of caution)
                        return (authorID, false, false, false)
                    }
                }
            }
            
            let privacyLog = Logger(subsystem: "com.miniadd.Misoto", category: "RecipePrivacyFilter")
            for await (userID, isBanned, isProfileHidden, isCompletelyPrivate) in group {
                // Filter out if banned, profile hidden, or completely private
                // IMPORTANT: We filter based on the RECIPE AUTHOR's privacy settings, not the current user's
                // This means: if Recipe Author A has isProfileHidden=true, their recipes are hidden from everyone
                // NOT: if Current User B has isProfileHidden=true, then User B can't see anyone's recipes
                if isBanned || isProfileHidden || isCompletelyPrivate {
                    filteredUserIDs.insert(userID)
                    if isProfileHidden || isCompletelyPrivate {
                        privacyLog.debug("Filtering recipes from private account userID=\(userID, privacy: .public) isProfileHidden=\(isProfileHidden, privacy: .public) isCompletelyPrivate=\(isCompletelyPrivate, privacy: .public)")
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

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
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


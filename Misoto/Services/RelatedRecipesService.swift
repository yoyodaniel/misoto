//
//  RelatedRecipesService.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import FirebaseFirestore

@MainActor
class RelatedRecipesService {
    private let firestore = FirebaseManager.shared.firestore
    private let recipesCollection = "recipes"
    
    // MARK: - Fetch Related Recipes
    
    func fetchRelatedRecipes(for recipe: Recipe, limit: Int = 4) async throws -> [Recipe] {
        var relatedRecipes: [Recipe] = []
        
        // Strategy 1: Find recipes with same cuisine
        if let cuisineEnglish = recipe.cuisineEnglish, !cuisineEnglish.isEmpty {
            let cuisineSnapshot = try await firestore.collection(recipesCollection)
                .whereField("cuisineEnglish", isEqualTo: cuisineEnglish)
                .limit(to: limit + 1) // Fetch one extra to account for current recipe
                .getDocuments()
            
            for document in cuisineSnapshot.documents {
                if let relatedRecipe = try? document.data(as: Recipe.self),
                   relatedRecipe.id != recipe.id,
                   !relatedRecipes.contains(where: { $0.id == relatedRecipe.id }),
                   relatedRecipes.count < limit {
                    relatedRecipes.append(relatedRecipe)
                }
            }
        }
        
        // Strategy 2: If we don't have enough, find recipes with similar ingredients
        if relatedRecipes.count < limit {
            let allRecipes = try await fetchAllRecipesExcept(recipeID: recipe.id, limit: limit * 2)
            
            // Score recipes by ingredient similarity
            let scoredRecipes = allRecipes.map { otherRecipe -> (Recipe, Int) in
                let score = calculateIngredientSimilarity(recipe.ingredients, otherRecipe.ingredients)
                return (otherRecipe, score)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(limit - relatedRecipes.count)
            
            for (scoredRecipe, _) in scoredRecipes {
                if !relatedRecipes.contains(where: { $0.id == scoredRecipe.id }) {
                    relatedRecipes.append(scoredRecipe)
                }
            }
        }
        
        // Strategy 3: If still not enough, get recent popular recipes
        if relatedRecipes.count < limit {
            let popularSnapshot = try await firestore.collection(recipesCollection)
                .order(by: "favoriteCount", descending: true)
                .order(by: "createdAt", descending: true)
                .limit(to: (limit - relatedRecipes.count) + 1) // Fetch one extra to account for current recipe
                .getDocuments()
            
            for document in popularSnapshot.documents {
                if let relatedRecipe = try? document.data(as: Recipe.self),
                   relatedRecipe.id != recipe.id,
                   !relatedRecipes.contains(where: { $0.id == relatedRecipe.id }),
                   relatedRecipes.count < limit {
                    relatedRecipes.append(relatedRecipe)
                }
            }
        }
        
        // Filter out recipes from banned users and hidden recipes before returning
        let filteredRecipes = try await filterRecipesFromBannedUsers(recipes: Array(relatedRecipes.prefix(limit)))
        // Also filter recipes with report count >= 10 (defensive check in case isHidden wasn't set)
        return filteredRecipes.filter { !$0.isHidden && $0.reportCount < 10 }
    }
    
    // MARK: - Helper Methods
    
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
    
    private func fetchAllRecipesExcept(recipeID: String, limit: Int) async throws -> [Recipe] {
        let snapshot = try await firestore.collection(recipesCollection)
            .limit(to: limit + 1) // Fetch one extra to account for current recipe
            .getDocuments()
        
        var recipes: [Recipe] = []
        for document in snapshot.documents {
            if let recipe = try? document.data(as: Recipe.self),
               recipe.id != recipeID {
                recipes.append(recipe)
            }
        }
        
        return Array(recipes.prefix(limit))
    }
    
    private func calculateIngredientSimilarity(_ ingredients1: [Ingredient], _ ingredients2: [Ingredient]) -> Int {
        let names1 = Set(ingredients1.map { $0.name.lowercased() })
        let names2 = Set(ingredients2.map { $0.name.lowercased() })
        
        let intersection = names1.intersection(names2)
        return intersection.count
    }
}


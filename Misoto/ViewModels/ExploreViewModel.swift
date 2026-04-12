//
//  ExploreViewModel.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class ExploreViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var todaysSpecial: [Recipe] = []
    @Published var likedRecipes: [Recipe] = []
    @Published var isLoading = false
    @Published var isLoadingMoreRecipes = false
    @Published var hasMoreRecipes = false
    @Published var isLoadingTodaysSpecial = false
    @Published var isLoadingMoreTodaysSpecial = false
    @Published var hasMoreTodaysSpecial = false
    @Published var isLoadingLiked = false
    @Published var errorMessage: String?
    @Published var searchResults: [Recipe] = []
    @Published var isSearching = false
    @Published var whatsNew: [Recipe] = []
    @Published var isLoadingWhatsNew = false
    @Published var isLoadingMoreWhatsNew = false
    @Published var hasMoreWhatsNew = false
    
    /// Trending cuisines with a representative recipe for each
    struct CuisineEntry: Identifiable {
        var id: String { english }
        let english: String
        let count: Int
        let representativeRecipe: Recipe  // latest or highest-scoring dish
    }
    @Published var trendingCuisines: [CuisineEntry] = []
    
    private let recipeService = RecipeService.shared
    private var lastRecipesDocument: DocumentSnapshot?
    private var lastTodaysSpecialDocument: DocumentSnapshot?
    private var lastWhatsNewDocument: DocumentSnapshot?
    private let recipesPerPage = 20
    private let whatsNewPerPage = 10
    private(set) var searchTask: Task<Void, Never>?
    
    func loadRecipes() async {
        isLoading = true
        errorMessage = nil
        recipes = []
        lastRecipesDocument = nil
        
        do {
            let (recipesList, lastDoc) = try await recipeService.fetchLatestRecipes(limit: recipesPerPage, startAfter: nil)
            recipes = recipesList
            lastRecipesDocument = lastDoc
            hasMoreRecipes = recipesList.count >= recipesPerPage
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadMoreRecipes() async {
        guard !isLoadingMoreRecipes, hasMoreRecipes, let lastDoc = lastRecipesDocument else {
            return
        }
        
        isLoadingMoreRecipes = true
        
        do {
            let (recipesList, lastDoc) = try await recipeService.fetchLatestRecipes(limit: recipesPerPage, startAfter: lastDoc)
            recipes.append(contentsOf: recipesList)
            lastRecipesDocument = lastDoc
            hasMoreRecipes = recipesList.count >= recipesPerPage
        } catch {
            print("⚠️ Error loading more recipes: \(error.localizedDescription)")
        }
        
        isLoadingMoreRecipes = false
    }
    
    func loadTodaysSpecial() async {
        isLoadingTodaysSpecial = true
        todaysSpecial = []
        lastTodaysSpecialDocument = nil
        
        do {
            let (recipes, lastDoc) = try await recipeService.fetchTodaysRecipes(limit: recipesPerPage, startAfter: nil)
            todaysSpecial = recipes
            lastTodaysSpecialDocument = lastDoc
            hasMoreTodaysSpecial = recipes.count >= recipesPerPage
        } catch {
            print("⚠️ Error loading today's special: \(error.localizedDescription)")
        }
        
        isLoadingTodaysSpecial = false
    }
    
    func loadMoreTodaysSpecial() async {
        guard !isLoadingMoreTodaysSpecial, hasMoreTodaysSpecial, let lastDoc = lastTodaysSpecialDocument else {
            return
        }
        
        isLoadingMoreTodaysSpecial = true
        
        do {
            let (recipes, lastDoc) = try await recipeService.fetchTodaysRecipes(limit: recipesPerPage, startAfter: lastDoc)
            todaysSpecial.append(contentsOf: recipes)
            lastTodaysSpecialDocument = lastDoc
            hasMoreTodaysSpecial = recipes.count >= recipesPerPage
        } catch {
            print("⚠️ Error loading more today's special: \(error.localizedDescription)")
        }
        
        isLoadingMoreTodaysSpecial = false
    }
    
    func loadLikedRecipes() async {
        guard let userID = Auth.auth().currentUser?.uid else {
            likedRecipes = []
            return
        }
        
        isLoadingLiked = true
        errorMessage = nil
        
        do {
            likedRecipes = try await recipeService.fetchFavoriteRecipes(userID: userID)
        } catch {
            print("⚠️ Error loading liked recipes: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoadingLiked = false
    }
    
    func searchRecipes(query: String) {
        // Cancel previous search task
        searchTask?.cancel()
        
        // Clear results if query is empty
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        // Debounce search - wait 300ms after user stops typing
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            
            // Check if task was cancelled
            guard !Task.isCancelled else { return }
            
            do {
                let results = try await recipeService.searchRecipes(query: query)
                
                // Check again if task was cancelled
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                print("⚠️ Error searching recipes: \(error.localizedDescription)")
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func loadWhatsNew() async {
        isLoadingWhatsNew = true
        whatsNew = []
        lastWhatsNewDocument = nil
        
        do {
            let (recipes, lastDoc) = try await recipeService.fetchLatestRecipes(limit: whatsNewPerPage, startAfter: nil)
            whatsNew = recipes
            lastWhatsNewDocument = lastDoc
            hasMoreWhatsNew = recipes.count >= whatsNewPerPage
            
            // Extract trending cuisines from recent recipes
            extractTrendingCuisines(from: recipes)
        } catch {
            print("⚠️ Error loading what's new: \(error.localizedDescription)")
        }
        
        isLoadingWhatsNew = false
    }
    
    /// Extract unique cuisines from recent recipes, picking the best representative dish for each
    private func extractTrendingCuisines(from recipes: [Recipe]) {
        var cuisineRecipes: [String: [Recipe]] = [:]
        
        for recipe in recipes {
            if let cuisine = recipe.cuisineEnglish ?? recipe.cuisine,
               !cuisine.isEmpty {
                let normalized = cuisine.trimmingCharacters(in: .whitespacesAndNewlines)
                cuisineRecipes[normalized, default: []].append(recipe)
            }
        }
        
        // For each cuisine, pick the best representative: prefer one with an image,
        // then highest favoriteCount, then most recent
        trendingCuisines = cuisineRecipes.compactMap { cuisine, recipes in
            let best = recipes
                .sorted { a, b in
                    // Prefer recipes with images
                    let aHasImage = !(a.imageURLs.isEmpty && (a.imageURL ?? "").isEmpty)
                    let bHasImage = !(b.imageURLs.isEmpty && (b.imageURL ?? "").isEmpty)
                    if aHasImage != bHasImage { return aHasImage }
                    // Then by favorite count (highest scoring)
                    if a.favoriteCount != b.favoriteCount { return a.favoriteCount > b.favoriteCount }
                    // Then by most recent
                    return a.createdAt > b.createdAt
                }
                .first
            
            guard let representative = best else { return nil }
            return CuisineEntry(english: cuisine, count: recipes.count, representativeRecipe: representative)
        }
        .sorted { $0.count != $1.count ? $0.count > $1.count : $0.english < $1.english }
    }
    
    /// Search recipes filtered by a specific cuisine
    func searchByCuisine(_ cuisineEnglish: String) {
        searchTask?.cancel()
        isSearching = true
        
        searchTask = Task {
            do {
                let results = try await recipeService.fetchRecipesByCuisine(cuisine: cuisineEnglish)
                
                guard !Task.isCancelled else { return }
                
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                print("⚠️ Error searching by cuisine: \(error.localizedDescription)")
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                }
            }
        }
    }
    
    func loadMoreWhatsNew() async {
        guard !isLoadingMoreWhatsNew, hasMoreWhatsNew, let lastDoc = lastWhatsNewDocument else {
            return
        }
        
        isLoadingMoreWhatsNew = true
        
        do {
            let (recipes, lastDoc) = try await recipeService.fetchLatestRecipes(limit: whatsNewPerPage, startAfter: lastDoc)
            whatsNew.append(contentsOf: recipes)
            lastWhatsNewDocument = lastDoc
            hasMoreWhatsNew = recipes.count >= whatsNewPerPage
        } catch {
            print("⚠️ Error loading more what's new: \(error.localizedDescription)")
        }
        
        isLoadingMoreWhatsNew = false
    }
}


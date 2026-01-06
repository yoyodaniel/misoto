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
    
    private let recipeService = RecipeService()
    private var lastTodaysSpecialDocument: DocumentSnapshot?
    private var lastWhatsNewDocument: DocumentSnapshot?
    private let recipesPerPage = 20
    private let whatsNewPerPage = 10
    private var searchTask: Task<Void, Never>?
    
    func loadRecipes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            recipes = try await recipeService.fetchAllRecipes()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
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
        } catch {
            print("⚠️ Error loading what's new: \(error.localizedDescription)")
        }
        
        isLoadingWhatsNew = false
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


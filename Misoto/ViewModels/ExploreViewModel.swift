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
    
    private let recipeService = RecipeService()
    private var lastTodaysSpecialDocument: DocumentSnapshot?
    private let recipesPerPage = 20
    
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
}


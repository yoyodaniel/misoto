//
//  RecipeDetailViewModel.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class RecipeDetailViewModel: ObservableObject {
    @Published var recipe: Recipe
    @Published var isFavorite: Bool = false
    @Published var isLoading: Bool = false
    @Published var noteCount: Int = 0
    @Published var errorMessage: String?
    
    private let recipeService = RecipeService()
    private let noteService = RecipeNoteService()
    
    init(recipe: Recipe) {
        self.recipe = recipe
    }
    
    // MARK: - Computed Properties
    
    var totalTime: Int {
        recipe.prepTime + recipe.cookTime
    }
    
    var difficultyDisplay: String {
        recipe.difficulty.rawValue
    }
    
    var difficultyDescription: String {
        switch recipe.difficulty {
        case .c:
            return LocalizedString("Zero cooking skills", comment: "Difficulty C description")
        case .b:
            return LocalizedString("Beginner", comment: "Difficulty B description")
        case .a:
            return LocalizedString("Intermediate", comment: "Difficulty A description")
        case .s:
            return LocalizedString("Advanced", comment: "Difficulty S description")
        case .ss:
            return LocalizedString("Expert", comment: "Difficulty SS description")
        }
    }
    
    // MARK: - Methods
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        async let favoriteCheck = checkFavoriteStatus()
        async let noteCountCheck = loadNoteCount()
        
        await favoriteCheck
        await noteCountCheck
        
        isLoading = false
    }
    
    func checkFavoriteStatus() async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        do {
            isFavorite = try await recipeService.isFavorite(recipeID: recipe.id, userID: userID)
        } catch {
            // Silently fail
            print("⚠️ Error checking favorite status: \(error.localizedDescription)")
        }
    }
    
    func toggleFavorite() async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        do {
            if isFavorite {
                try await recipeService.removeFavorite(recipeID: recipe.id, userID: userID)
                isFavorite = false
                recipe.favoriteCount = max(0, recipe.favoriteCount - 1)
            } else {
                try await recipeService.addFavorite(recipeID: recipe.id, userID: userID)
                isFavorite = true
                recipe.favoriteCount += 1
            }
        } catch {
            errorMessage = error.localizedDescription
            print("⚠️ Error toggling favorite: \(error.localizedDescription)")
        }
    }
    
    func loadNoteCount() async {
        do {
            noteCount = try await noteService.getNoteCount(for: recipe.id)
        } catch {
            // Silently fail
            print("⚠️ Error loading note count: \(error.localizedDescription)")
        }
    }
    
    func refreshRecipe() async {
        do {
            if let updatedRecipe = try await recipeService.fetchRecipe(byID: recipe.id) {
                recipe = updatedRecipe
                await loadData()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}


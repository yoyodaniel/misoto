//
//  RecipeStepViewModel.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class RecipeStepViewModel: ObservableObject {
    @Published var recipe: Recipe
    @Published var currentStepIndex: Int = 0
    @Published var isFavorite: Bool = false
    @Published var errorMessage: String?
    
    private let recipeService = RecipeService.shared
    
    init(recipe: Recipe, initialStepIndex: Int = 0) {
        self.recipe = recipe
        self.currentStepIndex = max(0, min(initialStepIndex, recipe.instructions.count - 1))
    }
    
    // MARK: - Computed Properties
    
    var currentStep: Instruction? {
        guard currentStepIndex >= 0 && currentStepIndex < recipe.instructions.count else {
            return nil
        }
        return recipe.instructions[currentStepIndex]
    }
    
    var stepNumber: Int {
        currentStepIndex + 1
    }
    
    var totalSteps: Int {
        recipe.instructions.count
    }
    
    var hasNextStep: Bool {
        currentStepIndex < recipe.instructions.count - 1
    }
    
    var hasPreviousStep: Bool {
        currentStepIndex > 0
    }
    
    // MARK: - Methods
    
    func loadData() async {
        await checkFavoriteStatus()
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
    
    func nextStep() {
        guard hasNextStep else { return }
        currentStepIndex += 1
    }
    
    func previousStep() {
        guard hasPreviousStep else { return }
        currentStepIndex -= 1
    }
    
    func goToStep(_ index: Int) {
        guard index >= 0 && index < recipe.instructions.count else { return }
        currentStepIndex = index
    }
}


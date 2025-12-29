//
//  ExploreViewModel.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine

@MainActor
class ExploreViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let recipeService = RecipeService()
    
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
}


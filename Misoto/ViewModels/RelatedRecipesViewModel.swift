//
//  RelatedRecipesViewModel.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine

@MainActor
class RelatedRecipesViewModel: ObservableObject {
    @Published var relatedRecipes: [Recipe] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let relatedRecipesService = RelatedRecipesService()
    
    func loadRelatedRecipes(for recipe: Recipe) async {
        isLoading = true
        errorMessage = nil
        
        do {
            relatedRecipes = try await relatedRecipesService.fetchRelatedRecipes(for: recipe, limit: 4)
        } catch {
            errorMessage = error.localizedDescription
            print("⚠️ Error loading related recipes: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
}


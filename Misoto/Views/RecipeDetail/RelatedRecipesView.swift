//
//  RelatedRecipesView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

struct RelatedRecipesView: View {
    @StateObject private var viewModel: RelatedRecipesViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedRecipe: Recipe?
    
    let recipe: Recipe
    
    init(recipe: Recipe) {
        self.recipe = recipe
        _viewModel = StateObject(wrappedValue: RelatedRecipesViewModel())
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.relatedRecipes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text(LocalizedString("No related recipes found", comment: "No related recipes message"))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 16) {
                            ForEach(viewModel.relatedRecipes) { relatedRecipe in
                                RelatedRecipeCard(recipe: relatedRecipe) {
                                    selectedRecipe = relatedRecipe
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle(LocalizedString("Related Recommendations", comment: "Related recipes title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text(LocalizedString("Close", comment: "Close button"))
                            .foregroundColor(.primary)
                    }
                }
            }
            .task {
                await viewModel.loadRelatedRecipes(for: recipe)
            }
            .fullScreenCover(item: $selectedRecipe) { recipe in
                RecipeDetailOverviewView(recipe: recipe)
            }
        }
    }
}

#Preview {
    RelatedRecipesView(recipe: Recipe(
        title: "Test Recipe",
        description: "Test",
        ingredients: [],
        instructions: [],
        prepTime: 15,
        cookTime: 30,
        servings: 2,
        difficulty: .a,
        authorID: "123",
        authorName: "Chef"
    ))
}


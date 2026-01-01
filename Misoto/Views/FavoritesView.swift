//
//  FavoritesView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    @State private var selectedRecipe: Recipe?
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.favoriteRecipes.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text(LocalizedString("No favorites yet", comment: "No favorites message"))
                            .foregroundColor(.secondary)
                        Text(LocalizedString("Start exploring and save your favorite recipes!", comment: "Favorites hint"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(viewModel.favoriteRecipes) { recipe in
                                ModernRecipeCard(recipe: recipe)
                                    .onTapGesture {
                                        selectedRecipe = recipe
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
        }
        .task {
            await viewModel.loadFavorites()
        }
        .fullScreenCover(item: $selectedRecipe) { recipe in
            ModernRecipeDetailView(recipe: recipe)
        }
    }
}

#Preview {
    FavoritesView()
}


//
//  ExploreView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()
    @State private var selectedRecipe: Recipe?
    @State private var selectedCategory = 0
    @State private var searchText = ""
    
    let categories = [
        NSLocalizedString("Today's Recommendations", comment: "Today's recommendations"),
        NSLocalizedString("Weekly Menu", comment: "Weekly menu"),
        NSLocalizedString("Trending", comment: "Trending"),
        NSLocalizedString("Ranking", comment: "Ranking")
    ]
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField(NSLocalizedString("Search ingredients, recipes", comment: "Search placeholder"), text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Category Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                            CategoryTab(
                                title: category,
                                isSelected: selectedCategory == index
                            ) {
                                selectedCategory = index
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                
                // Recipe List
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.recipes.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text(NSLocalizedString("No recipes found", comment: "No recipes message"))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(viewModel.recipes) { recipe in
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
        .fullScreenCover(item: $selectedRecipe) { recipe in
            ModernRecipeDetailView(recipe: recipe)
        }
        .task {
            await viewModel.loadRecipes()
        }
    }
}

struct CategoryTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .primary : .secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(isSelected ? Color(.secondarySystemBackground) : Color.clear)
                .cornerRadius(20)
        }
    }
}

#Preview {
    ExploreView()
}

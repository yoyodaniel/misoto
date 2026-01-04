//
//  ExploreView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import UIKit

struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var selectedRecipe: Recipe?
    @State private var selectedCategory = 0
    @State private var searchText = ""
    
    // Computed property that updates when language changes
    private var categories: [String] {
        [
            LocalizedString("Today's Special", comment: "Today's special"),
            LocalizedString("Follow", comment: "Follow"),
            LocalizedString("Chef's Choice", comment: "Chef's choice"),
            LocalizedString("Ranking", comment: "Ranking")
        ]
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField(LocalizedString("Search ingredients, recipes", comment: "Search placeholder"), text: $searchText)
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
                    HStack(spacing: 12) {
                        ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                            CategoryTab(
                                title: category,
                                isSelected: selectedCategory == index
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedCategory = index
                                }
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
                        Text(LocalizedString("No recipes found", comment: "No recipes message"))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // Featured Recipe (first one)
                            if let featuredRecipe = viewModel.recipes.first {
                                ModernRecipeCard(recipe: featuredRecipe)
                                    .onTapGesture {
                                        selectedRecipe = featuredRecipe
                                    }
                                
                                // Collections Section
                                if viewModel.recipes.count > 1 {
                                    CollectionsSection(recipes: Array(viewModel.recipes.dropFirst()))
                                }
                                
                                // Remaining Recipes
                                if viewModel.recipes.count > 1 {
                                    ForEach(Array(viewModel.recipes.dropFirst())) { recipe in
                                        ModernRecipeCard(recipe: recipe)
                                            .onTapGesture {
                                                selectedRecipe = recipe
                                            }
                                    }
                                }
                            } else {
                                ForEach(viewModel.recipes) { recipe in
                                    ModernRecipeCard(recipe: recipe)
                                        .onTapGesture {
                                            selectedRecipe = recipe
                                        }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .refreshable {
                        await viewModel.loadRecipes()
                    }
                    .onAppear {
                        // Scale down refresh control
                        scaleRefreshControl()
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedRecipe) { recipe in
            RecipeDetailOverviewView(recipe: recipe)
        }
        .task {
            await viewModel.loadRecipes()
        }
        .onChange(of: localizationManager.currentLanguage) { _, _ in
            // Trigger view update when language changes
            // The computed categories property will automatically update
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RecipeSaved"))) { _ in
            // Refresh recipes when a new recipe is saved
            Task {
                await viewModel.loadRecipes()
            }
        }
    }
    
    private func scaleRefreshControl() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                self.findAndScaleRefreshControl(in: window)
            }
        }
    }
    
    private func findAndScaleRefreshControl(in view: UIView) {
        if let scrollView = view as? UIScrollView,
           let refreshControl = scrollView.refreshControl {
            refreshControl.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
            return
        }
        
        for subview in view.subviews {
            findAndScaleRefreshControl(in: subview)
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
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(isSelected ? Color.black : Color.clear)
                .cornerRadius(20)
        }
    }
}

// MARK: - Collections Section

struct CollectionsSection: View {
    let recipes: [Recipe]
    @State private var selectedRecipe: Recipe?
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("Collections", comment: "Collections section title"))
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 16)
                .onChange(of: localizationManager.currentLanguage) { _, _ in
                    // Trigger view update when language changes
                }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(recipes.prefix(6).enumerated()), id: \.element.id) { index, recipe in
                        CollectionRecipeCard(recipe: recipe)
                            .onTapGesture {
                                selectedRecipe = recipe
                            }
                    }
                }
                .padding(.leading, 16) // Leading padding to align first card with featured card
                .padding(.bottom, 8) // Add bottom padding to prevent shadow cropping
            }
            .padding(.leading, -16) // Negative padding to extend ScrollView to screen edge
            .padding(.trailing, -16) // Negative padding to extend ScrollView to screen edge
        }
        .padding(.vertical, 16)
        .fullScreenCover(item: $selectedRecipe) { recipe in
            RecipeDetailOverviewView(recipe: recipe)
        }
    }
}

struct CollectionRecipeCard: View {
    let recipe: Recipe
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // Rounded Square Image at Top
            if let imageURL = recipe.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(.secondary)
                        }
                }
                .frame(width: 140, height: 140)
                .clipped()
                .cornerRadius(12, corners: [.topLeft, .topRight])
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 140, height: 140)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.secondary)
                    }
                    .cornerRadius(12, corners: [.topLeft, .topRight])
            }
            
            // White Bar at Bottom with Cuisine (Centered)
            VStack(alignment: .center, spacing: 0) {
                if let cuisine = recipe.displayCuisine, !cuisine.isEmpty {
                    Text(cuisine)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.black)
                        .lineLimit(1)
                } else {
                    Text(LocalizedString("Other", comment: "Other cuisine"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.black)
                        .lineLimit(1)
                }
            }
            .frame(width: 140)
            .frame(minHeight: 40)
            .background(Color.white)
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
            .onChange(of: localizationManager.currentLanguage) { _, _ in
                // Trigger view update when language changes
            }
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ExploreView()
}

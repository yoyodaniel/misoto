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
            LocalizedString("What's New", comment: "What's new category"),
            LocalizedString("Today's Special", comment: "Today's special"),
            LocalizedString("Liked", comment: "Liked recipes"),
            LocalizedString("Follow", comment: "Follow") + " " + LocalizedString("(coming soon)", comment: "Coming soon label"),
            LocalizedString("Chef's Choice", comment: "Chef's choice") + " " + LocalizedString("(coming soon)", comment: "Coming soon label"),
            LocalizedString("Ranking", comment: "Ranking") + " " + LocalizedString("(coming soon)", comment: "Coming soon label")
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
                        .onChange(of: searchText) { _, newValue in
                            viewModel.searchRecipes(query: newValue)
                        }
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            viewModel.searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
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
                if !searchText.isEmpty {
                    // Search Results
                    if viewModel.isSearching {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if viewModel.searchResults.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            Text(LocalizedString("No recipes found", comment: "No recipes message"))
                                .foregroundColor(.secondary)
                            Text(LocalizedString("Try searching for a different recipe or ingredient", comment: "Search no results hint"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                // Featured Recipe (first one)
                                if let featuredRecipe = viewModel.searchResults.first {
                                    ModernRecipeCard(recipe: featuredRecipe)
                                        .onTapGesture {
                                            selectedRecipe = featuredRecipe
                                        }
                                    
                                    // Collections Section
                                    if viewModel.searchResults.count > 1 {
                                        CollectionsSection(recipes: Array(viewModel.searchResults.dropFirst()))
                                    }
                                    
                                    // Remaining Recipes
                                    if viewModel.searchResults.count > 1 {
                                        ForEach(Array(viewModel.searchResults.dropFirst())) { recipe in
                                            ModernRecipeCard(recipe: recipe)
                                                .onTapGesture {
                                                    selectedRecipe = recipe
                                                }
                                        }
                                    }
                                } else {
                                    ForEach(viewModel.searchResults) { recipe in
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
                        .onAppear {
                            scaleRefreshControl()
                        }
                    }
                } else if selectedCategory == 0 {
                    // What's New
                    if viewModel.isLoadingWhatsNew {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if viewModel.whatsNew.isEmpty {
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
                                if let featuredRecipe = viewModel.whatsNew.first {
                                    ModernRecipeCard(recipe: featuredRecipe)
                                        .onTapGesture {
                                            selectedRecipe = featuredRecipe
                                        }
                                    
                                    // Collections Section
                                    if viewModel.whatsNew.count > 1 {
                                        CollectionsSection(recipes: Array(viewModel.whatsNew.dropFirst()))
                                    }
                                    
                                    // Remaining Recipes
                                    if viewModel.whatsNew.count > 1 {
                                        ForEach(Array(viewModel.whatsNew.dropFirst().enumerated()), id: \.element.id) { index, recipe in
                                            ModernRecipeCard(recipe: recipe)
                                                .onTapGesture {
                                                    selectedRecipe = recipe
                                                }
                                                .onAppear {
                                                    // Load more when we're near the end (3 items before the end)
                                                    let totalCount = viewModel.whatsNew.dropFirst().count
                                                    if index == totalCount - 3 && viewModel.hasMoreWhatsNew && !viewModel.isLoadingMoreWhatsNew {
                                                        Task {
                                                            await viewModel.loadMoreWhatsNew()
                                                        }
                                                    }
                                                }
                                        }
                                    }
                                } else {
                                    ForEach(Array(viewModel.whatsNew.enumerated()), id: \.element.id) { index, recipe in
                                        ModernRecipeCard(recipe: recipe)
                                            .onTapGesture {
                                                selectedRecipe = recipe
                                            }
                                            .onAppear {
                                                // Load more when we're near the end (3 items before the end)
                                                if index == viewModel.whatsNew.count - 3 && viewModel.hasMoreWhatsNew && !viewModel.isLoadingMoreWhatsNew {
                                                    Task {
                                                        await viewModel.loadMoreWhatsNew()
                                                    }
                                                }
                                            }
                                    }
                                }
                                
                                // Loading indicator at the bottom
                                if viewModel.isLoadingMoreWhatsNew {
                                    ProgressView()
                                        .padding()
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .refreshable {
                            await viewModel.loadWhatsNew()
                        }
                        .onAppear {
                            scaleRefreshControl()
                        }
                    }
                } else if selectedCategory == 1 {
                    // Today's Special
                    if viewModel.isLoadingTodaysSpecial {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if viewModel.todaysSpecial.isEmpty {
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
                                if let featuredRecipe = viewModel.todaysSpecial.first {
                                    ModernRecipeCard(recipe: featuredRecipe)
                                        .onTapGesture {
                                            selectedRecipe = featuredRecipe
                                        }
                                    
                                    // Collections Section
                                    if viewModel.todaysSpecial.count > 1 {
                                        CollectionsSection(recipes: Array(viewModel.todaysSpecial.dropFirst()))
                                    }
                                    
                                    // Remaining Recipes
                                    if viewModel.todaysSpecial.count > 1 {
                                        ForEach(Array(viewModel.todaysSpecial.dropFirst().enumerated()), id: \.element.id) { index, recipe in
                                            ModernRecipeCard(recipe: recipe)
                                                .onTapGesture {
                                                    selectedRecipe = recipe
                                                }
                                                .onAppear {
                                                    // Load more when we're near the end (3 items before the end)
                                                    let totalCount = viewModel.todaysSpecial.dropFirst().count
                                                    if index == totalCount - 3 && viewModel.hasMoreTodaysSpecial && !viewModel.isLoadingMoreTodaysSpecial {
                                                        Task {
                                                            await viewModel.loadMoreTodaysSpecial()
                                                        }
                                                    }
                                                }
                                        }
                                    }
                                } else {
                                    ForEach(Array(viewModel.todaysSpecial.enumerated()), id: \.element.id) { index, recipe in
                                        ModernRecipeCard(recipe: recipe)
                                            .onTapGesture {
                                                selectedRecipe = recipe
                                            }
                                            .onAppear {
                                                // Load more when we're near the end (3 items before the end)
                                                if index == viewModel.todaysSpecial.count - 3 && viewModel.hasMoreTodaysSpecial && !viewModel.isLoadingMoreTodaysSpecial {
                                                    Task {
                                                        await viewModel.loadMoreTodaysSpecial()
                                                    }
                                                }
                                            }
                                    }
                                }
                                
                                // Loading indicator at the bottom
                                if viewModel.isLoadingMoreTodaysSpecial {
                                    ProgressView()
                                        .padding()
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .refreshable {
                            await viewModel.loadTodaysSpecial()
                        }
                        .onAppear {
                            scaleRefreshControl()
                        }
                    }
                } else if selectedCategory == 2 {
                    // Liked recipes
                    if viewModel.isLoadingLiked {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if viewModel.likedRecipes.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "heart.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            Text(LocalizedString("No liked recipes yet", comment: "No liked recipes message"))
                                .foregroundColor(.secondary)
                            Text(LocalizedString("Start exploring and like your favorite recipes!", comment: "Liked recipes hint"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                // Featured Recipe (first one)
                                if let featuredRecipe = viewModel.likedRecipes.first {
                                    ModernRecipeCard(recipe: featuredRecipe)
                                        .onTapGesture {
                                            selectedRecipe = featuredRecipe
                                        }
                                    
                                    // Collections Section
                                    if viewModel.likedRecipes.count > 1 {
                                        CollectionsSection(recipes: Array(viewModel.likedRecipes.dropFirst()))
                                    }
                                    
                                    // Remaining Recipes
                                    if viewModel.likedRecipes.count > 1 {
                                        ForEach(Array(viewModel.likedRecipes.dropFirst())) { recipe in
                                            ModernRecipeCard(recipe: recipe)
                                                .onTapGesture {
                                                    selectedRecipe = recipe
                                                }
                                        }
                                    }
                                } else {
                                    ForEach(viewModel.likedRecipes) { recipe in
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
                            await viewModel.loadLikedRecipes()
                        }
                        .onAppear {
                            scaleRefreshControl()
                        }
                    }
                } else if selectedCategory == 3 || selectedCategory == 4 || selectedCategory == 5 {
                    // Coming soon categories (Follow, Chef's Choice, Ranking)
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text(LocalizedString("Coming Soon", comment: "Coming soon title"))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text(LocalizedString("This feature is under development and will be available soon!", comment: "Coming soon message"))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    // Other categories (default behavior)
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
                            scaleRefreshControl()
                        }
                    }
                }
            }
        }
        .fullScreenCover(item: $selectedRecipe) { recipe in
            RecipeDetailOverviewView(recipe: recipe)
        }
        .task {
            await viewModel.loadRecipes()
            await viewModel.loadWhatsNew()
            await viewModel.loadTodaysSpecial()
        }
        .onChange(of: selectedCategory) { _, newCategory in
            if newCategory == 0 {
                Task {
                    await viewModel.loadWhatsNew()
                }
            } else if newCategory == 1 {
                Task {
                    await viewModel.loadTodaysSpecial()
                }
            } else if newCategory == 2 {
                Task {
                    await viewModel.loadLikedRecipes()
                }
            }
        }
        .onChange(of: localizationManager.currentLanguage) { _, _ in
            // Trigger view update when language changes
            // The computed categories property will automatically update
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RecipeSaved"))) { _ in
            // Refresh recipes when a new recipe is saved
            Task {
                // Refresh based on current selected category
                if selectedCategory == 0 {
                    // Refresh What's New (new recipes will appear at the top)
                    await viewModel.loadWhatsNew()
                } else if selectedCategory == 1 {
                    // Refresh Today's Special (new recipes posted today will appear)
                    await viewModel.loadTodaysSpecial()
                } else if selectedCategory == 2 {
                    // Liked recipes probably won't change, but refresh anyway
                    await viewModel.loadLikedRecipes()
                } else {
                    // Refresh all recipes for other categories
                    await viewModel.loadRecipes()
                }
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

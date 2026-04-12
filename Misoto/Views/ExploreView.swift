//
//  ExploreView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import UIKit
import FirebaseAuth

struct ExploreView: View {
    @Binding var showLoginSheet: Bool
    @StateObject private var viewModel = ExploreViewModel()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var selectedRecipe: Recipe?
    @State private var selectedCategory = 0
    @State private var searchText = ""
    
    init(showLoginSheet: Binding<Bool>) {
        self._showLoginSheet = showLoginSheet
    }
    
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
                
                // Recipe List — extracted into sub-views to help the compiler
                contentView
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
                // Liked category requires authentication
                if Auth.auth().currentUser != nil {
                    Task {
                        await viewModel.loadLikedRecipes()
                    }
                } else {
                    showLoginSheet = true
                    // Reset to previous category
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        selectedCategory = 0
                    }
                }
            }
        }
        .onChange(of: localizationManager.currentLanguage) { _, _ in
            // Trigger view update when language changes
            // The computed categories property will automatically update
        }
        .onDisappear {
            // Cancel search task when view disappears
            viewModel.searchTask?.cancel()
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RecipeDeleted"))) { notification in
            // Refresh recipes when a recipe is deleted
            Task {
                let recipeID = notification.userInfo?["recipeID"] as? String
                
                // Remove deleted recipe optimistically from current arrays
                if let recipeID = recipeID {
                    viewModel.recipes.removeAll { $0.id == recipeID }
                    viewModel.whatsNew.removeAll { $0.id == recipeID }
                    viewModel.todaysSpecial.removeAll { $0.id == recipeID }
                    viewModel.likedRecipes.removeAll { $0.id == recipeID }
                    viewModel.searchResults.removeAll { $0.id == recipeID }
                }
                
                // Refresh based on current selected category
                if selectedCategory == 0 {
                    // Refresh What's New
                    await viewModel.loadWhatsNew()
                } else if selectedCategory == 1 {
                    // Refresh Today's Special
                    await viewModel.loadTodaysSpecial()
                } else if selectedCategory == 2 {
                    // Refresh Liked recipes
                    await viewModel.loadLikedRecipes()
                } else {
                    // Refresh all recipes for other categories
                    await viewModel.loadRecipes()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RecipePrivacyChanged"))) { notification in
            // Refresh public feeds when a recipe's privacy changes
            Task {
                let recipeID = notification.userInfo?["recipeID"] as? String
                let isPrivate = notification.userInfo?["isPrivate"] as? Bool ?? false
                
                // Remove private recipe from public feeds immediately
                if let recipeID = recipeID, isPrivate {
                    viewModel.whatsNew.removeAll { $0.id == recipeID }
                    viewModel.todaysSpecial.removeAll { $0.id == recipeID }
                    viewModel.recipes.removeAll { $0.id == recipeID }
                    viewModel.searchResults.removeAll { $0.id == recipeID }
                }
                
                // Refresh based on selected category if recipe was made private
                if isPrivate {
                    if selectedCategory == 0 {
                        await viewModel.loadWhatsNew()
                    } else if selectedCategory == 1 {
                        await viewModel.loadTodaysSpecial()
                    } else if selectedCategory != 2 { // Don't refresh liked recipes (they can have private recipes)
                        await viewModel.loadRecipes()
                    }
                }
            }
        }
    }
    
    // MARK: - Extracted Sub-Views
    
    @ViewBuilder
    private var contentView: some View {
        if !searchText.isEmpty {
            searchResultsView
        } else if selectedCategory == 0 {
            whatsNewView
        } else if selectedCategory == 1 {
            todaysSpecialView
        } else if selectedCategory == 2 {
            likedRecipesView
        } else if selectedCategory == 3 || selectedCategory == 4 || selectedCategory == 5 {
            comingSoonView
        } else {
            defaultRecipesView
        }
    }
    
    @ViewBuilder
    private var searchResultsView: some View {
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
                    ForEach(viewModel.searchResults) { recipe in
                        ModernRecipeCard(recipe: recipe, showLoginSheet: $showLoginSheet)
                            .onTapGesture { selectedRecipe = recipe }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .refreshable { viewModel.searchRecipes(query: searchText) }
            .onAppear { scaleRefreshControl() }
        }
    }
    
    @ViewBuilder
    private var whatsNewView: some View {
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
                    if let featuredRecipe = viewModel.whatsNew.first {
                        ModernRecipeCard(recipe: featuredRecipe, showLoginSheet: $showLoginSheet)
                            .onTapGesture { selectedRecipe = featuredRecipe }
                        
                        // Cuisines Section — dynamic from recent posts
                        if !viewModel.trendingCuisines.isEmpty {
                            CuisinesSection(
                                cuisines: viewModel.trendingCuisines,
                                onCuisineTapped: { cuisineEnglish in
                                    searchText = CuisineTranslations.translatedName(for: cuisineEnglish)
                                    viewModel.searchByCuisine(cuisineEnglish)
                                }
                            )
                        }
                        
                        // Remaining Recipes
                        if viewModel.whatsNew.count > 1 {
                            ForEach(Array(viewModel.whatsNew.dropFirst().enumerated()), id: \.element.id) { index, recipe in
                                ModernRecipeCard(recipe: recipe, showLoginSheet: $showLoginSheet)
                                    .onTapGesture { selectedRecipe = recipe }
                                    .onAppear {
                                        let totalCount = viewModel.whatsNew.dropFirst().count
                                        if index == totalCount - 3 && viewModel.hasMoreWhatsNew && !viewModel.isLoadingMoreWhatsNew {
                                            Task { await viewModel.loadMoreWhatsNew() }
                                        }
                                    }
                            }
                        }
                    } else {
                        ForEach(Array(viewModel.whatsNew.enumerated()), id: \.element.id) { index, recipe in
                            ModernRecipeCard(recipe: recipe, showLoginSheet: $showLoginSheet)
                                .onTapGesture { selectedRecipe = recipe }
                                .onAppear {
                                    if index == viewModel.whatsNew.count - 3 && viewModel.hasMoreWhatsNew && !viewModel.isLoadingMoreWhatsNew {
                                        Task { await viewModel.loadMoreWhatsNew() }
                                    }
                                }
                        }
                    }
                    
                    if viewModel.isLoadingMoreWhatsNew {
                        ProgressView().padding()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .refreshable { await viewModel.loadWhatsNew() }
            .onAppear { scaleRefreshControl() }
        }
    }
    
    @ViewBuilder
    private var todaysSpecialView: some View {
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
                    ForEach(Array(viewModel.todaysSpecial.enumerated()), id: \.element.id) { index, recipe in
                        ModernRecipeCard(recipe: recipe, showLoginSheet: $showLoginSheet)
                            .onTapGesture { selectedRecipe = recipe }
                            .onAppear {
                                if index == viewModel.todaysSpecial.count - 3 && viewModel.hasMoreTodaysSpecial && !viewModel.isLoadingMoreTodaysSpecial {
                                    Task { await viewModel.loadMoreTodaysSpecial() }
                                }
                            }
                    }
                    
                    if viewModel.isLoadingMoreTodaysSpecial {
                        ProgressView().padding()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .refreshable { await viewModel.loadTodaysSpecial() }
            .onAppear { scaleRefreshControl() }
        }
    }
    
    @ViewBuilder
    private var likedRecipesView: some View {
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
                    ForEach(viewModel.likedRecipes) { recipe in
                        ModernRecipeCard(recipe: recipe, showLoginSheet: $showLoginSheet)
                            .onTapGesture { selectedRecipe = recipe }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .refreshable { await viewModel.loadLikedRecipes() }
            .onAppear { scaleRefreshControl() }
        }
    }
    
    private var comingSoonView: some View {
        VStack {
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
        }
    }
    
    @ViewBuilder
    private var defaultRecipesView: some View {
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
                    ForEach(viewModel.recipes) { recipe in
                        ModernRecipeCard(recipe: recipe, showLoginSheet: $showLoginSheet)
                            .onTapGesture { selectedRecipe = recipe }
                    }
                }
                .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 40 : 16)
                .padding(.vertical, UIDevice.current.userInterfaceIdiom == .pad ? 20 : 12)
            }
            .refreshable { await viewModel.loadRecipes() }
            .onAppear { scaleRefreshControl() }
        }
    }
    
    // MARK: - Helper Functions
    
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

// MARK: - Cuisines Section

struct CuisinesSection: View {
    let cuisines: [ExploreViewModel.CuisineEntry]
    let onCuisineTapped: (String) -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("Cuisines", comment: "Cuisines section title"))
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 16)
                .onChange(of: localizationManager.currentLanguage) { _, _ in }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(cuisines) { cuisine in
                        CuisineCard(entry: cuisine)
                            .onTapGesture {
                                onCuisineTapped(cuisine.english)
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            }
        }
        .padding(.vertical, 12)
    }
}

/// A card showing a representative dish image with the cuisine name overlaid
struct CuisineCard: View {
    let entry: ExploreViewModel.CuisineEntry
    
    private var imageURL: String? {
        entry.representativeRecipe.imageURLs.first ?? entry.representativeRecipe.imageURL
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // Dish image
            if let urlString = imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            ProgressView()
                        }
                }
                .frame(width: 140, height: 140)
                .clipped()
                .cornerRadius(12, corners: [.topLeft, .topRight])
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 30))
                            .foregroundColor(.secondary)
                    }
                    .cornerRadius(12, corners: [.topLeft, .topRight])
            }
            
            // Cuisine label bar
            Text(CuisineTranslations.translatedName(for: entry.english))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(width: 140)
                .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ExploreView(showLoginSheet: .constant(false))
}

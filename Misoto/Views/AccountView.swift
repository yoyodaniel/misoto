//
//  AccountView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import FirebaseAuth

struct AccountView: View {
    @StateObject private var viewModel = AccountViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedRecipe: Recipe?
    @State private var showDeleteConfirmation = false
    @State private var recipeToDelete: Recipe?
    @State private var showSettingsMenu = false
    
    // Grid layout
    private let columns = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Profile Header
                        if let user = authViewModel.currentUser {
                            VStack(spacing: 16) {
                                // Profile Picture
                                ZStack(alignment: .bottomTrailing) {
                                    if let imageURL = user.profileImageURL, let url = URL(string: imageURL) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Circle()
                                                .fill(Color(.secondarySystemBackground))
                                                .overlay {
                                                    Image(systemName: "person.fill")
                                                        .font(.system(size: 40))
                                                        .foregroundColor(.secondary)
                                                }
                                        }
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Color(.secondarySystemBackground))
                                            .frame(width: 100, height: 100)
                                            .overlay {
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.secondary)
                                            }
                                    }
                                    
                                    // Camera Icon
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.accentColor)
                                        .clipShape(Circle())
                                        .offset(x: 4, y: 4)
                                }
                                
                                // Username
                                Text(user.displayName)
                                    .font(.system(size: 22, weight: .bold))
                                
                                // Stats
                                HStack(spacing: 40) {
                                    StatItem(value: "\(user.recipeCount)", label: NSLocalizedString("Recipes", comment: "Recipes count"))
                                    StatItem(value: "\(user.followerCount)", label: NSLocalizedString("Followers", comment: "Followers count"))
                                    StatItem(value: "\(user.followingCount)", label: NSLocalizedString("Following", comment: "Following count"))
                                }
                                .padding(.top, 8)
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 24)
                        }
                        
                        // Recipes Grid
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 60)
                        } else if viewModel.userRecipes.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "book.closed")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)
                                Text(NSLocalizedString("No recipes yet", comment: "No recipes message"))
                                    .foregroundColor(.secondary)
                                Text(NSLocalizedString("Start sharing your favorite recipes!", comment: "Recipes hint"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                if let errorMessage = viewModel.errorMessage {
                                    Text(errorMessage)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.top, 8)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            LazyVGrid(columns: columns, spacing: 1) {
                                ForEach(viewModel.userRecipes) { recipe in
                                    RecipeGridItem(recipe: recipe)
                                        .onTapGesture {
                                            selectedRecipe = recipe
                                        }
                                        .contextMenu {
                                            Button(role: .destructive, action: {
                                                recipeToDelete = recipe
                                                showDeleteConfirmation = true
                                            }) {
                                                Label(NSLocalizedString("Delete", comment: "Delete button"), systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding(.bottom, 100) // Space for tab bar
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if let user = authViewModel.currentUser {
                        HStack {
                            Text(user.displayName)
                                .font(.system(size: 18, weight: .bold))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {}) {
                            Image(systemName: "bell")
                                .font(.system(size: 20))
                        }
                        
                        Button(action: {
                            showSettingsMenu = true
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 20))
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadUserRecipes()
        }
        .fullScreenCover(item: $selectedRecipe) { recipe in
            ModernRecipeDetailView(recipe: recipe)
        }
        .confirmationDialog(
            NSLocalizedString("Delete Recipe", comment: "Delete confirmation title"),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(NSLocalizedString("Delete", comment: "Delete button"), role: .destructive) {
                if let recipe = recipeToDelete {
                    Task {
                        await viewModel.deleteRecipe(recipe)
                    }
                }
            }
            Button(NSLocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {}
        } message: {
            Text(NSLocalizedString("Are you sure you want to delete this recipe? This action cannot be undone.", comment: "Delete confirmation message"))
        }
        .confirmationDialog(
            NSLocalizedString("Settings", comment: "Settings menu title"),
            isPresented: $showSettingsMenu,
            titleVisibility: .visible
        ) {
            Button(NSLocalizedString("Sign Out", comment: "Sign out button"), role: .destructive) {
                authViewModel.signOut()
            }
            Button(NSLocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {}
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

struct RecipeGridItem: View {
    let recipe: Recipe
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let imageURL = recipe.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay {
                                ProgressView()
                            }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                } else {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.6))
                        }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    AccountView()
}


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
    
    init() {
        // Note: We'll set authViewModel reference in onAppear since we can't access @EnvironmentObject in init
    }
    @State private var selectedRecipe: Recipe?
    @State private var showDeleteConfirmation = false
    @State private var recipeToDelete: Recipe?
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var recipeToEdit: Recipe?
    @State private var lastRefreshTime: Date?
    
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
                                // Profile Picture (Tappable to edit)
                                Button(action: {
                                    showEditProfile = true
                                }) {
                                    ZStack(alignment: .bottomTrailing) {
                                        if let imageURL = user.profileImageURL, let url = URL(string: imageURL) {
                                            AsyncImage(url: url) { phase in
                                                switch phase {
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                case .failure(_), .empty:
                                                    Circle()
                                                        .fill(Color(.secondarySystemBackground))
                                                        .overlay {
                                                            Image(systemName: "person.fill")
                                                                .font(.system(size: 40))
                                                                .foregroundColor(.secondary)
                                                        }
                                                @unknown default:
                                                    Circle()
                                                        .fill(Color(.secondarySystemBackground))
                                                        .overlay {
                                                            Image(systemName: "person.fill")
                                                                .font(.system(size: 40))
                                                                .foregroundColor(.secondary)
                                                        }
                                                }
                                            }
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                            .id(imageURL) // Force refresh when URL changes
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
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Name
                                Text(user.displayName)
                                    .font(.system(size: 22, weight: .bold))
                                
                                // Username
                                if let username = user.username, !username.isEmpty {
                                    Text("@\(username)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Bio
                                if let bio = user.bio, !bio.isEmpty {
                                    Text(bio)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                                
                                // Edit Profile and Settings Buttons
                                HStack(spacing: 12) {
                                    Button(action: {
                                        HapticFeedback.buttonTap()
                                        showEditProfile = true
                                    }) {
                                        Text(LocalizedString("Edit Profile", comment: "Edit profile button"))
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 8)
                                            .background(Color.accentColor)
                                            .cornerRadius(8)
                                    }
                                    
                                    Button(action: {
                                        HapticFeedback.buttonTap()
                                        showSettings = true
                                    }) {
                                        Image(systemName: "gearshape.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.primary)
                                            .frame(width: 36, height: 36)
                                            .background(Color(.secondarySystemBackground))
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.top, 4)
                                
                                // Stats
                                HStack(spacing: 40) {
                                    StatItem(value: "\(user.recipeCount)", label: LocalizedString("Recipes", comment: "Recipes count"))
                                    StatItem(value: "\(user.followerCount)", label: LocalizedString("Followers", comment: "Followers count"))
                                    StatItem(value: "\(user.followingCount)", label: LocalizedString("Following", comment: "Following count"))
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
                            VStack(spacing: 24) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary.opacity(0.6))
                                
                                VStack(spacing: 8) {
                                    Text(LocalizedString("No recipes yet", comment: "No recipes message"))
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text(LocalizedString("Start sharing your favorite recipes with the community!", comment: "Recipes hint"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                                
                                if let errorMessage = viewModel.errorMessage {
                                    Text(errorMessage)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.top, 8)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 80)
                        } else {
                            LazyVGrid(columns: columns, spacing: 1) {
                                ForEach(viewModel.userRecipes, id: \.id) { recipe in
                                    RecipeGridItem(recipe: recipe)
                                        .id(recipe.id) // Stable ID for efficient updates
                                        .onTapGesture {
                                            selectedRecipe = recipe
                                        }
                                        .contextMenu {
                                            Button(action: {
                                                recipeToEdit = recipe
                                            }) {
                                                Label(LocalizedString("Edit Recipe", comment: "Edit recipe button"), systemImage: "pencil")
                                            }
                                            
                                            Button(role: .destructive, action: {
                                                recipeToDelete = recipe
                                                showDeleteConfirmation = true
                                            }) {
                                                Label(LocalizedString("Delete", comment: "Delete button"), systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding(.bottom, 100) // Space for tab bar
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.loadUserRecipes()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "bell")
                            .font(.system(size: 20))
                    }
                }
            }
        }
        .task {
            // Set authViewModel reference for recipe deletion
            viewModel.authViewModel = authViewModel
            await viewModel.loadUserRecipes()
            lastRefreshTime = Date()
        }
        .onAppear {
            // Refresh recipes when view appears (e.g., returning from recipe creation)
            // Only refresh if it's been more than 1 second since last refresh to avoid unnecessary calls
            if let lastRefresh = lastRefreshTime {
                let timeSinceLastRefresh = Date().timeIntervalSince(lastRefresh)
                if timeSinceLastRefresh > 1.0 {
                    Task {
                        await viewModel.loadUserRecipes()
                        lastRefreshTime = Date()
                    }
                }
            } else {
                // First appear - refresh
                Task {
                    await viewModel.loadUserRecipes()
                    lastRefreshTime = Date()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RecipeSaved"))) { _ in
            // Refresh when a recipe is saved
            Task {
                await viewModel.loadUserRecipes()
                lastRefreshTime = Date()
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(viewModel: viewModel, authViewModel: authViewModel)
        }
        .sheet(item: $recipeToEdit) { recipe in
            EditRecipeView(recipe: recipe)
        }
        .fullScreenCover(item: $selectedRecipe) { recipe in
            ModernRecipeDetailView(recipe: recipe)
        }
        .confirmationDialog(
            LocalizedString("Delete Recipe", comment: "Delete confirmation title"),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(LocalizedString("Delete", comment: "Delete button"), role: .destructive) {
                HapticFeedback.play(.error)
                if let recipe = recipeToDelete {
                    // Delete immediately (optimistic update - removes from UI instantly)
                    viewModel.deleteRecipe(recipe)
                    // Clear the selected recipe
                    recipeToDelete = nil
                }
            }
            Button(LocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {
                recipeToDelete = nil
            }
        } message: {
            Text(LocalizedString("Are you sure you want to delete this recipe? This action cannot be undone.", comment: "Delete confirmation message"))
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(authViewModel)
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
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure(_), .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay {
                                    ProgressView()
                                }
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay {
                                    ProgressView()
                                }
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .id(imageURL) // Cache key for image
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



//
//  AccountView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import FirebaseAuth

struct AccountView: View {
    @Binding var showLoginSheet: Bool
    @StateObject private var viewModel = AccountViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    init(showLoginSheet: Binding<Bool>) {
        self._showLoginSheet = showLoginSheet
        // Note: We'll set authViewModel reference in onAppear since we can't access @EnvironmentObject in init
    }
    @State private var selectedRecipe: Recipe?
    @State private var showDeleteConfirmation = false
    @State private var showMakePublicConfirmation = false
    @State private var showShareWithUsers = false
    @State private var recipeToDelete: Recipe?
    @State private var recipeToMakePublic: Recipe?
    @State private var recipeToShare: Recipe?
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
        let _ = localizationManager.currentLanguage // Force view update when language changes
        return NavigationView {
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
                                
                                // Name with Premium Checkmark Badge
                                ZStack(alignment: .topTrailing) {
                                    Text(user.displayName)
                                        .font(.system(size: 22, weight: .bold))
                                    
                                    if user.premiumUser {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.blue)
                                            .offset(x: 17, y: -2)
                                    }
                                }
                                
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
                                HStack(spacing: 30) {
                                    StatItem(value: "\(user.recipeCount)", label: LocalizedString("Recipes", comment: "Recipes count"))
                                    StatItem(value: "\(user.followerCount)", label: LocalizedString("Followers", comment: "Followers count"))
                                    StatItem(value: "\(user.followingCount)", label: LocalizedString("Following", comment: "Following count"))
                                    StatItem(value: "\(user.likesCount)", label: LocalizedString("Likes", comment: "Likes count"))
                                }
                                .padding(.top, 8)
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 24)
                        } else {
                            // Show login prompt when not authenticated
                            VStack(spacing: 24) {
                                Spacer()
                                
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.secondary.opacity(0.6))
                                
                                VStack(spacing: 12) {
                                    Text(LocalizedString("Sign in to your account", comment: "Sign in prompt title"))
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text(LocalizedString("Sign in to view your profile, save recipes, and more", comment: "Sign in prompt message"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                    
                                    Button(action: {
                                        HapticFeedback.buttonTap()
                                        showLoginSheet = true
                                    }) {
                                        Text(LocalizedString("Sign In", comment: "Sign in button"))
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.accentColor)
                                            .cornerRadius(12)
                                    }
                                    .padding(.horizontal, 40)
                                    .padding(.top, 8)
                                }
                                
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.vertical, 60)
                        }
                        
                        // Recipes Grid (only show if authenticated)
                        if authViewModel.currentUser != nil {
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
                                                
                                                Button(action: {
                                                    if recipe.isPrivate {
                                                        // Show confirmation alert when making public
                                                        recipeToMakePublic = recipe
                                                        showMakePublicConfirmation = true
                                                    } else {
                                                        // Make private to all (clear sharedWith, only owner can see)
                                                        Task {
                                                            await viewModel.toggleRecipePrivacy(recipe: recipe, clearSharedWith: true)
                                                        }
                                                    }
                                                }) {
                                                    Label(
                                                        recipe.isPrivate ? LocalizedString("Make Public", comment: "Make recipe public") : LocalizedString("Make Private", comment: "Make recipe private"),
                                                        systemImage: recipe.isPrivate ? "eye.fill" : "eye.slash.fill"
                                                    )
                                                }
                                                
                                                // Show "Private Sharing" option for all recipes
                                                // If recipe is public, it will be made private when opening private sharing
                                                Button(action: {
                                                    if !recipe.isPrivate {
                                                        // For public recipes, make private first, then show sheet
                                                        Task {
                                                            // Make private in backend first (preserve sharedWith, don't clear)
                                                            // This already optimistically updates the UI, so no reload needed
                                                            await viewModel.toggleRecipePrivacy(recipe: recipe, clearSharedWith: false)
                                                            
                                                            // Find the updated recipe from the optimistically updated array
                                                            if let updatedRecipe = viewModel.userRecipes.first(where: { $0.id == recipe.id }) {
                                                                await MainActor.run {
                                                                    recipeToShare = updatedRecipe
                                                                    showShareWithUsers = true
                                                                }
                                                            } else {
                                                                // Fallback: use current recipe (optimistic update should have worked)
                                                                await MainActor.run {
                                                                    recipeToShare = recipe
                                                                    showShareWithUsers = true
                                                                }
                                                            }
                                                        }
                                                    } else {
                                                        // Recipe is already private - use current recipe (already has latest state from optimistic updates)
                                                        recipeToShare = recipe
                                                        showShareWithUsers = true
                                                    }
                                                }) {
                                                    if recipe.hasSharedUsers {
                                                        Label(
                                                            String(format: LocalizedString("Private Sharing (%d)", comment: "Private sharing button with count"), recipe.effectiveSharedCount),
                                                            systemImage: "person.2.fill"
                                                        )
                                                    } else {
                                                        Label(
                                                            LocalizedString("Private Sharing", comment: "Private sharing button"),
                                                            systemImage: "person.2.fill"
                                                        )
                                                    }
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
                // Reload user data to update recipe count
                await authViewModel.reloadUserData()
                lastRefreshTime = Date()
                print("✅ AccountView: User data refreshed after recipe saved - recipe count: \(authViewModel.currentUser?.recipeCount ?? 0)")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDataUpdated"))) { _ in
            // Refresh user data when updated (e.g., after follow/unfollow)
            Task {
                await authViewModel.reloadUserData()
                print("✅ AccountView: User data refreshed from notification")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RecipeDeleted"))) { notification in
            // Refresh recipes when a recipe is deleted (e.g., from RecipeDetailOverviewView)
            Task {
                let recipeID = notification.userInfo?["recipeID"] as? String
                
                // Remove deleted recipe optimistically from user recipes array
                if let recipeID = recipeID {
                    viewModel.userRecipes.removeAll { $0.id == recipeID }
                }
                
                // Reload user recipes to ensure consistency
                await viewModel.loadUserRecipes()
                await authViewModel.reloadUserData()
                print("✅ AccountView: Recipes refreshed after deletion")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RecipePrivacyChanged"))) { notification in
            // Update recipe privacy status in grid view
            Task {
                let recipeID = notification.userInfo?["recipeID"] as? String
                let isPrivate = notification.userInfo?["isPrivate"] as? Bool ?? false
                let clearSharedWith = notification.userInfo?["clearSharedWith"] as? Bool ?? false
                
                // Update recipe optimistically in userRecipes array
                if let recipeID = recipeID, let index = viewModel.userRecipes.firstIndex(where: { $0.id == recipeID }) {
                    let currentSharedWith = viewModel.userRecipes[index].sharedWith
                    viewModel.userRecipes[index].isPrivate = isPrivate
                    
                    // If making private and clearSharedWith is true: Save current sharedWith to preservedSharedWith, then clear sharedWith
                    if isPrivate && clearSharedWith {
                        // Save current sharedWith to preservedSharedWith before clearing (if it has users)
                        if !currentSharedWith.isEmpty {
                            viewModel.userRecipes[index].preservedSharedWith = currentSharedWith
                        }
                        // Always clear sharedWith when making "Private to All" (removes access)
                        viewModel.userRecipes[index].sharedWith = []
                    }
                    // When making public: Restore preservedSharedWith to sharedWith if it exists
                    else if !isPrivate {
                        // Restore preserved sharedWith list if it exists
                        if let preserved = viewModel.userRecipes[index].preservedSharedWith, !preserved.isEmpty {
                            viewModel.userRecipes[index].sharedWith = preserved
                            viewModel.userRecipes[index].preservedSharedWith = nil // Clear preserved list after restore
                        }
                        // If no preserved list, keep current sharedWith as-is
                    }
                    print("✅ AccountView: Recipe privacy updated in grid view, sharedWith: \(viewModel.userRecipes[index].sharedWith.count) users, preserved: \(viewModel.userRecipes[index].preservedSharedWith?.count ?? 0) users")
                }
                
                // Reload to ensure consistency
                await viewModel.loadUserRecipes()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RecipeSharingChanged"))) { notification in
            // Update recipe sharing status in grid view
            Task {
                let recipeID = notification.userInfo?["recipeID"] as? String
                let sharedWith = notification.userInfo?["sharedWith"] as? [String] ?? []
                
                // Update recipe optimistically in userRecipes array
                if let recipeID = recipeID, let index = viewModel.userRecipes.firstIndex(where: { $0.id == recipeID }) {
                    viewModel.userRecipes[index].sharedWith = sharedWith
                    viewModel.userRecipes[index].isPrivate = true // Must be private to share
                    print("✅ AccountView: Recipe sharing updated in grid view")
                }
                
                // Reload to ensure consistency
                await viewModel.loadUserRecipes()
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(viewModel: viewModel, authViewModel: authViewModel)
        }
        .sheet(item: $recipeToEdit) { recipe in
            EditRecipeView(recipe: recipe)
                // No reload in onDisappear - recipe saves trigger RecipeSaved notification which handles refresh
        }
        .sheet(isPresented: Binding(
            get: { showShareWithUsers && recipeToShare != nil },
            set: { newValue in
                if !newValue {
                    recipeToShare = nil
                }
                showShareWithUsers = newValue
            }
        )) {
            if let recipe = recipeToShare {
                ShareRecipeView(recipe: recipe) { sharedUserIDs in
                    // Only reload if changes were actually made (onSave is called when user presses "Done")
                    Task {
                        await viewModel.updateRecipeSharing(recipe: recipe, sharedWith: sharedUserIDs)
                        // Refresh after saving to ensure consistency with server
                        await viewModel.loadUserRecipes()
                    }
                }
                .onDisappear {
                    // Just clear the recipe reference - no reload needed if user canceled
                    recipeToShare = nil
                }
            }
        }
        .fullScreenCover(item: $selectedRecipe) { recipe in
            RecipeDetailOverviewView(recipe: recipe)
        }
        .alert(
            LocalizedString("Delete Recipe", comment: "Delete confirmation title"),
            isPresented: $showDeleteConfirmation
        ) {
            Button(LocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {
                recipeToDelete = nil
            }
            Button(LocalizedString("Delete", comment: "Delete button"), role: .destructive) {
                HapticFeedback.play(.error)
                if let recipe = recipeToDelete {
                    // Delete immediately (optimistic update - removes from UI instantly)
                    viewModel.deleteRecipe(recipe)
                    // Clear the selected recipe
                    recipeToDelete = nil
                }
            }
        } message: {
            Text(LocalizedString("Are you sure you want to delete this recipe? This action cannot be undone.", comment: "Delete confirmation message"))
        }
        .alert(
            LocalizedString("Make Recipe Public", comment: "Make recipe public confirmation title"),
            isPresented: $showMakePublicConfirmation
        ) {
            Button(LocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {
                recipeToMakePublic = nil
            }
            Button(LocalizedString("Make Public", comment: "Make public button")) {
                if let recipe = recipeToMakePublic {
                    Task {
                        await viewModel.toggleRecipePrivacy(recipe: recipe)
                        recipeToMakePublic = nil
                    }
                }
            }
        } message: {
            Text(LocalizedString("Are you sure you want to make this recipe public?", comment: "Make recipe public confirmation message"))
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
            ZStack(alignment: .topTrailing) {
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
                
                // Privacy status indicator
                // Show icon for private recipes (fully private or shared)
                // Show person.2.fill if recipe has shared users (either active or preserved)
                if recipe.isPrivate {
                    Image(systemName: recipe.hasSharedUsers ? "person.2.fill" : "eye.slash.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                        .padding(8)
                }
                // Public recipes show no icon (or could show eye.fill if desired)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    AccountView(showLoginSheet: .constant(false))
        .environmentObject(AuthViewModel())
}



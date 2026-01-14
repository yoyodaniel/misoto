//
//  ShareRecipeView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

struct ShareRecipeView: View {
    @StateObject private var viewModel: ShareRecipeViewModel
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    let recipe: Recipe
    let onSave: ([String]) -> Void
    
    @State private var isSearching = false
    
    init(recipe: Recipe, onSave: @escaping ([String]) -> Void) {
        self.recipe = recipe
        self.onSave = onSave
        // Use preservedSharedWith if sharedWith is empty (recipe was "Private to All" but had previous sharing)
        // Otherwise use sharedWith (recipe is "Private Sharing" or "Public to All" with preserved list)
        let sharedUserIDs: [String]
        if recipe.sharedWith.isEmpty, let preserved = recipe.preservedSharedWith {
            sharedUserIDs = preserved
        } else {
            sharedUserIDs = recipe.sharedWith
        }
        print("📋 ShareRecipeView init - recipe.sharedWith: \(recipe.sharedWith.count) users, preservedSharedWith: \(recipe.preservedSharedWith?.count ?? 0) users, using: \(sharedUserIDs.count) users")
        _viewModel = StateObject(wrappedValue: ShareRecipeViewModel(sharedUserIDs: sharedUserIDs, recipeID: recipe.id))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Selected Users Section
                if !viewModel.selectedUsers.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.selectedUsers) { user in
                                SelectedUserChip(user: user) {
                                    viewModel.removeSelectedUser(user)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Color(.systemGray6))
                    
                    Divider()
                }
                
                // Search Bar
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField(LocalizedString("Search users", comment: "Search users placeholder"), text: $viewModel.searchQuery)
                            .textFieldStyle(.plain)
                            .onSubmit {
                                isSearching = true
                                Task {
                                    await viewModel.searchUsers(query: viewModel.searchQuery)
                                    isSearching = false
                                }
                            }
                        
                        if !viewModel.searchQuery.isEmpty {
                            Button(action: {
                                viewModel.searchQuery = ""
                                viewModel.searchResults = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    // Quick access to followers
                    if viewModel.searchQuery.isEmpty && viewModel.searchResults.isEmpty {
                        Button(action: {
                            Task {
                                await viewModel.loadFollowers()
                            }
                        }) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                Text(LocalizedString("Select from Followers", comment: "Select from followers button"))
                            }
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                }
                
                Divider()
                
                // User List
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text(LocalizedString("No users found", comment: "No users found message"))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    // Show existing shared users if no search is active
                    if viewModel.searchQuery.isEmpty && viewModel.searchResults.isEmpty {
                        if !viewModel.existingSharedUsers.isEmpty {
                            // Show existing shared users list
                            List {
                                Section(header: Text(LocalizedString("Users with Access", comment: "Users with access section header"))) {
                                    ForEach(viewModel.existingSharedUsers) { user in
                                        UserRowView(user: user, isSelected: false, isExisting: true) {
                                            viewModel.removeExistingSharedUser(user)
                                        }
                                    }
                                }
                            }
                            .listStyle(.plain)
                        } else {
                            // Empty state
                            Spacer()
                            VStack(spacing: 16) {
                                Image(systemName: "person.2.crop.square.stack")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                                Text(LocalizedString("Search for users or select from followers", comment: "Empty sharing state message"))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            Spacer()
                        }
                    } else {
                        // Show search results or followers list
                        List(viewModel.searchResults) { user in
                            UserRowView(user: user, isSelected: viewModel.selectedUsers.contains(where: { $0.id == user.id })) {
                                viewModel.toggleUserSelection(user)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle(LocalizedString("Private Sharing", comment: "Private sharing title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedString("Cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedString("Done", comment: "Done button")) {
                        onSave(viewModel.getSelectedUserIDs())
                        dismiss()
                    }
                    // Allow saving even if no users selected (to clear sharing)
                }
            }
            .task {
                // Load existing shared users when view appears
                await viewModel.loadExistingSharedUsers()
            }
        }
    }
}

struct SelectedUserChip: View {
    let user: AppUser
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            if let profileImageURL = user.profileImageURL, let url = URL(string: profileImageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.secondary)
                }
                .frame(width: 24, height: 24)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
            }
            
            Text(user.displayName)
                .font(.subheadline)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
    }
}

struct UserRowView: View {
    let user: AppUser
    let isSelected: Bool
    var isExisting: Bool = false // For existing shared users (non-interactive, can be removed)
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Profile Picture
                if let profileImageURL = user.profileImageURL, let url = URL(string: profileImageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary)
                }
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let username = user.username {
                        Text("@\(username)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Selection Indicator or Remove Button
                if isExisting {
                    // For existing shared users, show remove button
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary.opacity(0.3))
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}


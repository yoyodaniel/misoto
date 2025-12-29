//
//  FriendsView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

struct FriendsView: View {
    @StateObject private var viewModel = FriendsViewModel()
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Segmented Control
                Picker(NSLocalizedString("Friends", comment: "Friends picker"), selection: $viewModel.selectedTab) {
                    Text(NSLocalizedString("Followers", comment: "Followers")).tag(FriendsViewModel.FriendsTab.followers)
                    Text(NSLocalizedString("Following", comment: "Following")).tag(FriendsViewModel.FriendsTab.following)
                    Text(NSLocalizedString("Search", comment: "Search")).tag(FriendsViewModel.FriendsTab.search)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Group {
                    switch viewModel.selectedTab {
                    case .followers:
                        followersList
                    case .following:
                        followingList
                    case .search:
                        searchView
                    }
                }
            }
            .task {
                await viewModel.loadFollowers()
                await viewModel.loadFollowing()
            }
        }
    }
    
    private var followersList: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.followers.isEmpty {
                emptyStateView(message: NSLocalizedString("No followers yet", comment: "No followers message"))
            } else {
                List(viewModel.followers) { user in
                    UserRow(user: user)
                }
            }
        }
    }
    
    private var followingList: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.following.isEmpty {
                emptyStateView(message: NSLocalizedString("You're not following anyone yet", comment: "No following message"))
            } else {
                List(viewModel.following) { user in
                    UserRow(user: user, showUnfollow: true) {
                        Task {
                            await viewModel.unfollowUser(user)
                        }
                    }
                }
            }
        }
    }
    
    private var searchView: some View {
        VStack {
            HStack {
                TextField(NSLocalizedString("Search users", comment: "Search users placeholder"), text: $viewModel.searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task {
                            await viewModel.searchUsers()
                        }
                    }
                
                Button(action: {
                    Task {
                        await viewModel.searchUsers()
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                }
            }
            .padding()
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                emptyStateView(message: NSLocalizedString("No users found", comment: "No users found message"))
            } else {
                List(viewModel.searchResults) { user in
                    UserRow(user: user, showFollow: true) {
                        Task {
                            await viewModel.followUser(user)
                        }
                    }
                }
            }
        }
    }
    
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text(message)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FriendsView()
}


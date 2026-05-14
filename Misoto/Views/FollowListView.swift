//
//  FollowListView.swift
//  Misoto
//
//  Created by Daniel Chan on 04.05.2026.
//

import SwiftUI

struct FollowListView: View {
    let profileUserID: String
    let kind: FollowListKind

    @StateObject private var viewModel: FollowListViewModel

    init(profileUserID: String, kind: FollowListKind) {
        self.profileUserID = profileUserID
        self.kind = kind
        _viewModel = StateObject(wrappedValue: FollowListViewModel(profileUserID: profileUserID, kind: kind))
    }

    var body: some View {
        Group {
            if viewModel.isInitialLoading && viewModel.users.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage, viewModel.users.isEmpty {
                followEmptyState(message: errorMessage)
            } else if viewModel.filteredUsers.isEmpty {
                followEmptyState(message: LocalizedString("No users found", comment: "No users found"))
            } else {
                List(viewModel.filteredUsers) { user in
                    Group {
                        if viewModel.canManageFollowersFromList {
                            let isFollowingUser = viewModel.isFollowingUser(user.id)
                            UserRow(
                                user: user,
                                showFollow: !isFollowingUser,
                                followTitle: LocalizedString("Follow Back", comment: "Follow back button"),
                                showUnfollow: isFollowingUser
                            ) {
                                Task {
                                    await viewModel.toggleFollowState(for: user)
                                }
                            }
                        } else {
                            UserRow(
                                user: user,
                                showUnfollow: viewModel.canUnfollowFromList
                            ) {
                                Task {
                                    await viewModel.unfollow(user: user)
                                }
                            }
                        }
                    }
                    .onAppear {
                        Task {
                            await viewModel.loadNextPageIfNeeded(currentUser: user)
                        }
                    }
                }
                .overlay(alignment: .bottom) {
                    if viewModel.isLoadingMore && !viewModel.users.isEmpty {
                        ProgressView()
                            .padding(.vertical, 12)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: Text(LocalizedString("Search by name or username", comment: "Search by username or display name"))
        )
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private func followEmptyState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        FollowListView(profileUserID: "preview-user-id", kind: .followers)
            .environmentObject(AuthViewModel())
    }
}
#endif

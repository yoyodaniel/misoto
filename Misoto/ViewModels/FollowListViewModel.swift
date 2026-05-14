//
//  FollowListViewModel.swift
//  Misoto
//
//  Created by Daniel Chan on 04.05.2026.
//

import Foundation
import Combine
import FirebaseAuth

enum FollowListKind {
    case followers
    case following

    var title: String {
        switch self {
        case .followers:
            return LocalizedString("Followers", comment: "Followers title")
        case .following:
            return LocalizedString("Following", comment: "Following title")
        }
    }
}

@MainActor
final class FollowListViewModel: ObservableObject {
    @Published var users: [AppUser] = []
    @Published private(set) var followingUserIDs: Set<String> = []
    @Published var isInitialLoading = false
    @Published var isLoadingMore = false
    @Published var hasMore = true
    @Published var errorMessage: String?
    @Published var searchText = ""

    private let profileUserID: String
    private let kind: FollowListKind
    private let friendsService = FriendsService()
    private let authService = AuthService()
    private var cachedBrowseUsers: [AppUser] = []
    private var pageCursor: FollowPageCursor?
    private var searchDebounceCancellable: AnyCancellable?

    init(profileUserID: String, kind: FollowListKind) {
        self.profileUserID = profileUserID
        self.kind = kind
        configureSearchDebounce()
    }

    var filteredUsers: [AppUser] {
        users
    }

    var isOwnProfile: Bool {
        Auth.auth().currentUser?.uid == profileUserID
    }

    var canUnfollowFromList: Bool {
        isOwnProfile && kind == .following
    }

    var canManageFollowersFromList: Bool {
        isOwnProfile && kind == .followers
    }

    func load() async {
        let isSearching = isSearchActive
        isInitialLoading = true
        errorMessage = nil
        hasMore = true
        pageCursor = nil
        if !isSearching {
            users = []
        }
        defer { isInitialLoading = false }

        do {
            try await loadNextPageInternal()
            if !isSearching {
                cachedBrowseUsers = users
            }
            await refreshFollowingRelationshipState()
        } catch {
            errorMessage = error.localizedDescription
            if isSearching, !cachedBrowseUsers.isEmpty {
                users = cachedBrowseUsers.filter { user in
                    matchesSearch(user: user, query: searchText)
                }
            } else if users.isEmpty {
                followingUserIDs = []
            }
        }
    }

    func loadNextPageIfNeeded(currentUser user: AppUser) async {
        guard hasMore, !isLoadingMore, !isInitialLoading else { return }
        guard users.last?.id == user.id else { return }

        do {
            try await loadNextPageInternal()
            if canManageFollowersFromList {
                await loadCurrentUserFollowingIDs(for: users.map(\.id))
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func unfollow(user: AppUser) async {
        guard canUnfollowFromList else { return }
        do {
            try await friendsService.unfollowUser(followingID: user.id)
            users.removeAll { $0.id == user.id }
            followingUserIDs.remove(user.id)
            await authService.reloadUserData()
            NotificationCenter.default.post(name: NSNotification.Name("UserDataUpdated"), object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isFollowingUser(_ userID: String) -> Bool {
        followingUserIDs.contains(userID)
    }

    func toggleFollowState(for user: AppUser) async {
        guard canManageFollowersFromList else { return }
        do {
            if isFollowingUser(user.id) {
                try await friendsService.unfollowUser(followingID: user.id)
                followingUserIDs.remove(user.id)
            } else {
                try await friendsService.followUser(followingID: user.id)
                followingUserIDs.insert(user.id)
            }
            await authService.reloadUserData()
            NotificationCenter.default.post(name: NSNotification.Name("UserDataUpdated"), object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func configureSearchDebounce() {
        searchDebounceCancellable = $searchText
            .dropFirst()
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.load()
                }
            }
    }

    private func loadNextPageInternal() async throws {
        isLoadingMore = true
        defer { isLoadingMore = false }

        let page: FollowPageResult
        switch kind {
        case .followers:
            page = try await friendsService.fetchFollowersPage(
                userID: profileUserID,
                query: searchText,
                cursor: pageCursor
            )
        case .following:
            page = try await friendsService.fetchFollowingPage(
                userID: profileUserID,
                query: searchText,
                cursor: pageCursor
            )
        }

        if pageCursor == nil {
            users = page.users
        } else {
            users.append(contentsOf: page.users)
        }
        pageCursor = page.nextCursor
        hasMore = page.hasMore
    }

    private func refreshFollowingRelationshipState() async {
        switch kind {
        case .followers:
            await loadCurrentUserFollowingIDs(for: users.map(\.id))
        case .following:
            if isOwnProfile {
                followingUserIDs = Set(users.map(\.id))
            } else {
                followingUserIDs = []
            }
        }
    }

    private func loadCurrentUserFollowingIDs(for userIDs: [String]) async {
        guard isOwnProfile else {
            followingUserIDs = []
            return
        }

        do {
            followingUserIDs = try await friendsService.fetchFollowingMembership(
                userID: profileUserID,
                targetUserIDs: userIDs
            )
        } catch {
            followingUserIDs = []
        }
    }

    private var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func matchesSearch(user: AppUser, query: String) -> Bool {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return true }

        if normalized.hasPrefix("@") {
            let usernameQuery = String(normalized.dropFirst())
            return (user.username ?? "").lowercased().contains(usernameQuery)
        }

        if user.displayName.lowercased().contains(normalized) {
            return true
        }
        return (user.username ?? "").lowercased().contains(normalized)
    }
}

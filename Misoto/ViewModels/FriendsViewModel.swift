//
//  FriendsViewModel.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var followers: [AppUser] = []
    @Published var following: [AppUser] = []
    @Published var searchResults: [AppUser] = []
    @Published var searchQuery = ""
    @Published var selectedTab: FriendsTab = .followers
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let friendsService = FriendsService()
    
    enum FriendsTab {
        case followers
        case following
        case search
    }
    
    func loadFollowers() async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            followers = try await friendsService.fetchFollowers(userID: userID)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadFollowing() async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            following = try await friendsService.fetchFollowing(userID: userID)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func searchUsers() async {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            searchResults = try await friendsService.searchUsers(query: searchQuery)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func followUser(_ user: AppUser) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await friendsService.followUser(followingID: user.id)
            await loadFollowing()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func unfollowUser(_ user: AppUser) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await friendsService.unfollowUser(followingID: user.id)
            await loadFollowing()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func isFollowing(_ user: AppUser) async -> Bool {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return false }
        
        do {
            return try await friendsService.isFollowing(followerID: currentUserID, followingID: user.id)
        } catch {
            return false
        }
    }
}


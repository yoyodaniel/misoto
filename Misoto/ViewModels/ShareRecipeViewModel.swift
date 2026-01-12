//
//  ShareRecipeViewModel.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class ShareRecipeViewModel: ObservableObject {
    @Published var searchResults: [AppUser] = []
    @Published var selectedUsers: [AppUser] = [] // Newly selected users (not existing)
    @Published var existingSharedUsers: [AppUser] = [] // Users already shared with
    @Published var searchQuery: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let friendsService = FriendsService()
    private let firestore = FirebaseManager.shared.firestore
    private var initialSharedUserIDs: [String] = []
    
    init(sharedUserIDs: [String] = []) {
        self.initialSharedUserIDs = sharedUserIDs
    }
    
    func loadExistingSharedUsers() async {
        guard !initialSharedUserIDs.isEmpty else { return }
        
        isLoading = true
        
        do {
            var loadedUsers: [AppUser] = []
            for userID in initialSharedUserIDs {
                let userDoc = try await firestore.collection("users").document(userID).getDocument()
                if let user = try? userDoc.data(as: AppUser.self) {
                    loadedUsers.append(user)
                }
            }
            existingSharedUsers = loadedUsers
            print("✅ Loaded \(loadedUsers.count) existing shared users")
        } catch {
            print("⚠️ Error loading shared users: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func searchUsers(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let results = try await friendsService.searchUsers(query: query)
            // Filter out already selected users, existing shared users, and current user
            let currentUserID = Auth.auth().currentUser?.uid
            let allExcludedIDs = Set(selectedUsers.map { $0.id } + existingSharedUsers.map { $0.id })
            searchResults = results.filter { user in
                user.id != currentUserID && !allExcludedIDs.contains(user.id)
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error searching users: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func loadFollowers() async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let followers = try await friendsService.fetchFollowers(userID: userID)
            // Filter out already selected users and existing shared users
            let allExcludedIDs = Set(selectedUsers.map { $0.id } + existingSharedUsers.map { $0.id })
            let followersNotSelected = followers.filter { user in
                !allExcludedIDs.contains(user.id)
            }
            searchResults = followersNotSelected
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading followers: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func toggleUserSelection(_ user: AppUser) {
        if let index = selectedUsers.firstIndex(where: { $0.id == user.id }) {
            selectedUsers.remove(at: index)
        } else {
            selectedUsers.append(user)
        }
        // Remove from search results if selected
        searchResults.removeAll { $0.id == user.id }
    }
    
    func removeSelectedUser(_ user: AppUser) {
        selectedUsers.removeAll { $0.id == user.id }
    }
    
    func removeExistingSharedUser(_ user: AppUser) {
        existingSharedUsers.removeAll { $0.id == user.id }
    }
    
    func getSelectedUserIDs() -> [String] {
        // Return existing shared users + newly selected users (combine both)
        let existingIDs = existingSharedUsers.map { $0.id }
        let selectedIDs = selectedUsers.map { $0.id }
        return existingIDs + selectedIDs
    }
}


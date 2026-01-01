//
//  FriendsService.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

@MainActor
class FriendsService: ObservableObject {
    private let firestore = FirebaseManager.shared.firestore
    private let followsCollection = "follows"
    private let usersCollection = "users"
    
    // MARK: - Follow User
    
    func followUser(followingID: String) async throws {
        guard let followerID = Auth.auth().currentUser?.uid else {
            throw FriendsError.unauthorized
        }
        
        if followerID == followingID {
            throw FriendsError.cannotFollowSelf
        }
        
        // Check if already following
        let isAlreadyFollowing = try await isFollowing(followerID: followerID, followingID: followingID)
        if isAlreadyFollowing {
            return // Already following
        }
        
        let follow = Follow(followerID: followerID, followingID: followingID)
        try firestore.collection(followsCollection).document(follow.id).setData(from: follow)
        
        // Update follower count
        try await updateFollowerCount(userID: followingID, increment: 1)
        try await updateFollowingCount(userID: followerID, increment: 1)
    }
    
    // MARK: - Unfollow User
    
    func unfollowUser(followingID: String) async throws {
        guard let followerID = Auth.auth().currentUser?.uid else {
            throw FriendsError.unauthorized
        }
        
        // Find the Follow document
        let snapshot = try await firestore.collection(followsCollection)
            .whereField("followerID", isEqualTo: followerID)
            .whereField("followingID", isEqualTo: followingID)
            .limit(to: 1)
            .getDocuments()
        
        if let document = snapshot.documents.first {
            try await document.reference.delete()
            
            // Update follower count
            try await updateFollowerCount(userID: followingID, increment: -1)
            try await updateFollowingCount(userID: followerID, increment: -1)
        }
    }
    
    // MARK: - Fetch Follows
    
    func fetchFollowers(userID: String) async throws -> [AppUser] {
        let snapshot = try await firestore.collection(followsCollection)
            .whereField("followingID", isEqualTo: userID)
            .getDocuments()
        
        let followerIDs = try snapshot.documents.compactMap { document -> String? in
            let follow = try document.data(as: Follow.self)
            return follow.followerID
        }
        
        var users: [AppUser] = []
        for followerID in followerIDs {
            if let user = try await fetchUser(userID: followerID) {
                users.append(user)
            }
        }
        
        return users
    }
    
    func fetchFollowing(userID: String) async throws -> [AppUser] {
        let snapshot = try await firestore.collection(followsCollection)
            .whereField("followerID", isEqualTo: userID)
            .getDocuments()
        
        let followingIDs = try snapshot.documents.compactMap { document -> String? in
            let follow = try document.data(as: Follow.self)
            return follow.followingID
        }
        
        var users: [AppUser] = []
        for followingID in followingIDs {
            if let user = try await fetchUser(userID: followingID) {
                users.append(user)
            }
        }
        
        return users
    }
    
    func isFollowing(followerID: String, followingID: String) async throws -> Bool {
        let snapshot = try await firestore.collection(followsCollection)
            .whereField("followerID", isEqualTo: followerID)
            .whereField("followingID", isEqualTo: followingID)
            .limit(to: 1)
            .getDocuments()
        
        return !snapshot.documents.isEmpty
    }
    
    // MARK: - Search Users
    
    func searchUsers(query: String) async throws -> [AppUser] {
        guard !query.isEmpty else { return [] }
        
        // Firestore prefix search (case-sensitive)
        let snapshot = try await firestore.collection(usersCollection)
            .whereField("displayName", isGreaterThanOrEqualTo: query)
            .whereField("displayName", isLessThanOrEqualTo: query + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments()
        
        let results = try snapshot.documents.compactMap { document -> AppUser? in
            try? document.data(as: AppUser.self)
        }
        
        // Additional case-insensitive filtering
        let lowercaseQuery = query.lowercased()
        return results.filter { user in
            user.displayName.lowercased().hasPrefix(lowercaseQuery)
        }
    }
    
    // MARK: - Helper Methods
    
    private func fetchUser(userID: String) async throws -> AppUser? {
        let document = try await firestore.collection(usersCollection).document(userID).getDocument()
        return try? document.data(as: AppUser.self)
    }
    
    private func updateFollowerCount(userID: String, increment: Int) async throws {
        let userRef = firestore.collection(usersCollection).document(userID)
        try await userRef.updateData([
            "followerCount": FieldValue.increment(Int64(increment))
        ])
    }
    
    private func updateFollowingCount(userID: String, increment: Int) async throws {
        let userRef = firestore.collection(usersCollection).document(userID)
        try await userRef.updateData([
            "followingCount": FieldValue.increment(Int64(increment))
        ])
    }
}

enum FriendsError: LocalizedError {
    case unauthorized
    case cannotFollowSelf
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return LocalizedString("You are not authorized to perform this action", comment: "Unauthorized error")
        case .cannotFollowSelf:
            return LocalizedString("You cannot follow yourself", comment: "Cannot follow self error")
        }
    }
}


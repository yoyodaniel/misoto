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
    private let followersSubcollection = "followers"
    private let followingSubcollection = "following"
    private let xpService = XPService.shared
    private let defaultPageSize = 30
    
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
            print("✅ Already following user \(followingID)")
            return // Already following
        }
        
        print("🔄 Following user \(followingID)...")
        let follow = Follow(followerID: followerID, followingID: followingID)
        let followerUser = try await fetchUser(userID: followerID)
        let followingUser = try await fetchUser(userID: followingID)
        guard let followerUser, let followingUser else {
            throw FriendsError.userNotFound
        }

        let followRef = firestore.collection(followsCollection).document(follow.id)
        let followerFollowingRef = firestore.collection(usersCollection)
            .document(followerID)
            .collection(followingSubcollection)
            .document(followingID)
        let followingFollowersRef = firestore.collection(usersCollection)
            .document(followingID)
            .collection(followersSubcollection)
            .document(followerID)

        let followerSnapshot = FollowIndexUserSnapshot(user: followingUser, followedAt: follow.createdAt)
        let followingSnapshot = FollowIndexUserSnapshot(user: followerUser, followedAt: follow.createdAt)

        let batch = firestore.batch()
        try batch.setData(from: follow, forDocument: followRef)
        try batch.setData(from: followerSnapshot, forDocument: followerFollowingRef)
        try batch.setData(from: followingSnapshot, forDocument: followingFollowersRef)
        try await batch.commit()
        print("✅ Follow document created: \(follow.id)")
        
        // Update follower count
        try await updateFollowerCount(userID: followingID, increment: 1)
        print("✅ Follower count updated for user \(followingID)")
        try await updateFollowingCount(userID: followerID, increment: 1)
        print("✅ Following count updated for user \(followerID)")

        _ = try? await xpService.awardXPForAction(
            receiverUserId: followingID,
            actorUserId: followerID,
            actionType: .followerGained,
            targetId: followingID
        )
        _ = try? await xpService.awardXPForAction(
            receiverUserId: followerID,
            actorUserId: followerID,
            actionType: .userFollowed,
            targetId: followingID
        )
    }
    
    // MARK: - Unfollow User
    
    func unfollowUser(followingID: String) async throws {
        guard let followerID = Auth.auth().currentUser?.uid else {
            throw FriendsError.unauthorized
        }
        
        print("🔄 Unfollowing user \(followingID)...")
        // Find the Follow document
        let snapshot = try await firestore.collection(followsCollection)
            .whereField("followerID", isEqualTo: followerID)
            .whereField("followingID", isEqualTo: followingID)
            .limit(to: 1)
            .getDocuments()
        
        if let document = snapshot.documents.first {
            let followerFollowingRef = firestore.collection(usersCollection)
                .document(followerID)
                .collection(followingSubcollection)
                .document(followingID)
            let followingFollowersRef = firestore.collection(usersCollection)
                .document(followingID)
                .collection(followersSubcollection)
                .document(followerID)

            let batch = firestore.batch()
            batch.deleteDocument(document.reference)
            batch.deleteDocument(followerFollowingRef)
            batch.deleteDocument(followingFollowersRef)
            try await batch.commit()
            print("✅ Follow document deleted: \(document.documentID)")
            
            // Update follower count
            try await updateFollowerCount(userID: followingID, increment: -1)
            print("✅ Follower count updated for user \(followingID)")
            try await updateFollowingCount(userID: followerID, increment: -1)
            print("✅ Following count updated for user \(followerID)")

            _ = try? await xpService.revokeXPForAction(
                receiverUserId: followingID,
                actorUserId: followerID,
                actionType: .followerGained,
                targetId: followingID
            )
            _ = try? await xpService.revokeXPForAction(
                receiverUserId: followerID,
                actorUserId: followerID,
                actionType: .userFollowed,
                targetId: followingID
            )
        } else {
            print("⚠️ No follow document found to delete")
        }
    }
    
    // MARK: - Fetch Follows
    
    func fetchFollowers(userID: String) async throws -> [AppUser] {
        var cursor: FollowPageCursor?
        var results: [AppUser] = []

        repeat {
            let page = try await fetchFollowersPage(userID: userID, query: nil, cursor: cursor, limit: defaultPageSize)
            results.append(contentsOf: page.users)
            cursor = page.nextCursor
            if !page.hasMore {
                break
            }
        } while true

        return results
    }
    
    func fetchFollowing(userID: String) async throws -> [AppUser] {
        var cursor: FollowPageCursor?
        var results: [AppUser] = []

        repeat {
            let page = try await fetchFollowingPage(userID: userID, query: nil, cursor: cursor, limit: defaultPageSize)
            results.append(contentsOf: page.users)
            cursor = page.nextCursor
            if !page.hasMore {
                break
            }
        } while true

        return results
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
        
        let results = snapshot.documents.compactMap { document -> AppUser? in
            try? document.data(as: AppUser.self)
        }
        
        // Additional case-insensitive filtering and filter out banned users
        let lowercaseQuery = query.lowercased()
        return results.filter { user in
            user.displayName.lowercased().hasPrefix(lowercaseQuery) && !user.isBanned
        }
    }

    // MARK: - Paged Follows

    func fetchFollowersPage(
        userID: String,
        query: String?,
        cursor: FollowPageCursor?,
        limit: Int = 30
    ) async throws -> FollowPageResult {
        try await fetchFollowPage(
            userID: userID,
            subcollection: followersSubcollection,
            query: query,
            cursor: cursor,
            limit: limit
        )
    }

    func fetchFollowingPage(
        userID: String,
        query: String?,
        cursor: FollowPageCursor?,
        limit: Int = 30
    ) async throws -> FollowPageResult {
        try await fetchFollowPage(
            userID: userID,
            subcollection: followingSubcollection,
            query: query,
            cursor: cursor,
            limit: limit
        )
    }

    func fetchFollowingMembership(userID: String, targetUserIDs: [String]) async throws -> Set<String> {
        guard !targetUserIDs.isEmpty else { return [] }

        var followedIDs = Set<String>()
        let distinctIDs = Array(Set(targetUserIDs))
        for userIDToCheck in distinctIDs {
            let doc = try await firestore.collection(usersCollection)
                .document(userID)
                .collection(followingSubcollection)
                .document(userIDToCheck)
                .getDocument()
            if doc.exists {
                followedIDs.insert(userIDToCheck)
            }
        }
        return followedIDs
    }
    
    // MARK: - Helper Methods
    
    private func fetchUser(userID: String) async throws -> AppUser? {
        let document = try await firestore.collection(usersCollection).document(userID).getDocument()
        return try? document.data(as: AppUser.self)
    }

    private func fetchFollowPage(
        userID: String,
        subcollection: String,
        query: String?,
        cursor: FollowPageCursor?,
        limit: Int
    ) async throws -> FollowPageResult {
        let safeLimit = max(1, min(limit, 100))
        let normalizedQuery = normalizedSearchQuery(query)
        let isSearching = normalizedQuery != nil

        var request = firestore.collection(usersCollection)
            .document(userID)
            .collection(subcollection)
            .limit(to: safeLimit + 1)

        if let normalizedQuery {
            if normalizedQuery.hasPrefix("@") {
                let usernameQuery = String(normalizedQuery.dropFirst())
                request = request
                    .whereField("usernameLower", isGreaterThanOrEqualTo: usernameQuery)
                    .whereField("usernameLower", isLessThanOrEqualTo: usernameQuery + "\u{f8ff}")
                    .order(by: "usernameLower")
                    .order(by: "userID")
            } else {
                request = request
                    .whereField("displayNameLower", isGreaterThanOrEqualTo: normalizedQuery)
                    .whereField("displayNameLower", isLessThanOrEqualTo: normalizedQuery + "\u{f8ff}")
                    .order(by: "displayNameLower")
                    .order(by: "userID")
            }
        } else {
            request = request
                .order(by: "followedAt", descending: true)
                .order(by: "userID")
        }

        if !isSearching, let cursor {
            request = request.start(after: [cursor.followedAt, cursor.userID])
        }

        let snapshot = try await request.getDocuments()
        let docs = snapshot.documents
        let hasMore = docs.count > safeLimit
        let pageDocs = Array(docs.prefix(safeLimit))

        let snapshots = pageDocs.compactMap { try? $0.data(as: FollowIndexUserSnapshot.self) }
        let users = snapshots.map { $0.toAppUser() }

        let nextCursor: FollowPageCursor?
        if !isSearching, hasMore, let last = snapshots.last {
            nextCursor = FollowPageCursor(followedAt: last.followedAt, userID: last.userID)
        } else {
            nextCursor = nil
        }

        return FollowPageResult(
            users: users,
            nextCursor: nextCursor,
            hasMore: isSearching ? false : hasMore
        )
    }

    private func normalizedSearchQuery(_ query: String?) -> String? {
        guard let query else { return nil }
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.isEmpty ? nil : normalized
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
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return LocalizedString("You are not authorized to perform this action", comment: "Unauthorized error")
        case .cannotFollowSelf:
            return LocalizedString("You cannot follow yourself", comment: "Cannot follow self error")
        case .userNotFound:
            return LocalizedString("User could not be found", comment: "User not found error")
        }
    }
}


//
//  FollowIndexMigrationService.swift
//  Misoto
//
//  Created by Codex on 08.05.2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
final class FollowIndexMigrationService {
    private let firestore = FirebaseManager.shared.firestore
    private let usersCollection = "users"
    private let followsCollection = "follows"
    private let followersSubcollection = "followers"
    private let followingSubcollection = "following"

    private let lastCreatedAtCheckpointKey = "followIndexMigration.lastCreatedAt"
    private let lastFollowIDCheckpointKey = "followIndexMigration.lastFollowID"

    func runBackfill(batchSize: Int = 200) async throws -> Int {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            throw MigrationError.unauthorized
        }

        let safeBatchSize = max(1, min(batchSize, 500))
        let followerDocs = try await fetchFollowDocuments(
            roleField: "followerID",
            userID: currentUserID,
            limit: safeBatchSize
        )
        let followingDocs = try await fetchFollowDocuments(
            roleField: "followingID",
            userID: currentUserID,
            limit: safeBatchSize
        )

        var allDocumentsByID: [String: QueryDocumentSnapshot] = [:]
        for doc in followerDocs {
            allDocumentsByID[doc.documentID] = doc
        }
        for doc in followingDocs {
            allDocumentsByID[doc.documentID] = doc
        }

        let sortedDocuments = allDocumentsByID.values.sorted { lhs, rhs in
            let leftFollow = try? lhs.data(as: Follow.self)
            let rightFollow = try? rhs.data(as: Follow.self)
            let leftDate = leftFollow?.createdAt ?? .distantPast
            let rightDate = rightFollow?.createdAt ?? .distantPast
            if leftDate == rightDate {
                return lhs.documentID < rhs.documentID
            }
            return leftDate < rightDate
        }

        guard !sortedDocuments.isEmpty else {
            return 0
        }

        var writtenCount = 0
        for chunk in sortedDocuments.chunked(into: 100) {
            let batch = firestore.batch()
            for doc in chunk {
                guard let follow = try? doc.data(as: Follow.self) else { continue }
                guard let followerUser = try await fetchUser(userID: follow.followerID),
                      let followingUser = try await fetchUser(userID: follow.followingID) else {
                    continue
                }

                // Client-side migration can only safely write to the current
                // user's own indexed subcollections under security rules.
                if follow.followerID == currentUserID {
                    let followingRef = firestore.collection(usersCollection)
                        .document(currentUserID)
                        .collection(followingSubcollection)
                        .document(follow.followingID)
                    let snapshot = FollowIndexUserSnapshot(user: followingUser, followedAt: follow.createdAt)
                    try batch.setData(from: snapshot, forDocument: followingRef, merge: true)
                    writtenCount += 1
                }

                if follow.followingID == currentUserID {
                    let followersRef = firestore.collection(usersCollection)
                        .document(currentUserID)
                        .collection(followersSubcollection)
                        .document(follow.followerID)
                    let snapshot = FollowIndexUserSnapshot(user: followerUser, followedAt: follow.createdAt)
                    try batch.setData(from: snapshot, forDocument: followersRef, merge: true)
                    writtenCount += 1
                }
            }
            try await batch.commit()
        }

        if let last = sortedDocuments.last,
           let follow = try? last.data(as: Follow.self) {
            saveCheckpoint(createdAt: follow.createdAt, followID: last.documentID)
        }

        return writtenCount
    }

    func resetCheckpoint() {
        UserDefaults.standard.removeObject(forKey: lastCreatedAtCheckpointKey)
        UserDefaults.standard.removeObject(forKey: lastFollowIDCheckpointKey)
    }

    // MARK: - Helpers

    private func fetchUser(userID: String) async throws -> AppUser? {
        let doc = try await firestore.collection(usersCollection).document(userID).getDocument()
        return try? doc.data(as: AppUser.self)
    }

    private func fetchFollowDocuments(
        roleField: String,
        userID: String,
        limit: Int
    ) async throws -> [QueryDocumentSnapshot] {
        var query = firestore.collection(followsCollection)
            .whereField(roleField, isEqualTo: userID)
            .order(by: "createdAt")
            .order(by: FieldPath.documentID())
            .limit(to: limit)

        if let checkpointDate = checkpointDate(),
           let checkpointFollowID = checkpointFollowID() {
            query = query.start(after: [checkpointDate, checkpointFollowID])
        }

        let snapshot = try await query.getDocuments()
        return snapshot.documents
    }

    private func saveCheckpoint(createdAt: Date, followID: String) {
        UserDefaults.standard.set(createdAt.timeIntervalSince1970, forKey: lastCreatedAtCheckpointKey)
        UserDefaults.standard.set(followID, forKey: lastFollowIDCheckpointKey)
    }

    private func checkpointDate() -> Date? {
        let interval = UserDefaults.standard.double(forKey: lastCreatedAtCheckpointKey)
        guard interval > 0 else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    private func checkpointFollowID() -> String? {
        UserDefaults.standard.string(forKey: lastFollowIDCheckpointKey)
    }
}

enum MigrationError: LocalizedError {
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return LocalizedString("You are not authorized to run migration", comment: "Migration unauthorized error")
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

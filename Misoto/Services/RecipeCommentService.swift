//
//  RecipeCommentService.swift
//  Misoto
//
//  Created by Daniel Chan on 14.02.2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class RecipeCommentService {
    private let firestore = FirebaseManager.shared.firestore
    private let commentsCollection = "recipeComments"
    
    // MARK: - Fetch Comments
    
    /// Fetch all comments for a recipe with pagination
    func fetchComments(
        for recipeID: String,
        limit: Int = 10,
        startAfter: DocumentSnapshot? = nil
    ) async throws -> (comments: [RecipeComment], lastDocument: DocumentSnapshot?, hasMore: Bool) {
        
        do {
            var query = firestore.collection(commentsCollection)
                .whereField("recipeID", isEqualTo: recipeID)
                .order(by: "createdAt", descending: true)
                .limit(to: limit + 1)
            
            if let startAfter = startAfter {
                query = query.start(afterDocument: startAfter)
            }
            
            let snapshot = try await query.getDocuments()
            
            var comments: [RecipeComment] = []
            var lastDoc: DocumentSnapshot?
            
            let hasMore = snapshot.documents.count > limit
            let documentsToProcess = hasMore ? Array(snapshot.documents.prefix(limit)) : snapshot.documents
            
            for document in documentsToProcess {
                do {
                    var comment = try document.data(as: RecipeComment.self)
                    comment.id = document.documentID
                    comments.append(comment)
                    lastDoc = document
                } catch {
                    print("⚠️ Failed to decode comment \(document.documentID): \(error.localizedDescription)")
                }
            }
            
            return (comments, lastDoc, hasMore)
        } catch {
            print("⚠️ Query with ordering failed: \(error.localizedDescription)")
            print("🔄 Trying fallback query without ordering...")
            
            // Fallback: query without ordering (doesn't require composite index)
            var query = firestore.collection(commentsCollection)
                .whereField("recipeID", isEqualTo: recipeID)
                .limit(to: limit + 1)
            
            if let startAfter = startAfter {
                query = query.start(afterDocument: startAfter)
            }
            
            let snapshot = try await query.getDocuments()
            
            var comments: [RecipeComment] = []
            var lastDoc: DocumentSnapshot?
            
            let hasMore = snapshot.documents.count > limit
            let documentsToProcess = hasMore ? Array(snapshot.documents.prefix(limit)) : snapshot.documents
            
            for document in documentsToProcess {
                do {
                    var comment = try document.data(as: RecipeComment.self)
                    comment.id = document.documentID
                    comments.append(comment)
                    lastDoc = document
                } catch {
                    print("⚠️ Failed to decode comment \(document.documentID): \(error.localizedDescription)")
                }
            }
            
            // Sort manually by createdAt
            comments.sort { $0.createdAt > $1.createdAt }
            
            return (comments, lastDoc, hasMore)
        }
    }
    
    /// Get total comment count for a recipe
    func getCommentCount(for recipeID: String) async throws -> Int {
        let snapshot = try await firestore.collection(commentsCollection)
            .whereField("recipeID", isEqualTo: recipeID)
            .getDocuments()
        
        return snapshot.documents.count
    }
    
    /// Get average rating for a recipe
    func getAverageRating(for recipeID: String) async throws -> (average: Double, count: Int) {
        let snapshot = try await firestore.collection(commentsCollection)
            .whereField("recipeID", isEqualTo: recipeID)
            .getDocuments()
        
        let ratings = snapshot.documents.compactMap { doc -> Int? in
            try? doc.data(as: RecipeComment.self).rating
        }.filter { $0 > 0 }
        
        guard !ratings.isEmpty else { return (0, 0) }
        
        let average = Double(ratings.reduce(0, +)) / Double(ratings.count)
        return (average, ratings.count)
    }
    
    /// Check if the current user has already commented on this recipe
    func hasUserCommented(recipeID: String) async throws -> RecipeComment? {
        guard let userID = Auth.auth().currentUser?.uid else { return nil }
        
        let snapshot = try await firestore.collection(commentsCollection)
            .whereField("recipeID", isEqualTo: recipeID)
            .whereField("userID", isEqualTo: userID)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else { return nil }
        var comment = try document.data(as: RecipeComment.self)
        comment.id = document.documentID
        return comment
    }
    
    // MARK: - Create Comment
    
    func createComment(_ comment: RecipeComment) async throws -> RecipeComment {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw RecipeCommentError.unauthorized
        }
        
        var newComment = comment
        newComment.userID = userID
        newComment.id = UUID().uuidString
        newComment.createdAt = Date()
        newComment.updatedAt = Date()
        
        // Enforce character limit
        if newComment.content.count > 250 {
            newComment.content = String(newComment.content.prefix(250))
        }
        
        let commentRef = firestore.collection(commentsCollection).document(newComment.id)
        try commentRef.setData(from: newComment)
        
        print("✅ Comment saved successfully: \(newComment.id)")
        return newComment
    }
    
    // MARK: - Update Comment
    
    func updateComment(_ comment: RecipeComment) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw RecipeCommentError.unauthorized
        }
        
        guard comment.userID == userID else {
            throw RecipeCommentError.unauthorized
        }
        
        var updatedComment = comment
        updatedComment.updatedAt = Date()
        
        // Enforce character limit
        if updatedComment.content.count > 250 {
            updatedComment.content = String(updatedComment.content.prefix(250))
        }
        
        let commentRef = firestore.collection(commentsCollection).document(comment.id)
        try commentRef.setData(from: updatedComment, merge: true)
    }
    
    // MARK: - Delete Comment
    
    func deleteComment(commentID: String) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw RecipeCommentError.unauthorized
        }
        
        // Verify ownership
        let commentRef = firestore.collection(commentsCollection).document(commentID)
        let document = try await commentRef.getDocument()
        
        guard let comment = try? document.data(as: RecipeComment.self),
              comment.userID == userID else {
            throw RecipeCommentError.unauthorized
        }
        
        try await commentRef.delete()
        print("✅ Comment deleted: \(commentID)")
    }
}

enum RecipeCommentError: LocalizedError {
    case unauthorized
    case notFound
    case alreadyCommented
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return LocalizedString("You are not authorized to perform this action", comment: "Unauthorized error")
        case .notFound:
            return LocalizedString("Comment not found", comment: "Comment not found error")
        case .alreadyCommented:
            return LocalizedString("You have already left a review for this recipe", comment: "Already commented error")
        }
    }
}

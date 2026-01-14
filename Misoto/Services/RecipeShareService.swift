//
//  RecipeShareService.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service for managing recipe shares using a separate collection for scalability
class RecipeShareService {
    static let shared = RecipeShareService()
    
    private let firestore = FirebaseManager.shared.firestore
    private let sharesCollection = "recipeShares"
    
    private init() {}
    
    // MARK: - Share Management
    
    /// Share a recipe with multiple users
    /// - Parameters:
    ///   - recipeID: The recipe to share
    ///   - userIDs: Array of user IDs to share with
    /// - Returns: Number of shares created
    func shareRecipe(recipeID: String, with userIDs: [String]) async throws -> Int {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            throw RecipeShareError.unauthorized
        }
        
        guard !userIDs.isEmpty else {
            return 0
        }
        
        // Remove duplicates
        let uniqueUserIDs = Array(Set(userIDs))
        
        // Batch write all shares
        let batch = firestore.batch()
        var shareCount = 0
        
        for userID in uniqueUserIDs {
            // Skip if trying to share with self
            if userID == currentUserID {
                continue
            }
            
            // Check if share already exists
            let existingShareQuery = firestore.collection(sharesCollection)
                .whereField("recipeID", isEqualTo: recipeID)
                .whereField("userID", isEqualTo: userID)
                .limit(to: 1)
            
            let existingShares = try await existingShareQuery.getDocuments()
            
            // Only create if it doesn't exist
            if existingShares.documents.isEmpty {
                let share = RecipeShare(
                    recipeID: recipeID,
                    userID: userID,
                    sharedBy: currentUserID
                )
                
                let shareRef = firestore.collection(sharesCollection).document(share.id)
                try batch.setData(from: share, forDocument: shareRef)
                shareCount += 1
            }
        }
        
        if shareCount > 0 {
            try await batch.commit()
            print("✅ Created \(shareCount) recipe share(s) for recipe \(recipeID)")
        }
        
        return shareCount
    }
    
    /// Remove sharing for a recipe with specific users
    /// - Parameters:
    ///   - recipeID: The recipe to unshare
    ///   - userIDs: Array of user IDs to remove access from
    func unshareRecipe(recipeID: String, from userIDs: [String]) async throws {
        guard Auth.auth().currentUser != nil else {
            throw RecipeShareError.unauthorized
        }
        
        guard !userIDs.isEmpty else {
            return
        }
        
        // Batch delete all shares
        let batch = firestore.batch()
        var deleteCount = 0
        
        for userID in userIDs {
            let shareQuery = firestore.collection(sharesCollection)
                .whereField("recipeID", isEqualTo: recipeID)
                .whereField("userID", isEqualTo: userID)
                .limit(to: 1)
            
            let shares = try await shareQuery.getDocuments()
            for document in shares.documents {
                batch.deleteDocument(document.reference)
                deleteCount += 1
            }
        }
        
        if deleteCount > 0 {
            try await batch.commit()
            print("✅ Removed \(deleteCount) recipe share(s) for recipe \(recipeID)")
        }
    }
    
    /// Remove all shares for a recipe (useful when making recipe public or deleting)
    func removeAllShares(for recipeID: String) async throws {
        guard Auth.auth().currentUser != nil else {
            throw RecipeShareError.unauthorized
        }
        
        let sharesQuery = firestore.collection(sharesCollection)
            .whereField("recipeID", isEqualTo: recipeID)
        
        let shares = try await sharesQuery.getDocuments()
        
        if !shares.documents.isEmpty {
            let batch = firestore.batch()
            for document in shares.documents {
                batch.deleteDocument(document.reference)
            }
            try await batch.commit()
            print("✅ Removed all \(shares.documents.count) recipe share(s) for recipe \(recipeID)")
        }
    }
    
    // MARK: - Query Shares
    
    /// Check if a recipe is shared with a specific user
    func isRecipeShared(recipeID: String, with userID: String) async throws -> Bool {
        print("🔍 isRecipeShared - recipeID: \(recipeID), userID: \(userID)")
        let shareQuery = firestore.collection(sharesCollection)
            .whereField("recipeID", isEqualTo: recipeID)
            .whereField("userID", isEqualTo: userID)
            .limit(to: 1)
        
        do {
            let shares = try await shareQuery.getDocuments()
            let found = !shares.documents.isEmpty
            print("🔍 Share query result: \(found ? "FOUND" : "NOT FOUND") - \(shares.documents.count) document(s)")
            if found {
                for doc in shares.documents {
                    print("🔍 Share document: \(doc.documentID), data: \(doc.data())")
                }
            } else {
                print("⚠️ No share document found for recipeID: \(recipeID), userID: \(userID)")
            }
            return found
        } catch {
            print("❌ Error querying shares: \(error.localizedDescription)")
            print("❌ Error details: \(error)")
            throw error
        }
    }
    
    /// Get all user IDs that a recipe is shared with
    /// Note: Only recipe owners can call this (filters by sharedBy to match security rules)
    func getSharedUserIDs(for recipeID: String) async throws -> [String] {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            throw RecipeShareError.unauthorized
        }
        
        // Filter by both recipeID and sharedBy to match Firestore security rules
        let shareQuery = firestore.collection(sharesCollection)
            .whereField("recipeID", isEqualTo: recipeID)
            .whereField("sharedBy", isEqualTo: currentUserID)
        
        let shares = try await shareQuery.getDocuments()
        return shares.documents.compactMap { doc in
            try? doc.data(as: RecipeShare.self).userID
        }
    }
    
    /// Get all recipes shared with the current user
    func getRecipesSharedWithMe() async throws -> [RecipeShare] {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            throw RecipeShareError.unauthorized
        }
        
        let shareQuery = firestore.collection(sharesCollection)
            .whereField("userID", isEqualTo: currentUserID)
            .order(by: "sharedAt", descending: true)
        
        let shares = try await shareQuery.getDocuments()
        return shares.documents.compactMap { doc in
            try? doc.data(as: RecipeShare.self)
        }
    }
    
    /// Get all recipes shared by the current user
    func getRecipesSharedByMe() async throws -> [RecipeShare] {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            throw RecipeShareError.unauthorized
        }
        
        let shareQuery = firestore.collection(sharesCollection)
            .whereField("sharedBy", isEqualTo: currentUserID)
            .order(by: "sharedAt", descending: true)
        
        let shares = try await shareQuery.getDocuments()
        return shares.documents.compactMap { doc in
            try? doc.data(as: RecipeShare.self)
        }
    }
    
    /// Get all shares for a specific recipe
    /// Note: Only recipe owners can call this (filters by sharedBy to match security rules)
    func getShares(for recipeID: String) async throws -> [RecipeShare] {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            throw RecipeShareError.unauthorized
        }
        
        // Filter by both recipeID and sharedBy to match Firestore security rules
        // This ensures only the recipe owner can query their recipe's shares
        let shareQuery = firestore.collection(sharesCollection)
            .whereField("recipeID", isEqualTo: recipeID)
            .whereField("sharedBy", isEqualTo: currentUserID)
            .order(by: "sharedAt", descending: true)
        
        let shares = try await shareQuery.getDocuments()
        return shares.documents.compactMap { doc in
            try? doc.data(as: RecipeShare.self)
        }
    }
}

// MARK: - Errors

enum RecipeShareError: LocalizedError {
    case unauthorized
    case invalidRecipe
    case shareNotFound
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "You must be signed in to share recipes"
        case .invalidRecipe:
            return "Invalid recipe"
        case .shareNotFound:
            return "Share not found"
        }
    }
}

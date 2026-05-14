//
//  RecipeChangeProposalService.swift
//  Misoto
//
//  Persists viewer suggestions for recipe changes. Requires matching Firestore security rules.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
final class RecipeChangeProposalService {
    private let firestore = FirebaseManager.shared.firestore
    private let collectionName = "recipeChangeProposals"
    private let maxProposalLength = 1_000
    private let maxContextLength = 500
    
    // MARK: - Create
    
    func createProposal(_ proposal: RecipeChangeProposal) async throws -> RecipeChangeProposal {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw RecipeChangeProposalError.unauthorized
        }
        
        guard proposal.userID == userID else {
            throw RecipeChangeProposalError.unauthorized
        }
        
        guard proposal.userID != proposal.recipeAuthorID else {
            throw RecipeChangeProposalError.cannotSuggestOwnRecipe
        }
        
        var newProposal = proposal
        newProposal.id = UUID().uuidString
        newProposal.userID = userID
        newProposal.createdAt = Date()
        newProposal.updatedAt = Date()
        
        if newProposal.proposal.count > maxProposalLength {
            newProposal.proposal = String(newProposal.proposal.prefix(maxProposalLength))
        }
        if newProposal.contextSnapshot.count > maxContextLength {
            newProposal.contextSnapshot = String(newProposal.contextSnapshot.prefix(maxContextLength))
        }
        
        let ref = firestore.collection(collectionName).document(newProposal.id)
        try ref.setData(from: newProposal)
        return newProposal
    }
    
    // MARK: - Fetch
    
    /// Fetches change proposals that were sent to the current user's recipes.
    func fetchIncomingProposals(limit: Int = 50) async throws -> [RecipeChangeProposal] {
        guard let authorID = Auth.auth().currentUser?.uid else {
            return []
        }
        
        do {
            let snapshot = try await firestore.collection(collectionName)
                .whereField("recipeAuthorID", isEqualTo: authorID)
                .order(by: "createdAt", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            return try snapshot.documents.compactMap { document in
                var proposal = try document.data(as: RecipeChangeProposal.self)
                proposal.id = document.documentID
                return proposal
            }
        } catch {
            // Fallback query for projects missing composite indexes.
            let snapshot = try await firestore.collection(collectionName)
                .whereField("recipeAuthorID", isEqualTo: authorID)
                .limit(to: limit)
                .getDocuments()
            
            let proposals = try snapshot.documents.compactMap { document in
                var proposal = try document.data(as: RecipeChangeProposal.self)
                proposal.id = document.documentID
                return proposal
            }
            return proposals.sorted { $0.createdAt > $1.createdAt }
        }
    }
}

// MARK: - Errors

enum RecipeChangeProposalError: LocalizedError {
    case unauthorized
    case cannotSuggestOwnRecipe
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return LocalizedString("You are not authorized to perform this action", comment: "Unauthorized error")
        case .cannotSuggestOwnRecipe:
            return LocalizedString("You cannot suggest changes to your own recipe", comment: "Own recipe suggestion error")
        }
    }
}

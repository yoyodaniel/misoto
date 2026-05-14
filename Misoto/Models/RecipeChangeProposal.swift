//
//  RecipeChangeProposal.swift
//  Misoto
//
//  Created for recipe change suggestions from viewers.
//

import Foundation
import FirebaseFirestore

// MARK: - RecipeChangeProposal

struct RecipeChangeProposal: Identifiable, Codable {
    enum TargetKind: String, Codable {
        case ingredient
        case instruction
        case tip
        case description
    }
    
    var id: String
    var recipeID: String
    var recipeAuthorID: String
    var userID: String
    var displayName: String
    var username: String?
    var profileImageURL: String?
    var targetKind: TargetKind
    /// Index in `recipe.ingredients`, `recipe.instructions`, or `recipe.tips` when applicable.
    var targetIndex: Int?
    /// Short snapshot of the line the viewer is referring to (e.g. scaled ingredient text).
    var contextSnapshot: String
    var proposal: String
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case recipeID
        case recipeAuthorID
        case userID
        case displayName
        case username
        case profileImageURL
        case targetKind
        case targetIndex
        case contextSnapshot
        case proposal
        case createdAt
        case updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        recipeID = try container.decode(String.self, forKey: .recipeID)
        recipeAuthorID = try container.decode(String.self, forKey: .recipeAuthorID)
        userID = try container.decode(String.self, forKey: .userID)
        displayName = try container.decode(String.self, forKey: .displayName)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
        targetKind = try container.decode(TargetKind.self, forKey: .targetKind)
        targetIndex = try container.decodeIfPresent(Int.self, forKey: .targetIndex)
        contextSnapshot = try container.decode(String.self, forKey: .contextSnapshot)
        proposal = try container.decode(String.self, forKey: .proposal)
        
        if let timestamp = try? container.decodeIfPresent(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else if let date = try? container.decodeIfPresent(Date.self, forKey: .createdAt) {
            createdAt = date
        } else {
            createdAt = Date()
        }
        
        if let timestamp = try? container.decodeIfPresent(Timestamp.self, forKey: .updatedAt) {
            updatedAt = timestamp.dateValue()
        } else if let date = try? container.decodeIfPresent(Date.self, forKey: .updatedAt) {
            updatedAt = date
        } else {
            updatedAt = createdAt
        }
    }
    
    init(
        id: String = UUID().uuidString,
        recipeID: String,
        recipeAuthorID: String,
        userID: String,
        displayName: String,
        username: String? = nil,
        profileImageURL: String? = nil,
        targetKind: TargetKind,
        targetIndex: Int? = nil,
        contextSnapshot: String,
        proposal: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.recipeID = recipeID
        self.recipeAuthorID = recipeAuthorID
        self.userID = userID
        self.displayName = displayName
        self.username = username
        self.profileImageURL = profileImageURL
        self.targetKind = targetKind
        self.targetIndex = targetIndex
        self.contextSnapshot = contextSnapshot
        self.proposal = proposal
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

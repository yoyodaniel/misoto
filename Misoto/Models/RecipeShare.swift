//
//  RecipeShare.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import FirebaseFirestore

/// Represents a share relationship between a recipe and a user
/// This is stored in a separate collection for scalability (can handle thousands of shares per recipe)
struct RecipeShare: Identifiable, Codable {
    var id: String
    var recipeID: String
    var userID: String // The user who has access to the recipe
    var sharedBy: String // The user who shared the recipe (recipe owner)
    var sharedAt: Date
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case recipeID
        case userID
        case sharedBy
        case sharedAt
        case createdAt
    }
    
    init(id: String = UUID().uuidString,
         recipeID: String,
         userID: String,
         sharedBy: String,
         sharedAt: Date = Date(),
         createdAt: Date = Date()) {
        self.id = id
        self.recipeID = recipeID
        self.userID = userID
        self.sharedBy = sharedBy
        self.sharedAt = sharedAt
        self.createdAt = createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        recipeID = try container.decode(String.self, forKey: .recipeID)
        userID = try container.decode(String.self, forKey: .userID)
        sharedBy = try container.decode(String.self, forKey: .sharedBy)
        
        // Handle Firestore Timestamp
        if let timestamp = try? container.decode(Timestamp.self, forKey: .sharedAt) {
            sharedAt = timestamp.dateValue()
        } else if let date = try? container.decode(Date.self, forKey: .sharedAt) {
            sharedAt = date
        } else {
            sharedAt = Date()
        }
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else if let date = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = date
        } else {
            createdAt = Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(recipeID, forKey: .recipeID)
        try container.encode(userID, forKey: .userID)
        try container.encode(sharedBy, forKey: .sharedBy)
        try container.encode(Timestamp(date: sharedAt), forKey: .sharedAt)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
    }
}

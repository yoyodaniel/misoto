//
//  RecipeNote.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import FirebaseFirestore

struct RecipeNote: Identifiable, Codable {
    var id: String
    var recipeID: String
    var userID: String
    var userName: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case recipeID
        case userID
        case userName
        case content
        case createdAt
        case updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        recipeID = try container.decode(String.self, forKey: .recipeID)
        userID = try container.decode(String.self, forKey: .userID)
        userName = try container.decode(String.self, forKey: .userName)
        content = try container.decode(String.self, forKey: .content)
        
        // Handle dates with Firestore Timestamp support
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
        userID: String,
        userName: String,
        content: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.recipeID = recipeID
        self.userID = userID
        self.userName = userName
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}


//
//  RecipeComment.swift
//  Misoto
//
//  Created by Daniel Chan on 14.02.2026.
//

import Foundation
import FirebaseFirestore

struct RecipeComment: Identifiable, Codable {
    var id: String
    var recipeID: String
    var userID: String
    var displayName: String
    var username: String?
    var profileImageURL: String?
    var content: String
    var rating: Int // 1-5 stars
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case recipeID
        case userID
        case displayName
        case username
        case profileImageURL
        case content
        case rating
        case createdAt
        case updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        recipeID = try container.decode(String.self, forKey: .recipeID)
        userID = try container.decode(String.self, forKey: .userID)
        displayName = try container.decode(String.self, forKey: .displayName)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
        content = try container.decode(String.self, forKey: .content)
        rating = try container.decodeIfPresent(Int.self, forKey: .rating) ?? 0
        
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
        displayName: String,
        username: String? = nil,
        profileImageURL: String? = nil,
        content: String,
        rating: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.recipeID = recipeID
        self.userID = userID
        self.displayName = displayName
        self.username = username
        self.profileImageURL = profileImageURL
        self.content = content
        self.rating = min(5, max(0, rating))
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Time Ago Formatting
    
    var timeAgo: String {
        let now = Date()
        let interval = now.timeIntervalSince(createdAt)
        
        let seconds = Int(interval)
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24
        let weeks = days / 7
        let months = days / 30
        let years = days / 365
        
        if seconds < 60 {
            return LocalizedString("Just now", comment: "Time ago just now")
        } else if minutes < 60 {
            return String(format: LocalizedString("%d min ago", comment: "Time ago minutes"), minutes)
        } else if hours < 24 {
            return String(format: LocalizedString("%d h ago", comment: "Time ago hours"), hours)
        } else if days < 7 {
            return String(format: LocalizedString("%d d ago", comment: "Time ago days"), days)
        } else if weeks < 5 {
            return String(format: LocalizedString("%d w ago", comment: "Time ago weeks"), weeks)
        } else if months < 12 {
            return String(format: LocalizedString("%d mo ago", comment: "Time ago months"), months)
        } else {
            return String(format: LocalizedString("%d y ago", comment: "Time ago years"), years)
        }
    }
}

//
//  Recipe.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import FirebaseFirestore

struct Recipe: Identifiable, Codable {
    var id: String
    var title: String
    var description: String
    var ingredients: [String]
    var instructions: [Instruction]
    var prepTime: Int // in minutes
    var cookTime: Int // in minutes
    var servings: Int
    var difficulty: Difficulty
    var cuisine: String?
    var imageURL: String?
    var authorID: String
    var authorName: String
    var createdAt: Date
    var updatedAt: Date
    var favoriteCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case ingredients
        case instructions
        case prepTime
        case cookTime
        case servings
        case difficulty
        case cuisine
        case imageURL
        case authorID
        case authorName
        case createdAt
        case updatedAt
        case favoriteCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        authorID = try container.decode(String.self, forKey: .authorID)
        authorName = try container.decodeIfPresent(String.self, forKey: .authorName) ?? ""
        
        // Arrays with defaults
        ingredients = try container.decodeIfPresent([String].self, forKey: .ingredients) ?? []
        instructions = try container.decodeIfPresent([Instruction].self, forKey: .instructions) ?? []
        
        // Numbers with defaults
        prepTime = try container.decodeIfPresent(Int.self, forKey: .prepTime) ?? 0
        cookTime = try container.decodeIfPresent(Int.self, forKey: .cookTime) ?? 0
        servings = try container.decodeIfPresent(Int.self, forKey: .servings) ?? 1
        favoriteCount = try container.decodeIfPresent(Int.self, forKey: .favoriteCount) ?? 0
        
        // Optional fields
        cuisine = try container.decodeIfPresent(String.self, forKey: .cuisine)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        
        // Difficulty with fallback
        if let difficultyString = try? container.decodeIfPresent(String.self, forKey: .difficulty),
           let decodedDifficulty = Difficulty(rawValue: difficultyString) {
            difficulty = decodedDifficulty
        } else {
            difficulty = .c // Default to C if decoding fails
        }
        
        // Dates with defaults
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
    
    enum Difficulty: String, Codable, CaseIterable {
        case c = "C"
        case b = "B"
        case a = "A"
        case s = "S"
        case ss = "SS"
        
        var displayName: String {
            return self.rawValue
        }
        
        var level: Int {
            switch self {
            case .c: return 1
            case .b: return 2
            case .a: return 3
            case .s: return 4
            case .ss: return 5
            }
        }
        
        static func fromLevel(_ level: Int) -> Difficulty {
            switch level {
            case 1: return .c
            case 2: return .b
            case 3: return .a
            case 4: return .s
            case 5: return .ss
            default: return .c
            }
        }
    }
    
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        ingredients: [String],
        instructions: [Instruction],
        prepTime: Int,
        cookTime: Int,
        servings: Int,
        difficulty: Difficulty,
        cuisine: String? = nil,
        imageURL: String? = nil,
        authorID: String,
        authorName: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        favoriteCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.ingredients = ingredients
        self.instructions = instructions
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.servings = servings
        self.difficulty = difficulty
        self.cuisine = cuisine
        self.imageURL = imageURL
        self.authorID = authorID
        self.authorName = authorName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.favoriteCount = favoriteCount
    }
}


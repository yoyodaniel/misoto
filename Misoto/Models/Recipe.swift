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
    var title: String // Kept for backward compatibility, uses titleLocal or titleEnglish based on user's language
    var titleEnglish: String? // English title
    var titleLocal: String? // Local language title (user's system language, if not English)
    var titleOriginal: String? // Original recipe name in original language (if not English or system language)
    var description: String
    var ingredients: [Ingredient]
    var instructions: [Instruction]
    var prepTime: Int // in minutes
    var cookTime: Int // in minutes
    var servings: Int
    var difficulty: Difficulty
    var spicyLevel: SpicyLevel
    var tips: [String]
    var cuisine: String? // Kept for backward compatibility, uses cuisineEnglish
    var cuisineEnglish: String? // English cuisine name (always saved, used for translations)
    var imageURL: String? // Deprecated: use imageURLs instead, kept for backward compatibility
    var imageURLs: [String] // Array of image URLs (up to 5)
    var sourceImageURL: String? // Deprecated: use sourceImageURLs instead, kept for backward compatibility
    var sourceImageURLs: [String] // Array of source image URLs used for extraction
    var authorID: String
    var authorName: String
    var authorUsername: String?
    var createdAt: Date
    var updatedAt: Date
    var favoriteCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case titleEnglish
        case titleLocal
        case titleOriginal
        case description
        case ingredients
        case instructions
        case prepTime
        case cookTime
        case servings
        case difficulty
        case spicyLevel
        case tips
        case cuisine
        case cuisineEnglish
        case imageURL
        case imageURLs
        case sourceImageURL
        case sourceImageURLs = "sourceImages" // Firebase field name
        case authorID
        case authorName
        case authorUsername
        case createdAt
        case updatedAt
        case favoriteCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        id = try container.decode(String.self, forKey: .id)
        
        // Handle title with backward compatibility
        titleEnglish = try container.decodeIfPresent(String.self, forKey: .titleEnglish)
        titleLocal = try container.decodeIfPresent(String.self, forKey: .titleLocal)
        titleOriginal = try container.decodeIfPresent(String.self, forKey: .titleOriginal)
        
        // Decode title (for backward compatibility)
        let decodedTitle = try container.decodeIfPresent(String.self, forKey: .title)
        
        // Set title based on available data
        // Prefer titleLocal (user's language when recipe was created), then titleEnglish, then decoded title
        if let titleLocal = titleLocal {
            title = titleLocal
        } else if let titleEnglish = titleEnglish {
            title = titleEnglish
        } else if let decodedTitle = decodedTitle {
            title = decodedTitle
            // If we only have the old title field, set it as both English and Local for backward compatibility
            titleEnglish = decodedTitle
            titleLocal = decodedTitle
        } else {
            title = "" // Fallback
        }
        
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        authorID = try container.decode(String.self, forKey: .authorID)
        authorName = try container.decodeIfPresent(String.self, forKey: .authorName) ?? ""
        authorUsername = try container.decodeIfPresent(String.self, forKey: .authorUsername)
        
        // Arrays with defaults
        // Handle backward compatibility: decode [Ingredient] if available, otherwise try [String] and convert
        if let ingredientObjects = try? container.decodeIfPresent([Ingredient].self, forKey: .ingredients) {
            ingredients = ingredientObjects
        } else if let ingredientStrings = try? container.decodeIfPresent([String].self, forKey: .ingredients) {
            // Convert old [String] format to [Ingredient] format for backward compatibility
            ingredients = ingredientStrings.map { string in
                // Try to parse the string format "amount unit name" or "amount name" or just "name"
                let parts = string.trimmingCharacters(in: .whitespaces).components(separatedBy: " ")
                if parts.count >= 2 {
                    // Check if first part is a number
                    if let _ = Double(parts[0]) {
                        // Format: "amount unit name" or "amount name"
                        if parts.count >= 3 {
                            return Ingredient(
                                amount: parts[0],
                                unit: parts[1],
                                name: parts[2...].joined(separator: " ")
                            )
                        } else {
                            return Ingredient(
                                amount: parts[0],
                                unit: "",
                                name: parts[1]
                            )
                        }
                    }
                }
                // Just a name, no amount/unit
                return Ingredient(
                    amount: "",
                    unit: "",
                    name: string
                )
            }
        } else {
            ingredients = []
        }
        // Decode instructions (IDs will be ignored if present in old data)
        instructions = try container.decodeIfPresent([Instruction].self, forKey: .instructions) ?? []
        
        // Numbers with defaults
        prepTime = try container.decodeIfPresent(Int.self, forKey: .prepTime) ?? 0
        cookTime = try container.decodeIfPresent(Int.self, forKey: .cookTime) ?? 0
        servings = try container.decodeIfPresent(Int.self, forKey: .servings) ?? 1
        favoriteCount = try container.decodeIfPresent(Int.self, forKey: .favoriteCount) ?? 0
        
        // Optional fields
        // Handle cuisine with backward compatibility
        cuisineEnglish = try container.decodeIfPresent(String.self, forKey: .cuisineEnglish)
        
        // Decode cuisine (for backward compatibility)
        let decodedCuisine = try container.decodeIfPresent(String.self, forKey: .cuisine)
        
        // Set cuisine based on available data
        // Prefer cuisineEnglish, then decoded cuisine
        if let cuisineEnglish = cuisineEnglish {
            cuisine = cuisineEnglish
        } else if let decodedCuisine = decodedCuisine {
            cuisine = decodedCuisine
            // If we only have the old cuisine field, set it as English for backward compatibility
            cuisineEnglish = decodedCuisine
        } else {
            cuisine = nil
        }
        
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        
        // Handle imageURLs: decode array if present, otherwise fall back to single imageURL for backward compatibility
        if let imageURLsArray = try? container.decodeIfPresent([String].self, forKey: .imageURLs) {
            imageURLs = imageURLsArray
            // If imageURLs exists but imageURL doesn't, set imageURL to first item for backward compatibility
            if imageURL == nil && !imageURLs.isEmpty {
                imageURL = imageURLs.first
            }
        } else if let singleImageURL = imageURL {
            // Backward compatibility: convert single imageURL to array
            imageURLs = [singleImageURL]
        } else {
            imageURLs = []
        }
        
        // Handle source image URLs for backward compatibility
        if let urls = try? container.decodeIfPresent([String].self, forKey: .sourceImageURLs) {
            sourceImageURLs = urls
        } else if let url = try? container.decodeIfPresent(String.self, forKey: .sourceImageURL) {
            // Convert old single sourceImageURL to array for backward compatibility
            sourceImageURLs = [url]
        } else {
            sourceImageURLs = []
        }
        sourceImageURL = try container.decodeIfPresent(String.self, forKey: .sourceImageURL) // Keep for backward compatibility
        tips = try container.decodeIfPresent([String].self, forKey: .tips) ?? []
        
        // Difficulty with fallback
        if let difficultyString = try? container.decodeIfPresent(String.self, forKey: .difficulty),
           let decodedDifficulty = Difficulty(rawValue: difficultyString) {
            difficulty = decodedDifficulty
        } else {
            difficulty = .c // Default to C if decoding fails
        }
        
        // SpicyLevel with fallback
        if let spicyLevelInt = try? container.decodeIfPresent(Int.self, forKey: .spicyLevel),
           let decodedSpicyLevel = SpicyLevel(rawValue: spicyLevelInt) {
            spicyLevel = decodedSpicyLevel
        } else if let spicyLevelString = try? container.decodeIfPresent(String.self, forKey: .spicyLevel),
                  let spicyLevelInt = Int(spicyLevelString),
                  let decodedSpicyLevel = SpicyLevel(rawValue: spicyLevelInt) {
            spicyLevel = decodedSpicyLevel
        } else {
            spicyLevel = .none // Default to none if decoding fails
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
    
    enum SpicyLevel: Int, Codable, CaseIterable {
        case none = 0
        case one = 1
        case two = 2
        case three = 3
        case four = 4
        case five = 5
        
        var displayName: String {
            return "\(self.rawValue)"
        }
        
        var chiliCount: Int {
            return self.rawValue
        }
    }
    
    init(
        id: String = UUID().uuidString,
        title: String,
        titleEnglish: String? = nil,
        titleLocal: String? = nil,
        titleOriginal: String? = nil,
        description: String,
        ingredients: [Ingredient],
        instructions: [Instruction],
        prepTime: Int,
        cookTime: Int,
        servings: Int,
        difficulty: Difficulty,
        spicyLevel: SpicyLevel = .none,
        tips: [String] = [],
        cuisine: String? = nil, // Kept for backward compatibility
        cuisineEnglish: String? = nil,
        imageURL: String? = nil, // Deprecated: use imageURLs instead
        imageURLs: [String] = [],
        sourceImageURL: String? = nil, // Deprecated: use sourceImageURLs instead
        sourceImageURLs: [String] = [],
        authorID: String,
        authorName: String,
        authorUsername: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        favoriteCount: Int = 0
    ) {
        self.id = id
        
        // Set title fields
        self.titleEnglish = titleEnglish
        self.titleLocal = titleLocal
        self.titleOriginal = titleOriginal
        
        // Set title based on available data: prefer titleLocal, then titleEnglish, then provided title
        if let titleLocal = titleLocal {
            self.title = titleLocal
        } else if let titleEnglish = titleEnglish {
            self.title = titleEnglish
        } else {
            self.title = title
            // If neither titleEnglish nor titleLocal provided, use title for both
            self.titleEnglish = title
            self.titleLocal = title
        }
        
        self.description = description
        self.ingredients = ingredients
        self.instructions = instructions
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.servings = servings
        self.difficulty = difficulty
        self.spicyLevel = spicyLevel
        self.tips = tips
        
        // Set cuisine fields
        self.cuisineEnglish = cuisineEnglish
        
        // Set cuisine based on available data: prefer cuisineEnglish, then provided cuisine
        if let cuisineEnglish = cuisineEnglish {
            self.cuisine = cuisineEnglish
        } else if let cuisine = cuisine {
            self.cuisine = cuisine
            // If cuisineEnglish not provided, use cuisine as English
            self.cuisineEnglish = cuisine
        } else {
            self.cuisine = nil
        }
        
        self.imageURL = imageURL
        // If imageURLs is provided, use it; otherwise convert imageURL to array for backward compatibility
        if !imageURLs.isEmpty {
            self.imageURLs = imageURLs
            // Set imageURL to first item for backward compatibility if not already set
            if self.imageURL == nil {
                self.imageURL = imageURLs.first
            }
        } else if let imageURL = imageURL {
            self.imageURLs = [imageURL]
        } else {
            self.imageURLs = []
        }
        // Handle source image URLs: if sourceImageURLs is provided, use it; otherwise convert sourceImageURL to array
        if !sourceImageURLs.isEmpty {
            self.sourceImageURLs = sourceImageURLs
            // Set sourceImageURL to first item for backward compatibility if not already set
            if sourceImageURL == nil {
                self.sourceImageURL = sourceImageURLs.first
            } else {
                self.sourceImageURL = sourceImageURL
            }
        } else if let sourceImageURL = sourceImageURL {
            self.sourceImageURLs = [sourceImageURL]
            self.sourceImageURL = sourceImageURL
        } else {
            self.sourceImageURLs = []
            self.sourceImageURL = nil
        }
        self.authorID = authorID
        self.authorName = authorName
        self.authorUsername = authorUsername
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.favoriteCount = favoriteCount
    }
    
    /// Get the appropriate cuisine name based on the current language setting
    /// Uses hardcoded translations from CuisineTranslations
    var displayCuisine: String? {
        guard let englishCuisine = cuisineEnglish ?? cuisine, !englishCuisine.isEmpty else {
            return nil
        }
        return CuisineTranslations.translatedName(for: englishCuisine)
    }
}


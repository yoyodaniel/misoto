//
//  ProfanityFilter.swift
//  Misoto
//
//  Created by Daniel Chan on 4.1.2026.
//

import Foundation

/// Service for filtering profanity and harmful content
class ProfanityFilter {
    static let shared = ProfanityFilter()
    
    // Common profanity and harmful words list
    // This is a basic list - in production, you may want to use a more comprehensive list
    private let profanityWords: Set<String> = [
        // Explicit profanity (common English)
        "fuck", "fucking", "fucked", "fucker",
        "shit", "shitting", "shitted",
        "damn", "damned", "dammit",
        "ass", "asshole",
        "bitch", "bitches",
        "bastard", "bastards",
        "crap", "crappy",
        "piss", "pissed", "pissing",
        "hell", "hells",
        "dick", "dicks",
        "cock", "cocks",
        "pussy", "pussies",
        "cunt", "cunts",
        "whore", "whores",
        "slut", "sluts",
        "nigger", "niggers", "nigga", "niggas",
        "kike", "kikes",
        "spic", "spics",
        "chink", "chinks",
        "gook", "gooks",
        "terrorist", "terrorists",
        "kill", "killing", "killed", "kills",
        "murder", "murdering", "murdered", "murders",
        "suicide", "suicides",
        "bomb", "bombing", "bombed", "bombs",
        "hate", "hating", "hated", "hates",
        // Add more as needed
    ]
    
    private init() {}
    
    /// Check if text contains profanity
    /// - Parameter text: The text to check
    /// - Returns: Tuple containing (hasProfanity: Bool, detectedWords: [String])
    func checkProfanity(in text: String) -> (hasProfanity: Bool, detectedWords: [String]) {
        guard !text.isEmpty else {
            return (false, [])
        }
        
        // Normalize text: lowercase, remove punctuation, split into words
        let normalizedText = text.lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
        
        let words = normalizedText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        var detectedWords: [String] = []
        
        for word in words {
            // Check exact match
            if profanityWords.contains(word) {
                detectedWords.append(word)
                print("🚫 Profanity detected (exact match): '\(word)' in text: '\(text.prefix(50))'")
                continue
            }
            
            // Check if word contains profanity (for cases like "fuckinghell")
            for profanity in profanityWords {
                if word.contains(profanity) {
                    detectedWords.append(profanity)
                    print("🚫 Profanity detected (contains): '\(profanity)' in word: '\(word)' from text: '\(text.prefix(50))'")
                    break
                }
            }
        }
        
        if !detectedWords.isEmpty {
            print("🚫 Profanity filter triggered! Detected words: \(Array(Set(detectedWords)))")
        }
        
        return (!detectedWords.isEmpty, Array(Set(detectedWords))) // Remove duplicates
    }
    
    /// Check if a recipe contains profanity in any of its text fields
    /// - Parameter recipe: The recipe to check
    /// - Returns: Tuple containing (hasProfanity: Bool, field: String?, detectedWords: [String])
    func checkRecipe(_ recipe: Recipe) -> (hasProfanity: Bool, field: String?, detectedWords: [String]) {
        var allDetectedWords: [String] = []
        var problematicField: String?
        
        // Check title
        let titleCheck = checkProfanity(in: recipe.title)
        if titleCheck.hasProfanity {
            allDetectedWords.append(contentsOf: titleCheck.detectedWords)
            if problematicField == nil {
                problematicField = "title"
            }
        }
        
        // Check description
        if !recipe.description.isEmpty {
            let descCheck = checkProfanity(in: recipe.description)
            if descCheck.hasProfanity {
                allDetectedWords.append(contentsOf: descCheck.detectedWords)
                if problematicField == nil {
                    problematicField = "description"
                }
            }
        }
        
        // Check ingredients
        for ingredient in recipe.ingredients {
            let ingredientText = "\(ingredient.name) \(ingredient.amount) \(ingredient.unit)"
            let ingredientCheck = checkProfanity(in: ingredientText)
            if ingredientCheck.hasProfanity {
                allDetectedWords.append(contentsOf: ingredientCheck.detectedWords)
                if problematicField == nil {
                    problematicField = "ingredients"
                }
            }
        }
        
        // Check instructions
        for instruction in recipe.instructions {
            let instructionCheck = checkProfanity(in: instruction.text)
            if instructionCheck.hasProfanity {
                allDetectedWords.append(contentsOf: instructionCheck.detectedWords)
                if problematicField == nil {
                    problematicField = "instructions"
                }
            }
        }
        
        // Check tips
        for tip in recipe.tips {
            let tipCheck = checkProfanity(in: tip)
            if tipCheck.hasProfanity {
                allDetectedWords.append(contentsOf: tipCheck.detectedWords)
                if problematicField == nil {
                    problematicField = "tips"
                }
            }
        }
        
        return (!allDetectedWords.isEmpty, problematicField, Array(Set(allDetectedWords)))
    }
    
    /// Get a user-friendly error message for detected profanity
    /// - Parameters:
    ///   - field: The field where profanity was detected
    ///   - detectedWords: The words that were detected
    /// - Returns: Localized error message
    func getErrorMessage(field: String?, detectedWords: [String]) -> String {
        let fieldName = field ?? "content"
        let wordsList = detectedWords.prefix(3).joined(separator: ", ")
        let moreText = detectedWords.count > 3 ? " and more" : ""
        
        return "Your recipe contains inappropriate content in the \(fieldName). Please review and remove any offensive language before submitting."
    }
}


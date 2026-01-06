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
        
        // Whitelist of legitimate words that contain profanity substrings
        let whitelist: Set<String> = [
            // Spice-related words (legitimate cooking terms)
            "spice", "spices", "spicy", "spiced", "spicing", "spicier", "spiciest", "spiciness",
            // Classic-related words
            "classic", "classics", "classical", "classify", "classification", "classified",
            // Basil-related words
            "basil", "basilica", "basilisk",
            // Assassin-related words
            "assassin", "assassinate", "assassination",
            // Pass-related words
            "pass", "passage", "passenger", "passing", "passport", "password", "passive", "passion", "passionate",
            // Glass-related words
            "glass", "glasses", "glassy",
            // Mass-related words
            "mass", "massive", "massage", "massacre", "massive",
            // Grass-related words
            "grass", "grassy", "grassland",
            // Brass-related words
            "brass", "brassy",
            // Class-related words
            "class", "classic", "classroom", "classify", "classical",
            // Bass-related words
            "bass", "bassist", "bassoon",
            // Cassette-related words
            "cassette", "casserole",
            // Harass-related words
            "harass", "harassment",
            // Embarrass-related words
            "embarrass", "embarrassment", "embarrassing",
            // Kill-related words (cooking context)
            "killjoy", "killswitch", "skill", "skills", "skilled", "skillet", "killing", "killed", "kills",
            // Hate-related words (cooking context - "I hate when it burns" is legitimate)
            "hateful", "hateful",
        ]
        
        for word in words {
            // Skip whitelisted words
            if whitelist.contains(word.lowercased()) {
                continue
            }
            
            // Check exact match
            if profanityWords.contains(word) {
                detectedWords.append(word)
                print("🚫 Profanity detected (exact match): '\(word)' in text: '\(text.prefix(50))'")
                continue
            }
            
            // Check if word contains profanity as a whole word (not substring)
            // Only check if the word is longer than the profanity and contains it at word boundaries
            for profanity in profanityWords {
                // Only match if profanity appears as a whole word, not as a substring
                // Check if word equals profanity, or if word contains profanity at word boundaries
                let wordLower = word.lowercased()
                if wordLower == profanity {
                    detectedWords.append(profanity)
                    print("🚫 Profanity detected (exact match): '\(profanity)' in word: '\(word)' from text: '\(text.prefix(50))'")
                    break
                } else if wordLower.count > profanity.count {
                    // Only check compound words for specific profanity that commonly appears in compounds
                    // Skip substring matching for words that are commonly part of legitimate words
                    let profanityThatCanBeInCompounds: Set<String> = [
                        "fuck", "fucking", "shit", "damn", "hell"
                    ]
                    
                    // Only do compound word detection for profanity that commonly appears in compounds
                    if profanityThatCanBeInCompounds.contains(profanity) {
                        // Check if profanity appears at the start or end of the word (compound words like "fuckinghell")
                        if wordLower.hasPrefix(profanity) || wordLower.hasSuffix(profanity) {
                            // Make sure it's not part of a legitimate word by checking adjacent characters
                            let remainingChars = wordLower.replacingOccurrences(of: profanity, with: "")
                            // If remaining chars are very short or empty, it's likely a compound profanity word
                            if remainingChars.count <= 3 {
                                detectedWords.append(profanity)
                                print("🚫 Profanity detected (compound word): '\(profanity)' in word: '\(word)' from text: '\(text.prefix(50))'")
                                break
                            }
                        }
                    }
                    // For other profanity (like "spic"), only match exact words, not substrings
                    // This prevents false positives like "spice" being flagged for containing "spic"
                }
            }
        }
        
        if !detectedWords.isEmpty {
            let uniqueWords = Array(Set(detectedWords))
            print("🚫 ========== PROFANITY FILTER TRIGGERED ==========")
            print("🚫 Detected inappropriate words: \(uniqueWords)")
            print("🚫 Original text (first 100 chars): \(text.prefix(100))")
            print("🚫 ================================================")
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
        
        if !allDetectedWords.isEmpty {
            let uniqueWords = Array(Set(allDetectedWords))
            print("🚫 ========== RECIPE PROFANITY CHECK RESULT ==========")
            print("🚫 Recipe Title: \(recipe.title)")
            print("🚫 Problematic Field: \(problematicField ?? "unknown")")
            print("🚫 All detected inappropriate words: \(uniqueWords)")
            print("🚫 ==================================================")
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
        let wordsList = detectedWords.prefix(5).joined(separator: ", ")
        let moreText = detectedWords.count > 5 ? " and more" : ""
        
        // Show which words were detected to help user understand what triggered the filter
        if !wordsList.isEmpty {
            return "Your recipe contains inappropriate content in the \(fieldName). Detected words: \(wordsList)\(moreText). Please review and remove any offensive language before submitting."
        } else {
            return "Your recipe contains inappropriate content in the \(fieldName). Please review and remove any offensive language before submitting."
        }
    }
}


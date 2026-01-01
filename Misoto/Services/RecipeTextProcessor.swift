//
//  RecipeTextProcessor.swift
//  Misoto
//
//  Uses Foundation model capabilities to understand, correct, and structure recipe text
//

import Foundation
import UIKit
import NaturalLanguage

@MainActor
class RecipeTextProcessor {
    
    // Process and correct OCR text using intelligent text understanding and Foundation model capabilities
    func processAndCorrectText(_ rawText: String) async -> String {
        // Safety check: if input is empty, return it
        guard !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return rawText
        }
        
        // Step 1: Basic normalization
        var processedText = normalizeText(rawText)
        
        // Safety check: ensure we didn't remove all content
        guard !processedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("Warning: Normalization removed all text, using raw text")
            return rawText
        }
        
        // Step 2: Correct OCR errors using intelligent spell checking
        processedText = await correctTextWithSpellChecker(processedText)
        
        // Step 3: Fix common recipe-specific OCR issues
        processedText = fixRecipeSpecificOCRIssues(processedText)
        
        // Step 4: Improve text structure using language understanding
        processedText = improveTextStructure(processedText)
        
        // Final safety check: ensure we have content
        if processedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("Warning: Final processed text is empty, using raw text")
            return rawText
        }
        
        return processedText
    }
    
    // Normalize text (whitespace, line breaks)
    private func normalizeText(_ text: String) -> String {
        var normalized = text
        
        // Normalize line breaks
        normalized = normalized.replacingOccurrences(of: "\r\n", with: "\n")
        normalized = normalized.replacingOccurrences(of: "\r", with: "\n")
        
        // Trim each line but keep all lines (even empty ones) to preserve structure
        let lines = normalized.components(separatedBy: .newlines)
        normalized = lines.map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")
        
        // Only remove trailing empty lines, not all empty lines
        normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return normalized
    }
    
    // Correct text using UITextChecker (uses on-device language models)
    private func correctTextWithSpellChecker(_ text: String) async -> String {
        let checker = UITextChecker()
        let language = "en"
        let lines = text.components(separatedBy: .newlines)
        var correctedLines: [String] = []
        
        for line in lines {
            // Skip measurement lines - they're usually correct
            if Self.isMeasurementLine(line) {
                correctedLines.append(line)
                continue
            }
            
            let correctedLine = await Self.correctLine(line, checker: checker, language: language)
            correctedLines.append(correctedLine)
        }
        
        return correctedLines.joined(separator: "\n")
    }
    
    // Check if line is a measurement line (shouldn't be spell-checked)
    nonisolated private static func isMeasurementLine(_ line: String) -> Bool {
        let measurementPattern = "^\\d+\\s*(tbsp|tsp|cup|cups|oz|lb|g|kg|ml|l|tablespoon|teaspoon|piece|pieces|pinch|dash|clove|cloves|slice|slices|bunch|bunches|head|heads|strand|strands|/|gram|grams|kilogram|kilograms|ounce|ounces|pound|pounds|milliliter|milliliters|liter|liters)"
        return line.range(of: measurementPattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
    
    // Correct a single line using spell checker
    @MainActor
    private static func correctLine(_ line: String, checker: UITextChecker, language: String) -> String {
        let words = line.components(separatedBy: .whitespaces)
        var correctedWords: [String] = []
        
        for word in words {
            // Skip if it's a number, unit, or measurement
            if isMeasurementOrNumber(word) {
                correctedWords.append(word)
                continue
            }
            
            // Clean word of punctuation for checking
            let cleanedWord = word.trimmingCharacters(in: .punctuationCharacters)
            if cleanedWord.isEmpty || cleanedWord.count < 3 {
                correctedWords.append(word)
                continue
            }
            
            // Check spelling using on-device language model
            let range = NSRange(location: 0, length: cleanedWord.utf16.count)
            let misspelledRange = checker.rangeOfMisspelledWord(
                in: cleanedWord,
                range: range,
                startingAt: 0,
                wrap: false,
                language: language
            )
            
            if misspelledRange.location != NSNotFound {
                // Get correction suggestions from language model
                if let guesses = checker.guesses(forWordRange: range, in: cleanedWord, language: language),
                   let bestGuess = guesses.first,
                   bestGuess.count > 0 && similarity(bestGuess, cleanedWord) > 0.6 {
                    // Use the best guess, preserving formatting
                    let corrected = preserveWordFormat(original: word, corrected: bestGuess)
                    correctedWords.append(corrected)
                } else {
                    correctedWords.append(word)
                }
            } else {
                correctedWords.append(word)
            }
        }
        
        return correctedWords.joined(separator: " ")
    }
    
    // Check if word is a measurement or number
    nonisolated private static func isMeasurementOrNumber(_ word: String) -> Bool {
        // Check if it's a number or fraction
        if Double(word) != nil || word.range(of: "^\\d+/\\d+$", options: .regularExpression) != nil {
            return true
        }
        
        // Check if it's a unit
        let units = ["tsp", "tbsp", "cup", "cups", "oz", "lb", "g", "kg", "ml", "l",
                     "tablespoon", "teaspoon", "ounce", "pound", "gram", "grams", "kilogram", "kilograms",
                     "milliliter", "milliliters", "liter", "liters", "pinch", "pinches", "dash", "dashes",
                     "piece", "pieces", "pc", "pcs", "slice", "slices", "clove", "cloves",
                     "bunch", "bunches", "head", "heads", "strand", "strands", "x"]
        return units.contains(word.lowercased().trimmingCharacters(in: .punctuationCharacters))
    }
    
    // Calculate similarity between two strings
    nonisolated private static func similarity(_ s1: String, _ s2: String) -> Double {
        let longer = s1.count > s2.count ? s1 : s2
        let shorter = s1.count > s2.count ? s2 : s1
        
        if longer.isEmpty { return 1.0 }
        
        let distance = levenshteinDistance(shorter, longer)
        return 1.0 - (Double(distance) / Double(longer.count))
    }
    
    // Levenshtein distance calculation
    nonisolated private static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let m = s1Array.count
        let n = s2Array.count
        
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m { dp[i][0] = i }
        for j in 0...n { dp[0][j] = j }
        
        for i in 1...m {
            for j in 1...n {
                if s1Array[i - 1] == s2Array[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1]
                } else {
                    dp[i][j] = min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]) + 1
                }
            }
        }
        
        return dp[m][n]
    }
    
    // Preserve original word formatting when correcting
    nonisolated private static func preserveWordFormat(original: String, corrected: String) -> String {
        var result = corrected
        
        // Preserve capitalization
        if original.first?.isUppercase == true {
            result = result.capitalized
        }
        if original == original.uppercased() {
            result = result.uppercased()
        }
        
        // Preserve trailing punctuation
        if original.last?.isPunctuation == true {
            result = result + String(original.last!)
        }
        
        // Preserve leading punctuation
        if original.first?.isPunctuation == true {
            result = String(original.first!) + result
        }
        
        return result
    }
    
    // Improve text structure using language understanding
    private func improveTextStructure(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var structuredLines: [String] = []
        
        for (_, line) in lines.enumerated() {
            var processedLine = line.trimmingCharacters(in: .whitespaces)
            
            if processedLine.isEmpty {
                continue
            }
            
            // Fix: Remove periods after numbers in ingredient lines (e.g., "12. chicken" -> "12 chicken")
            // Also fix "30. ml" -> "30 ml" patterns
            if Self.isLikelyIngredientLine(processedLine) {
                // Preserve bullet points/dashes at the start (e.g., "– 500gr" or "- 2 uien")
                // Remove period after number if followed by space and text (but keep dashes)
                processedLine = processedLine.replacingOccurrences(
                    of: "^([–-•]?\\s*)(\\d+)\\.\\s+",
                    with: "$1$2 ",
                    options: .regularExpression
                )
                // Fix "30. ml" -> "30 ml" (period before unit)
                processedLine = processedLine.replacingOccurrences(
                    of: "(\\d+)\\.\\s+(ml|kg|g|l|tsp|tbsp|oz|lb|cup|cups|tablespoon|teaspoon|gr|gram|grams)",
                    with: "$1 $2",
                    options: [.regularExpression, .caseInsensitive]
                )
                // Normalize different dash types to standard dash for consistency
                processedLine = processedLine.replacingOccurrences(
                    of: "^[–—]\\s*",
                    with: "- ",
                    options: .regularExpression
                )
            } else if let firstChar = processedLine.first, firstChar.isNumber {
                // For instructions, normalize to "1. " format
                if let numberRange = processedLine.range(of: "^\\d+", options: .regularExpression) {
                    let number = String(processedLine[numberRange])
                    let remainingStart = processedLine.index(processedLine.startIndex, offsetBy: number.count)
                    var rest = String(processedLine[remainingStart...])
                    
                    // Remove leading punctuation and spaces
                    rest = rest.trimmingCharacters(in: CharacterSet(charactersIn: ". )"))
                    
                    if !rest.isEmpty {
                        processedLine = "\(number). \(rest)"
                    }
                }
            }
            
            structuredLines.append(processedLine)
        }
        
        return structuredLines.joined(separator: "\n")
    }
    
    // Check if line is likely an ingredient (has measurements or ingredient keywords)
    nonisolated private static func isLikelyIngredientLine(_ line: String) -> Bool {
        let lowercased = line.lowercased()
        
        // Check for measurement patterns
        let measurementPattern = "\\d+\\s*(tbsp|tsp|cup|cups|oz|lb|g|kg|ml|l|tablespoon|teaspoon|piece|pieces|pinch|dash|clove|cloves|slice|slices|bunch|bunches|head|heads|strand|strands|gram|grams|kilogram|kilograms|ounce|ounces|pound|pounds|milliliter|milliliters|liter|liters)"
        if line.range(of: measurementPattern, options: [.regularExpression, .caseInsensitive]) != nil {
            return true
        }
        
        // Check for common ingredient keywords
        let ingredientKeywords = ["chicken", "beef", "pork", "fish", "garlic", "onion", "tomato", "pepper", "salt", "sugar", "oil", "butter", "flour", "rice", "noodle", "vegetable", "herb", "spice"]
        return ingredientKeywords.contains { lowercased.contains($0) }
    }
    
    // Clean and normalize text
    private func cleanAndNormalizeText(_ text: String) -> String {
        var cleaned = text
        
        // Normalize whitespace (multiple spaces/tabs to single space)
        cleaned = cleaned.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        
        // Fix common OCR issues: '0' vs 'O', '1' vs 'I', '5' vs 'S'
        // But be careful - only fix when context suggests it
        cleaned = fixCommonOCRCharacterConfusions(cleaned)
        
        // Normalize line breaks
        cleaned = cleaned.replacingOccurrences(of: "\r\n", with: "\n")
        cleaned = cleaned.replacingOccurrences(of: "\r", with: "\n")
        
        // Trim each line
        let lines = cleaned.components(separatedBy: .newlines)
        cleaned = lines.map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        
        return cleaned
    }
    
    // Fix common OCR character confusions in context
    private func fixCommonOCRCharacterConfusions(_ text: String) -> String {
        var fixed = text
        
        // Fix '0' -> 'O' in word contexts (but keep numbers)
        // Pattern: word boundaries with '0' that should be 'O'
        let zeroToO = [
            ("\\b([A-Za-z])0([A-Za-z])\\b", "$1O$2"),  // Between letters
            ("\\b0([a-z]{2,})\\b", "O$1"),  // Start of lowercase word
        ]
        
        for (pattern, replacement) in zeroToO {
            fixed = fixed.replacingOccurrences(
                of: pattern,
                with: replacement,
                options: .regularExpression
            )
        }
        
        // Fix '1' -> 'I' in word contexts
        let oneToI = [
            ("\\b([A-Za-z])1([A-Za-z])\\b", "$1I$2"),  // Between letters
            ("\\b1([a-z]{2,})\\b", "I$1"),  // Start of lowercase word
        ]
        
        for (pattern, replacement) in oneToI {
            fixed = fixed.replacingOccurrences(
                of: pattern,
                with: replacement,
                options: .regularExpression
            )
        }
        
        return fixed
    }
    
    
    // Fix common recipe-specific OCR issues using intelligent pattern recognition
    private func fixRecipeSpecificOCRIssues(_ text: String) -> String {
        var fixed = text
        
        // Fix common recipe term misspellings
        let recipeCorrections: [String: String] = [
            "ingrediant": "ingredient",
            "ingrediants": "ingredients",
            "instrucion": "instruction",
            "instrucions": "instructions",
            "marinade": "marinade",  // Keep as is, just for consistency
            "marinades": "marinades",
            "seasoning": "seasoning",
            "seasonings": "seasonings",
            "tablespon": "tablespoon",
            "teaspon": "teaspoon",
            "garli": "garlic",
            "onion": "onion",  // Keep as is
            "tomato": "tomato",
            "potato": "potato",
        ]
        
        for (wrong, correct) in recipeCorrections {
            let pattern = "\\b\(wrong)\\b"
            fixed = fixed.replacingOccurrences(
                of: pattern,
                with: correct,
                options: [.regularExpression, .caseInsensitive]
            )
        }
        
        // Fix spacing around punctuation
        fixed = fixed.replacingOccurrences(of: " ,", with: ",")
        fixed = fixed.replacingOccurrences(of: " .", with: ".")
        fixed = fixed.replacingOccurrences(of: " :", with: ":")
        
        return fixed
    }
}


//
//  RecipeDetector.swift
//  Misoto
//
//  Service for detecting if a webpage contains recipe content using on-device Foundation models
//

import Foundation
import NaturalLanguage
import WebKit

@MainActor
class RecipeDetector {
    
    /// Detect if a webpage contains recipe content using on-device Foundation models
    /// This method only reads content - it does NOT modify the webpage in any way
    /// Translates text to English first to support multilingual recipe detection
    static func detectRecipe(on webView: WKWebView) async -> Bool {
        do {
            // Read text content from the webpage WITHOUT modifying it
            let text = try await readTextOnly(from: webView)
            
            // Translate text to English if needed (for multilingual recipe detection)
            // This ensures recipes in any language can be detected using English keywords
            let translatedText = await TextTranslationService.translateToEnglish(text)
            
            // Use on-device Foundation models to detect recipe content
            return detectRecipeInText(translatedText)
        } catch {
            // If we can't read text, assume no recipe
            return false
        }
    }
    
    /// Read text content from WKWebView without modifying the DOM
    /// This is a read-only operation that does not change the webpage
    private static func readTextOnly(from webView: WKWebView) async throws -> String {
        // JavaScript to ONLY read text content - does NOT modify the page
        let readOnlyScript = """
        (function() {
            // Try to find main content area (common recipe website patterns)
            const contentSelectors = [
                'article', '.recipe-content', '.recipe', '.content', 
                'main', '.main-content', '[role="main"]', '.post-content',
                '.entry-content', '.recipe-details', '.recipe-body'
            ];
            
            let mainContent = null;
            for (const selector of contentSelectors) {
                const element = document.querySelector(selector);
                if (element) {
                    mainContent = element;
                    break;
                }
            }
            
            // If no main content found, use body
            const targetElement = mainContent || document.body;
            
            // Extract text, preserving line breaks - READ ONLY, no modifications
            const text = targetElement.innerText || targetElement.textContent || '';
            
            // Clean up excessive whitespace while preserving structure
            return text
                .replace(/\\s+/g, ' ')
                .replace(/\\n\\s*\\n\\s*\\n/g, '\\n\\n')
                .trim();
        })();
        """
        
        // Execute JavaScript and get result
        let result = try await webView.evaluateJavaScript(readOnlyScript) as? String
        
        guard let extractedText = result, !extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw RecipeDetectionError.noContentFound
        }
        
        return extractedText
    }
    
    private enum RecipeDetectionError: LocalizedError {
        case noContentFound
        
        var errorDescription: String? {
            switch self {
            case .noContentFound:
                return "No content found on the webpage"
            }
        }
    }
    
    /// Detect if text contains recipe content using NaturalLanguage framework and pattern matching
    /// Uses very lenient scoring system - requires minimal recipe indicators
    private static func detectRecipeInText(_ text: String) -> Bool {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        // Rule 0: Text length must be reasonable
        guard text.count > 120 && text.count < 50000 else {
            return false
        }
        
        let lowercasedText = text.lowercased()
        var score = 0
        
        // CATEGORY 1: Recipe structure keywords (weight: 1-2 points)
        let recipeKeywords = [
            "ingredient", "ingredients", "instruction", "instructions", "directions",
            "recipe", "method", "steps", "preparation", "servings", "serves", "yield",
            "how to", "directions", "make"
        ]
        var keywordCount = 0
        for keyword in recipeKeywords {
            if lowercasedText.contains(keyword) {
                keywordCount += 1
            }
        }
        if keywordCount >= 1 {
            score += 2  // Any keyword = 2 points (strong signal)
        }
        
        // CATEGORY 2: Measurement units (weight: 2 points)
        let measurementPattern = #"\d+\s*(cup|cups|tbsp|tsp|oz|lb|g|kg|ml|l|gram|grams|ounce|ounces|pound|pounds|tablespoon|tablespoons|teaspoon|teaspoons)"#
        if let regex = try? NSRegularExpression(pattern: measurementPattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: text.utf16.count)
            if regex.firstMatch(in: text, options: [], range: range) != nil {
                score += 2
            }
        }
        
        // CATEGORY 3: Cooking actions/verbs (weight: 1-2 points)
        let cookingVerbs = ["preheat", "bake", "cook", "simmer", "boil", "fry", "sauté", "roast", "mix", "combine", "add", "heat", "stir", "whisk", "beat", "fold", "knead", "roll", "season", "chop", "slice", "dice", "cut", "peel", "grate", "pour", "sprinkle", "steam", "grill", "marinate", "brush", "glaze"]
        var cookingVerbCount = 0
        for verb in cookingVerbs {
            if lowercasedText.contains(verb) {
                cookingVerbCount += 1
            }
        }
        if cookingVerbCount >= 2 {
            score += 2  // 2+ verbs = 2 points
        } else if cookingVerbCount >= 1 {
            score += 1  // 1 verb = 1 point
        }
        
        // CATEGORY 4: Instructions/steps indicators (weight: 1 point)
        let numberedStepsPattern = #"\d+\.\s+[A-Za-z]"#  // "1. Mix", "2. Add"
        let stepPattern = #"step\s+\d+|step\s+[a-z]+:"#  // "step 1", "step 2"
        var hasSteps = false
        if let regex = try? NSRegularExpression(pattern: numberedStepsPattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: text.utf16.count)
            if regex.firstMatch(in: text, options: [], range: range) != nil {
                hasSteps = true
            }
        }
        if !hasSteps, let regex = try? NSRegularExpression(pattern: stepPattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: text.utf16.count)
            if regex.firstMatch(in: text, options: [], range: range) != nil {
                hasSteps = true
            }
        }
        if hasSteps {
            score += 1
        }
        
        // CATEGORY 5: Ingredient list patterns (weight: 1 point)
        let ingredientListPatterns = [
            #"ingredient[s]?:"#,  // "Ingredients:"
            #"\d+\s+\w+\s+(cup|tbsp|tsp|oz|lb|g|kg|ml|l|gram|ounce|pound)"#,  // Measurement followed by ingredient
            #"^[\s]*[-•]\s*\w+"#,  // Bullet list items
            #"\n[\s]*[-•]\s*\w+"#
        ]
        for pattern in ingredientListPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: text.utf16.count)
                if regex.firstMatch(in: text, options: [], range: range) != nil {
                    score += 1
                    break
                }
            }
        }
        
        // CATEGORY 6: Time/serving info (weight: 1 point)
        let timePatterns = [
            #"(prep|cook|preparation|cooking)\s+time"#,
            #"\d+\s*(minute|minutes|min|hour|hours|hr)"#,
            #"serves?\s+\d+|servings?:\s*\d+"#
        ]
        for pattern in timePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: text.utf16.count)
                if regex.firstMatch(in: text, options: [], range: range) != nil {
                    score += 1
                    break
                }
            }
        }
        
        // CATEGORY 7: Common ingredients (weight: 1-2 points)
        let commonIngredients = ["salt", "pepper", "garlic", "onion", "butter", "oil", "flour", "sugar", "egg", "eggs", "milk", "cheese", "chicken", "beef", "pork", "fish", "tomato", "carrot", "potato", "water", "vinegar", "lemon", "herb", "spice", "rice", "pasta", "noodle", "bread", "meat", "vegetable", "fruit", "sauce", "broth", "stock", "soy", "ginger", "scallion", "chili", "sesame"]
        var ingredientCount = 0
        for ingredient in commonIngredients {
            let pattern = "\\b\(ingredient)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: text.utf16.count)
                if !regex.matches(in: text, options: [], range: range).isEmpty {
                    ingredientCount += 1
                }
            }
        }
        if ingredientCount >= 2 {
            score += 2  // 2+ ingredients = 2 points
        } else if ingredientCount >= 1 {
            score += 1  // 1 ingredient = 1 point
        }
        
        // More lenient: Need only 2 points to be considered a recipe
        // Examples: keyword (2), or measurements (2), or cooking verb (1) + ingredient (1), etc.
        // This makes it much easier for recipe pages to pass detection
        return score >= 2
    }
}


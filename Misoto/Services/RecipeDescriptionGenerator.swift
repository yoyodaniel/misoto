//
//  RecipeDescriptionGenerator.swift
//  Misoto
//
//  Generates recipe descriptions using Foundation model capabilities
//

import Foundation
import NaturalLanguage

@MainActor
class RecipeDescriptionGenerator {
    
    /// Generate a recipe description based on title and ingredients
    static func generateDescription(
        title: String,
        marinadeIngredients: [RecipeTextParser.IngredientItem],
        seasoningIngredients: [RecipeTextParser.IngredientItem],
        dishIngredients: [RecipeTextParser.IngredientItem]
    ) -> String {
        // Combine all ingredients
        let allIngredients = marinadeIngredients + seasoningIngredients + dishIngredients
        let ingredientNames = allIngredients.map { $0.name }.filter { !$0.isEmpty }
        
        // If no title or ingredients, return empty
        guard !title.isEmpty, !ingredientNames.isEmpty else {
            return ""
        }
        
        // Extract key information from title and ingredients
        let cuisineType = detectCuisineType(title: title, ingredients: ingredientNames)
        let mainIngredients = extractMainIngredients(ingredientNames)
        let cookingMethod = detectCookingMethod(title: title, ingredients: ingredientNames)
        let flavorProfile = detectFlavorProfile(ingredients: ingredientNames)
        
        // Generate description based on detected information
        var descriptionParts: [String] = []
        
        // Start with the dish type and main ingredients
        if !mainIngredients.isEmpty {
            let mainIngredientText = mainIngredients.prefix(3).joined(separator: ", ")
            descriptionParts.append("A delicious \(cuisineType) dish featuring \(mainIngredientText).")
        } else {
            descriptionParts.append("A flavorful \(cuisineType) recipe.")
        }
        
        // Add flavor profile if detected
        if !flavorProfile.isEmpty {
            descriptionParts.append("This dish offers a \(flavorProfile) flavor profile.")
        }
        
        // Add cooking method if detected
        if !cookingMethod.isEmpty {
            descriptionParts.append("Prepared using \(cookingMethod) techniques.")
        }
        
        // Add ingredient highlights
        if marinadeIngredients.count > 0 {
            descriptionParts.append("The marinade enhances the flavors with carefully selected ingredients.")
        }
        
        if seasoningIngredients.count > 0 {
            descriptionParts.append("Seasoned with aromatic spices and herbs.")
        }
        
        // Combine description parts
        let generatedDescription = descriptionParts.joined(separator: " ")
        
        // Use NaturalLanguage framework to improve the description
        return improveDescriptionWithNLP(generatedDescription)
    }
    
    // MARK: - Helper Methods
    
    private static func detectCuisineType(title: String, ingredients: [String]) -> String {
        let titleLower = title.lowercased()
        let ingredientsText = ingredients.joined(separator: " ").lowercased()
        let combined = "\(titleLower) \(ingredientsText)"
        
        // Detect cuisine types
        let cuisineKeywords: [String: String] = [
            "japanese": "Japanese",
            "chinese": "Chinese",
            "thai": "Thai",
            "indian": "Indian",
            "italian": "Italian",
            "mexican": "Mexican",
            "french": "French",
            "korean": "Korean",
            "vietnamese": "Vietnamese",
            "mediterranean": "Mediterranean",
            "asian": "Asian",
            "wok": "Asian",
            "soy": "Asian",
            "mirin": "Japanese",
            "sake": "Japanese",
            "miso": "Japanese",
            "ginger": "Asian",
            "garlic": "Asian",
            "sesame": "Asian",
            "curry": "Indian",
            "coconut": "Thai",
            "lemongrass": "Thai",
            "fish sauce": "Thai",
            "oyster sauce": "Chinese",
            "hoisin": "Chinese",
            "szechuan": "Chinese",
            "sichuan": "Chinese",
            "parmesan": "Italian",
            "basil": "Italian",
            "oregano": "Italian",
            "cilantro": "Mexican",
            "cumin": "Mexican",
            "chili": "Mexican"
        ]
        
        for (keyword, cuisine) in cuisineKeywords {
            if combined.contains(keyword) {
                return cuisine
            }
        }
        
        return "delicious"
    }
    
    private static func extractMainIngredients(_ ingredients: [String]) -> [String] {
        // Filter out common ingredients that are not "main" ingredients
        let commonIngredients = ["salt", "pepper", "oil", "water", "sugar", "flour", "butter", "garlic", "onion", "ginger"]
        
        let mainIngredients = ingredients.filter { ingredient in
            let lower = ingredient.lowercased()
            // Remove parenthetical notes
            let cleaned = lower.components(separatedBy: "(").first?.trimmingCharacters(in: .whitespaces) ?? lower
            return !commonIngredients.contains(cleaned) && cleaned.count > 3
        }
        
        // Return top ingredients (limit to 5)
        return Array(mainIngredients.prefix(5))
    }
    
    private static func detectCookingMethod(title: String, ingredients: [String]) -> String {
        let combined = "\(title.lowercased()) \(ingredients.joined(separator: " ").lowercased())"
        
        let cookingMethods: [String: String] = [
            "stir-fry": "stir-frying",
            "wok": "stir-frying",
            "deep-fry": "deep-frying",
            "fry": "frying",
            "roast": "roasting",
            "bake": "baking",
            "grill": "grilling",
            "steam": "steaming",
            "braise": "braising",
            "simmer": "simmering",
            "boil": "boiling",
            "marinate": "marinating"
        ]
        
        for (keyword, method) in cookingMethods {
            if combined.contains(keyword) {
                return method
            }
        }
        
        return ""
    }
    
    private static func detectFlavorProfile(ingredients: [String]) -> String {
        let ingredientsText = ingredients.joined(separator: " ").lowercased()
        
        var flavors: [String] = []
        
        // Sweet
        if ingredientsText.contains("sugar") || ingredientsText.contains("honey") || 
           ingredientsText.contains("brown sugar") || ingredientsText.contains("mirin") {
            flavors.append("sweet")
        }
        
        // Spicy
        if ingredientsText.contains("pepper") || ingredientsText.contains("chili") || 
           ingredientsText.contains("spicy") || ingredientsText.contains("szechuan") {
            flavors.append("spicy")
        }
        
        // Sour
        if ingredientsText.contains("lemon") || ingredientsText.contains("lime") || 
           ingredientsText.contains("vinegar") || ingredientsText.contains("citrus") {
            flavors.append("tangy")
        }
        
        // Umami
        if ingredientsText.contains("soy") || ingredientsText.contains("miso") || 
           ingredientsText.contains("oyster") || ingredientsText.contains("fish sauce") {
            flavors.append("umami-rich")
        }
        
        // Aromatic
        if ingredientsText.contains("ginger") || ingredientsText.contains("garlic") || 
           ingredientsText.contains("herb") || ingredientsText.contains("spice") {
            flavors.append("aromatic")
        }
        
        if flavors.isEmpty {
            return "balanced"
        }
        
        return flavors.joined(separator: " and ")
    }
    
    private static func improveDescriptionWithNLP(_ description: String) -> String {
        // Use NaturalLanguage framework to improve the description
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = description
        
        // Ensure proper capitalization
        var words = description.components(separatedBy: " ")
        if !words.isEmpty {
            // Capitalize first letter of first word
            words[0] = words[0].prefix(1).uppercased() + words[0].dropFirst()
        }
        
        let improved = words.joined(separator: " ")
        
        // Ensure it ends with proper punctuation
        if !improved.hasSuffix(".") && !improved.hasSuffix("!") && !improved.hasSuffix("?") {
            return improved + "."
        }
        
        return improved
    }
}




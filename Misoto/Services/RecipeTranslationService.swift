//
//  RecipeTranslationService.swift
//  Misoto
//
//  Service for translating recipe content to user's selected language
//

import Foundation
import NaturalLanguage

@MainActor
class RecipeTranslationService {
    
    /// Translate recipe content to user's selected language
    /// - Parameters:
    ///   - title: Recipe title
    ///   - description: Recipe description
    ///   - dishIngredients: Dish ingredients
    ///   - marinadeIngredients: Marinade ingredients
    ///   - seasoningIngredients: Seasoning ingredients
    ///   - batterIngredients: Batter ingredients
    ///   - sauceIngredients: Sauce ingredients
    ///   - baseIngredients: Base ingredients
    ///   - doughIngredients: Dough ingredients
    ///   - toppingIngredients: Topping ingredients
    ///   - instructions: Array of instruction strings
    ///   - tips: Array of tip strings
    ///   - cuisine: Cuisine name (optional)
    /// - Returns: Translated recipe content
    static func translateRecipe(
        title: String,
        description: String,
        dishIngredients: [RecipeTextParser.IngredientItem],
        marinadeIngredients: [RecipeTextParser.IngredientItem],
        seasoningIngredients: [RecipeTextParser.IngredientItem],
        batterIngredients: [RecipeTextParser.IngredientItem],
        sauceIngredients: [RecipeTextParser.IngredientItem],
        baseIngredients: [RecipeTextParser.IngredientItem],
        doughIngredients: [RecipeTextParser.IngredientItem],
        toppingIngredients: [RecipeTextParser.IngredientItem],
        instructions: [String],
        tips: [String],
        cuisine: String?
    ) async -> (
        title: String,
        description: String,
        dishIngredients: [RecipeTextParser.IngredientItem],
        marinadeIngredients: [RecipeTextParser.IngredientItem],
        seasoningIngredients: [RecipeTextParser.IngredientItem],
        batterIngredients: [RecipeTextParser.IngredientItem],
        sauceIngredients: [RecipeTextParser.IngredientItem],
        baseIngredients: [RecipeTextParser.IngredientItem],
        doughIngredients: [RecipeTextParser.IngredientItem],
        toppingIngredients: [RecipeTextParser.IngredientItem],
        instructions: [String],
        tips: [String],
        cuisine: String?
    ) {
        // Get user's selected language
        let selectedLanguage = LocalizationManager.shared.currentLanguage
        let targetLanguageCode: String
        
        switch selectedLanguage {
        case .english:
            // If English is selected, return as-is
            return (title, description, dishIngredients, marinadeIngredients, seasoningIngredients, batterIngredients, sauceIngredients, baseIngredients, doughIngredients, toppingIngredients, instructions, tips, cuisine)
        case .system:
            // Get system language code (preserve full code including variants like zh-Hant, zh-Hans)
            if let preferredLanguage = Locale.preferredLanguages.first {
                // Normalize Chinese regional variants to zh-Hans or zh-Hant
                targetLanguageCode = normalizeChineseLanguageCode(preferredLanguage)
            } else {
                return (title, description, dishIngredients, marinadeIngredients, seasoningIngredients, batterIngredients, sauceIngredients, baseIngredients, doughIngredients, toppingIngredients, instructions, tips, cuisine)
            }
        default:
            // Use the language code from the enum
            targetLanguageCode = selectedLanguage.rawValue
        }
        
        // Don't translate if target is English
        if targetLanguageCode.lowercased() == "en" || targetLanguageCode.lowercased().hasPrefix("en-") {
            return (title, description, dishIngredients, marinadeIngredients, seasoningIngredients, batterIngredients, sauceIngredients, baseIngredients, doughIngredients, toppingIngredients, instructions, tips, cuisine)
        }
        
        print("🌍 Translating recipe to \(targetLanguageCode)...")
        
        // Translate all text fields
        var translatedTitle = title
        var translatedDescription = description
        var translatedInstructions: [String] = []
        var translatedTips: [String] = []
        var translatedCuisine = cuisine
        
        // Helper function to translate ingredient names and units (preserve amounts)
        func translateIngredients(_ ingredients: [RecipeTextParser.IngredientItem]) async -> [RecipeTextParser.IngredientItem] {
            var translated: [RecipeTextParser.IngredientItem] = []
            for ingredient in ingredients {
                var translatedIngredient = ingredient
                
                // Translate ingredient name
                if !ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    do {
                        translatedIngredient.name = try await OpenAIService.translateFromEnglish(ingredient.name, to: targetLanguageCode)
                    } catch {
                        print("⚠️ Failed to translate ingredient name '\(ingredient.name)': \(error.localizedDescription)")
                    }
                }
                
                // Translate unit using hardcoded translations
                if !ingredient.unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    translatedIngredient.unit = UnitTranslationService.translateUnit(ingredient.unit, to: targetLanguageCode)
                }
                
                translated.append(translatedIngredient)
            }
            return translated
        }
        
        // Translate title
        if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                translatedTitle = try await OpenAIService.translateFromEnglish(title, to: targetLanguageCode)
                print("✅ Translated title")
            } catch {
                print("⚠️ Failed to translate title: \(error.localizedDescription)")
            }
        }
        
        // Translate description
        if !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                translatedDescription = try await OpenAIService.translateFromEnglish(description, to: targetLanguageCode)
                print("✅ Translated description")
            } catch {
                print("⚠️ Failed to translate description: \(error.localizedDescription)")
            }
        }
        
        // Translate all ingredient categories
        let translatedDishIngredients = await translateIngredients(dishIngredients)
        let translatedMarinadeIngredients = await translateIngredients(marinadeIngredients)
        let translatedSeasoningIngredients = await translateIngredients(seasoningIngredients)
        let translatedBatterIngredients = await translateIngredients(batterIngredients)
        let translatedSauceIngredients = await translateIngredients(sauceIngredients)
        let translatedBaseIngredients = await translateIngredients(baseIngredients)
        let translatedDoughIngredients = await translateIngredients(doughIngredients)
        let translatedToppingIngredients = await translateIngredients(toppingIngredients)
        print("✅ Translated all ingredients")
        
        // Translate instructions
        for instruction in instructions {
            if !instruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                do {
                    let translated = try await OpenAIService.translateFromEnglish(instruction, to: targetLanguageCode)
                    translatedInstructions.append(translated)
                } catch {
                    print("⚠️ Failed to translate instruction: \(error.localizedDescription)")
                    translatedInstructions.append(instruction) // Fallback to original
                }
            } else {
                translatedInstructions.append(instruction)
            }
        }
        print("✅ Translated \(instructions.count) instructions")
        
        // Translate tips
        for tip in tips {
            if !tip.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                do {
                    let translated = try await OpenAIService.translateFromEnglish(tip, to: targetLanguageCode)
                    translatedTips.append(translated)
                } catch {
                    print("⚠️ Failed to translate tip: \(error.localizedDescription)")
                    translatedTips.append(tip) // Fallback to original
                }
            } else {
                translatedTips.append(tip)
            }
        }
        print("✅ Translated \(tips.count) tips")
        
        // Translate cuisine
        if let cuisine = cuisine, !cuisine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            do {
                translatedCuisine = try await OpenAIService.translateFromEnglish(cuisine, to: targetLanguageCode)
                print("✅ Translated cuisine")
            } catch {
                print("⚠️ Failed to translate cuisine: \(error.localizedDescription)")
            }
        }
        
        print("✅ Recipe translation complete")
        
        return (translatedTitle, translatedDescription, translatedDishIngredients, translatedMarinadeIngredients, translatedSeasoningIngredients, translatedBatterIngredients, translatedSauceIngredients, translatedBaseIngredients, translatedDoughIngredients, translatedToppingIngredients, translatedInstructions, translatedTips, translatedCuisine)
    }
    
    /// Normalize Chinese language codes to zh-Hans or zh-Hant
    /// - Parameter code: Language code from system (e.g., "zh-HK", "zh-TW", "zh-CN", "zh-Hans", "zh-Hant")
    /// - Returns: Normalized code (zh-Hans or zh-Hant)
    private static func normalizeChineseLanguageCode(_ code: String) -> String {
        let lowercased = code.lowercased()
        
        // Traditional Chinese regions: Hong Kong, Taiwan, Macau
        if lowercased.hasPrefix("zh-hk") || lowercased.hasPrefix("zh-tw") || lowercased.hasPrefix("zh-mo") || lowercased == "zh-hant" {
            return "zh-Hant"
        }
        
        // Simplified Chinese regions: China, Singapore
        if lowercased.hasPrefix("zh-cn") || lowercased.hasPrefix("zh-sg") || lowercased == "zh-hans" {
            return "zh-Hans"
        }
        
        // If it's just "zh" without variant, default to Simplified (most common)
        if lowercased == "zh" {
            return "zh-Hans"
        }
        
        // For all other cases, return as-is
        return code
    }
}


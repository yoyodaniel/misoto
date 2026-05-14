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
    
    /// Capitalize title in title case (capitalize each word)
    static func capitalizeTitle(_ title: String) -> String {
        guard !title.isEmpty else { return title }
        
        // Split by spaces and capitalize each word
        let words = title.components(separatedBy: .whitespaces)
        let capitalizedWords = words.map { word -> String in
            guard !word.isEmpty else { return word }
            // Capitalize first letter, keep rest lowercase
            return word.prefix(1).uppercased() + word.dropFirst().lowercased()
        }
        return capitalizedWords.joined(separator: " ")
    }
    
    /// Translate title to English, user's system language, and preserve original
    /// - Parameter title: The original title (can be in any language)
    /// - Returns: A tuple with (titleEnglish, titleLocal, titleOriginal)
    static func translateTitle(_ title: String) async -> (titleEnglish: String, titleLocal: String, titleOriginal: String?) {
        // Detect original language
        let originalLanguage = TextTranslationService.detectLanguage(title)
        let originalLanguageCode = originalLanguage?.rawValue ?? ""
        let isOriginalEnglish = TextTranslationService.isEnglish(title)
        
        // First, ensure we have English title
        let englishTitle: String
        if isOriginalEnglish {
            englishTitle = Self.capitalizeTitle(title)
        } else {
            // Translate to English
            let translated = await TextTranslationService.translateToEnglish(title)
            englishTitle = Self.capitalizeTitle(translated)
        }
        
        // Get user's system language
        let selectedLanguage = LocalizationManager.shared.currentLanguage
        let systemLanguageCode: String
        
        switch selectedLanguage {
        case .english:
            systemLanguageCode = "en"
        case .system:
            // Get system language code
            if let preferredLanguage = Locale.preferredLanguages.first {
                systemLanguageCode = normalizeChineseLanguageCode(preferredLanguage)
            } else {
                systemLanguageCode = "en"
            }
        default:
            systemLanguageCode = selectedLanguage.rawValue
        }
        
        // Translate to system language (if not English)
        var localTitle = englishTitle
        if systemLanguageCode.lowercased() != "en" && !systemLanguageCode.lowercased().hasPrefix("en-") {
            do {
                let translated = try await OpenAIService.translateFromEnglish(englishTitle, to: systemLanguageCode)
                localTitle = Self.capitalizeTitle(translated)
            } catch {
                print("⚠️ Failed to translate title to \(systemLanguageCode): \(error.localizedDescription)")
                // Fallback to English if translation fails
                localTitle = englishTitle
            }
        }
        
        // Determine original title
        // Only save original if it's different from both English and system language
        var titleOriginal: String? = nil
        if !isOriginalEnglish {
            // Original is not English
            let normalizedOriginal = normalizeChineseLanguageCode(originalLanguageCode)
            let normalizedSystem = normalizeChineseLanguageCode(systemLanguageCode)
            
            // Save original if it's different from both English and system language
            if normalizedOriginal.lowercased() != "en" && 
               !normalizedOriginal.lowercased().hasPrefix("en-") &&
               normalizedOriginal.lowercased() != normalizedSystem.lowercased() &&
               !normalizedOriginal.lowercased().hasPrefix(normalizedSystem.lowercased()) {
                titleOriginal = Self.capitalizeTitle(title)
            }
        }
        
        return (titleEnglish: englishTitle, titleLocal: localTitle, titleOriginal: titleOriginal)
    }
    
    /// Normalize Chinese language codes to zh-Hans or zh-Hant
    private static func normalizeChineseLanguageCode(_ code: String) -> String {
        let lowercased = code.lowercased()
        
        // Traditional Chinese regions
        if lowercased.hasPrefix("zh-hk") || 
           lowercased.contains("-hk") || 
           lowercased.contains("_hk") ||
           lowercased.hasPrefix("zh-tw") || 
           lowercased.contains("-tw") || 
           lowercased.contains("_tw") ||
           lowercased.hasPrefix("zh-mo") || 
           lowercased.contains("-mo") || 
           lowercased.contains("_mo") ||
           lowercased == "zh-hant" ||
           lowercased.hasPrefix("zh-hant") {
            return "zh-Hant"
        }
        
        // Simplified Chinese regions
        if lowercased.hasPrefix("zh-cn") || 
           lowercased.contains("-cn") || 
           lowercased.contains("_cn") ||
           lowercased.hasPrefix("zh-sg") || 
           lowercased.contains("-sg") || 
           lowercased.contains("_sg") ||
           lowercased == "zh-hans" ||
           lowercased.hasPrefix("zh-hans") {
            return "zh-Hans"
        }
        
        // If it's just "zh" without variant, default to Simplified
        if lowercased == "zh" {
            return "zh-Hans"
        }
        
        return code
    }
    
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
    ///   - garnishIngredients: Garnish / finish ingredients
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
        garnishIngredients: [RecipeTextParser.IngredientItem] = [],
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
        garnishIngredients: [RecipeTextParser.IngredientItem],
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
            return (title, description, dishIngredients, marinadeIngredients, seasoningIngredients, batterIngredients, sauceIngredients, baseIngredients, doughIngredients, toppingIngredients, garnishIngredients, instructions, tips, cuisine)
        case .system:
            // Get system language code (preserve full code including variants like zh-Hant, zh-Hans)
            if let preferredLanguage = Locale.preferredLanguages.first {
                // Normalize Chinese regional variants to zh-Hans or zh-Hant
                targetLanguageCode = normalizeChineseLanguageCode(preferredLanguage)
            } else {
                return (title, description, dishIngredients, marinadeIngredients, seasoningIngredients, batterIngredients, sauceIngredients, baseIngredients, doughIngredients, toppingIngredients, garnishIngredients, instructions, tips, cuisine)
            }
        default:
            // Use the language code from the enum
            targetLanguageCode = selectedLanguage.rawValue
        }
        
        // Don't translate if target is English
        if targetLanguageCode.lowercased() == "en" || targetLanguageCode.lowercased().hasPrefix("en-") {
            return (title, description, dishIngredients, marinadeIngredients, seasoningIngredients, batterIngredients, sauceIngredients, baseIngredients, doughIngredients, toppingIngredients, garnishIngredients, instructions, tips, cuisine)
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
                let translated = try await OpenAIService.translateFromEnglish(title, to: targetLanguageCode)
                translatedTitle = Self.capitalizeTitle(translated)
                print("✅ Translated title")
            } catch {
                print("⚠️ Failed to translate title: \(error.localizedDescription)")
                // Fallback to capitalized original title
                translatedTitle = Self.capitalizeTitle(title)
            }
        } else {
            translatedTitle = Self.capitalizeTitle(title)
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
        let translatedGarnishIngredients = await translateIngredients(garnishIngredients)
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
        
        return (translatedTitle, translatedDescription, translatedDishIngredients, translatedMarinadeIngredients, translatedSeasoningIngredients, translatedBatterIngredients, translatedSauceIngredients, translatedBaseIngredients, translatedDoughIngredients, translatedToppingIngredients, translatedGarnishIngredients, translatedInstructions, translatedTips, translatedCuisine)
    }
}


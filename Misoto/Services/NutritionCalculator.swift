//
//  NutritionCalculator.swift
//  Misoto
//
//  Created by Daniel Chan on 14.02.2026.
//
//  Calculates accurate nutritional values for a recipe by:
//  1. Looking up each ingredient in the USDA FoodData Central database
//  2. Converting recipe amounts to grams
//  3. Calculating per-ingredient nutrition contribution
//  4. Summing and dividing by servings
//  Falls back to AI estimation for ingredients not found in USDA.
//

import Foundation

class NutritionCalculator {
    
    private let usdaService = USDANutritionService.shared
    
    struct IngredientResult {
        let name: String
        let weightInGrams: Double
        let nutrients: NutrientsPer100g?
        let source: Source
        
        enum Source {
            case usda
            case fallback
        }
    }
    
    // MARK: - Public API
    
    /// Calculate nutrition for a full recipe using USDA data.
    /// Returns nil if too many ingredients fail to resolve.
    func calculateNutrition(
        title: String,
        ingredients: [Ingredient],
        servings: Int
    ) async -> NutritionInfo? {
        guard !ingredients.isEmpty, servings > 0 else { return nil }
        
        print("🍽️ ===== NUTRITION CALCULATION START =====")
        print("🍽️ Recipe: \(title) | \(ingredients.count) ingredients | \(servings) servings")
        
        var totalCalories: Double = 0
        var totalProtein: Double = 0
        var totalCarbs: Double = 0
        var totalFat: Double = 0
        var totalSatFat: Double = 0
        var totalFiber: Double = 0
        var totalSugar: Double = 0
        var totalSodium: Double = 0
        
        var resolvedCount = 0
        var failedIngredients: [Ingredient] = []
        
        for ingredient in ingredients {
            // 1. Look up nutrition per 100g from USDA
            let searchName = ingredient.canonicalId != nil
                ? ingredient.name  // Use the display name
                : ingredient.name
            
            guard let nutrients = await usdaService.lookupNutrition(for: searchName) else {
                failedIngredients.append(ingredient)
                continue
            }
            
            // 2. Convert the ingredient amount to grams
            guard let grams = convertToGrams(
                amount: ingredient.amount,
                unit: ingredient.unit,
                ingredientName: ingredient.name,
                foodMeasures: nutrients.foodMeasures
            ), grams > 0 else {
                print("⚠️ Could not convert '\(ingredient.amount) \(ingredient.unit) \(ingredient.name)' to grams")
                failedIngredients.append(ingredient)
                continue
            }
            
            // 3. Calculate nutrition contribution: (grams / 100) × per100g
            let factor = grams / 100.0
            totalCalories += nutrients.calories * factor
            totalProtein += nutrients.protein * factor
            totalCarbs += nutrients.carbohydrates * factor
            totalFat += nutrients.fat * factor
            totalSatFat += nutrients.saturatedFat * factor
            totalFiber += nutrients.fiber * factor
            totalSugar += nutrients.sugar * factor
            totalSodium += nutrients.sodium * factor
            
            resolvedCount += 1
            print("📊 \(ingredient.name): \(String(format: "%.0f", grams))g → \(String(format: "%.0f", nutrients.calories * factor)) kcal")
        }
        
        // If we couldn't resolve any ingredients, fall back entirely to AI
        if resolvedCount == 0 {
            print("⚠️ USDA resolved 0/\(ingredients.count) ingredients, falling back to AI")
            return nil
        }
        
        // If some ingredients failed, use AI to estimate just those
        if !failedIngredients.isEmpty {
            print("ℹ️ USDA resolved \(resolvedCount)/\(ingredients.count), estimating \(failedIngredients.count) via AI")
            
            if let aiPartial = try? await OpenAIService.estimateNutritionForSubset(
                title: title,
                ingredients: failedIngredients,
                totalServings: servings
            ) {
                // AI returns per-serving values for the subset, multiply back by servings to get totals
                totalCalories += Double(aiPartial.calories) * Double(servings)
                totalProtein += aiPartial.protein * Double(servings)
                totalCarbs += aiPartial.carbohydrates * Double(servings)
                totalFat += aiPartial.fat * Double(servings)
                totalSatFat += aiPartial.saturatedFat * Double(servings)
                totalFiber += aiPartial.fiber * Double(servings)
                totalSugar += aiPartial.sugar * Double(servings)
                totalSodium += Double(aiPartial.sodium) * Double(servings)
            }
        }
        
        // 4. Divide by servings
        let s = Double(servings)
        let result = NutritionInfo(
            calories: Int(round(totalCalories / s)),
            protein: round((totalProtein / s) * 10) / 10,
            carbohydrates: round((totalCarbs / s) * 10) / 10,
            fat: round((totalFat / s) * 10) / 10,
            saturatedFat: round((totalSatFat / s) * 10) / 10,
            fiber: round((totalFiber / s) * 10) / 10,
            sugar: round((totalSugar / s) * 10) / 10,
            sodium: Int(round(totalSodium / s))
        )
        
        print("🍽️ ===== NUTRITION CALCULATION RESULT =====")
        print("🍽️ Total recipe: \(Int(totalCalories)) kcal | P: \(String(format: "%.1f", totalProtein))g | C: \(String(format: "%.1f", totalCarbs))g | F: \(String(format: "%.1f", totalFat))g")
        print("🍽️ Per serving (÷\(servings)): \(result.calories) kcal | P: \(result.protein)g | C: \(result.carbohydrates)g | F: \(result.fat)g")
        print("🍽️ Resolved: \(resolvedCount)/\(ingredients.count) via USDA, \(failedIngredients.count) via AI fallback")
        print("🍽️ ==========================================")
        
        return result
    }
    
    // MARK: - Unit Conversion
    
    /// Convert an ingredient amount + unit to grams.
    /// Uses USDA food measures when available, otherwise standard conversions.
    func convertToGrams(
        amount: String,
        unit: String,
        ingredientName: String,
        foodMeasures: [USDAFoodMeasure]
    ) -> Double? {
        // Parse the amount string to a number
        guard let numericAmount = parseAmount(amount) else {
            // "to taste", "a pinch", empty → use small default
            if amount.isEmpty || amount.lowercased().contains("taste") || amount.lowercased().contains("pinch") {
                return 2.0 // ~2g default for seasoning
            }
            return nil
        }
        
        let unitLower = unit.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Direct weight units → no conversion needed
        switch unitLower {
        case "g", "gram", "grams":
            return numericAmount
        case "kg", "kilogram", "kilograms":
            return numericAmount * 1000
        case "oz", "ounce", "ounces":
            return numericAmount * 28.3495
        case "lb", "lbs", "pound", "pounds":
            return numericAmount * 453.592
        default:
            break
        }
        
        // Volume units → try USDA food measures first for ingredient-specific conversion
        if let gramWeight = matchFoodMeasure(unit: unitLower, measures: foodMeasures) {
            return numericAmount * gramWeight
        }
        
        // Fallback: standard volume-to-gram conversions (using water density as baseline)
        switch unitLower {
        case "ml", "milliliter", "milliliters":
            return numericAmount * densityFactor(for: ingredientName)
        case "l", "liter", "liters", "litre", "litres":
            return numericAmount * 1000 * densityFactor(for: ingredientName)
        case "cup", "cups":
            return numericAmount * cupToGrams(for: ingredientName)
        case "tbsp", "tablespoon", "tablespoons", "el", "ess", "esslöffel":
            return numericAmount * tbspToGrams(for: ingredientName)
        case "tsp", "teaspoon", "teaspoons", "tl", "teelöffel":
            return numericAmount * tspToGrams(for: ingredientName)
        case "piece", "pieces", "pcs", "stück", "stk":
            return numericAmount * pieceToGrams(for: ingredientName)
        case "clove", "cloves":
            return numericAmount * 3.0 // garlic clove ≈ 3g
        case "slice", "slices":
            return numericAmount * 25.0 // bread slice ≈ 25g
        case "bunch", "bunches":
            return numericAmount * 30.0 // herb bunch ≈ 30g
        case "can", "cans":
            return numericAmount * 400.0 // standard can ≈ 400g
        case "handful":
            return numericAmount * 30.0
        case "dash":
            return numericAmount * 0.6
        case "pinch":
            return numericAmount * 0.3
        case "":
            // No unit specified — likely "1 egg", "2 onions"
            return numericAmount * pieceToGrams(for: ingredientName)
        default:
            // Unknown unit — try treating as pieces
            return numericAmount * pieceToGrams(for: ingredientName)
        }
    }
    
    // MARK: - Amount Parsing
    
    /// Parse amount strings like "1", "1.5", "1/2", "1 1/2", "½"
    private func parseAmount(_ amount: String) -> Double? {
        let trimmed = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        // Replace Unicode fractions
        var cleaned = trimmed
            .replacingOccurrences(of: "½", with: "0.5")
            .replacingOccurrences(of: "⅓", with: "0.333")
            .replacingOccurrences(of: "⅔", with: "0.667")
            .replacingOccurrences(of: "¼", with: "0.25")
            .replacingOccurrences(of: "¾", with: "0.75")
            .replacingOccurrences(of: "⅛", with: "0.125")
        
        // Try direct parse
        if let value = Double(cleaned) {
            return value
        }
        
        // Handle fractions like "1/2", "3/4"
        if cleaned.contains("/") {
            let parts = cleaned.split(separator: " ")
            if parts.count == 2, let whole = Double(parts[0]) {
                // "1 1/2" format
                if let frac = parseFraction(String(parts[1])) {
                    return whole + frac
                }
            } else if parts.count == 1 {
                return parseFraction(cleaned)
            }
        }
        
        // Handle comma decimal (European: "1,5")
        cleaned = cleaned.replacingOccurrences(of: ",", with: ".")
        return Double(cleaned)
    }
    
    private func parseFraction(_ str: String) -> Double? {
        let parts = str.split(separator: "/")
        guard parts.count == 2,
              let num = Double(parts[0]),
              let den = Double(parts[1]),
              den != 0 else { return nil }
        return num / den
    }
    
    // MARK: - Food Measure Matching
    
    /// Try to find a matching USDA food measure for the given unit
    private func matchFoodMeasure(unit: String, measures: [USDAFoodMeasure]) -> Double? {
        let unitLower = unit.lowercased()
        
        for measure in measures {
            guard let gramWeight = measure.gramWeight, gramWeight > 0 else { continue }
            
            let measureText = (measure.disseminationText ?? "").lowercased()
            let measureUnit = (measure.measureUnitName ?? "").lowercased()
            let measureAbbr = (measure.measureUnitAbbreviation ?? "").lowercased()
            
            // Match unit name against measure
            if measureUnit == unitLower || measureAbbr == unitLower {
                return gramWeight
            }
            
            // Match common patterns in disseminationText
            if unitLower == "cup" || unitLower == "cups" {
                if measureText.contains("cup") { return gramWeight }
            }
            if unitLower == "tbsp" || unitLower == "tablespoon" || unitLower == "tablespoons" {
                if measureText.contains("tbsp") || measureText.contains("tablespoon") { return gramWeight }
            }
            if unitLower == "tsp" || unitLower == "teaspoon" || unitLower == "teaspoons" {
                if measureText.contains("tsp") || measureText.contains("teaspoon") { return gramWeight }
            }
        }
        
        return nil
    }
    
    // MARK: - Ingredient-Specific Conversions
    
    /// Density factor for ml → g conversion (most liquids ≈ 1.0)
    private func densityFactor(for name: String) -> Double {
        let lower = name.lowercased()
        if lower.contains("oil") || lower.contains("öl") { return 0.92 }
        if lower.contains("honey") || lower.contains("honig") { return 1.42 }
        if lower.contains("syrup") || lower.contains("sirup") { return 1.33 }
        if lower.contains("cream") || lower.contains("sahne") { return 1.01 }
        return 1.0  // water, milk, broth, etc.
    }
    
    /// Cup to grams conversion for common ingredients
    private func cupToGrams(for name: String) -> Double {
        let lower = name.lowercased()
        
        // Flours
        if lower.contains("flour") || lower.contains("mehl") { return 125 }
        // Sugars
        if lower.contains("sugar") || lower.contains("zucker") {
            if lower.contains("powdered") || lower.contains("icing") || lower.contains("puder") { return 120 }
            if lower.contains("brown") || lower.contains("braun") { return 220 }
            return 200
        }
        // Rice
        if lower.contains("rice") || lower.contains("reis") { return 185 }
        // Oats
        if lower.contains("oat") || lower.contains("hafer") { return 80 }
        // Butter
        if lower.contains("butter") { return 227 }
        // Milk, yogurt, skyr
        if lower.contains("milk") || lower.contains("milch") || lower.contains("yogurt") ||
           lower.contains("joghurt") || lower.contains("skyr") { return 245 }
        // Cream
        if lower.contains("cream") || lower.contains("sahne") { return 240 }
        // Honey
        if lower.contains("honey") || lower.contains("honig") { return 340 }
        // Nuts
        if lower.contains("nut") || lower.contains("nuss") || lower.contains("nüsse") { return 140 }
        // Cheese (shredded)
        if lower.contains("cheese") || lower.contains("käse") { return 113 }
        // Water, broth, stock
        if lower.contains("water") || lower.contains("wasser") || lower.contains("broth") || lower.contains("brühe") || lower.contains("stock") { return 240 }
        // Oil
        if lower.contains("oil") || lower.contains("öl") { return 220 }
        
        return 240 // default: water-based
    }
    
    /// Tablespoon to grams
    private func tbspToGrams(for name: String) -> Double {
        let lower = name.lowercased()
        if lower.contains("oil") || lower.contains("öl") { return 13.5 }
        if lower.contains("butter") { return 14.2 }
        if lower.contains("sugar") || lower.contains("zucker") { return 12.5 }
        if lower.contains("flour") || lower.contains("mehl") { return 8 }
        if lower.contains("honey") || lower.contains("honig") { return 21 }
        if lower.contains("soy sauce") || lower.contains("sojasauce") { return 18 }
        if lower.contains("fish sauce") { return 18 }
        if lower.contains("salt") || lower.contains("salz") { return 18 }
        return 15 // default
    }
    
    /// Teaspoon to grams
    private func tspToGrams(for name: String) -> Double {
        let lower = name.lowercased()
        if lower.contains("salt") || lower.contains("salz") { return 6 }
        if lower.contains("sugar") || lower.contains("zucker") { return 4.2 }
        if lower.contains("oil") || lower.contains("öl") { return 4.5 }
        if lower.contains("baking powder") || lower.contains("backpulver") { return 4 }
        if lower.contains("baking soda") || lower.contains("natron") { return 4.6 }
        if lower.contains("vanilla") || lower.contains("vanille") { return 4.2 }
        if lower.contains("cinnamon") || lower.contains("zimt") { return 2.6 }
        return 5 // default
    }
    
    /// Piece/whole to grams for common produce and proteins
    private func pieceToGrams(for name: String) -> Double {
        let lower = name.lowercased()
        
        // Eggs
        if lower.contains("egg") || lower.contains("ei") { return 50 }
        // Poultry
        if lower.contains("chicken breast") || lower.contains("hähnchenbrust") { return 170 }
        if lower.contains("chicken thigh") || lower.contains("hähnchenkeule") { return 115 }
        // Produce
        if lower.contains("onion") || lower.contains("zwiebel") { return 150 }
        if lower.contains("garlic") || lower.contains("knoblauch") { return 3 } // single clove
        if lower.contains("tomato") || lower.contains("tomate") { return 120 }
        if lower.contains("potato") || lower.contains("kartoffel") { return 150 }
        if lower.contains("carrot") || lower.contains("karotte") || lower.contains("möhre") { return 75 }
        if lower.contains("pepper") || lower.contains("paprika") { return 120 }
        if lower.contains("lemon") || lower.contains("zitrone") { return 60 }
        if lower.contains("lime") || lower.contains("limette") { return 45 }
        if lower.contains("orange") { return 130 }
        if lower.contains("apple") || lower.contains("apfel") { return 180 }
        if lower.contains("banana") || lower.contains("banane") { return 120 }
        if lower.contains("avocado") { return 150 }
        if lower.contains("cucumber") || lower.contains("gurke") { return 200 }
        if lower.contains("zucchini") { return 200 }
        
        return 100 // generic default
    }
}

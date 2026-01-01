//
//  ExtractMenuFromImageViewModel.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine
import FirebaseAuth
import UIKit

@MainActor
class ExtractMenuFromImageViewModel: ObservableObject {
    @Published var extractedText: String = ""
    @Published var parsedRecipe: RecipeTextParser.ParsedRecipe?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showEditRecipe = false
    @Published var isGeneratingDescription = false
    @Published var isDetectingCuisine = false
    @Published var isExtractingTime = false
    @Published var isDetectingDifficulty = false
    
    // Cost optimization settings
    // Use cost-optimized extraction (iOS OCR + on-device parsing + optional OpenAI refinement)
    // Set to false to use direct OpenAI Vision API (more expensive but potentially better quality)
    private var useCostOptimizedExtraction: Bool {
        // Default to true for cost savings, can be made configurable via UserDefaults
        return UserDefaults.standard.bool(forKey: "useCostOptimizedExtraction") != false // Default to true
    }
    
    private var useOpenAIRefinement: Bool {
        // Default to true to refine on-device parsed results with OpenAI (still cheaper than sending images)
        return UserDefaults.standard.bool(forKey: "useOpenAIRefinement") != false // Default to true
    }
    
    private let costOptimizedExtractor = CostOptimizedRecipeExtractor()
    
    // Recipe fields for editing
    @Published var title = ""
    @Published var description = ""
    @Published var cuisine: String? = nil
    @Published var prepTime: Int = 15
    @Published var cookTime: Int = 30
    @Published var servings: Int = 4
    @Published var difficulty: Recipe.Difficulty = .c
    @Published var spicyLevel: Recipe.SpicyLevel = .none
    @Published var tips: [String] = []
    @Published var marinadeIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var seasoningIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var dishIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var batterIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var sauceIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var baseIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var doughIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var toppingIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var instructions: [InstructionItem] = []
    @Published var mainRecipeImages: [UIImage] = [] // Up to 5 images for the recipe
    private var sourceImages: [UIImage] = [] // Source images used for extraction
    
    struct InstructionItem: Identifiable {
        var id = UUID()
        var text: String = ""
        var image: UIImage?
        var videoURL: URL?
        
        func toInstruction() -> Instruction {
            return Instruction(text: text)
        }
    }
    
    // Combined accessor for backward compatibility
    var allIngredientItems: [RecipeTextParser.IngredientItem] {
        return marinadeIngredients + seasoningIngredients + dishIngredients + batterIngredients + sauceIngredients + baseIngredients + doughIngredients + toppingIngredients
    }
    
    // MARK: - Ingredient Management (Batter and Sauce only - other methods defined later)
    
    func addBatterIngredient() {
        batterIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func removeBatterIngredient(at index: Int) {
        guard index >= 0 && index < batterIngredients.count else { return }
        batterIngredients.remove(at: index)
    }
    
    func updateBatterIngredientAmount(_ amount: String, at index: Int) {
        guard index >= 0 && index < batterIngredients.count else { return }
        batterIngredients[index].amount = amount
    }
    
    func updateBatterIngredientUnit(_ unit: String, at index: Int) {
        guard index >= 0 && index < batterIngredients.count else { return }
        batterIngredients[index].unit = unit
    }
    
    func updateBatterIngredientName(_ name: String, at index: Int) {
        guard index >= 0 && index < batterIngredients.count else { return }
        batterIngredients[index].name = name
    }
    
    func addSauceIngredient() {
        sauceIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func removeSauceIngredient(at index: Int) {
        guard index >= 0 && index < sauceIngredients.count else { return }
        sauceIngredients.remove(at: index)
    }
    
    func updateSauceIngredientAmount(_ amount: String, at index: Int) {
        guard index >= 0 && index < sauceIngredients.count else { return }
        sauceIngredients[index].amount = amount
    }
    
    func updateSauceIngredientUnit(_ unit: String, at index: Int) {
        guard index >= 0 && index < sauceIngredients.count else { return }
        sauceIngredients[index].unit = unit
    }
    
    func updateSauceIngredientName(_ name: String, at index: Int) {
        guard index >= 0 && index < sauceIngredients.count else { return }
        sauceIngredients[index].name = name
    }
    
    func addBaseIngredient() {
        baseIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func removeBaseIngredient(at index: Int) {
        guard index >= 0 && index < baseIngredients.count else { return }
        baseIngredients.remove(at: index)
    }
    
    func updateBaseIngredientAmount(_ amount: String, at index: Int) {
        guard index >= 0 && index < baseIngredients.count else { return }
        let convertedAmount = convertFractionToDecimal(amount)
        baseIngredients[index].amount = convertedAmount
    }
    
    func updateBaseIngredientUnit(_ unit: String, at index: Int) {
        guard index >= 0 && index < baseIngredients.count else { return }
        baseIngredients[index].unit = unit
    }
    
    func updateBaseIngredientName(_ name: String, at index: Int) {
        guard index >= 0 && index < baseIngredients.count else { return }
        baseIngredients[index].name = name
    }
    
    func addDoughIngredient() {
        doughIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func removeDoughIngredient(at index: Int) {
        guard index >= 0 && index < doughIngredients.count else { return }
        doughIngredients.remove(at: index)
    }
    
    func updateDoughIngredientAmount(_ amount: String, at index: Int) {
        guard index >= 0 && index < doughIngredients.count else { return }
        let convertedAmount = convertFractionToDecimal(amount)
        doughIngredients[index].amount = convertedAmount
    }
    
    func updateDoughIngredientUnit(_ unit: String, at index: Int) {
        guard index >= 0 && index < doughIngredients.count else { return }
        doughIngredients[index].unit = unit
    }
    
    func updateDoughIngredientName(_ name: String, at index: Int) {
        guard index >= 0 && index < doughIngredients.count else { return }
        doughIngredients[index].name = name
    }
    
    func addToppingIngredient() {
        toppingIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func removeToppingIngredient(at index: Int) {
        guard index >= 0 && index < toppingIngredients.count else { return }
        toppingIngredients.remove(at: index)
    }
    
    func updateToppingIngredientAmount(_ amount: String, at index: Int) {
        guard index >= 0 && index < toppingIngredients.count else { return }
        let convertedAmount = convertFractionToDecimal(amount)
        toppingIngredients[index].amount = convertedAmount
    }
    
    func updateToppingIngredientUnit(_ unit: String, at index: Int) {
        guard index >= 0 && index < toppingIngredients.count else { return }
        toppingIngredients[index].unit = unit
    }
    
    func updateToppingIngredientName(_ name: String, at index: Int) {
        guard index >= 0 && index < toppingIngredients.count else { return }
        toppingIngredients[index].name = name
    }
    
    // Helper to parse ingredient string (expose parser method)
    private func parseIngredient(_ ingredient: String) -> RecipeTextParser.IngredientItem {
        // Parse it manually here
        return parseIngredientString(ingredient)
    }
    
    private func parseIngredientString(_ ingredient: String) -> RecipeTextParser.IngredientItem {
        let cleaned = ingredient.trimmingCharacters(in: .whitespaces)
        let units = ["tsp", "tbsp", "tablespoon", "teaspoon", "cup", "cups", "oz", "ounce", "ounces", "lb", "pound", "pounds", "g", "gram", "grams", "kg", "kilogram", "kilograms", "ml", "milliliter", "milliliters", "l", "liter", "liters", "pinch", "pinches", "dash", "dashes", "piece", "pieces", "pcs", "pc", "slice", "slices", "clove", "cloves", "bunch", "bunches", "head", "heads"]
        
        // Try pattern: "1 1/2 tsp ingredient" or "12 pieces ingredient"
        let fullPattern = "^(\\d+(?:\\s+\\d+/\\d+)?)\\s+(\(units.joined(separator: "|")))\\s+(.+)$"
        if let regex = try? NSRegularExpression(pattern: fullPattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count)),
           match.numberOfRanges >= 4,
           let amountRange = Range(match.range(at: 1), in: cleaned),
           let unitRange = Range(match.range(at: 2), in: cleaned),
           let nameRange = Range(match.range(at: 3), in: cleaned) {
            
            let amount = String(cleaned[amountRange]).trimmingCharacters(in: .whitespaces)
            let unit = String(cleaned[unitRange]).trimmingCharacters(in: .whitespaces).lowercased()
            let name = String(cleaned[nameRange]).trimmingCharacters(in: .whitespaces)
            
            return RecipeTextParser.IngredientItem(amount: amount, unit: unit, name: name)
        }
        
        // Try pattern: just amount + ingredient name (no unit)
        let amountPattern = "^(\\d+(?:\\s+\\d+/\\d+)?)\\s+(.+)$"
        if let regex = try? NSRegularExpression(pattern: amountPattern, options: []),
           let match = regex.firstMatch(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count)),
           match.numberOfRanges >= 3,
           let amountRange = Range(match.range(at: 1), in: cleaned),
           let nameRange = Range(match.range(at: 2), in: cleaned) {
            
            let amount = String(cleaned[amountRange]).trimmingCharacters(in: .whitespaces)
            var name = String(cleaned[nameRange]).trimmingCharacters(in: .whitespaces)
            
            // Check if the name starts with a unit
            let words = name.components(separatedBy: .whitespaces)
            if let firstWord = words.first?.lowercased(), units.contains(firstWord) {
                let unit = firstWord
                name = words.dropFirst().joined(separator: " ")
                return RecipeTextParser.IngredientItem(amount: amount, unit: unit, name: name)
            }
            
            return RecipeTextParser.IngredientItem(amount: amount, unit: "", name: name)
        }
        
        // No amount or unit, just the ingredient name
        return RecipeTextParser.IngredientItem(amount: "", unit: "", name: cleaned)
    }
    
    private let recipeService = RecipeService()
    private let storageService = StorageService()
    
    /// Extract recipe from image using OpenAI
    func extractText(from image: UIImage) async {
        await extractText(from: [image])
    }
    
    /// Extract recipe from multiple images using OpenAI
    func extractText(from images: [UIImage]) async {
        isLoading = true
        errorMessage = nil
        extractedText = ""
        parsedRecipe = nil
        
        guard !images.isEmpty else {
            errorMessage = LocalizedString("Please select at least one image", comment: "No image selected error")
            isLoading = false
            return
        }
        
        // Store source images for later saving
        sourceImages = images
        
        do {
            let response: OpenAIRecipeResponse
            
            if useCostOptimizedExtraction {
                // Cost-optimized approach: iOS OCR -> on-device parsing -> optional OpenAI refinement
                // This is MUCH cheaper than sending images to OpenAI Vision API
                response = try await costOptimizedExtractor.extractRecipe(
                    from: images,
                    useOpenAIRefinement: useOpenAIRefinement
                )
            } else {
                // Direct OpenAI Vision API approach (more expensive but potentially better quality)
                response = try await OpenAIService.extractRecipe(from: images)
            }
            
            // Step 4: Translate recipe to user's selected language
            print("🌍 Translating extracted recipe to user's selected language...")
            let translated = await RecipeTranslationService.translateRecipe(
                title: response.title,
                description: response.description,
                dishIngredients: response.dishIngredients,
                marinadeIngredients: response.marinadeIngredients,
                seasoningIngredients: response.seasoningIngredients,
                batterIngredients: response.batterIngredients,
                sauceIngredients: response.sauceIngredients,
                baseIngredients: response.baseIngredients,
                doughIngredients: response.doughIngredients,
                toppingIngredients: response.toppingIngredients,
                instructions: response.instructions,
                tips: response.tips.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
                cuisine: nil // Will be detected later
            )
            
            // Populate editable fields with translated content
            title = translated.title
            description = translated.description
            dishIngredients = translated.dishIngredients.isEmpty ? [RecipeTextParser.IngredientItem(amount: "", unit: "", name: "")] : translated.dishIngredients
            marinadeIngredients = translated.marinadeIngredients
            seasoningIngredients = translated.seasoningIngredients
            batterIngredients = translated.batterIngredients
            sauceIngredients = translated.sauceIngredients
            baseIngredients = translated.baseIngredients
            doughIngredients = translated.doughIngredients
            toppingIngredients = translated.toppingIngredients
            instructions = translated.instructions.isEmpty ? [InstructionItem()] : translated.instructions.map { InstructionItem(text: $0) }
            tips = translated.tips
            
            // Use extracted servings, prepTime, and cookTime if available (non-zero means found in image)
            if response.servings > 0 {
                servings = response.servings
            }
            if response.prepTime > 0 {
                prepTime = response.prepTime
            }
            if response.cookTime > 0 {
                cookTime = response.cookTime
            }
            
            // Auto-generate description, auto-detect cuisine, extract time (if not already extracted), and detect difficulty after extraction
            // Small delay to ensure all fields are properly set
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            await generateDescription()
            await detectCuisine()
            // Only extract time if it wasn't already extracted from the image
            if response.prepTime == 0 && response.cookTime == 0 {
                await extractTime()
            }
            await detectDifficulty()
            
            showEditRecipe = true
            isLoading = false
        } catch {
            isLoading = false
            if let openAIError = error as? OpenAIError {
                errorMessage = openAIError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func saveRecipe(image: UIImage? = nil) async -> Bool {
        guard let userID = Auth.auth().currentUser?.uid,
              let displayName = Auth.auth().currentUser?.displayName else {
            errorMessage = LocalizedString("You must be logged in to save a recipe", comment: "Not logged in error")
            return false
        }
        
        // Get username from AuthService (ensure user data is loaded)
        let authService = AuthService()
        await authService.reloadUserData()
        let username = authService.currentUser?.username
        
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = LocalizedString("Title is required", comment: "Title required error")
            return false
        }
        
        // Combine all ingredient types, filter out empty ones
        let validMarinadeItems = marinadeIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validSeasoningItems = seasoningIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validDishItems = dishIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validBatterItems = batterIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validSauceItems = sauceIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validBaseItems = baseIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validDoughItems = doughIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validToppingItems = toppingIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard !validDishItems.isEmpty else {
            errorMessage = LocalizedString("At least one dish ingredient is required", comment: "Dish ingredients required error")
            return false
        }
        
        // Convert ingredient items to Ingredient objects with IDs and categories
        var ingredientObjects: [Ingredient] = []
        
        // Add ingredients with their respective categories
        ingredientObjects.append(contentsOf: validDishItems.map { 
            Ingredient(amount: $0.amount, unit: $0.unit, name: $0.name, category: .dish) 
        })
        ingredientObjects.append(contentsOf: validMarinadeItems.map { 
            Ingredient(amount: $0.amount, unit: $0.unit, name: $0.name, category: .marinade) 
        })
        ingredientObjects.append(contentsOf: validSeasoningItems.map { 
            Ingredient(amount: $0.amount, unit: $0.unit, name: $0.name, category: .seasoning) 
        })
        ingredientObjects.append(contentsOf: validBatterItems.map { 
            Ingredient(amount: $0.amount, unit: $0.unit, name: $0.name, category: .batter) 
        })
        ingredientObjects.append(contentsOf: validSauceItems.map { 
            Ingredient(amount: $0.amount, unit: $0.unit, name: $0.name, category: .sauce) 
        })
        ingredientObjects.append(contentsOf: validBaseItems.map { 
            Ingredient(amount: $0.amount, unit: $0.unit, name: $0.name, category: .base) 
        })
        ingredientObjects.append(contentsOf: validDoughItems.map { 
            Ingredient(amount: $0.amount, unit: $0.unit, name: $0.name, category: .dough) 
        })
        ingredientObjects.append(contentsOf: validToppingItems.map { 
            Ingredient(amount: $0.amount, unit: $0.unit, name: $0.name, category: .topping) 
        })
        
        let validInstructions = instructions.filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !validInstructions.isEmpty else {
            errorMessage = LocalizedString("At least one instruction is required", comment: "Instructions required error")
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Upload all recipe images (up to 5)
            var allImageURLs: [String] = []
            for image in mainRecipeImages {
                let imagePath = "recipes/\(UUID().uuidString).jpg"
                if let url = try? await storageService.uploadImage(image, path: imagePath) {
                    allImageURLs.append(url)
                }
            }
            
            // Use first image URL for backward compatibility
            let mainImageURL = allImageURLs.first
            
            // Upload all source images
            var sourceImageURLs: [String] = []
            print("📸 Starting source image upload. Count: \(sourceImages.count)")
            for (index, sourceImage) in sourceImages.enumerated() {
                let sourceImagePath = "source-images/\(UUID().uuidString).jpg"
                do {
                    let url = try await storageService.uploadImage(sourceImage, path: sourceImagePath)
                    sourceImageURLs.append(url)
                    print("✅ Uploaded source image \(index + 1)/\(sourceImages.count): \(url)")
                } catch {
                    print("❌ Failed to upload source image \(index + 1)/\(sourceImages.count): \(error.localizedDescription)")
                    // Continue with other images even if one fails
                }
            }
            print("📸 Finished source image upload. Total URLs: \(sourceImageURLs.count)")
            
            // Convert instructions to Instruction objects (upload images/videos if present)
            var instructionObjects: [Instruction] = []
            for instructionItem in validInstructions {
                var imageURL: String? = nil
                var videoURL: String? = nil
                
                // Upload instruction image if present
                if let image = instructionItem.image {
                    let imagePath = "instructions/\(UUID().uuidString).jpg"
                    do {
                        imageURL = try await storageService.uploadImage(image, path: imagePath)
                    } catch {
                        print("Failed to upload instruction image: \(error.localizedDescription)")
                    }
                }
                
                // Store video URL if present (videos are already URLs)
                if let videoURLValue = instructionItem.videoURL {
                    videoURL = videoURLValue.absoluteString
                }
                
                let instruction = Instruction(
                    text: instructionItem.text.trimmingCharacters(in: .whitespaces),
                    imageURL: imageURL,
                    videoURL: videoURL
                )
                instructionObjects.append(instruction)
            }
            
            // Create recipe
            print("📝 Creating recipe with sourceImageURLs: \(sourceImageURLs)")
            let recipe = Recipe(
                title: title.trimmingCharacters(in: .whitespaces),
                description: description.trimmingCharacters(in: .whitespaces),
                ingredients: ingredientObjects,
                instructions: instructionObjects,
                prepTime: prepTime,
                cookTime: cookTime,
                servings: servings,
                difficulty: difficulty,
                spicyLevel: spicyLevel,
                tips: tips.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
                cuisine: cuisine?.trimmingCharacters(in: .whitespaces).isEmpty == false ? cuisine?.trimmingCharacters(in: .whitespaces) : nil,
                imageURL: mainImageURL, // For backward compatibility
                imageURLs: allImageURLs, // Array of all image URLs
                sourceImageURL: sourceImageURLs.first, // For backward compatibility
                sourceImageURLs: sourceImageURLs,
                authorID: userID,
                authorName: displayName,
                authorUsername: username
            )
            
            print("📝 Recipe created with sourceImageURLs count: \(recipe.sourceImageURLs.count)")
            try await recipeService.createRecipe(recipe)
            print("✅ Recipe saved to Firestore with sourceImageURLs: \(recipe.sourceImageURLs)")
            isLoading = false
            
            // Post notification to refresh account view
            NotificationCenter.default.post(name: NSNotification.Name("RecipeSaved"), object: nil)
            
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    // Convert fractions to decimal strings (e.g., "1/2" -> "0.5", "1 1/2" -> "1.5")
    private func convertFractionToDecimal(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        
        // Pattern: mixed number "1 1/2"
        let mixedPattern = "^\\s*(\\d+)\\s+(\\d+)/(\\d+)\\s*$"
        if let regex = try? NSRegularExpression(pattern: mixedPattern, options: []),
           let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count)),
           match.numberOfRanges >= 4,
           let wholeRange = Range(match.range(at: 1), in: trimmed),
           let numeratorRange = Range(match.range(at: 2), in: trimmed),
           let denominatorRange = Range(match.range(at: 3), in: trimmed),
           let whole = Double(String(trimmed[wholeRange])),
           let numerator = Double(String(trimmed[numeratorRange])),
           let denominator = Double(String(trimmed[denominatorRange])),
           denominator != 0 {
            let decimal = whole + (numerator / denominator)
            return formatDecimal(decimal)
        }
        
        // Pattern: simple fraction "1/2"
        let fractionPattern = "^\\s*(\\d+)/(\\d+)\\s*$"
        if let regex = try? NSRegularExpression(pattern: fractionPattern, options: []),
           let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count)),
           match.numberOfRanges >= 3,
           let numeratorRange = Range(match.range(at: 1), in: trimmed),
           let denominatorRange = Range(match.range(at: 2), in: trimmed),
           let numerator = Double(String(trimmed[numeratorRange])),
           let denominator = Double(String(trimmed[denominatorRange])),
           denominator != 0 {
            let decimal = numerator / denominator
            return formatDecimal(decimal)
        }
        
        // No fraction found, return original
        return trimmed
    }
    
    // Format decimal to remove unnecessary trailing zeros
    private func formatDecimal(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        
        // Format with up to 2 decimal places, then remove trailing zeros
        var formatted = String(format: "%.2f", value)
        while formatted.hasSuffix("0") && formatted.contains(".") {
            formatted = String(formatted.dropLast())
        }
        if formatted.hasSuffix(".") {
            formatted = String(formatted.dropLast())
        }
        return formatted
    }
    
    func addMarinadeIngredient() {
        marinadeIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func addSeasoningIngredient() {
        seasoningIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func addDishIngredient() {
        dishIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func removeMarinadeIngredient(at index: Int) {
        guard index >= 0 && index < marinadeIngredients.count else { return }
        marinadeIngredients.remove(at: index)
    }
    
    func removeSeasoningIngredient(at index: Int) {
        guard index >= 0 && index < seasoningIngredients.count else { return }
        seasoningIngredients.remove(at: index)
    }
    
    func removeDishIngredient(at index: Int) {
        guard index >= 0 && index < dishIngredients.count else { return }
        dishIngredients.remove(at: index)
    }
    
    func updateMarinadeIngredientAmount(_ amount: String, at index: Int) {
        guard index >= 0 && index < marinadeIngredients.count else { return }
        let convertedAmount = convertFractionToDecimal(amount)
        marinadeIngredients[index].amount = convertedAmount
    }
    
    func updateSeasoningIngredientAmount(_ amount: String, at index: Int) {
        guard index >= 0 && index < seasoningIngredients.count else { return }
        let convertedAmount = convertFractionToDecimal(amount)
        seasoningIngredients[index].amount = convertedAmount
    }
    
    func updateDishIngredientAmount(_ amount: String, at index: Int) {
        guard index >= 0 && index < dishIngredients.count else { return }
        let convertedAmount = convertFractionToDecimal(amount)
        dishIngredients[index].amount = convertedAmount
    }
    
    func updateMarinadeIngredientUnit(_ unit: String, at index: Int) {
        guard index >= 0 && index < marinadeIngredients.count else { return }
        marinadeIngredients[index].unit = unit
    }
    
    func updateSeasoningIngredientUnit(_ unit: String, at index: Int) {
        guard index >= 0 && index < seasoningIngredients.count else { return }
        seasoningIngredients[index].unit = unit
    }
    
    func updateDishIngredientUnit(_ unit: String, at index: Int) {
        guard index >= 0 && index < dishIngredients.count else { return }
        dishIngredients[index].unit = unit
    }
    
    func updateMarinadeIngredientName(_ name: String, at index: Int) {
        guard index >= 0 && index < marinadeIngredients.count else { return }
        marinadeIngredients[index].name = name
    }
    
    func updateSeasoningIngredientName(_ name: String, at index: Int) {
        guard index >= 0 && index < seasoningIngredients.count else { return }
        seasoningIngredients[index].name = name
    }
    
    func updateDishIngredientName(_ name: String, at index: Int) {
        guard index >= 0 && index < dishIngredients.count else { return }
        dishIngredients[index].name = name
    }
    
    // MARK: - Recipe Image Management
    
    func addRecipeImage(_ image: UIImage) {
        guard mainRecipeImages.count < 5 else { return }
        mainRecipeImages.append(image)
    }
    
    func removeRecipeImage(at index: Int) {
        guard index >= 0 && index < mainRecipeImages.count else { return }
        mainRecipeImages.remove(at: index)
    }
    
    // MARK: - AI Generation Methods
    
    /// Generate a description for the recipe using AI
    func generateDescription() async {
        guard !title.isEmpty else {
            errorMessage = LocalizedString("Please enter a recipe title first", comment: "Title required for description")
            return
        }
        
        isGeneratingDescription = true
        errorMessage = nil
        
        do {
            let allIngredients = (marinadeIngredients + seasoningIngredients + dishIngredients)
                .map { item in
                    if item.unit.isEmpty {
                        return item.amount.isEmpty ? item.name : "\(item.amount) \(item.name)"
                    } else {
                        return "\(item.amount) \(item.unit) \(item.name)"
                    }
                }
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            let generatedDescription = try await OpenAIService.generateRecipeDescription(
                title: title,
                ingredients: allIngredients,
                instructions: instructions.map { $0.text }.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            )
            
            if !generatedDescription.isEmpty {
                description = generatedDescription
            }
        } catch {
            errorMessage = LocalizedString("Failed to generate description: \(error.localizedDescription)", comment: "Description generation error")
        }
        
        isGeneratingDescription = false
    }
    
    /// Detect and set the most suitable cuisine for the recipe
    func detectCuisine() async {
        guard !title.isEmpty else {
            return
        }
        
        // Only detect if cuisine is not already set
        guard cuisine == nil || cuisine?.isEmpty == true else {
            return
        }
        
        isDetectingCuisine = true
        
        do {
            let allIngredients = (marinadeIngredients + seasoningIngredients + dishIngredients)
                .map { item in
                    if item.unit.isEmpty {
                        return item.amount.isEmpty ? item.name : "\(item.amount) \(item.name)"
                    } else {
                        return "\(item.amount) \(item.unit) \(item.name)"
                    }
                }
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            if let detectedCuisine = try await OpenAIService.detectCuisine(
                title: title,
                ingredients: allIngredients,
                instructions: instructions.map { $0.text }.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            ) {
                cuisine = detectedCuisine
            }
        } catch {
            // Silently fail for cuisine detection - it's not critical
            print("Failed to detect cuisine: \(error.localizedDescription)")
        }
        
        isDetectingCuisine = false
    }
    
    /// Extract preparation and cooking time from instructions
    func extractTime() async {
        guard !instructions.isEmpty else {
            return
        }
        
        isExtractingTime = true
        
        do {
            let (extractedPrepTime, extractedCookTime) = try await OpenAIService.extractTimeFromInstructions(
                title: title,
                instructions: instructions.map { $0.text }.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            )
            prepTime = extractedPrepTime
            cookTime = extractedCookTime
        } catch {
            // Silently fail for time extraction - use defaults
            print("Failed to extract time: \(error.localizedDescription)")
        }
        
        isExtractingTime = false
    }
    
    /// Detect and set the difficulty level for the recipe
    func detectDifficulty() async {
        guard !title.isEmpty else {
            return
        }
        
        isDetectingDifficulty = true
        
        do {
            let allIngredients = (marinadeIngredients + seasoningIngredients + dishIngredients)
                .map { item in
                    if item.unit.isEmpty {
                        return item.amount.isEmpty ? item.name : "\(item.amount) \(item.name)"
                    } else {
                        return "\(item.amount) \(item.unit) \(item.name)"
                    }
                }
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            let detectedDifficulty = try await OpenAIService.detectDifficulty(
                title: title,
                ingredients: allIngredients,
                instructions: instructions.map { $0.text }.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            )
            difficulty = detectedDifficulty
        } catch {
            // Silently fail for difficulty detection - use default
            print("Failed to detect difficulty: \(error.localizedDescription)")
        }
        
        isDetectingDifficulty = false
    }
    
    // MARK: - Instruction Management
    
    func addInstruction() {
        instructions.append(InstructionItem())
    }
    
    func removeInstruction(at index: Int) {
        guard instructions.count > 1 else { return }
        instructions.remove(at: index)
    }
    
    func moveInstruction(from source: IndexSet, to destination: Int) {
        // Manually implement move operation (since we can't use SwiftUI's move method in ViewModel)
        var items = instructions
        let sourceIndices = source.map { $0 }.sorted(by: >)
        
        // Remove items from source indices (in reverse order to maintain indices)
        var movedItems: [InstructionItem] = []
        for index in sourceIndices {
            movedItems.insert(items.remove(at: index), at: 0)
        }
        
        // Calculate new destination index after removals
        // Count how many source indices were before the destination
        let countBeforeDestination = sourceIndices.filter { $0 < destination }.count
        let adjustedDestination = max(0, destination - countBeforeDestination)
        
        // Insert items at new destination
        for (offset, item) in movedItems.enumerated() {
            let insertIndex = min(adjustedDestination + offset, items.count)
            items.insert(item, at: insertIndex)
        }
        
        instructions = items
    }
    
    func setInstructionImage(_ image: UIImage, at index: Int) {
        guard index < instructions.count else { return }
        instructions[index].image = image
    }
    
    func setInstructionVideo(_ videoURL: URL, at index: Int) {
        guard index < instructions.count else { return }
        instructions[index].videoURL = videoURL
    }
    
    func removeInstructionMedia(at index: Int) {
        guard index < instructions.count else { return }
        instructions[index].image = nil
        instructions[index].videoURL = nil
    }
}


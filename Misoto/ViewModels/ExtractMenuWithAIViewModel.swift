//
//  ExtractMenuWithAIViewModel.swift
//  Misoto
//
//  ViewModel for extracting recipes from images using OpenAI
//

import Foundation
import Combine
import FirebaseAuth
import UIKit

@MainActor
class ExtractMenuWithAIViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showEditRecipe = false
    @Published var showRegionalRestrictionAlert = false
    @Published var isGeneratingDescription = false
    @Published var isDetectingCuisine = false
    @Published var isExtractingTime = false
    @Published var isDetectingDifficulty = false
    
    // Recipe fields for editing
    @Published var title = ""
    @Published var originalExtractedTitle: String? = nil // Preserve original title before translation
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
    @Published var doughBatterFillingIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var sauceIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var toppingIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var garnishIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var instructions: [String] = []
    @Published var mainRecipeImages: [UIImage] = [] // Up to 5 images for the recipe
    private var sourceImage: UIImage? = nil // Source image used for extraction
    
    private let recipeService = RecipeService.shared
    private let storageService = StorageService()
    
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
    
    /// Check if an error is due to regional restrictions (OpenAI not available in region)
    private func isRegionalRestrictionError(_ error: Error) -> Bool {
        // Check for HTTP 403 (Forbidden) - typical for regional restrictions
        if let openAIError = error as? OpenAIError {
            switch openAIError {
            case .httpError(let statusCode):
                // HTTP 403 Forbidden typically indicates regional restrictions
                if statusCode == 403 {
                    return true
                }
            case .apiError(let message):
                // Check error message for regional restriction keywords
                let lowerMessage = message.lowercased()
                if lowerMessage.contains("region") || 
                   lowerMessage.contains("country") || 
                   lowerMessage.contains("not available") ||
                   lowerMessage.contains("forbidden") ||
                   lowerMessage.contains("blocked") ||
                   lowerMessage.contains("access denied") ||
                   lowerMessage.contains("not supported") ||
                   lowerMessage.contains("unavailable") {
                    return true
                }
            default:
                break
            }
        }
        
        // Check error message for regional restriction keywords (general error)
        let errorMessage = error.localizedDescription.lowercased()
        return errorMessage.contains("region") || 
               errorMessage.contains("country") || 
               errorMessage.contains("not available in your region") ||
               errorMessage.contains("forbidden") ||
               errorMessage.contains("403") ||
               errorMessage.contains("access denied") ||
               errorMessage.contains("not supported in your region")
    }
    
    /// Extract recipe from image using cost-optimized approach
    func extractRecipe(from image: UIImage) async {
        isLoading = true
        errorMessage = nil
        
        // Check AI image extraction limit for free tier users
        do {
            let canExtract = try await SubscriptionHelper.checkAIImageExtractionLimit()
            if !canExtract {
                errorMessage = LocalizedString("You have reached your free tier limit for AI image extractions", comment: "AI image extraction limit error") + "\n" + LocalizedString("Upgrade to Premium for unlimited AI image extractions", comment: "Upgrade prompt")
                isLoading = false
                return
            }
        } catch {
            print("⚠️ Error checking AI extraction limit: \(error.localizedDescription)")
            // Continue anyway - don't block user if check fails
        }
        
        // Store source image for later saving
        sourceImage = image
        
        do {
            let response: OpenAIRecipeResponse
            
            if useCostOptimizedExtraction {
                // Cost-optimized approach: iOS OCR -> on-device parsing -> optional OpenAI refinement
                // This is MUCH cheaper than sending images to OpenAI Vision API
                response = try await costOptimizedExtractor.extractRecipe(
                    from: [image],
                    useOpenAIRefinement: useOpenAIRefinement
                )
            } else {
                // Direct OpenAI Vision API approach (more expensive but potentially better quality)
                response = try await OpenAIService.extractRecipe(from: image)
            }
            
            // Preserve original title before translation
            originalExtractedTitle = response.title
            
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
            
            // Populate fields with translated content (already capitalized by RecipeTranslationService)
            title = translated.title
            description = translated.description
            dishIngredients = translated.dishIngredients.isEmpty ? [RecipeTextParser.IngredientItem(amount: "", unit: "", name: "")] : translated.dishIngredients
            marinadeIngredients = translated.marinadeIngredients
            seasoningIngredients = translated.seasoningIngredients
            // Consolidate batter, base, and dough into doughBatterFillingIngredients
            // Note: fillingIngredients is not returned by translateRecipe, so we only consolidate the available types
            doughBatterFillingIngredients = translated.batterIngredients + translated.baseIngredients + translated.doughIngredients
            sauceIngredients = translated.sauceIngredients
            toppingIngredients = translated.toppingIngredients
            instructions = translated.instructions.isEmpty ? [""] : translated.instructions
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
            
            // Note: AI extraction tracking happens when user presses "Save", not here
            // This prevents counting extractions that aren't saved
            
            print("✅ ExtractMenuWithAIViewModel: Extraction completed, showing edit recipe view")
            showEditRecipe = true
            isLoading = false
        } catch {
            isLoading = false
            // Check if error is due to regional restrictions
            if isRegionalRestrictionError(error) {
                showRegionalRestrictionAlert = true
                errorMessage = nil
            } else {
                if let openAIError = error as? OpenAIError {
                    errorMessage = openAIError.localizedDescription
                } else {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Ingredient Management
    
    func addDishIngredient() {
        dishIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func removeDishIngredient(at index: Int) {
        guard index >= 0 && index < dishIngredients.count else { return }
        dishIngredients.remove(at: index)
    }
    
    func updateDishIngredientAmount(_ amount: String, at index: Int) {
        guard index >= 0 && index < dishIngredients.count else { return }
        dishIngredients[index].amount = amount
    }
    
    func updateDishIngredientUnit(_ unit: String, at index: Int) {
        guard index >= 0 && index < dishIngredients.count else { return }
        dishIngredients[index].unit = unit
    }
    
    func updateDishIngredientName(_ name: String, at index: Int) {
        guard index >= 0 && index < dishIngredients.count else { return }
        dishIngredients[index].name = name
    }
    
    func addMarinadeIngredient() {
        marinadeIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func removeMarinadeIngredient(at index: Int) {
        guard index >= 0 && index < marinadeIngredients.count else { return }
        marinadeIngredients.remove(at: index)
    }
    
    func updateMarinadeIngredientAmount(_ amount: String, at index: Int) {
        guard index >= 0 && index < marinadeIngredients.count else { return }
        marinadeIngredients[index].amount = amount
    }
    
    func updateMarinadeIngredientUnit(_ unit: String, at index: Int) {
        guard index >= 0 && index < marinadeIngredients.count else { return }
        marinadeIngredients[index].unit = unit
    }
    
    func updateMarinadeIngredientName(_ name: String, at index: Int) {
        guard index >= 0 && index < marinadeIngredients.count else { return }
        marinadeIngredients[index].name = name
    }
    
    func addSeasoningIngredient() {
        seasoningIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func removeSeasoningIngredient(at index: Int) {
        guard index >= 0 && index < seasoningIngredients.count else { return }
        seasoningIngredients.remove(at: index)
    }
    
    func updateSeasoningIngredientAmount(_ amount: String, at index: Int) {
        guard index >= 0 && index < seasoningIngredients.count else { return }
        seasoningIngredients[index].amount = amount
    }
    
    func updateSeasoningIngredientUnit(_ unit: String, at index: Int) {
        guard index >= 0 && index < seasoningIngredients.count else { return }
        seasoningIngredients[index].unit = unit
    }
    
    func updateSeasoningIngredientName(_ name: String, at index: Int) {
        guard index >= 0 && index < seasoningIngredients.count else { return }
        seasoningIngredients[index].name = name
    }
    
    func addDoughBatterFillingIngredient() {
        doughBatterFillingIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func removeDoughBatterFillingIngredient(at index: Int) {
        guard index >= 0 && index < doughBatterFillingIngredients.count else { return }
        doughBatterFillingIngredients.remove(at: index)
    }
    
    func updateDoughBatterFillingIngredientAmount(_ amount: String, at index: Int) {
        guard index >= 0 && index < doughBatterFillingIngredients.count else { return }
        doughBatterFillingIngredients[index].amount = amount
    }
    
    func updateDoughBatterFillingIngredientUnit(_ unit: String, at index: Int) {
        guard index >= 0 && index < doughBatterFillingIngredients.count else { return }
        doughBatterFillingIngredients[index].unit = unit
    }
    
    func updateDoughBatterFillingIngredientName(_ name: String, at index: Int) {
        guard index >= 0 && index < doughBatterFillingIngredients.count else { return }
        doughBatterFillingIngredients[index].name = name
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
    
    func addToppingIngredient() {
        toppingIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func removeToppingIngredient(at index: Int) {
        guard index >= 0 && index < toppingIngredients.count else { return }
        toppingIngredients.remove(at: index)
    }
    
    func updateToppingIngredientAmount(_ amount: String, at index: Int) {
        guard index >= 0 && index < toppingIngredients.count else { return }
        toppingIngredients[index].amount = amount
    }
    
    func updateToppingIngredientUnit(_ unit: String, at index: Int) {
        guard index >= 0 && index < toppingIngredients.count else { return }
        toppingIngredients[index].unit = unit
    }
    
    func updateToppingIngredientName(_ name: String, at index: Int) {
        guard index >= 0 && index < toppingIngredients.count else { return }
        toppingIngredients[index].name = name
    }
    
    func addGarnishIngredient() {
        garnishIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func removeGarnishIngredient(at index: Int) {
        guard index >= 0 && index < garnishIngredients.count else { return }
        garnishIngredients.remove(at: index)
    }
    
    func updateGarnishIngredientAmount(_ amount: String, at index: Int) {
        guard index >= 0 && index < garnishIngredients.count else { return }
        garnishIngredients[index].amount = amount
    }
    
    func updateGarnishIngredientUnit(_ unit: String, at index: Int) {
        guard index >= 0 && index < garnishIngredients.count else { return }
        garnishIngredients[index].unit = unit
    }
    
    func updateGarnishIngredientName(_ name: String, at index: Int) {
        guard index >= 0 && index < garnishIngredients.count else { return }
        garnishIngredients[index].name = name
    }
    
    // MARK: - Cross-Section Ingredient Movement
    
    /// Move an ingredient from one section to another
    func moveIngredient(from sourceCategory: Ingredient.Category, sourceIndex: Int, to destinationCategory: Ingredient.Category, destinationIndex: Int) {
        // Get source array
        var sourceArray: [RecipeTextParser.IngredientItem] {
            switch sourceCategory {
            case .dish: return dishIngredients
            case .marinade: return marinadeIngredients
            case .seasoning: return seasoningIngredients
            case .batter, .base, .dough, .filling: return doughBatterFillingIngredients
            case .sauce: return sauceIngredients
            case .topping: return toppingIngredients
            case .garnish: return garnishIngredients
            }
        }
        
        guard sourceIndex < sourceArray.count else { return }
        
        // Remove from source
        let ingredient = sourceArray[sourceIndex]
        
        switch sourceCategory {
        case .dish:
            dishIngredients.remove(at: sourceIndex)
            if dishIngredients.isEmpty {
                dishIngredients = [RecipeTextParser.IngredientItem(amount: "", unit: "", name: "")]
            }
        case .marinade:
            marinadeIngredients.remove(at: sourceIndex)
        case .seasoning:
            seasoningIngredients.remove(at: sourceIndex)
        case .batter, .base, .dough, .filling:
            doughBatterFillingIngredients.remove(at: sourceIndex)
        case .sauce:
            sauceIngredients.remove(at: sourceIndex)
        case .topping:
            toppingIngredients.remove(at: sourceIndex)
        case .garnish:
            garnishIngredients.remove(at: sourceIndex)
        }
        
        // Insert into destination - always append to create a new row
        switch destinationCategory {
        case .dish:
            // Remove empty placeholder if it's the only item, then append
            if dishIngredients.count == 1 && dishIngredients[0].amount.isEmpty && dishIngredients[0].name.isEmpty && dishIngredients[0].unit.isEmpty {
                dishIngredients.removeAll()
            }
            dishIngredients.append(ingredient)
        case .marinade:
            marinadeIngredients.append(ingredient)
        case .seasoning:
            seasoningIngredients.append(ingredient)
        case .batter, .base, .dough, .filling:
            doughBatterFillingIngredients.append(ingredient)
        case .sauce:
            sauceIngredients.append(ingredient)
        case .topping:
            toppingIngredients.append(ingredient)
        case .garnish:
            garnishIngredients.append(ingredient)
        }
    }
    
    func updateInstruction(_ instruction: String, at index: Int) {
        guard index >= 0 && index < instructions.count else { return }
        instructions[index] = instruction
    }
    
    func addInstruction() {
        instructions.append("")
    }
    
    func removeInstruction(at index: Int) {
        guard index >= 0 && index < instructions.count else { return }
        instructions.remove(at: index)
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
    
    // MARK: - Save Recipe
    
    func saveRecipe(image: UIImage? = nil) async -> Bool {
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = LocalizedString("You must be logged in to save a recipe", comment: "Not logged in error")
            return false
        }
        
        // Get display name from AuthService (ensure user data is loaded)
        let authService = AuthService()
        await authService.reloadUserData()
        let username = authService.currentUser?.username
        let displayName = authService.currentUser?.displayName ?? Auth.auth().currentUser?.displayName ?? "User"
        // Use display name (actual name) for authorName, fall back to username if display name is empty
        let authorName = displayName.isEmpty ? (username ?? "User") : displayName
        
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = LocalizedString("Title is required", comment: "Title required error")
            return false
        }
        
        // Combine all ingredient types, filter out empty ones
        let validMarinadeItems = marinadeIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validSeasoningItems = seasoningIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validDishItems = dishIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validDoughBatterFillingItems = doughBatterFillingIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validSauceItems = sauceIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validToppingItems = toppingIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validGarnishItems = garnishIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        
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
        ingredientObjects.append(contentsOf: validDoughBatterFillingItems.map { 
            Ingredient(amount: $0.amount, unit: $0.unit, name: $0.name, category: .batter) // Default to .batter for consolidated dough/batter/filling section
        })
        ingredientObjects.append(contentsOf: validSauceItems.map { 
            Ingredient(amount: $0.amount, unit: $0.unit, name: $0.name, category: .sauce) 
        })
        ingredientObjects.append(contentsOf: validToppingItems.map { 
            Ingredient(amount: $0.amount, unit: $0.unit, name: $0.name, category: .topping) 
        })
        ingredientObjects.append(contentsOf: validGarnishItems.map { 
            Ingredient(amount: $0.amount, unit: $0.unit, name: $0.name, category: .garnish) 
        })
        
        let validInstructions = instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
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
            
            // Upload source image if available
            var sourceImageURLs: [String] = []
            if let sourceImage = sourceImage {
                print("📸 Starting source image upload")
                let sourceImagePath = "source-images/\(UUID().uuidString).jpg"
                do {
                    let url = try await storageService.uploadImage(sourceImage, path: sourceImagePath)
                    sourceImageURLs.append(url)
                    print("✅ Uploaded source image: \(url)")
                } catch {
                    print("❌ Failed to upload source image: \(error.localizedDescription)")
                    // Continue even if upload fails
                }
            } else {
                print("⚠️ No source image available to upload")
            }
            print("📸 Source image URLs: \(sourceImageURLs)")
            
            // Convert instructions to Instruction objects
            let instructionObjects = validInstructions.map { text in
                Instruction(text: text.trimmingCharacters(in: .whitespaces))
            }
            
            // Profanity check - first line of defense (before creating recipe object)
            // Check all text fields
            var profanityDetected = false
            var profanityField: String? = nil
            var detectedWords: [String] = []
            
            // Check title
            let titleCheck = ProfanityFilter.shared.checkProfanity(in: title)
            if titleCheck.hasProfanity {
                profanityDetected = true
                profanityField = "title"
                detectedWords.append(contentsOf: titleCheck.detectedWords)
            }
            
            // Check description
            if !description.isEmpty {
                let descCheck = ProfanityFilter.shared.checkProfanity(in: description)
                if descCheck.hasProfanity {
                    profanityDetected = true
                    if profanityField == nil { profanityField = "description" }
                    detectedWords.append(contentsOf: descCheck.detectedWords)
                }
            }
            
            // Check ingredients
            for ingredient in dishIngredients + marinadeIngredients + seasoningIngredients + doughBatterFillingIngredients + sauceIngredients + toppingIngredients + garnishIngredients {
                let ingredientText = "\(ingredient.name) \(ingredient.amount) \(ingredient.unit)"
                let ingredientCheck = ProfanityFilter.shared.checkProfanity(in: ingredientText)
                if ingredientCheck.hasProfanity {
                    profanityDetected = true
                    if profanityField == nil { profanityField = "ingredients" }
                    detectedWords.append(contentsOf: ingredientCheck.detectedWords)
                }
            }
            
            // Check instructions
            for instruction in instructions {
                let instructionCheck = ProfanityFilter.shared.checkProfanity(in: instruction)
                if instructionCheck.hasProfanity {
                    profanityDetected = true
                    if profanityField == nil { profanityField = "instructions" }
                    detectedWords.append(contentsOf: instructionCheck.detectedWords)
                }
            }
            
            // Check tips
            for tip in tips {
                let tipCheck = ProfanityFilter.shared.checkProfanity(in: tip)
                if tipCheck.hasProfanity {
                    profanityDetected = true
                    if profanityField == nil { profanityField = "tips" }
                    detectedWords.append(contentsOf: tipCheck.detectedWords)
                }
            }
            
            if profanityDetected {
                let errorMsg = ProfanityFilter.shared.getErrorMessage(
                    field: profanityField,
                    detectedWords: Array(Set(detectedWords))
                )
                errorMessage = errorMsg
                isLoading = false
                return false
            }
            
            // Create recipe
            // Translate title to English, local language, and preserve original
            // Use original extracted title if available, otherwise use current title
            let titleToTranslate = originalExtractedTitle ?? title.trimmingCharacters(in: .whitespaces)
            let (titleEnglish, titleLocal, titleOriginal) = await RecipeTranslationService.translateTitle(titleToTranslate)
            
            print("📝 Creating recipe with sourceImageURLs: \(sourceImageURLs)")
            // Use original language as primary title
            let primaryTitle = titleOriginal ?? (titleLocal.isEmpty ? titleEnglish : titleLocal)
            let recipe = Recipe(
                title: primaryTitle, // Use original language as primary
                titleEnglish: titleEnglish,
                titleLocal: titleLocal,
                titleOriginal: titleOriginal,
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
                authorName: authorName,
                authorUsername: username
            )
            
            print("📝 Recipe created with sourceImageURLs count: \(recipe.sourceImageURLs.count)")
            try await recipeService.createRecipe(recipe)
            print("✅ Recipe saved to Firestore with sourceImageURLs: \(recipe.sourceImageURLs)")
            
            // Track recipe creation for free tier users
            print("🔍 ExtractMenuWithAIViewModel.saveRecipe(): About to track recipe creation...")
            do {
                try await SubscriptionHelper.trackRecipeCreation()
                print("✅ ExtractMenuWithAIViewModel.saveRecipe(): Recipe creation tracked successfully")
            } catch {
                print("⚠️ ExtractMenuWithAIViewModel.saveRecipe(): Error tracking recipe creation: \(error.localizedDescription)")
            }
            
            // Track AI image extraction for free tier users (when user presses Save)
            print("🔍 ExtractMenuWithAIViewModel.saveRecipe(): About to track AI extraction...")
            do {
                try await SubscriptionHelper.trackAIImageExtraction()
                print("✅ ExtractMenuWithAIViewModel.saveRecipe(): AI image extraction tracked successfully")
            } catch {
                print("⚠️ ExtractMenuWithAIViewModel.saveRecipe(): Error tracking AI image extraction: \(error.localizedDescription)")
            }
            
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
    
    private var pluralForms: [String: String] {
        [
            "cup": "cups",
            "pinch": "pinches",
            "piece": "pieces",
            "pc": "pieces",
            "slice": "slices",
            "clove": "cloves",
            "bunch": "bunches",
            "head": "heads",
            "strand": "strands"
        ]
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
                instructions: instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
                backgroundContext: nil // No background context for AI extraction
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
                instructions: instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
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
                instructions: instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
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
                instructions: instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            )
            difficulty = detectedDifficulty
        } catch {
            // Silently fail for difficulty detection - use default
            print("Failed to detect difficulty: \(error.localizedDescription)")
        }
        
        isDetectingDifficulty = false
    }
}

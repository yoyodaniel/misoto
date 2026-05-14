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
    @Published var showRegionalRestrictionAlert = false
    @Published var isGeneratingDescription = false
    @Published var isDetectingCuisine = false
    @Published var isExtractingTime = false
    @Published var isDetectingDifficulty = false
    @Published var isEditingInstructions = false
    @Published var isTipsAILoading = false
    @Published private(set) var canUndoLastInstructionAIEdit = false
    @Published private(set) var canRedoLastInstructionAIEdit = false
    @Published private(set) var canUndoDescriptionAIEdit = false
    @Published private(set) var canRedoDescriptionAIEdit = false
    @Published private(set) var canUndoTipsAIEdit = false
    @Published private(set) var canRedoTipsAIEdit = false
    
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
    
    // Recipe fields for editing
    @Published var title = ""
    @Published var originalExtractedTitle: String? = nil // Preserve original title before translation
    @Published var titleEnglish: String? = nil
    @Published var titleLocal: String? = nil
    @Published var titleOriginal: String? = nil
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
    @Published var instructions: [InstructionItem] = []
    @Published var mainRecipeImages: [UIImage] = [] // Up to 5 images for the recipe
    @Published var postSharing: AppSettings.DefaultPostSharing = AppSettings.shared.defaultPostSharing
    private var sourceImages: [UIImage] = [] // Source images used for extraction
    
    private var undoRedoCancellables = Set<AnyCancellable>()
    private var postExtractionUndoRedoReady = false
    
    private var instructionAIUndoStack: [[InstructionItem]] = []
    private var instructionAIRedoStack: [[InstructionItem]] = []
    private let maxInstructionAIUndoDepth = 30
    
    private var descriptionAIUndoStack: [String] = []
    private var descriptionAIRedoStack: [String] = []
    private let maxDescriptionAIUndoDepth = 30
    
    private var tipsAIUndoStack: [[String]] = []
    private var tipsAIRedoStack: [[String]] = []
    private let maxTipsAIUndoDepth = 30
    
    private let debouncedEditUndoDelayNanoseconds: UInt64 = 2_000_000_000
    
    private var descriptionUndoDebounceTask: Task<Void, Never>?
    private var descriptionCommitted: String = ""
    private var suppressDescriptionUndoScheduling = false
    
    private var tipsUndoDebounceTask: Task<Void, Never>?
    private var tipsCommitted: [String] = []
    private var suppressTipsUndoScheduling = false
    
    private var instructionsUndoDebounceTask: Task<Void, Never>?
    private var instructionsCommitted: [InstructionItem] = []
    private var suppressInstructionsUndoScheduling = false
    
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
        return marinadeIngredients + seasoningIngredients + dishIngredients + doughBatterFillingIngredients + sauceIngredients + toppingIngredients
    }
    
    // MARK: - Ingredient Management (Batter and Sauce only - other methods defined later)
    
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
    
    private let recipeService = RecipeService.shared
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
                garnishIngredients: response.garnishIngredients,
                instructions: response.instructions,
                tips: response.tips.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
                cuisine: nil // Will be detected later
            )
            
            // Populate editable fields with translated content (already capitalized by RecipeTranslationService)
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
            garnishIngredients = translated.garnishIngredients
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
            
            // Note: AI extraction tracking happens when user presses "Save", not here
            // This prevents counting extractions that aren't saved
            
            print("✅ ExtractMenuFromImageViewModel: Extraction completed, showing edit recipe view")
            enableDebouncedUndoRedoAfterExtraction()
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
    
    func saveRecipe(image: UIImage? = nil) async -> Bool {
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = LocalizedString("You must be logged in to save a recipe", comment: "Not logged in error")
            return false
        }
        
        // Check recipe creation limit for free tier users
        do {
            let canCreate = try await SubscriptionHelper.checkRecipeCreationLimit()
            if !canCreate {
                errorMessage = LocalizedString("You have reached the free tier limit", comment: "Recipe limit error")
                return false
            }
        } catch {
            print("⚠️ Error checking recipe limit: \(error.localizedDescription)")
            // Continue anyway - don't block user if check fails
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
            // Translate title to English, local language, and preserve original
            // Use original extracted title if available, otherwise use current title
            let titleToTranslate = originalExtractedTitle ?? title.trimmingCharacters(in: .whitespaces)
            let (titleEnglish, titleLocal, titleOriginal) = await RecipeTranslationService.translateTitle(titleToTranslate)
            
            // Update UI fields so they show in the edit form
            self.titleEnglish = titleEnglish
            self.titleLocal = titleLocal
            self.titleOriginal = titleOriginal
            // Set main title to local language (or English if local is not available)
            self.title = titleLocal.isEmpty ? titleEnglish : titleLocal
            
            print("📝 Creating recipe with sourceImageURLs: \(sourceImageURLs)")
            // Use original language as primary title
            let primaryTitle = titleOriginal ?? (titleLocal.isEmpty ? titleEnglish : titleLocal)
            
            // Save cuisine in English (translations are handled by CuisineTranslations)
            let cuisineEnglish: String? = cuisine?.trimmingCharacters(in: .whitespaces).isEmpty == false ? cuisine?.trimmingCharacters(in: .whitespaces) : nil
            
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
                cuisineEnglish: cuisineEnglish,
                imageURL: mainImageURL, // For backward compatibility
                imageURLs: allImageURLs, // Array of all image URLs
                sourceImageURL: sourceImageURLs.first, // For backward compatibility
                sourceImageURLs: sourceImageURLs,
                authorID: userID,
                authorName: authorName,
                authorUsername: username,
                isPrivate: postSharing.isPrivateRecipe
            )
            
            // Profanity check - first line of defense
            let profanityCheck = ProfanityFilter.shared.checkRecipe(recipe)
            if profanityCheck.hasProfanity {
                let errorMsg = ProfanityFilter.shared.getErrorMessage(
                    field: profanityCheck.field,
                    detectedWords: profanityCheck.detectedWords
                )
                errorMessage = errorMsg
                isLoading = false
                return false
            }
            
            print("📝 Recipe created with sourceImageURLs count: \(recipe.sourceImageURLs.count)")
            try await recipeService.createRecipe(recipe)
            print("✅ Recipe saved to Firestore with sourceImageURLs: \(recipe.sourceImageURLs)")
            
            // Track recipe creation for free tier users
            print("🔍 ExtractMenuFromImageViewModel.saveRecipe(): About to track recipe creation...")
            do {
                try await SubscriptionHelper.trackRecipeCreation()
                print("✅ ExtractMenuFromImageViewModel.saveRecipe(): Recipe creation tracked successfully")
            } catch {
                print("⚠️ ExtractMenuFromImageViewModel.saveRecipe(): Error tracking recipe creation: \(error.localizedDescription)")
            }
            
            // Track AI image extraction for free tier users (when user presses Save)
            print("🔍 ExtractMenuFromImageViewModel.saveRecipe(): About to track AI extraction...")
            do {
                try await SubscriptionHelper.trackAIImageExtraction()
                print("✅ ExtractMenuFromImageViewModel.saveRecipe(): AI image extraction tracked successfully")
            } catch {
                print("⚠️ ExtractMenuFromImageViewModel.saveRecipe(): Error tracking AI image extraction: \(error.localizedDescription)")
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
                instructions: instructions.map { $0.text }.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
                backgroundContext: nil // No background context for image extraction
            )
            
            if !generatedDescription.isEmpty {
                if postExtractionUndoRedoReady {
                    captureDescriptionSnapshotForUndo()
                }
                description = generatedDescription
                if postExtractionUndoRedoReady {
                    descriptionCommitted = description
                }
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
    
    // MARK: - Post-extraction debounced undo / redo
    
    func enableDebouncedUndoRedoAfterExtraction() {
        setupDebouncedEditUndoSubscriptionsIfNeeded()
    }
    
    private func setupDebouncedEditUndoSubscriptionsIfNeeded() {
        guard !postExtractionUndoRedoReady else {
            syncDescriptionCommittedFromCurrent()
            syncTipsCommittedFromCurrent()
            syncInstructionsCommittedFromCurrent()
            return
        }
        postExtractionUndoRedoReady = true
        syncDescriptionCommittedFromCurrent()
        syncTipsCommittedFromCurrent()
        syncInstructionsCommittedFromCurrent()
        
        $description
            .sink { [weak self] _ in
                guard let self, !self.suppressDescriptionUndoScheduling else { return }
                self.scheduleDescriptionUndoCheckpoint()
            }
            .store(in: &undoRedoCancellables)
        
        $tips
            .sink { [weak self] _ in
                guard let self, !self.suppressTipsUndoScheduling else { return }
                self.scheduleTipsUndoCheckpoint()
            }
            .store(in: &undoRedoCancellables)
        
        $instructions
            .sink { [weak self] _ in
                guard let self, !self.suppressInstructionsUndoScheduling else { return }
                self.scheduleInstructionsUndoCheckpoint()
            }
            .store(in: &undoRedoCancellables)
    }
    
    private func syncDescriptionCommittedFromCurrent() {
        descriptionCommitted = description
    }
    
    private func syncTipsCommittedFromCurrent() {
        tipsCommitted = copyTipsForUndo(tips)
    }
    
    private func syncInstructionsCommittedFromCurrent() {
        instructionsCommitted = copyInstructionsForUndo(instructions)
    }
    
    private func scheduleDescriptionUndoCheckpoint() {
        descriptionUndoDebounceTask?.cancel()
        descriptionUndoDebounceTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: self.debouncedEditUndoDelayNanoseconds)
            guard !Task.isCancelled else { return }
            self.flushDescriptionUndoCheckpointIfNeeded()
        }
    }
    
    private func flushDescriptionUndoCheckpointIfNeeded() {
        guard postExtractionUndoRedoReady else { return }
        guard !suppressDescriptionUndoScheduling else { return }
        guard description != descriptionCommitted else { return }
        descriptionAIRedoStack.removeAll()
        canRedoDescriptionAIEdit = false
        pushDescriptionUndo(descriptionCommitted)
        descriptionCommitted = description
        canUndoDescriptionAIEdit = !descriptionAIUndoStack.isEmpty
    }
    
    private func scheduleTipsUndoCheckpoint() {
        tipsUndoDebounceTask?.cancel()
        tipsUndoDebounceTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: self.debouncedEditUndoDelayNanoseconds)
            guard !Task.isCancelled else { return }
            self.flushTipsUndoCheckpointIfNeeded()
        }
    }
    
    private func flushTipsUndoCheckpointIfNeeded() {
        guard postExtractionUndoRedoReady else { return }
        guard !suppressTipsUndoScheduling else { return }
        guard tips != tipsCommitted else { return }
        tipsAIRedoStack.removeAll()
        canRedoTipsAIEdit = false
        pushTipsUndo(tipsCommitted)
        tipsCommitted = copyTipsForUndo(tips)
        canUndoTipsAIEdit = !tipsAIUndoStack.isEmpty
    }
    
    private func scheduleInstructionsUndoCheckpoint() {
        instructionsUndoDebounceTask?.cancel()
        instructionsUndoDebounceTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: self.debouncedEditUndoDelayNanoseconds)
            guard !Task.isCancelled else { return }
            self.flushInstructionsUndoCheckpointIfNeeded()
        }
    }
    
    private func instructionItemsTextuallyEqual(_ a: [InstructionItem], _ b: [InstructionItem]) -> Bool {
        guard a.count == b.count else { return false }
        return zip(a, b).allSatisfy { $0.id == $1.id && $0.text == $1.text }
    }
    
    private func flushInstructionsUndoCheckpointIfNeeded() {
        guard postExtractionUndoRedoReady else { return }
        guard !suppressInstructionsUndoScheduling else { return }
        let current = copyInstructionsForUndo(instructions)
        guard !instructionItemsTextuallyEqual(current, instructionsCommitted) else { return }
        instructionAIRedoStack.removeAll()
        canRedoLastInstructionAIEdit = false
        pushToUndoStack(copyInstructionsForUndo(instructionsCommitted))
        instructionsCommitted = current
        canUndoLastInstructionAIEdit = !instructionAIUndoStack.isEmpty
    }
    
    private func allIngredientStringsForAI() -> [String] {
        let groups = [
            dishIngredients, marinadeIngredients, seasoningIngredients,
            doughBatterFillingIngredients, sauceIngredients, toppingIngredients, garnishIngredients
        ]
        return groups.flatMap { items in
            items.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }.map { item in
                var parts: [String] = []
                if !item.amount.isEmpty { parts.append(item.amount) }
                if !item.unit.isEmpty { parts.append(item.unit) }
                if !item.name.isEmpty { parts.append(item.name) }
                return parts.joined(separator: " ")
            }
        }
    }
    
    private func instructionTextsForAI() -> [String] {
        instructions.compactMap { $0.text.isEmpty ? nil : $0.text }
    }
    
    func polishDescriptionWithAI() async {
        guard postExtractionUndoRedoReady else { return }
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = LocalizedString("Add description text to polish.", comment: "Need description text for polish")
            return
        }
        
        isGeneratingDescription = true
        errorMessage = nil
        
        do {
            let edited = try await RecipeInstructionAI.improveInstructionStrings([description])
            guard let polished = edited.first else { return }
            captureDescriptionSnapshotForUndo()
            description = polished
            descriptionCommitted = description
        } catch {
            errorMessage = String(format: LocalizedString("Failed to polish description: %@", comment: "AI description polish error"), error.localizedDescription)
        }
        
        isGeneratingDescription = false
    }
    
    func undoDescriptionAIEdit() {
        guard postExtractionUndoRedoReady else { return }
        descriptionUndoDebounceTask?.cancel()
        guard let older = descriptionAIUndoStack.popLast() else { return }
        pushDescriptionRedo(description)
        suppressDescriptionUndoScheduling = true
        description = older
        descriptionCommitted = older
        suppressDescriptionUndoScheduling = false
        canUndoDescriptionAIEdit = !descriptionAIUndoStack.isEmpty
        canRedoDescriptionAIEdit = !descriptionAIRedoStack.isEmpty
    }
    
    func redoDescriptionAIEdit() {
        guard postExtractionUndoRedoReady else { return }
        descriptionUndoDebounceTask?.cancel()
        guard let newer = descriptionAIRedoStack.popLast() else { return }
        pushDescriptionUndo(description)
        suppressDescriptionUndoScheduling = true
        description = newer
        descriptionCommitted = newer
        suppressDescriptionUndoScheduling = false
        canUndoDescriptionAIEdit = !descriptionAIUndoStack.isEmpty
        canRedoDescriptionAIEdit = !descriptionAIRedoStack.isEmpty
    }
    
    private func captureDescriptionSnapshotForUndo() {
        guard postExtractionUndoRedoReady else { return }
        descriptionUndoDebounceTask?.cancel()
        descriptionAIRedoStack.removeAll()
        canRedoDescriptionAIEdit = false
        pushDescriptionUndo(description)
        canUndoDescriptionAIEdit = true
    }
    
    private func pushDescriptionUndo(_ snapshot: String) {
        descriptionAIUndoStack.append(snapshot)
        if descriptionAIUndoStack.count > maxDescriptionAIUndoDepth {
            descriptionAIUndoStack.removeFirst(descriptionAIUndoStack.count - maxDescriptionAIUndoDepth)
        }
    }
    
    private func pushDescriptionRedo(_ snapshot: String) {
        descriptionAIRedoStack.append(snapshot)
        if descriptionAIRedoStack.count > maxDescriptionAIUndoDepth {
            descriptionAIRedoStack.removeFirst(descriptionAIRedoStack.count - maxDescriptionAIUndoDepth)
        }
    }
    
    func polishTipsWithAI() async {
        guard postExtractionUndoRedoReady else { return }
        tipsUndoDebounceTask?.cancel()
        let hasTip = tips.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard hasTip else {
            errorMessage = LocalizedString("Add at least one tip to polish.", comment: "Need tip text for polish")
            return
        }
        
        isTipsAILoading = true
        errorMessage = nil
        
        do {
            let edited = try await RecipeInstructionAI.improveInstructionStrings(tips)
            captureTipsSnapshotForUndo()
            suppressTipsUndoScheduling = true
            defer { suppressTipsUndoScheduling = false }
            for i in 0..<min(tips.count, edited.count) {
                tips[i] = edited[i]
            }
            tipsCommitted = copyTipsForUndo(tips)
        } catch {
            errorMessage = String(format: LocalizedString("Failed to polish tips: %@", comment: "AI tips polish error"), error.localizedDescription)
        }
        
        isTipsAILoading = false
    }
    
    func generateTipsWithOpenAI() async {
        guard postExtractionUndoRedoReady else { return }
        tipsUndoDebounceTask?.cancel()
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = LocalizedString("Please enter a recipe title first", comment: "Title required for AI instructions")
            return
        }
        
        isTipsAILoading = true
        errorMessage = nil
        
        do {
            let generated = try await OpenAIService.generateRecipeTips(
                title: title,
                ingredients: allIngredientStringsForAI(),
                instructions: instructionTextsForAI(),
                description: description
            )
            guard !generated.isEmpty else {
                errorMessage = LocalizedString("No tips were generated. Try adding more recipe detail.", comment: "AI tips empty result")
                isTipsAILoading = false
                return
            }
            captureTipsSnapshotForUndo()
            tips = generated
            tipsCommitted = copyTipsForUndo(tips)
        } catch {
            errorMessage = String(format: LocalizedString("Failed to generate tips: %@", comment: "AI tips generation error"), error.localizedDescription)
        }
        
        isTipsAILoading = false
    }
    
    func undoTipsAIEdit() {
        guard postExtractionUndoRedoReady else { return }
        tipsUndoDebounceTask?.cancel()
        guard let older = tipsAIUndoStack.popLast() else { return }
        pushTipsRedo(copyTipsForUndo(tips))
        suppressTipsUndoScheduling = true
        tips = copyTipsForUndo(older)
        tipsCommitted = copyTipsForUndo(tips)
        suppressTipsUndoScheduling = false
        canUndoTipsAIEdit = !tipsAIUndoStack.isEmpty
        canRedoTipsAIEdit = !tipsAIRedoStack.isEmpty
    }
    
    func redoTipsAIEdit() {
        guard postExtractionUndoRedoReady else { return }
        tipsUndoDebounceTask?.cancel()
        guard let newer = tipsAIRedoStack.popLast() else { return }
        pushTipsUndo(copyTipsForUndo(tips))
        suppressTipsUndoScheduling = true
        tips = copyTipsForUndo(newer)
        tipsCommitted = copyTipsForUndo(tips)
        suppressTipsUndoScheduling = false
        canUndoTipsAIEdit = !tipsAIUndoStack.isEmpty
        canRedoTipsAIEdit = !tipsAIRedoStack.isEmpty
    }
    
    private func captureTipsSnapshotForUndo() {
        guard postExtractionUndoRedoReady else { return }
        tipsUndoDebounceTask?.cancel()
        tipsAIRedoStack.removeAll()
        canRedoTipsAIEdit = false
        pushTipsUndo(copyTipsForUndo(tips))
        canUndoTipsAIEdit = true
    }
    
    private func pushTipsUndo(_ snapshot: [String]) {
        tipsAIUndoStack.append(snapshot)
        if tipsAIUndoStack.count > maxTipsAIUndoDepth {
            tipsAIUndoStack.removeFirst(tipsAIUndoStack.count - maxTipsAIUndoDepth)
        }
    }
    
    private func pushTipsRedo(_ snapshot: [String]) {
        tipsAIRedoStack.append(snapshot)
        if tipsAIRedoStack.count > maxTipsAIUndoDepth {
            tipsAIRedoStack.removeFirst(tipsAIRedoStack.count - maxTipsAIUndoDepth)
        }
    }
    
    private func copyTipsForUndo(_ items: [String]) -> [String] {
        Array(items)
    }
    
    func improveInstructionsWithAI() async {
        guard postExtractionUndoRedoReady else { return }
        instructionsUndoDebounceTask?.cancel()
        let validInstructions = instructions.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !validInstructions.isEmpty else {
            errorMessage = LocalizedString("Add at least one instruction step to polish.", comment: "Need instruction text for polish action")
            return
        }
        
        isEditingInstructions = true
        errorMessage = nil
        
        do {
            let instructionTexts = instructions.map { $0.text }
            let editedTexts = try await RecipeInstructionAI.improveInstructionStrings(instructionTexts)
            captureInstructionsSnapshotForUndo()
            suppressInstructionsUndoScheduling = true
            defer { suppressInstructionsUndoScheduling = false }
            for i in 0..<min(instructions.count, editedTexts.count) {
                instructions[i].text = editedTexts[i]
            }
            instructionsCommitted = copyInstructionsForUndo(instructions)
        } catch {
            errorMessage = String(format: LocalizedString("Failed to polish instructions: %@", comment: "AI instruction polish error"), error.localizedDescription)
        }
        
        isEditingInstructions = false
    }
    
    func generateInstructionsWithOpenAI() async {
        guard postExtractionUndoRedoReady else { return }
        instructionsUndoDebounceTask?.cancel()
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = LocalizedString("Please enter a recipe title first", comment: "Title required for AI instructions")
            return
        }
        
        isEditingInstructions = true
        errorMessage = nil
        
        do {
            let generatedSteps = try await RecipeInstructionAI.generateInstructionStrings(
                title: title,
                ingredients: allIngredientStringsForAI()
            )
            
            captureInstructionsSnapshotForUndo()
            instructions = generatedSteps.map { text in
                InstructionItem(text: text)
            }
            instructionsCommitted = copyInstructionsForUndo(instructions)
        } catch {
            errorMessage = LocalizedString("Failed to generate instructions: \(error.localizedDescription)", comment: "AI instruction generation error")
        }
        
        isEditingInstructions = false
    }
    
    func undoLastInstructionAIEdit() {
        guard postExtractionUndoRedoReady else { return }
        instructionsUndoDebounceTask?.cancel()
        guard let older = instructionAIUndoStack.popLast() else { return }
        pushToRedoStack(copyInstructionsForUndo(instructions))
        suppressInstructionsUndoScheduling = true
        instructions = copyInstructionsForUndo(older)
        instructionsCommitted = copyInstructionsForUndo(instructions)
        suppressInstructionsUndoScheduling = false
        canUndoLastInstructionAIEdit = !instructionAIUndoStack.isEmpty
        canRedoLastInstructionAIEdit = !instructionAIRedoStack.isEmpty
    }
    
    func redoLastInstructionAIEdit() {
        guard postExtractionUndoRedoReady else { return }
        instructionsUndoDebounceTask?.cancel()
        guard let newer = instructionAIRedoStack.popLast() else { return }
        pushToUndoStack(copyInstructionsForUndo(instructions))
        suppressInstructionsUndoScheduling = true
        instructions = copyInstructionsForUndo(newer)
        instructionsCommitted = copyInstructionsForUndo(instructions)
        suppressInstructionsUndoScheduling = false
        canUndoLastInstructionAIEdit = !instructionAIUndoStack.isEmpty
        canRedoLastInstructionAIEdit = !instructionAIRedoStack.isEmpty
    }
    
    private func captureInstructionsSnapshotForUndo() {
        guard postExtractionUndoRedoReady else { return }
        instructionsUndoDebounceTask?.cancel()
        instructionAIRedoStack.removeAll()
        canRedoLastInstructionAIEdit = false
        pushToUndoStack(copyInstructionsForUndo(instructions))
        canUndoLastInstructionAIEdit = true
    }
    
    private func pushToUndoStack(_ snapshot: [InstructionItem]) {
        instructionAIUndoStack.append(snapshot)
        if instructionAIUndoStack.count > maxInstructionAIUndoDepth {
            instructionAIUndoStack.removeFirst(instructionAIUndoStack.count - maxInstructionAIUndoDepth)
        }
    }
    
    private func pushToRedoStack(_ snapshot: [InstructionItem]) {
        instructionAIRedoStack.append(snapshot)
        if instructionAIRedoStack.count > maxInstructionAIUndoDepth {
            instructionAIRedoStack.removeFirst(instructionAIRedoStack.count - maxInstructionAIUndoDepth)
        }
    }
    
    private func copyInstructionsForUndo(_ items: [InstructionItem]) -> [InstructionItem] {
        items.map { item in
            InstructionItem(id: item.id, text: item.text, image: item.image, videoURL: item.videoURL)
        }
    }
}


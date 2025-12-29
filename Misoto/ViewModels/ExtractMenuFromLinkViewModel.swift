//
//  ExtractMenuFromLinkViewModel.swift
//  Misoto
//
//  ViewModel for extracting recipes from URLs using OpenAI
//

import Foundation
import Combine
import FirebaseAuth
import UIKit

@MainActor
class ExtractMenuFromLinkViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showEditRecipe = false
    @Published var isGeneratingDescription = false
    @Published var isDetectingCuisine = false
    @Published var isExtractingTime = false
    @Published var isDetectingDifficulty = false
    
    // Recipe fields for editing
    @Published var title = ""
    @Published var description = ""
    @Published var cuisine: String? = nil
    @Published var prepTime: Int = 15
    @Published var cookTime: Int = 30
    @Published var servings: Int = 4
    @Published var difficulty: Recipe.Difficulty = .c
    @Published var marinadeIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var seasoningIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var dishIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var batterIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var sauceIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var baseIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var doughIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var toppingIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var instructions: [String] = []
    @Published var mainRecipeImages: [UIImage] = [] // Up to 5 images for the recipe
    
    private let recipeService = RecipeService()
    private let storageService = StorageService()
    
    /// Extract recipe from URL using OpenAI
    func extractRecipe(from urlString: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await OpenAIService.extractRecipe(fromURL: urlString)
            
            // Populate fields
            title = response.title
            description = response.description
            marinadeIngredients = response.marinadeIngredients.isEmpty ? [] : response.marinadeIngredients
            seasoningIngredients = response.seasoningIngredients.isEmpty ? [] : response.seasoningIngredients
            dishIngredients = response.dishIngredients.isEmpty ? [RecipeTextParser.IngredientItem(amount: "", unit: "", name: "")] : response.dishIngredients
            instructions = response.instructions.isEmpty ? [""] : response.instructions
            
            // Auto-generate description, auto-detect cuisine, extract time, and detect difficulty after extraction
            // Small delay to ensure all fields are properly set
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            await generateDescription()
            await detectCuisine()
            await extractTime()
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
    
    // MARK: - Additional Ingredient Management (Batter and Sauce)
    
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
        baseIngredients[index].amount = amount
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
        doughIngredients[index].amount = amount
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
        guard let userID = Auth.auth().currentUser?.uid,
              let displayName = Auth.auth().currentUser?.displayName else {
            errorMessage = NSLocalizedString("You must be logged in to save a recipe", comment: "Not logged in error")
            return false
        }
        
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = NSLocalizedString("Title is required", comment: "Title required error")
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
        let validIngredientItems = validMarinadeItems + validSeasoningItems + validDishItems + validBatterItems + validSauceItems + validBaseItems + validDoughItems + validToppingItems
        
        guard !validDishItems.isEmpty else {
            errorMessage = NSLocalizedString("At least one dish ingredient is required", comment: "Dish ingredients required error")
            return false
        }
        
        // Convert ingredient items to strings for Recipe model (pluralize units if amount > 1)
        let validIngredients = validIngredientItems.map { item in
            if item.unit.isEmpty {
                return item.amount.isEmpty ? item.name : "\(item.amount) \(item.name)"
            } else {
                var unit = item.unit
                // Pluralize unit if amount > 1
                if let amountValue = Double(item.amount.trimmingCharacters(in: .whitespaces)), amountValue > 1 {
                    if let plural = pluralForms[item.unit] {
                        unit = plural
                    }
                }
                return "\(item.amount) \(unit) \(item.name)"
            }
        }
        
        let validInstructions = instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !validInstructions.isEmpty else {
            errorMessage = NSLocalizedString("At least one instruction is required", comment: "Instructions required error")
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Upload main recipe images (up to 5) - use first one as primary imageURL
            // Do NOT use the extraction image parameter - it's separate from main recipe images
            var mainImageURL: String? = nil
            if let firstImage = mainRecipeImages.first {
                let imagePath = "recipes/\(UUID().uuidString).jpg"
                mainImageURL = try await storageService.uploadImage(firstImage, path: imagePath)
            }
            
            // Convert instructions to Instruction objects
            let instructionObjects = validInstructions.map { text in
                Instruction(text: text.trimmingCharacters(in: .whitespaces))
            }
            
            // Create recipe
            let recipe = Recipe(
                title: title.trimmingCharacters(in: .whitespaces),
                description: description.trimmingCharacters(in: .whitespaces),
                ingredients: validIngredients,
                instructions: instructionObjects,
                prepTime: prepTime,
                cookTime: cookTime,
                servings: servings,
                difficulty: difficulty,
                cuisine: cuisine?.trimmingCharacters(in: .whitespaces).isEmpty == false ? cuisine?.trimmingCharacters(in: .whitespaces) : nil,
                imageURL: mainImageURL,
                authorID: userID,
                authorName: displayName
            )
            
            try await recipeService.createRecipe(recipe)
            isLoading = false
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
            errorMessage = NSLocalizedString("Please enter a recipe title first", comment: "Title required for description")
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
                instructions: instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            )
            
            if !generatedDescription.isEmpty {
                description = generatedDescription
            }
        } catch {
            errorMessage = NSLocalizedString("Failed to generate description: \(error.localizedDescription)", comment: "Description generation error")
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

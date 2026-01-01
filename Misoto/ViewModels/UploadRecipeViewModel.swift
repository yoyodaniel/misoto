//
//  UploadRecipeViewModel.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine
import FirebaseAuth
import UIKit
import PhotosUI

@MainActor
class UploadRecipeViewModel: ObservableObject {
    @Published var title = ""
    @Published var description = ""
    @Published var dishIngredients: [RecipeTextParser.IngredientItem] = [RecipeTextParser.IngredientItem(amount: "", unit: "", name: "")]
    @Published var marinadeIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var seasoningIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var batterIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var sauceIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var baseIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var doughIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var toppingIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var instructions: [InstructionItem] = [InstructionItem()]
    @Published var prepTime = 15
    @Published var cookTime = 30
    @Published var servings = 4
    @Published var difficulty: Recipe.Difficulty = .c
    @Published var spicyLevel: Recipe.SpicyLevel = .none
    @Published var tips: [String] = []
    @Published var cuisine: String? = nil
    @Published var mainRecipeImages: [UIImage] = [] // Up to 5 images for the recipe
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSuccess = false
    @Published var isGeneratingDescription = false
    @Published var isDetectingCuisine = false
    
    private let recipeService = RecipeService()
    private let storageService = StorageService()
    private let authService = AuthService()
    
    struct InstructionItem: Identifiable {
        var id = UUID()
        var text: String = ""
        var image: UIImage?
        var videoURL: URL?
        
        func toInstruction() -> Instruction {
            return Instruction(text: text)
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
    
    func addRecipeImage(_ image: UIImage) {
        guard mainRecipeImages.count < 5 else { return }
        mainRecipeImages.append(image)
    }
    
    func removeRecipeImage(at index: Int) {
        guard index >= 0 && index < mainRecipeImages.count else { return }
        mainRecipeImages.remove(at: index)
    }
    
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
    
    func uploadRecipe() async {
        guard let userID = Auth.auth().currentUser?.uid,
              let displayName = Auth.auth().currentUser?.displayName else {
            errorMessage = LocalizedString("You must be logged in to upload a recipe", comment: "Not logged in error")
            return
        }
        
        // Get username from AuthService (ensure user data is loaded)
        await authService.reloadUserData()
        let username = authService.currentUser?.username
        
        // Validate
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = LocalizedString("Title is required", comment: "Title required error")
            return
        }
        
        // Collect all valid ingredients from all sections
        let validDishItems = dishIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validMarinadeItems = marinadeIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validSeasoningItems = seasoningIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validBatterItems = batterIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validSauceItems = sauceIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validBaseItems = baseIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validDoughItems = doughIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validToppingItems = toppingIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        
        let allValidIngredients = validDishItems + validMarinadeItems + validSeasoningItems + validBatterItems + validSauceItems + validBaseItems + validDoughItems + validToppingItems
        
        guard !allValidIngredients.isEmpty else {
            errorMessage = LocalizedString("At least one ingredient is required", comment: "Ingredients required error")
            return
        }
        
        // Convert ingredient items to Ingredient objects with IDs
        let ingredientObjects = allValidIngredients.map { item -> Ingredient in
            // Determine category based on which array it came from
            let category: Ingredient.Category?
            if validDishItems.contains(where: { $0.name == item.name && $0.amount == item.amount && $0.unit == item.unit }) {
                category = .dish
            } else if validMarinadeItems.contains(where: { $0.name == item.name && $0.amount == item.amount && $0.unit == item.unit }) {
                category = .marinade
            } else if validSeasoningItems.contains(where: { $0.name == item.name && $0.amount == item.amount && $0.unit == item.unit }) {
                category = .seasoning
            } else if validBatterItems.contains(where: { $0.name == item.name && $0.amount == item.amount && $0.unit == item.unit }) {
                category = .batter
            } else if validSauceItems.contains(where: { $0.name == item.name && $0.amount == item.amount && $0.unit == item.unit }) {
                category = .sauce
            } else if validBaseItems.contains(where: { $0.name == item.name && $0.amount == item.amount && $0.unit == item.unit }) {
                category = .base
            } else if validDoughItems.contains(where: { $0.name == item.name && $0.amount == item.amount && $0.unit == item.unit }) {
                category = .dough
            } else if validToppingItems.contains(where: { $0.name == item.name && $0.amount == item.amount && $0.unit == item.unit }) {
                category = .topping
            } else {
                category = nil
            }
            
            return Ingredient(
                amount: item.amount,
                unit: item.unit,
                name: item.name,
                category: category
            )
        }
        
        let validInstructions = instructions.filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !validInstructions.isEmpty else {
            errorMessage = LocalizedString("At least one instruction is required", comment: "Instructions required error")
            return
        }
        
        isLoading = true
        errorMessage = nil
        isSuccess = false
        
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
            
            // Upload instruction images/videos and create Instruction objects
            var uploadedInstructions: [Instruction] = []
            for (index, instructionItem) in validInstructions.enumerated() {
                var imageURL: String? = nil
                var videoURL: String? = nil
                
                // Upload image if present
                if let image = instructionItem.image {
                    let imagePath = "recipe-instructions/\(UUID().uuidString).jpg"
                    imageURL = try await storageService.uploadImage(image, path: imagePath)
                }
                
                // Upload video if present
                if let videoURLToUpload = instructionItem.videoURL {
                    let videoPath = "recipe-instructions/\(UUID().uuidString).mp4"
                    videoURL = try await storageService.uploadVideo(videoURLToUpload, path: videoPath)
                }
                
                let instruction = Instruction(
                    text: instructionItem.text.trimmingCharacters(in: .whitespaces),
                    imageURL: imageURL,
                    videoURL: videoURL
                )
                uploadedInstructions.append(instruction)
            }
            
            // Create recipe with uploaded media URLs
            let recipe = Recipe(
                title: title.trimmingCharacters(in: .whitespaces),
                description: description.trimmingCharacters(in: .whitespaces),
                ingredients: ingredientObjects,
                instructions: uploadedInstructions,
                prepTime: prepTime,
                cookTime: cookTime,
                servings: servings,
                difficulty: difficulty,
                spicyLevel: spicyLevel,
                tips: tips.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
                cuisine: cuisine?.trimmingCharacters(in: .whitespaces).isEmpty == false ? cuisine?.trimmingCharacters(in: .whitespaces) : nil,
                imageURL: mainImageURL, // For backward compatibility
                imageURLs: allImageURLs, // Array of all image URLs
                authorID: userID,
                authorName: displayName,
                authorUsername: username
            )
            
            try await recipeService.createRecipe(recipe)
            isSuccess = true
            resetForm()
            
            // Post notification to refresh account view
            NotificationCenter.default.post(name: NSNotification.Name("RecipeSaved"), object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func resetForm() {
        title = ""
        description = ""
        dishIngredients = [RecipeTextParser.IngredientItem(amount: "", unit: "", name: "")]
        marinadeIngredients = []
        seasoningIngredients = []
        batterIngredients = []
        sauceIngredients = []
        baseIngredients = []
        doughIngredients = []
        toppingIngredients = []
        instructions = [InstructionItem()]
        prepTime = 15
        cookTime = 30
        servings = 4
        difficulty = .c
        spicyLevel = .none
        tips = []
        cuisine = nil
        mainRecipeImages = []
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
            // Collect all valid ingredients from all sections
            let validDishItems = dishIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            let validMarinadeItems = marinadeIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            let validSeasoningItems = seasoningIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            let validBatterItems = batterIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            let validSauceItems = sauceIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            let validBaseItems = baseIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            let validDoughItems = doughIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            let validToppingItems = toppingIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            
            let allValidIngredients = validDishItems + validMarinadeItems + validSeasoningItems + validBatterItems + validSauceItems + validBaseItems + validDoughItems + validToppingItems
            
            // Convert to string format for API
            let ingredientsStrings = allValidIngredients.map { item in
                var parts: [String] = []
                if !item.amount.isEmpty {
                    parts.append(item.amount)
                }
                if !item.unit.isEmpty {
                    parts.append(item.unit)
                }
                if !item.name.isEmpty {
                    parts.append(item.name)
                }
                return parts.joined(separator: " ")
            }
            
            let validInstructions = instructions.compactMap { $0.text.isEmpty ? nil : $0.text }
            
            let generatedDescription = try await OpenAIService.generateRecipeDescription(
                title: title,
                ingredients: ingredientsStrings,
                instructions: validInstructions
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
            // Collect all valid ingredients from all sections
            let validDishItems = dishIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            let validMarinadeItems = marinadeIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            let validSeasoningItems = seasoningIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            let validBatterItems = batterIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            let validSauceItems = sauceIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            let validBaseItems = baseIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            let validDoughItems = doughIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            let validToppingItems = toppingIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            
            let allValidIngredients = validDishItems + validMarinadeItems + validSeasoningItems + validBatterItems + validSauceItems + validBaseItems + validDoughItems + validToppingItems
            
            // Convert to string format for API
            let ingredientsStrings = allValidIngredients.map { item in
                var parts: [String] = []
                if !item.amount.isEmpty {
                    parts.append(item.amount)
                }
                if !item.unit.isEmpty {
                    parts.append(item.unit)
                }
                if !item.name.isEmpty {
                    parts.append(item.name)
                }
                return parts.joined(separator: " ")
            }
            
            let validInstructions = instructions.compactMap { $0.text.isEmpty ? nil : $0.text }
            
            if let detectedCuisine = try await OpenAIService.detectCuisine(
                title: title,
                ingredients: ingredientsStrings,
                instructions: validInstructions
            ) {
                cuisine = detectedCuisine
            }
        } catch {
            // Silently fail for cuisine detection - it's not critical
            print("Failed to detect cuisine: \(error.localizedDescription)")
        }
        
        isDetectingCuisine = false
    }
}

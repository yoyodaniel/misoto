//
//  EditRecipeViewModel.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine
import FirebaseAuth
import UIKit
import PhotosUI
import SwiftUI

@MainActor
class EditRecipeViewModel: ObservableObject {
    let recipe: Recipe
    
    @Published var title = ""
    @Published var description = ""
    @Published var dishIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var marinadeIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var seasoningIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var batterIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var sauceIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var baseIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var doughIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var toppingIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var instructions: [InstructionItem] = []
    @Published var prepTime = 0
    @Published var cookTime = 0
    @Published var servings = 1
    @Published var difficulty: Recipe.Difficulty = .c
    @Published var spicyLevel: Recipe.SpicyLevel = .none
    @Published var tips: [String] = []
    @Published var cuisine: String? = nil
    @Published var mainRecipeImages: [UIImage] = []
    @Published var sourceImageURLs: [String] = []
    
    // Track mapping: index in mainRecipeImages -> original URL (if it came from URL)
    // If an image doesn't have a URL in this map, it's a new image that needs uploading
    private var imageIndexToURL: [Int: String] = [:]
    // Track which URLs were explicitly deleted (for cleanup from storage)
    private var deletedImageURLs: Set<String> = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isGeneratingDescription = false
    @Published var isDetectingCuisine = false
    
    private let recipeService = RecipeService()
    private let storageService = StorageService()
    
    struct InstructionItem: Identifiable {
        var id: String
        var text: String
        var image: UIImage?
        var videoURL: URL?
        var existingImageURL: String?
        var existingVideoURL: String?
        
        init(id: String = UUID().uuidString, text: String, image: UIImage? = nil, videoURL: URL? = nil, existingImageURL: String? = nil, existingVideoURL: String? = nil) {
            self.id = id
            self.text = text
            self.image = image
            self.videoURL = videoURL
            self.existingImageURL = existingImageURL
            self.existingVideoURL = existingVideoURL
        }
    }
    
    init(recipe: Recipe) {
        self.recipe = recipe
        loadRecipeData()
    }
    
    private func loadRecipeData() {
        title = recipe.title
        description = recipe.description
        prepTime = recipe.prepTime
        cookTime = recipe.cookTime
        servings = recipe.servings
        difficulty = recipe.difficulty
        spicyLevel = recipe.spicyLevel
        tips = recipe.tips
        cuisine = recipe.cuisine
        
        // Convert ingredients to IngredientItem format
        dishIngredients = []
        marinadeIngredients = []
        seasoningIngredients = []
        batterIngredients = []
        sauceIngredients = []
        baseIngredients = []
        doughIngredients = []
        toppingIngredients = []
        
        for ingredient in recipe.ingredients {
            let item = RecipeTextParser.IngredientItem(
                amount: ingredient.amount,
                unit: ingredient.unit,
                name: ingredient.name
            )
            
            if let category = ingredient.category {
                switch category {
                case .dish:
                    dishIngredients.append(item)
                case .marinade:
                    marinadeIngredients.append(item)
                case .seasoning:
                    seasoningIngredients.append(item)
                case .batter:
                    batterIngredients.append(item)
                case .sauce:
                    sauceIngredients.append(item)
                case .base:
                    baseIngredients.append(item)
                case .dough:
                    doughIngredients.append(item)
                case .topping:
                    toppingIngredients.append(item)
                }
            } else {
                // Default to dish if no category
                dishIngredients.append(item)
            }
        }
        
        // Ensure at least one dish ingredient
        if dishIngredients.isEmpty {
            dishIngredients = [RecipeTextParser.IngredientItem(amount: "", unit: "", name: "")]
        }
        
        // Convert instructions
        instructions = recipe.instructions.map { instruction in
            InstructionItem(
                id: instruction.id,
                text: instruction.text,
                existingImageURL: instruction.imageURL,
                existingVideoURL: instruction.videoURL
            )
        }
        
        // Ensure at least one instruction
        if instructions.isEmpty {
            instructions = [InstructionItem(text: "")]
        }
        
        // Store existing image URLs from array (or fallback to single imageURL for backward compatibility)
        let existingURLs = recipe.imageURLs.isEmpty && recipe.imageURL != nil ? [recipe.imageURL!] : recipe.imageURLs
        
        // Pre-allocate array with placeholders, then load images asynchronously
        mainRecipeImages = Array(repeating: UIImage(), count: existingURLs.count)
        
        // Load existing images from URLs asynchronously and track their indices
        for (index, urlString) in existingURLs.enumerated() {
            imageIndexToURL[index] = urlString
            Task {
                await loadImageFromURL(urlString, at: index)
            }
        }
        
        // Store source image URLs if available
        if let sourceImageURL = recipe.sourceImageURL {
            sourceImageURLs = [sourceImageURL]
        }
    }
    
    // MARK: - Image Loading
    
    private func loadImageFromURL(_ urlString: String, at index: Int) async {
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    // Replace placeholder at the correct index
                    if index < mainRecipeImages.count {
                        mainRecipeImages[index] = image
                    }
                }
            }
        } catch {
            print("Failed to load image from URL: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Ingredient Management
    
    func addDishIngredient() {
        dishIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func removeDishIngredient(at index: Int) {
        guard index < dishIngredients.count else { return }
        dishIngredients.remove(at: index)
        if dishIngredients.isEmpty {
            dishIngredients = [RecipeTextParser.IngredientItem(amount: "", unit: "", name: "")]
        }
    }
    
    func updateDishIngredientAmount(_ amount: String, at index: Int) {
        guard index < dishIngredients.count else { return }
        dishIngredients[index].amount = amount
    }
    
    func updateDishIngredientUnit(_ unit: String, at index: Int) {
        guard index < dishIngredients.count else { return }
        dishIngredients[index].unit = unit
    }
    
    func updateDishIngredientName(_ name: String, at index: Int) {
        guard index < dishIngredients.count else { return }
        dishIngredients[index].name = name
    }
    
    // Similar methods for other ingredient types...
    func addMarinadeIngredient() { marinadeIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: "")) }
    func removeMarinadeIngredient(at index: Int) { if index < marinadeIngredients.count { marinadeIngredients.remove(at: index) } }
    func updateMarinadeIngredientAmount(_ amount: String, at index: Int) { if index < marinadeIngredients.count { marinadeIngredients[index].amount = amount } }
    func updateMarinadeIngredientUnit(_ unit: String, at index: Int) { if index < marinadeIngredients.count { marinadeIngredients[index].unit = unit } }
    func updateMarinadeIngredientName(_ name: String, at index: Int) { if index < marinadeIngredients.count { marinadeIngredients[index].name = name } }
    
    func addSeasoningIngredient() { seasoningIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: "")) }
    func removeSeasoningIngredient(at index: Int) { if index < seasoningIngredients.count { seasoningIngredients.remove(at: index) } }
    func updateSeasoningIngredientAmount(_ amount: String, at index: Int) { if index < seasoningIngredients.count { seasoningIngredients[index].amount = amount } }
    func updateSeasoningIngredientUnit(_ unit: String, at index: Int) { if index < seasoningIngredients.count { seasoningIngredients[index].unit = unit } }
    func updateSeasoningIngredientName(_ name: String, at index: Int) { if index < seasoningIngredients.count { seasoningIngredients[index].name = name } }
    
    func addBatterIngredient() { batterIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: "")) }
    func removeBatterIngredient(at index: Int) { if index < batterIngredients.count { batterIngredients.remove(at: index) } }
    func updateBatterIngredientAmount(_ amount: String, at index: Int) { if index < batterIngredients.count { batterIngredients[index].amount = amount } }
    func updateBatterIngredientUnit(_ unit: String, at index: Int) { if index < batterIngredients.count { batterIngredients[index].unit = unit } }
    func updateBatterIngredientName(_ name: String, at index: Int) { if index < batterIngredients.count { batterIngredients[index].name = name } }
    
    func addSauceIngredient() { sauceIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: "")) }
    func removeSauceIngredient(at index: Int) { if index < sauceIngredients.count { sauceIngredients.remove(at: index) } }
    func updateSauceIngredientAmount(_ amount: String, at index: Int) { if index < sauceIngredients.count { sauceIngredients[index].amount = amount } }
    func updateSauceIngredientUnit(_ unit: String, at index: Int) { if index < sauceIngredients.count { sauceIngredients[index].unit = unit } }
    func updateSauceIngredientName(_ name: String, at index: Int) { if index < sauceIngredients.count { sauceIngredients[index].name = name } }
    
    func addBaseIngredient() { baseIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: "")) }
    func removeBaseIngredient(at index: Int) { if index < baseIngredients.count { baseIngredients.remove(at: index) } }
    func updateBaseIngredientAmount(_ amount: String, at index: Int) { if index < baseIngredients.count { baseIngredients[index].amount = amount } }
    func updateBaseIngredientUnit(_ unit: String, at index: Int) { if index < baseIngredients.count { baseIngredients[index].unit = unit } }
    func updateBaseIngredientName(_ name: String, at index: Int) { if index < baseIngredients.count { baseIngredients[index].name = name } }
    
    func addDoughIngredient() { doughIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: "")) }
    func removeDoughIngredient(at index: Int) { if index < doughIngredients.count { doughIngredients.remove(at: index) } }
    func updateDoughIngredientAmount(_ amount: String, at index: Int) { if index < doughIngredients.count { doughIngredients[index].amount = amount } }
    func updateDoughIngredientUnit(_ unit: String, at index: Int) { if index < doughIngredients.count { doughIngredients[index].unit = unit } }
    func updateDoughIngredientName(_ name: String, at index: Int) { if index < doughIngredients.count { doughIngredients[index].name = name } }
    
    func addToppingIngredient() { toppingIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: "")) }
    func removeToppingIngredient(at index: Int) { if index < toppingIngredients.count { toppingIngredients.remove(at: index) } }
    func updateToppingIngredientAmount(_ amount: String, at index: Int) { if index < toppingIngredients.count { toppingIngredients[index].amount = amount } }
    func updateToppingIngredientUnit(_ unit: String, at index: Int) { if index < toppingIngredients.count { toppingIngredients[index].unit = unit } }
    func updateToppingIngredientName(_ name: String, at index: Int) { if index < toppingIngredients.count { toppingIngredients[index].name = name } }
    
    // MARK: - Instruction Management
    
    func addInstruction() {
        instructions.append(InstructionItem(text: ""))
    }
    
    func removeInstruction(at index: Int) {
        guard index < instructions.count else { return }
        instructions.remove(at: index)
        if instructions.isEmpty {
            instructions = [InstructionItem(text: "")]
        }
    }
    
    func moveInstruction(from source: IndexSet, to destination: Int) {
        instructions.move(fromOffsets: source, toOffset: destination)
    }
    
    func setInstructionText(_ text: String, at index: Int) {
        guard index < instructions.count else { return }
        instructions[index].text = text
    }
    
    func setInstructionImage(_ image: UIImage?, at index: Int) {
        guard index < instructions.count else { return }
        instructions[index].image = image
        // Clear existing URL when new image is set
        if image != nil {
            instructions[index].existingImageURL = nil
        }
    }
    
    func setInstructionVideo(_ videoURL: URL?, at index: Int) {
        guard index < instructions.count else { return }
        instructions[index].videoURL = videoURL
        // Clear existing URL when new video is set
        if videoURL != nil {
            instructions[index].existingVideoURL = nil
        }
    }
    
    func removeInstructionMedia(at index: Int) {
        guard index < instructions.count else { return }
        instructions[index].image = nil
        instructions[index].videoURL = nil
        instructions[index].existingImageURL = nil
        instructions[index].existingVideoURL = nil
    }
    
    // MARK: - Recipe Image Management
    
    func addRecipeImage(_ image: UIImage) {
        if mainRecipeImages.count < 5 {
            mainRecipeImages.append(image)
        }
    }
    
    func removeRecipeImage(at index: Int) {
        guard index < mainRecipeImages.count else { return }
        
        // If this image has an associated URL, mark it for deletion
        if let url = imageIndexToURL[index] {
            deletedImageURLs.insert(url)
        }
        
        mainRecipeImages.remove(at: index)
        
        // Rebuild the index mapping after removal
        var newMapping: [Int: String] = [:]
        for (oldIndex, url) in imageIndexToURL {
            if oldIndex < index {
                // Index before removed item stays the same
                newMapping[oldIndex] = url
            } else if oldIndex > index {
                // Index after removed item shifts down by 1
                newMapping[oldIndex - 1] = url
            }
            // oldIndex == index is skipped (deleted)
        }
        imageIndexToURL = newMapping
    }
    
    
    // MARK: - Save Recipe
    
    func updateRecipe() async -> Bool {
        guard let userID = Auth.auth().currentUser?.uid,
              let displayName = Auth.auth().currentUser?.displayName else {
            errorMessage = NSLocalizedString("You must be logged in to update a recipe", comment: "Not logged in error")
            return false
        }
        
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = NSLocalizedString("Title is required", comment: "Title required error")
            return false
        }
        
        // Combine all ingredient types, filter out empty ones
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
            errorMessage = NSLocalizedString("At least one ingredient is required", comment: "Ingredients required error")
            return false
        }
        
        // Convert ingredient items to Ingredient objects with IDs and categories
        var ingredientObjects: [Ingredient] = []
        
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
            errorMessage = NSLocalizedString("At least one instruction is required", comment: "Instructions required error")
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Delete removed images from storage
            for deletedURL in deletedImageURLs {
                do {
                    try await storageService.deleteFile(from: deletedURL)
                } catch {
                    print("Failed to delete image from storage: \(error.localizedDescription)")
                    // Continue even if deletion fails
                }
            }
            
            // Process recipe images: upload new ones, keep existing URLs
            var finalImageURLs: [String] = []
            
            for (index, image) in mainRecipeImages.enumerated() {
                if let existingURL = imageIndexToURL[index] {
                    // Keep existing URL (image wasn't changed)
                    finalImageURLs.append(existingURL)
                } else {
                    // New image, upload it
                    let imagePath = "recipes/\(UUID().uuidString).jpg"
                    let url = try await storageService.uploadImage(image, path: imagePath)
                    finalImageURLs.append(url)
                }
            }
            
            // Use first image URL for backward compatibility
            let mainImageURL = finalImageURLs.first
            
            // Upload instruction images/videos and create Instruction objects
            var uploadedInstructions: [Instruction] = []
            for (index, instructionItem) in validInstructions.enumerated() {
                var imageURL: String? = instructionItem.existingImageURL
                var videoURL: String? = instructionItem.existingVideoURL
                
                // Upload new image if present
                if let image = instructionItem.image {
                    let imagePath = "recipe-instructions/\(UUID().uuidString).jpg"
                    imageURL = try await storageService.uploadImage(image, path: imagePath)
                }
                
                // Upload new video if present
                if let videoURLToUpload = instructionItem.videoURL {
                    let videoPath = "recipe-instructions/\(UUID().uuidString).mp4"
                    videoURL = try await storageService.uploadVideo(videoURLToUpload, path: videoPath)
                }
                
                let instruction = Instruction(
                    id: instructionItem.id,
                    text: instructionItem.text.trimmingCharacters(in: .whitespaces),
                    imageURL: imageURL,
                    videoURL: videoURL
                )
                uploadedInstructions.append(instruction)
            }
            
            // Create updated recipe
            let updatedRecipe = Recipe(
                id: recipe.id, // Keep original ID
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
                imageURLs: finalImageURLs, // Array of all image URLs
                authorID: recipe.authorID, // Keep original author
                authorName: recipe.authorName, // Keep original author name
                authorUsername: recipe.authorUsername, // Keep original author username
                createdAt: recipe.createdAt, // Keep original creation date
                updatedAt: Date(), // Update this
                favoriteCount: recipe.favoriteCount // Keep original favorite count
            )
            
            try await recipeService.updateRecipe(updatedRecipe)
            
            // Post notification to refresh account view
            NotificationCenter.default.post(name: NSNotification.Name("RecipeSaved"), object: nil)
            
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    // MARK: - AI Generation Methods
    
    /// Generate a description for the recipe using AI
    func generateDescription() async {
        guard !title.isEmpty else { return }
        
        isGeneratingDescription = true
        
        do {
            // Convert ingredients to string format for API
            let allIngredients = (dishIngredients + marinadeIngredients + seasoningIngredients + batterIngredients + sauceIngredients + baseIngredients + doughIngredients + toppingIngredients)
                .map { item in
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
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            let validInstructions = instructions.compactMap { $0.text.isEmpty ? nil : $0.text }
            
            let generatedDescription = try await OpenAIService.generateRecipeDescription(
                title: title,
                ingredients: allIngredients,
                instructions: validInstructions
            )
            
            if !generatedDescription.isEmpty {
                description = generatedDescription
            }
        } catch {
            print("Error generating description: \(error.localizedDescription)")
        }
        
        isGeneratingDescription = false
    }
}


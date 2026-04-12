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
    @Published var doughBatterFillingIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var sauceIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var toppingIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var garnishIngredients: [RecipeTextParser.IngredientItem] = []
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
    @Published var isEditingInstructions = false
    @Published private(set) var canUndoLastInstructionAIEdit = false
    @Published private(set) var canRedoLastInstructionAIEdit = false
    @Published private(set) var canUndoDescriptionAIEdit = false
    @Published private(set) var canRedoDescriptionAIEdit = false
    @Published var isTipsAILoading = false
    @Published private(set) var canUndoTipsAIEdit = false
    @Published private(set) var canRedoTipsAIEdit = false
    
    /// Visibility for this new recipe (initialized from Settings; user can change before upload).
    @Published var postSharing: AppSettings.DefaultPostSharing = AppSettings.shared.defaultPostSharing
    
    private let recipeService = RecipeService.shared
    private let storageService = StorageService()
    private let authService = AuthService()
    
    /// Snapshots of instructions before each successful AI polish or auto-generate (most recent last). Undo pops one level at a time.
    private var instructionAIUndoStack: [[InstructionItem]] = []
    /// States cancelled by undo; redo restores most recent first. Cleared when a new AI edit is applied.
    private var instructionAIRedoStack: [[InstructionItem]] = []
    private let maxInstructionAIUndoDepth = 30
    
    private var descriptionAIUndoStack: [String] = []
    private var descriptionAIRedoStack: [String] = []
    private let maxDescriptionAIUndoDepth = 30
    
    private var tipsAIUndoStack: [[String]] = []
    private var tipsAIRedoStack: [[String]] = []
    private let maxTipsAIUndoDepth = 30
    
    struct InstructionItem: Identifiable {
        var id = UUID()
        var text: String = ""
        var image: UIImage?
        var videoURL: URL?
        
        func toInstruction() -> Instruction {
            return Instruction(text: text)
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    /// Time to wait after the last edit before recording an undo milestone (manual typing).
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
    
    init() {
        setupDebouncedEditUndoSubscriptions()
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
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = LocalizedString("You must be logged in to upload a recipe", comment: "Not logged in error")
            return
        }
        
        // Check recipe creation limit for free tier users
        do {
            let canCreate = try await SubscriptionHelper.checkRecipeCreationLimit()
            if !canCreate {
                errorMessage = LocalizedString("You have reached the free tier limit", comment: "Recipe limit error")
                return
            }
        } catch {
            print("⚠️ Error checking recipe limit: \(error.localizedDescription)")
            // Continue anyway - don't block user if check fails
        }
        
        // Get display name from AuthService (ensure user data is loaded)
        await authService.reloadUserData()
        let username = authService.currentUser?.username
        let displayName = authService.currentUser?.displayName ?? Auth.auth().currentUser?.displayName ?? "User"
        // Use display name (actual name) for authorName, fall back to username if display name is empty
        let authorName = displayName.isEmpty ? (username ?? "User") : displayName
        
        // Validate
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = LocalizedString("Title is required", comment: "Title required error")
            return
        }
        
        // Collect all valid ingredients from all sections
        let validDishItems = dishIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validMarinadeItems = marinadeIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validSeasoningItems = seasoningIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validDoughBatterFillingItems = doughBatterFillingIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validSauceItems = sauceIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validToppingItems = toppingIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validGarnishItems = garnishIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        
        let allValidIngredients = validDishItems + validMarinadeItems + validSeasoningItems + validDoughBatterFillingItems + validSauceItems + validToppingItems + validGarnishItems
        
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
            } else if validDoughBatterFillingItems.contains(where: { $0.name == item.name && $0.amount == item.amount && $0.unit == item.unit }) {
                category = .batter // Default to .batter for consolidated dough/batter/filling section
            } else if validSauceItems.contains(where: { $0.name == item.name && $0.amount == item.amount && $0.unit == item.unit }) {
                category = .sauce
            } else if validToppingItems.contains(where: { $0.name == item.name && $0.amount == item.amount && $0.unit == item.unit }) {
                category = .topping
            } else if validGarnishItems.contains(where: { $0.name == item.name && $0.amount == item.amount && $0.unit == item.unit }) {
                category = .garnish
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
            for instructionItem in validInstructions {
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
            
            // Translate title to English, local language, and preserve original
            let titleTrimmed = title.trimmingCharacters(in: .whitespaces)
            let (titleEnglish, titleLocal, titleOriginal) = await RecipeTranslationService.translateTitle(titleTrimmed)
            
            // Use original language as primary title
            let primaryTitle = titleOriginal ?? (titleLocal.isEmpty ? titleEnglish : titleLocal)
            
            // Save cuisine in English (translations are handled by CuisineTranslations)
            let cuisineEnglish: String? = cuisine?.trimmingCharacters(in: .whitespaces).isEmpty == false ? cuisine?.trimmingCharacters(in: .whitespaces) : nil
            
            // Create recipe with uploaded media URLs
            let recipe = Recipe(
                title: primaryTitle, // Use original language as primary
                titleEnglish: titleEnglish,
                titleLocal: titleLocal,
                titleOriginal: titleOriginal,
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
                cuisineEnglish: cuisineEnglish,
                imageURL: mainImageURL, // For backward compatibility
                imageURLs: allImageURLs, // Array of all image URLs
                authorID: userID,
                authorName: authorName,
                authorUsername: username,
                isPrivate: postSharing.isPrivateRecipe
            )
            
            // Profanity check - first line of defense
            print("🔍 Running profanity check on recipe...")
            let profanityCheck = ProfanityFilter.shared.checkRecipe(recipe)
            if profanityCheck.hasProfanity {
                print("🚫 Profanity detected! Field: \(profanityCheck.field ?? "unknown"), Words: \(profanityCheck.detectedWords)")
                let errorMsg = ProfanityFilter.shared.getErrorMessage(
                    field: profanityCheck.field,
                    detectedWords: profanityCheck.detectedWords
                )
                print("🚫 Throwing error: \(errorMsg)")
                errorMessage = errorMsg
                isLoading = false
                return
            }
            print("✅ Profanity check passed")
            
            try await recipeService.createRecipe(recipe)
            
            // Track recipe creation for free tier users
            try? await SubscriptionHelper.trackRecipeCreation()
            
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
        doughBatterFillingIngredients = []
        sauceIngredients = []
        toppingIngredients = []
        garnishIngredients = []
        instructions = [InstructionItem()]
        prepTime = 15
        cookTime = 30
        servings = 4
        difficulty = .c
        spicyLevel = .none
        tips = []
        cuisine = nil
        mainRecipeImages = []
        resetDebouncedUndoRedoStateForNewForm()
    }
    
    // MARK: - Debounced undo / redo (description, tips, instructions)
    
    private func setupDebouncedEditUndoSubscriptions() {
        syncDescriptionCommittedFromCurrent()
        syncTipsCommittedFromCurrent()
        syncInstructionsCommittedFromCurrent()
        
        $description
            .sink { [weak self] _ in
                guard let self, !self.suppressDescriptionUndoScheduling else { return }
                self.scheduleDescriptionUndoCheckpoint()
            }
            .store(in: &cancellables)
        
        $tips
            .sink { [weak self] _ in
                guard let self, !self.suppressTipsUndoScheduling else { return }
                self.scheduleTipsUndoCheckpoint()
            }
            .store(in: &cancellables)
        
        $instructions
            .sink { [weak self] _ in
                guard let self, !self.suppressInstructionsUndoScheduling else { return }
                self.scheduleInstructionsUndoCheckpoint()
            }
            .store(in: &cancellables)
    }
    
    private func resetDebouncedUndoRedoStateForNewForm() {
        descriptionUndoDebounceTask?.cancel()
        tipsUndoDebounceTask?.cancel()
        instructionsUndoDebounceTask?.cancel()
        descriptionAIUndoStack.removeAll()
        descriptionAIRedoStack.removeAll()
        tipsAIUndoStack.removeAll()
        tipsAIRedoStack.removeAll()
        instructionAIUndoStack.removeAll()
        instructionAIRedoStack.removeAll()
        canUndoDescriptionAIEdit = false
        canRedoDescriptionAIEdit = false
        canUndoTipsAIEdit = false
        canRedoTipsAIEdit = false
        canUndoLastInstructionAIEdit = false
        canRedoLastInstructionAIEdit = false
        syncDescriptionCommittedFromCurrent()
        syncTipsCommittedFromCurrent()
        syncInstructionsCommittedFromCurrent()
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
        tipsUndoDebounceTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: self.debouncedEditUndoDelayNanoseconds)
            guard !Task.isCancelled else { return }
            await self.flushTipsUndoCheckpointIfNeeded()
        }
    }
    
    private func flushTipsUndoCheckpointIfNeeded() {
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
        guard !suppressInstructionsUndoScheduling else { return }
        let current = copyInstructionsForUndo(instructions)
        guard !instructionItemsTextuallyEqual(current, instructionsCommitted) else { return }
        instructionAIRedoStack.removeAll()
        canRedoLastInstructionAIEdit = false
        pushToUndoStack(copyInstructionsForUndo(instructionsCommitted))
        instructionsCommitted = current
        canUndoLastInstructionAIEdit = !instructionAIUndoStack.isEmpty
    }
    
    // MARK: - AI Generation Methods
    
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
    
    /// Generate a description for the recipe using AI
    func generateDescription() async {
        descriptionUndoDebounceTask?.cancel()
        guard !title.isEmpty else {
            errorMessage = LocalizedString("Please enter a recipe title first", comment: "Title required for description")
            return
        }
        
        isGeneratingDescription = true
        errorMessage = nil
        
        do {
            let generatedDescription = try await OpenAIService.generateRecipeDescription(
                title: title,
                ingredients: allIngredientStringsForAI(),
                instructions: instructionTextsForAI(),
                backgroundContext: nil // No background context for manual upload
            )
            
            if !generatedDescription.isEmpty {
                captureDescriptionSnapshotForUndo()
                description = generatedDescription
                descriptionCommitted = description
            }
        } catch {
            errorMessage = LocalizedString("Failed to generate description: \(error.localizedDescription)", comment: "Description generation error")
        }
        
        isGeneratingDescription = false
    }
    
    /// Polishes description wording (Foundation Models when available, else OpenAI).
    func polishDescriptionWithAI() async {
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
    
    /// Polishes tip lines (Foundation Models when available, else OpenAI).
    func polishTipsWithAI() async {
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
    
    /// Generates suggested tips from title, ingredients, instructions, and description (OpenAI).
    func generateTipsWithOpenAI() async {
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
    
    /// Improves spelling/grammar using Apple Foundation Models when available, otherwise OpenAI.
    func improveInstructionsWithAI() async {
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
            print("✅ Instructions improved (Foundation or OpenAI fallback)")
        } catch {
            errorMessage = String(format: LocalizedString("Failed to polish instructions: %@", comment: "AI instruction polish error"), error.localizedDescription)
        }
        
        isEditingInstructions = false
    }
    
    /// Generates new steps from title + ingredients using OpenAI (replaces current steps).
    func generateInstructionsWithOpenAI() async {
        instructionsUndoDebounceTask?.cancel()
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = LocalizedString("Please enter a recipe title first", comment: "Title required for AI instructions")
            return
        }
        
        isEditingInstructions = true
        errorMessage = nil
        
        do {
            let allIngredients = (dishIngredients + marinadeIngredients + seasoningIngredients + doughBatterFillingIngredients + sauceIngredients + toppingIngredients + garnishIngredients)
                .filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
                .map { item in
                    var parts: [String] = []
                    if !item.amount.isEmpty { parts.append(item.amount) }
                    if !item.unit.isEmpty { parts.append(item.unit) }
                    if !item.name.isEmpty { parts.append(item.name) }
                    return parts.joined(separator: " ")
                }
            
            let generatedSteps = try await RecipeInstructionAI.generateInstructionStrings(
                title: title,
                ingredients: allIngredients
            )
            
            captureInstructionsSnapshotForUndo()
            instructions = generatedSteps.map { text in
                InstructionItem(text: text)
            }
            instructionsCommitted = copyInstructionsForUndo(instructions)
            print("✅ Instructions generated by OpenAI: \(generatedSteps.count) steps")
        } catch {
            errorMessage = LocalizedString("Failed to generate instructions: \(error.localizedDescription)", comment: "AI instruction generation error")
        }
        
        isEditingInstructions = false
    }
    
    /// Restores instructions to the state before the most recent successful AI polish or auto-generate. Call again to step further back.
    func undoLastInstructionAIEdit() {
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
    
    /// Re-applies instructions after an undo (same order as undone).
    func redoLastInstructionAIEdit() {
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
            let validDoughBatterFillingItems = doughBatterFillingIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            let validSauceItems = sauceIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            let validToppingItems = toppingIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            let validGarnishItems = garnishIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            
            let allValidIngredients = validDishItems + validMarinadeItems + validSeasoningItems + validDoughBatterFillingItems + validSauceItems + validToppingItems + validGarnishItems
            
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

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
    @Published var titleEnglish: String? = nil
    @Published var titleLocal: String? = nil
    @Published var titleOriginal: String? = nil
    @Published var description = ""
    @Published var dishIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var marinadeIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var seasoningIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var doughBatterFillingIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var sauceIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var toppingIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var garnishIngredients: [RecipeTextParser.IngredientItem] = []
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
    // Track image loading tasks for cleanup
    private var imageLoadingTasks: [Task<Void, Never>] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isGeneratingDescription = false
    @Published var isDetectingCuisine = false
    @Published var nutritionInfo: NutritionInfo?
    @Published var isEstimatingNutrition = false
    @Published var isEditingInstructions = false
    @Published private(set) var canUndoLastInstructionAIEdit = false
    @Published private(set) var canRedoLastInstructionAIEdit = false
    @Published private(set) var canUndoDescriptionAIEdit = false
    @Published private(set) var canRedoDescriptionAIEdit = false
    @Published var isTipsAILoading = false
    @Published private(set) var canUndoTipsAIEdit = false
    @Published private(set) var canRedoTipsAIEdit = false
    
    private let recipeService = RecipeService.shared
    private let storageService = StorageService()
    
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
    
    struct InstructionItem {
        var text: String
        var image: UIImage?
        var videoURL: URL?
        var existingImageURL: String?
        var existingVideoURL: String?
        
        init(text: String, image: UIImage? = nil, videoURL: URL? = nil, existingImageURL: String? = nil, existingVideoURL: String? = nil) {
            self.text = text
            self.image = image
            self.videoURL = videoURL
            self.existingImageURL = existingImageURL
            self.existingVideoURL = existingVideoURL
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
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
    
    init(recipe: Recipe) {
        self.recipe = recipe
        loadRecipeData()
        setupDebouncedEditUndoSubscriptions()
    }
    
    deinit {
        descriptionUndoDebounceTask?.cancel()
        tipsUndoDebounceTask?.cancel()
        instructionsUndoDebounceTask?.cancel()
        // Cancel all image loading tasks when ViewModel is deallocated
        for task in imageLoadingTasks {
            task.cancel()
        }
        imageLoadingTasks.removeAll()
    }
    
    private func loadRecipeData() {
        titleEnglish = recipe.titleEnglish
        titleLocal = recipe.titleLocal
        titleOriginal = recipe.titleOriginal
        
        // Set the editable title based on user's current language preference
        let currentLanguage = LocalizationManager.shared.currentLanguage
        if currentLanguage == .english {
            // If user is using English, show English title
            title = recipe.titleEnglish ?? recipe.title
        } else {
            // If user is NOT using English, show local language title (system language)
            title = recipe.titleLocal ?? recipe.titleEnglish ?? recipe.title
        }
        
        description = recipe.description
        prepTime = recipe.prepTime
        cookTime = recipe.cookTime
        servings = recipe.servings
        difficulty = recipe.difficulty
        spicyLevel = recipe.spicyLevel
        tips = recipe.tips
        cuisine = recipe.cuisine
        nutritionInfo = recipe.nutritionInfo
        
        // Convert ingredients to IngredientItem format
        dishIngredients = []
        marinadeIngredients = []
        seasoningIngredients = []
        doughBatterFillingIngredients = []
        sauceIngredients = []
        toppingIngredients = []
        garnishIngredients = []
        
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
                case .batter, .base, .dough, .filling:
                    // Consolidate batter, base, dough, and filling into doughBatterFillingIngredients
                    doughBatterFillingIngredients.append(item)
                case .sauce:
                    sauceIngredients.append(item)
                case .topping:
                    toppingIngredients.append(item)
                case .garnish:
                    garnishIngredients.append(item)
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
            let task = Task {
                await loadImageFromURL(urlString, at: index)
            }
            imageLoadingTasks.append(task)
        }
        
        // Store source image URLs if available (use array, fallback to single URL for backward compatibility)
        if !recipe.sourceImageURLs.isEmpty {
            sourceImageURLs = recipe.sourceImageURLs
        } else if let sourceImageURL = recipe.sourceImageURL {
            sourceImageURLs = [sourceImageURL]
        }
        
        resetDebouncedUndoRedoStateAfterRecipeLoad()
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
    
    private func resetDebouncedUndoRedoStateAfterRecipeLoad() {
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
        tipsUndoDebounceTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: self.debouncedEditUndoDelayNanoseconds)
            guard !Task.isCancelled else { return }
            self.flushTipsUndoCheckpointIfNeeded()
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
        return zip(a, b).allSatisfy { $0.text == $1.text }
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
    
    // MARK: - Image Loading
    
    private func loadImageFromURL(_ urlString: String, at index: Int) async {
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                // Resize image for display to reduce memory usage
                let optimizedImage = ImageOptimizer.resizeForDisplay(image, maxDimension: 1200)
                await MainActor.run {
                    // Replace placeholder at the correct index
                    if index < mainRecipeImages.count {
                        mainRecipeImages[index] = optimizedImage
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
    
    func addDoughBatterFillingIngredient() { doughBatterFillingIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: "")) }
    func removeDoughBatterFillingIngredient(at index: Int) { if index < doughBatterFillingIngredients.count { doughBatterFillingIngredients.remove(at: index) } }
    func updateDoughBatterFillingIngredientAmount(_ amount: String, at index: Int) { if index < doughBatterFillingIngredients.count { doughBatterFillingIngredients[index].amount = amount } }
    func updateDoughBatterFillingIngredientUnit(_ unit: String, at index: Int) { if index < doughBatterFillingIngredients.count { doughBatterFillingIngredients[index].unit = unit } }
    func updateDoughBatterFillingIngredientName(_ name: String, at index: Int) { if index < doughBatterFillingIngredients.count { doughBatterFillingIngredients[index].name = name } }
    
    func addSauceIngredient() { sauceIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: "")) }
    func removeSauceIngredient(at index: Int) { if index < sauceIngredients.count { sauceIngredients.remove(at: index) } }
    func updateSauceIngredientAmount(_ amount: String, at index: Int) { if index < sauceIngredients.count { sauceIngredients[index].amount = amount } }
    func updateSauceIngredientUnit(_ unit: String, at index: Int) { if index < sauceIngredients.count { sauceIngredients[index].unit = unit } }
    func updateSauceIngredientName(_ name: String, at index: Int) { if index < sauceIngredients.count { sauceIngredients[index].name = name } }
    
    func addToppingIngredient() { toppingIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: "")) }
    func removeToppingIngredient(at index: Int) { if index < toppingIngredients.count { toppingIngredients.remove(at: index) } }
    func updateToppingIngredientAmount(_ amount: String, at index: Int) { if index < toppingIngredients.count { toppingIngredients[index].amount = amount } }
    func updateToppingIngredientUnit(_ unit: String, at index: Int) { if index < toppingIngredients.count { toppingIngredients[index].unit = unit } }
    func updateToppingIngredientName(_ name: String, at index: Int) { if index < toppingIngredients.count { toppingIngredients[index].name = name } }
    
    func addGarnishIngredient() { garnishIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: "")) }
    func removeGarnishIngredient(at index: Int) { if index < garnishIngredients.count { garnishIngredients.remove(at: index) } }
    func updateGarnishIngredientAmount(_ amount: String, at index: Int) { if index < garnishIngredients.count { garnishIngredients[index].amount = amount } }
    func updateGarnishIngredientUnit(_ unit: String, at index: Int) { if index < garnishIngredients.count { garnishIngredients[index].unit = unit } }
    func updateGarnishIngredientName(_ name: String, at index: Int) { if index < garnishIngredients.count { garnishIngredients[index].name = name } }
    
    // MARK: - Ingredient Reordering
    
    func moveDishIngredient(from source: Int, to destination: Int) {
        dishIngredients.move(fromOffsets: IndexSet(integer: source), toOffset: destination)
    }
    
    func moveMarinadeIngredient(from source: Int, to destination: Int) {
        marinadeIngredients.move(fromOffsets: IndexSet(integer: source), toOffset: destination)
    }
    
    func moveSeasoningIngredient(from source: Int, to destination: Int) {
        seasoningIngredients.move(fromOffsets: IndexSet(integer: source), toOffset: destination)
    }
    
    func moveDoughBatterFillingIngredient(from source: Int, to destination: Int) {
        doughBatterFillingIngredients.move(fromOffsets: IndexSet(integer: source), toOffset: destination)
    }
    
    func moveSauceIngredient(from source: Int, to destination: Int) {
        sauceIngredients.move(fromOffsets: IndexSet(integer: source), toOffset: destination)
    }
    
    func moveToppingIngredient(from source: Int, to destination: Int) {
        toppingIngredients.move(fromOffsets: IndexSet(integer: source), toOffset: destination)
    }
    
    func moveGarnishIngredient(from source: Int, to destination: Int) {
        garnishIngredients.move(fromOffsets: IndexSet(integer: source), toOffset: destination)
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
        
        // Get destination array
        var destinationArray: [RecipeTextParser.IngredientItem] {
            switch destinationCategory {
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
        // This ensures we create a new row instead of updating an existing one
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
    
    func updateRecipe(saveAsPrivate: Bool) async -> Bool {
        guard Auth.auth().currentUser != nil else {
            errorMessage = LocalizedString("You must be logged in to update a recipe", comment: "Not logged in error")
            return false
        }
        
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = LocalizedString("Title is required", comment: "Title required error")
            return false
        }
        
        // Combine all ingredient types, filter out empty ones
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
            for instructionItem in validInstructions {
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
                    text: instructionItem.text.trimmingCharacters(in: .whitespaces),
                    imageURL: imageURL,
                    videoURL: videoURL
                )
                uploadedInstructions.append(instruction)
            }
            
            // Use the three title fields directly (all are now editable) - capitalize them
            let finalTitleEnglish = titleEnglish?.trimmingCharacters(in: .whitespaces).isEmpty == false ? RecipeTranslationService.capitalizeTitle(titleEnglish!.trimmingCharacters(in: .whitespaces)) : nil
            let finalTitleLocal = titleLocal?.trimmingCharacters(in: .whitespaces).isEmpty == false ? RecipeTranslationService.capitalizeTitle(titleLocal!.trimmingCharacters(in: .whitespaces)) : nil
            let finalTitleOriginal = titleOriginal?.trimmingCharacters(in: .whitespaces).isEmpty == false ? RecipeTranslationService.capitalizeTitle(titleOriginal!.trimmingCharacters(in: .whitespaces)) : nil
            
            // Use original language as primary title, fallback to local or English - capitalize it
            let primaryTitle = RecipeTranslationService.capitalizeTitle(finalTitleOriginal ?? finalTitleLocal ?? finalTitleEnglish ?? title.trimmingCharacters(in: .whitespaces))
            
            // Save cuisine in English (translations are handled by CuisineTranslations)
            let cuisineEnglish: String? = cuisine?.trimmingCharacters(in: .whitespaces).isEmpty == false ? cuisine?.trimmingCharacters(in: .whitespaces) : nil
            
            // Best-effort refresh of author metadata. Saving the recipe itself should not
            // fail just because author refresh could not be completed.
            let recipeWithFreshAuthor = (try? await recipeService.refreshRecipeAuthorInfoIfNeeded(recipe)) ?? recipe
            
            // Create updated recipe with fresh author info
            let updatedRecipe = Recipe(
                id: recipe.id, // Keep original ID
                title: primaryTitle, // Use original language as primary
                titleEnglish: finalTitleEnglish,
                titleLocal: finalTitleLocal,
                titleOriginal: finalTitleOriginal,
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
                imageURLs: finalImageURLs, // Array of all image URLs
                sourceImageURL: recipe.sourceImageURLs.first ?? recipe.sourceImageURL, // For backward compatibility
                sourceImageURLs: recipe.sourceImageURLs, // Preserve original source image URLs
                authorID: recipeWithFreshAuthor.authorID, // Keep original author ID
                authorName: recipeWithFreshAuthor.authorName, // Use fresh author name
                authorUsername: recipeWithFreshAuthor.authorUsername, // Use fresh author username
                createdAt: recipe.createdAt, // Keep original creation date
                updatedAt: Date(), // Update this
                favoriteCount: recipe.favoriteCount, // Keep original favorite count
                reportCount: recipe.reportCount,
                isHidden: recipe.isHidden,
                isPrivate: saveAsPrivate,
                sharedWith: saveAsPrivate ? recipe.sharedWith : [],
                preservedSharedWith: saveAsPrivate ? recipe.preservedSharedWith : nil,
                searchKeywords: recipe.searchKeywords,
                nutritionInfo: nutritionInfo // Carry forward or newly estimated nutrition
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
    
    private let nutritionCalculator = NutritionCalculator()
    
    /// Estimate nutrition using USDA database (primary) with AI fallback
    func estimateNutrition() async {
        guard !isEstimatingNutrition else { return }
        
        // Collect all valid ingredients as Ingredient objects
        let allIngredientItems = dishIngredients + marinadeIngredients + seasoningIngredients + doughBatterFillingIngredients + sauceIngredients + toppingIngredients + garnishIngredients
        let validItems = allIngredientItems.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !validItems.isEmpty else { return }
        
        let ingredientObjects = validItems.map {
            Ingredient(
                amount: $0.amount,
                unit: $0.unit,
                name: $0.name
            )
        }
        
        isEstimatingNutrition = true
        
        // 1. Try USDA-based calculation (accurate, database-backed)
        if let usdaInfo = await nutritionCalculator.calculateNutrition(
            title: title,
            ingredients: ingredientObjects,
            servings: servings
        ) {
            print("✅ Nutrition calculated via USDA database")
            nutritionInfo = usdaInfo
            isEstimatingNutrition = false
            return
        }
        
        // 2. Fallback: AI estimation
        print("ℹ️ Falling back to AI nutrition estimation")
        do {
            let info = try await OpenAIService.estimateNutrition(
                title: title,
                ingredients: ingredientObjects,
                servings: servings
            )
            nutritionInfo = info
        } catch {
            print("⚠️ Error estimating nutrition: \(error.localizedDescription)")
        }
        
        isEstimatingNutrition = false
    }
    
    /// Improves instruction wording (Foundation Models when available, else OpenAI).
    func improveInstructionsWithAI() async {
        let hasStep = instructions.contains { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard hasStep else {
            errorMessage = LocalizedString("Add at least one instruction step to polish.", comment: "Need instruction text for polish action")
            return
        }
        
        instructionsUndoDebounceTask?.cancel()
        isEditingInstructions = true
        errorMessage = nil
        
        do {
            let texts = instructions.map(\.text)
            let edited = try await RecipeInstructionAI.improveInstructionStrings(texts)
            captureInstructionsSnapshotForUndo()
            suppressInstructionsUndoScheduling = true
            defer { suppressInstructionsUndoScheduling = false }
            for i in 0..<min(instructions.count, edited.count) {
                instructions[i].text = edited[i]
            }
            instructionsCommitted = copyInstructionsForUndo(instructions)
        } catch {
            errorMessage = String(format: LocalizedString("Failed to polish instructions: %@", comment: "AI instruction polish error"), error.localizedDescription)
        }
        
        isEditingInstructions = false
    }
    
    /// Generates new instruction steps from title + ingredients (OpenAI).
    func generateInstructionsWithOpenAI() async {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = LocalizedString("Please enter a recipe title first", comment: "Title required for AI instructions")
            return
        }
        
        instructionsUndoDebounceTask?.cancel()
        isEditingInstructions = true
        errorMessage = nil
        
        do {
            let allIngredients = ingredientStringsForAI()
            let generated = try await RecipeInstructionAI.generateInstructionStrings(title: title, ingredients: allIngredients)
            captureInstructionsSnapshotForUndo()
            instructions = generated.map { InstructionItem(text: $0) }
            instructionsCommitted = copyInstructionsForUndo(instructions)
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
            InstructionItem(
                text: item.text,
                image: item.image,
                videoURL: item.videoURL,
                existingImageURL: item.existingImageURL,
                existingVideoURL: item.existingVideoURL
            )
        }
    }
    
    private func ingredientStringsForAI() -> [String] {
        (dishIngredients + marinadeIngredients + seasoningIngredients + doughBatterFillingIngredients + sauceIngredients + toppingIngredients + garnishIngredients)
            .map { item in
                var parts: [String] = []
                if !item.amount.isEmpty { parts.append(item.amount) }
                if !item.unit.isEmpty { parts.append(item.unit) }
                if !item.name.isEmpty { parts.append(item.name) }
                return parts.joined(separator: " ")
            }
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    private func instructionTextsForAI() -> [String] {
        instructions.compactMap { $0.text.isEmpty ? nil : $0.text }
    }
    
    /// Generate a description for the recipe using AI
    func generateDescription() async {
        descriptionUndoDebounceTask?.cancel()
        guard !title.isEmpty else { return }
        
        isGeneratingDescription = true
        errorMessage = nil
        
        do {
            let generatedDescription = try await OpenAIService.generateRecipeDescription(
                title: title,
                ingredients: ingredientStringsForAI(),
                instructions: instructionTextsForAI(),
                backgroundContext: nil // No background context for recipe editing
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
        descriptionUndoDebounceTask?.cancel()
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
    
    /// Generates suggested tips from recipe context (OpenAI).
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
                ingredients: ingredientStringsForAI(),
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
}


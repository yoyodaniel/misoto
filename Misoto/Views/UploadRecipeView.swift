//
//  UploadRecipeView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import PhotosUI

struct UploadRecipeView: View {
    // Get localized unit display name for dropdown menu
    private func menuDisplayName(for unit: String) -> String {
        return UnitTranslations.translatedName(for: unit)
    }
    
    // Pluralization mapping for units that need to be pluralized
    private let pluralForms: [String: String] = [
        "cup": "cups",
        "pinch": "pinches",
        "piece": "pieces",
        "pc": "pieces",
        "slice": "slices",
        "clove": "cloves",
        "bunch": "bunches",
        "head": "heads",
        "strand": "strands",
        "large": "large",
        "small": "small"
    ]
    
    // Common units (singular forms only)
    private var commonUnits: [String] {
        ["", "x", "tsp", "tbsp", "cup", "oz", "fl_oz", "lb", "g", "kg", "ml", "l", "pinch", "pc", "slice", "clove", "bunch", "head", "strand", "large", "small"].sorted { unit1, unit2 in
            // Sort: empty first, then "x", then alphabetically
            if unit1.isEmpty { return true }
            if unit2.isEmpty { return false }
            if unit1 == "x" { return true }
            if unit2 == "x" { return false }
            return unit1 < unit2
        }
    }
    
    // Get display name for a unit (shows abbreviation in current language, pluralizes if amount > 1)
    private func displayName(for unit: String, amount: String) -> String {
        if unit.isEmpty {
            return "-"
        }
        
        // Use UnitTranslations to get the language-specific abbreviation with pluralization support
        return UnitTranslations.abbreviation(for: unit, amount: amount)
    }
    
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = UploadRecipeViewModel()
    @State private var selectedRecipePhotos: [PhotosPickerItem] = []
    @State private var showCuisineSelection = false
    @State private var cuisineDetectionTask: Task<Void, Never>?
    @State private var showFullScreenImage = false
    @State private var fullScreenImage: UIImage?
    @State private var selectedInstructionPhotos: [Int: PhotosPickerItem] = [:]
    @State private var showingImagePickerForIndex: Int? = nil
    @State private var showDishImageOptions = false
    @State private var showCameraForDishImage = false
    @State private var showPhotoPickerForDishImage = false
    
    @FocusState private var focusedAmountField: Int?
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    @FocusState private var focusedIngredientNameField: Int?
    @FocusState private var focusedInstructionField: Int?
    
    // Dismiss keyboard
    private func dismissKeyboard() {
        // Clear all focus states
        focusedAmountField = nil
        isTitleFocused = false
        isDescriptionFocused = false
        focusedIngredientNameField = nil
        focusedInstructionField = nil
        
        // Dismiss keyboard using window's endEditing method (more reliable)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.endEditing(true)
        } else {
            // Fallback method
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // Collapse/expand state for sections
    @State private var isTitleExpanded = true
    @State private var isDescriptionExpanded = true
    @State private var isMarinadeExpanded = false
    @State private var isSeasoningExpanded = false
    @State private var isSauceExpanded = false
    @State private var isToppingExpanded = false
    @State private var isDishExpanded = true
    @State private var isInstructionsExpanded = true
    @State private var isRecipeImagesExpanded = true
    @State private var isDifficultyExpanded = true
    
    private var titleSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isTitleExpanded) {
                TextField(LocalizedString("Title", comment: "Title placeholder"), text: $viewModel.title)
                    .focused($isTitleFocused)
            } label: {
                Text(LocalizedString("Recipe Title", comment: "Recipe title section"))
                    .font(.headline)
            }
        }
    }
    
    private var descriptionSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isDescriptionExpanded) {
                VStack(alignment: .leading, spacing: 8) {
                    TextField(LocalizedString("Description", comment: "Description placeholder"), text: $viewModel.description, axis: .vertical)
                        .lineLimit(1...)
                        .focused($isDescriptionFocused)
                    
                    Button(action: {
                        Task {
                            await viewModel.generateDescription()
                        }
                    }) {
                        HStack {
                            if viewModel.isGeneratingDescription {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(LocalizedString("Regenerate Description", comment: "Regenerate description button"))
                        }
                        .font(.caption)
                    }
                    .disabled(viewModel.isGeneratingDescription || viewModel.title.isEmpty)
                    .foregroundColor(viewModel.isGeneratingDescription || viewModel.title.isEmpty ? .secondary : .accentColor)
                }
            } label: {
                Text(LocalizedString("Description", comment: "Description section"))
                    .font(.headline)
            }
        }
    }
    
    private var cuisineSection: some View {
        Section {
            Button(action: {
                showCuisineSelection = true
            }) {
                HStack {
                    Text(LocalizedString("Cuisine", comment: "Cuisine label"))
                        .foregroundColor(.primary)
                    Spacer()
                    if viewModel.isDetectingCuisine {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if let cuisine = viewModel.cuisine, !cuisine.isEmpty {
                        Text(LocalizedString(cuisine, comment: "Cuisine name"))
                            .foregroundColor(.secondary)
                    } else {
                        Text(LocalizedString("Select Cuisine", comment: "Select cuisine placeholder"))
                            .foregroundColor(.secondary)
                    }
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
    }
    
    private var timeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedString("Preparation Time", comment: "Preparation time label"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TimePickerView(totalMinutes: $viewModel.prepTime)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedString("Cooking Time", comment: "Cooking time label"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TimePickerView(totalMinutes: $viewModel.cookTime)
                    }
                }
            }
            .padding(.vertical, 2)
        } header: {
            Text(LocalizedString("Time", comment: "Time section header"))
        }
    }
    
    private var servingsSection: some View {
        Section {
            HStack {
                Text(LocalizedString("Servings", comment: "Servings label"))
                    .foregroundColor(.primary)
                Spacer()
                ServingsPickerView(servings: $viewModel.servings)
            }
        }
    }
    
    private var difficultySection: some View {
        Section {
            DisclosureGroup(isExpanded: $isDifficultyExpanded) {
                DifficultyLevelView(
                    difficulty: viewModel.difficulty,
                    selectedDifficulty: $viewModel.difficulty
                )
                .padding(.vertical, 4)
            } label: {
                Text(LocalizedString("Difficulty", comment: "Difficulty section header"))
                    .font(.headline)
            }
        }
    }
    
    private var recipeImagesSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isRecipeImagesExpanded) {
                // Scrollable horizontal stack of 80x80 images
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Display existing images as 80x80 previews
                        ForEach(Array(viewModel.mainRecipeImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Button(action: {
                                    fullScreenImage = image
                                    showFullScreenImage = true
                                }) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipped()
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    viewModel.removeRecipeImage(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                }
                                .padding(4)
                            }
                        }
                        
                        // Add image button (only show if less than 5 images)
                        if viewModel.mainRecipeImages.count < 5 {
                            Button(action: {
                                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                    showCameraForDishImage = true
                                }
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 20))
                                        .foregroundColor(.accentColor)
                                    Text(LocalizedString("Add", comment: "Add image button"))
                                        .font(.caption2)
                                        .foregroundColor(.accentColor)
                                }
                                .frame(width: 80, height: 80)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            } label: {
                Text(LocalizedString("Dish Images", comment: "Dish images section"))
                    .font(.headline)
            }
        } footer: {
            Text(LocalizedString("Dish images can be added later as required", comment: "Dish images footer"))
        }
    }
    
    private var dishIngredientsSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isDishExpanded) {
                ForEach(Array(viewModel.dishIngredients.enumerated()), id: \.offset) { index, ingredient in
                    dishIngredientRow(at: index)
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        viewModel.removeDishIngredient(at: index)
                    }
                }
                
                Button(action: {
                    viewModel.addDishIngredient()
                }) {
                    Label(LocalizedString("Add Dish Ingredient", comment: "Add dish ingredient button"), systemImage: "plus.circle")
                }
            } label: {
                Text(LocalizedString("Dish Ingredients", comment: "Dish ingredients section"))
                    .font(.headline)
            }
        }
    }
    
    private var marinadeIngredientsSection: some View {
        Section {
            DisclosureGroup(isExpanded: Binding(
                get: { isMarinadeExpanded || !viewModel.marinadeIngredients.isEmpty },
                set: { isMarinadeExpanded = $0 }
            )) {
                ForEach(Array(viewModel.marinadeIngredients.enumerated()), id: \.offset) { index, ingredient in
                    marinadeIngredientRow(at: index)
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        viewModel.removeMarinadeIngredient(at: index)
                    }
                }
                
                Button(action: {
                    viewModel.addMarinadeIngredient()
                    isMarinadeExpanded = true
                }) {
                    Label(LocalizedString("Add Marinade Ingredient", comment: "Add marinade ingredient button"), systemImage: "plus.circle")
                }
            } label: {
                Text(LocalizedString("Marinade Ingredients", comment: "Marinade ingredients section"))
                    .font(.headline)
            }
        }
    }
    
    private var seasoningIngredientsSection: some View {
        Section {
            DisclosureGroup(isExpanded: Binding(
                get: { isSeasoningExpanded || !viewModel.seasoningIngredients.isEmpty },
                set: { isSeasoningExpanded = $0 }
            )) {
                ForEach(Array(viewModel.seasoningIngredients.enumerated()), id: \.offset) { index, ingredient in
                    seasoningIngredientRow(at: index)
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        viewModel.removeSeasoningIngredient(at: index)
                    }
                }
                
                Button(action: {
                    viewModel.addSeasoningIngredient()
                    isSeasoningExpanded = true
                }) {
                    Label(LocalizedString("Add Seasoning Ingredient", comment: "Add seasoning ingredient button"), systemImage: "plus.circle")
                }
            } label: {
                Text(LocalizedString("Seasoning Ingredients", comment: "Seasoning ingredients section"))
                    .font(.headline)
            }
        }
    }
    
    private var sauceIngredientsSection: some View {
        Section {
            DisclosureGroup(isExpanded: Binding(
                get: { isSauceExpanded || !viewModel.sauceIngredients.isEmpty },
                set: { isSauceExpanded = $0 }
            )) {
                ForEach(Array(viewModel.sauceIngredients.enumerated()), id: \.offset) { index, ingredient in
                    sauceIngredientRow(at: index)
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        viewModel.removeSauceIngredient(at: index)
                    }
                }
                
                Button(action: {
                    viewModel.addSauceIngredient()
                    isSauceExpanded = true
                }) {
                    Label(LocalizedString("Add Sauce Ingredient", comment: "Add sauce ingredient button"), systemImage: "plus.circle")
                }
            } label: {
                Text(LocalizedString("Sauce Ingredients", comment: "Sauce ingredients section"))
                    .font(.headline)
            }
        }
    }
    
    private var toppingIngredientsSection: some View {
        Section {
            DisclosureGroup(isExpanded: Binding(
                get: { isToppingExpanded || !viewModel.toppingIngredients.isEmpty },
                set: { isToppingExpanded = $0 }
            )) {
                ForEach(Array(viewModel.toppingIngredients.enumerated()), id: \.offset) { index, ingredient in
                    toppingIngredientRow(at: index)
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        viewModel.removeToppingIngredient(at: index)
                    }
                }
                
                Button(action: {
                    viewModel.addToppingIngredient()
                    isToppingExpanded = true
                }) {
                    Label(LocalizedString("Add Topping Ingredient", comment: "Add topping ingredient button"), systemImage: "plus.circle")
                }
            } label: {
                Text(LocalizedString("Topping Ingredients", comment: "Topping ingredients section"))
                    .font(.headline)
            }
        }
    }
    
    private var instructionsSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isInstructionsExpanded) {
                ForEach(Array(viewModel.instructions.enumerated()), id: \.offset) { index, instruction in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 16) {
                            // Blue circle with number (matching ModernRecipeDetailView style)
                            Text("\(index + 1)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                            
                            let stepBinding = Binding<String>(
                                get: { viewModel.instructions[index].text },
                                set: { viewModel.instructions[index].text = $0 }
                            )
                            TextField(LocalizedString("Step", comment: "Step placeholder"), text: stepBinding, axis: .vertical)
                                .lineLimit(2...6)
                                .focused($focusedInstructionField, equals: index)
                            
                            if viewModel.instructions.count > 1 {
                                Button(action: {
                                    viewModel.removeInstruction(at: index)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        // Instruction Image/Video
                        if let image = instruction.image {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 150)
                                    .clipped()
                                    .cornerRadius(8)
                                
                                Button(action: {
                                    viewModel.removeInstructionMedia(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                        .padding(6)
                                }
                            }
                        } else if instruction.videoURL != nil {
                            HStack {
                                Image(systemName: "video.fill")
                                Text(LocalizedString("Video attached", comment: "Video attached label"))
                                    .font(.caption)
                                Spacer()
                                Button(LocalizedString("Remove", comment: "Remove button")) {
                                    viewModel.removeInstructionMedia(at: index)
                                }
                                .font(.caption)
                            }
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        } else {
                            let photoSelection = Binding<PhotosPickerItem?>(
                                get: { selectedInstructionPhotos[index] },
                                set: { selectedInstructionPhotos[index] = $0 }
                            )
                            HStack(spacing: 12) {
                                PhotosPicker(
                                    selection: photoSelection,
                                    matching: .images
                                ) {
                                    HStack {
                                        Image(systemName: "photo")
                                        Text(LocalizedString("Add Photo", comment: "Add photo button"))
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    showingImagePickerForIndex = index
                                }) {
                                    HStack {
                                        Image(systemName: "video")
                                        Text(LocalizedString("Add Video", comment: "Add video button"))
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onMove { source, destination in
                    viewModel.moveInstruction(from: source, to: destination)
                }
                
                Button(action: {
                    viewModel.addInstruction()
                }) {
                    Label(LocalizedString("Add Step", comment: "Add step button"), systemImage: "plus.circle")
                }
            } label: {
                Text(LocalizedString("Instructions", comment: "Instructions section"))
                    .font(.headline)
            }
        }
    }
    
    // MARK: - Ingredient Row Helpers
    
    private func dishIngredientRow(at index: Int) -> some View {
        ingredientRow(
            amount: Binding(
                get: { viewModel.dishIngredients[index].amount },
                set: { viewModel.updateDishIngredientAmount($0, at: index) }
            ),
            unit: Binding(
                get: { viewModel.dishIngredients[index].unit },
                set: { viewModel.updateDishIngredientUnit($0, at: index) }
            ),
            name: Binding(
                get: { viewModel.dishIngredients[index].name },
                set: { viewModel.updateDishIngredientName($0, at: index) }
            ),
            amountIndex: index + 1000,
            nameIndex: index + 1000
        )
    }
    
    private func marinadeIngredientRow(at index: Int) -> some View {
        ingredientRow(
            amount: Binding(
                get: { viewModel.marinadeIngredients[index].amount },
                set: { viewModel.updateMarinadeIngredientAmount($0, at: index) }
            ),
            unit: Binding(
                get: { viewModel.marinadeIngredients[index].unit },
                set: { viewModel.updateMarinadeIngredientUnit($0, at: index) }
            ),
            name: Binding(
                get: { viewModel.marinadeIngredients[index].name },
                set: { viewModel.updateMarinadeIngredientName($0, at: index) }
            ),
            amountIndex: index,
            nameIndex: index
        )
    }
    
    private func seasoningIngredientRow(at index: Int) -> some View {
        ingredientRow(
            amount: Binding(
                get: { viewModel.seasoningIngredients[index].amount },
                set: { viewModel.updateSeasoningIngredientAmount($0, at: index) }
            ),
            unit: Binding(
                get: { viewModel.seasoningIngredients[index].unit },
                set: { viewModel.updateSeasoningIngredientUnit($0, at: index) }
            ),
            name: Binding(
                get: { viewModel.seasoningIngredients[index].name },
                set: { viewModel.updateSeasoningIngredientName($0, at: index) }
            ),
            amountIndex: index + 500,
            nameIndex: index + 500
        )
    }
    
    private func sauceIngredientRow(at index: Int) -> some View {
        ingredientRow(
            amount: Binding(
                get: { viewModel.sauceIngredients[index].amount },
                set: { viewModel.updateSauceIngredientAmount($0, at: index) }
            ),
            unit: Binding(
                get: { viewModel.sauceIngredients[index].unit },
                set: { viewModel.updateSauceIngredientUnit($0, at: index) }
            ),
            name: Binding(
                get: { viewModel.sauceIngredients[index].name },
                set: { viewModel.updateSauceIngredientName($0, at: index) }
            ),
            amountIndex: index + 3000,
            nameIndex: index + 3000
        )
    }
    
    private func toppingIngredientRow(at index: Int) -> some View {
        ingredientRow(
            amount: Binding(
                get: { viewModel.toppingIngredients[index].amount },
                set: { viewModel.updateToppingIngredientAmount($0, at: index) }
            ),
            unit: Binding(
                get: { viewModel.toppingIngredients[index].unit },
                set: { viewModel.updateToppingIngredientUnit($0, at: index) }
            ),
            name: Binding(
                get: { viewModel.toppingIngredients[index].name },
                set: { viewModel.updateToppingIngredientName($0, at: index) }
            ),
            amountIndex: index + 6000,
            nameIndex: index + 6000
        )
    }
    
    // Reusable ingredient row view
    private func ingredientRow(amount: Binding<String>, unit: Binding<String>, name: Binding<String>, amountIndex: Int, nameIndex: Int) -> some View {
        HStack(spacing: 8) {
            // Amount field - narrower with smaller font, centered
            TextField("0", text: amount)
                .frame(width: 30, height: 44)
                .font(.system(size: 14))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(maxHeight: .infinity, alignment: .center)
                .focused($focusedAmountField, equals: amountIndex)
            
            // Unit field - dropdown picker (narrower, no chevron)
            Menu {
                ForEach(commonUnits, id: \.self) { unitOption in
                    Button(action: {
                        unit.wrappedValue = unitOption
                    }) {
                        HStack {
                            Text(menuDisplayName(for: unitOption))
                            Spacer()
                            if unit.wrappedValue == unitOption {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 0) {
                    Text(displayName(for: unit.wrappedValue, amount: amount.wrappedValue))
                        .font(.system(size: 14))
                        .foregroundColor(unit.wrappedValue.isEmpty ? .secondary : .primary)
                }
                .frame(width: 56, alignment: .leading)
            }
            .frame(width: 56)
            
            // Ingredient name field - wider, takes remaining space
            TextField(LocalizedString("Ingredient", comment: "Ingredient placeholder"), text: name)
                .autocapitalization(.words)
                .focused($focusedIngredientNameField, equals: nameIndex)
        }
    }
    
    var body: some View {
        NavigationStack {
            makeRecipeForm()
            .navigationTitle(LocalizedString("Upload Recipe", comment: "Upload recipe title"))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCuisineSelection) {
                CuisineSelectionView(selectedCuisine: $viewModel.cuisine)
            }
            .sheet(isPresented: $showFullScreenImage) {
                if let image = fullScreenImage {
                    ZoomableImageView(image: image)
                }
            }
            .sheet(item: $showingImagePickerForIndex) { index in
                let videoBinding = Binding<URL?>(
                    get: { viewModel.instructions[safe: index]?.videoURL },
                    set: { newValue in
                        if let url = newValue {
                            viewModel.setInstructionVideo(url, at: index)
                        }
                    }
                )
                VideoPickerView(selectedVideoURL: videoBinding)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(LocalizedString("Done", comment: "Done button")) {
                        dismissKeyboard()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedString("Cancel", comment: "Cancel button")) {
                        HapticFeedback.buttonTap()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticFeedback.importantAction()
                        dismissKeyboard()
                        Task {
                            await viewModel.uploadRecipe()
                            if viewModel.isSuccess {
                                HapticFeedback.play(.success)
                                dismiss()
                            } else {
                                HapticFeedback.play(.error)
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(LocalizedString("Upload", comment: "Upload button"))
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.title.isEmpty)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: selectedRecipePhotos) { oldValue, newItems in
                // Process when user finishes selecting images
                guard !newItems.isEmpty else { return }
                
                // Process all items - PhotosPicker provides all selected items when user presses Done
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            // Optimize image for display and add to recipe images
                            let optimizedImage = ImageOptimizer.resizeForDisplay(image, maxDimension: 1200)
                            await MainActor.run {
                                // addRecipeImage has a guard to prevent more than 5 images total
                                viewModel.addRecipeImage(optimizedImage)
                            }
                        }
                    }
                    // Clear selection after processing to allow selecting again
                    await MainActor.run {
                        selectedRecipePhotos = []
                        showPhotoPickerForDishImage = false
                    }
                }
            }
            .onChange(of: selectedInstructionPhotos) { oldValue, newValue in
                handleInstructionPhotosChange(newValue)
            }
            .onChange(of: viewModel.title) {
                // Auto-detect cuisine when title changes (with debounce)
                cuisineDetectionTask?.cancel()
                cuisineDetectionTask = Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 second debounce
                    guard !Task.isCancelled else { return }
                    if !viewModel.title.isEmpty && (viewModel.cuisine == nil || viewModel.cuisine?.isEmpty == true) {
                        await viewModel.detectCuisine()
                    }
                }
            }
            .onChange(of: viewModel.dishIngredients) {
                // Auto-detect cuisine when ingredients change (with debounce)
                cuisineDetectionTask?.cancel()
                cuisineDetectionTask = Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 second debounce
                    guard !Task.isCancelled else { return }
                    if !viewModel.title.isEmpty && (viewModel.cuisine == nil || viewModel.cuisine?.isEmpty == true) {
                        await viewModel.detectCuisine()
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                }
            }
            .alert(LocalizedString("Error", comment: "Error alert title"), isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button(LocalizedString("OK", comment: "OK button")) {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .background {
                PhotoLibraryPickerView(
                    isPresented: $showPhotoPickerForDishImage,
                    maxSelectionCount: 5 - viewModel.mainRecipeImages.count
                ) { images in
                    // Process selected images
                    Task {
                        for image in images {
                            // Optimize image for display to reduce memory usage
                            let optimizedImage = ImageOptimizer.resizeForDisplay(image, maxDimension: 1200)
                            await MainActor.run {
                                // addRecipeImage has a guard to prevent more than 5 images total
                                viewModel.addRecipeImage(optimizedImage)
                            }
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showCameraForDishImage) {
                CameraCaptureView { image in
                    // Add the captured image to recipe images
                    Task {
                        // Optimize image for display to reduce memory usage
                        let optimizedImage = ImageOptimizer.resizeForDisplay(image, maxDimension: 1200)
                        await MainActor.run {
                            // addRecipeImage has a guard to prevent more than 5 images total
                            viewModel.addRecipeImage(optimizedImage)
                            showCameraForDishImage = false
                        }
                    }
                }
                .ignoresSafeArea(.all)
            }
            .onChange(of: selectedRecipePhotos) { oldValue, newItems in
                // Process when user finishes selecting images
                guard !newItems.isEmpty else {
                    // If selection is cleared, reset the picker flag
                    if newItems.isEmpty && showPhotoPickerForDishImage {
                        showPhotoPickerForDishImage = false
                    }
                    return
                }
                
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            // Optimize image for display to reduce memory usage
                            let optimizedImage = ImageOptimizer.resizeForDisplay(image, maxDimension: 1200)
                            await MainActor.run {
                                // addRecipeImage has a guard to prevent more than 5 images total
                                viewModel.addRecipeImage(optimizedImage)
                            }
                        }
                    }
                    // Clear the selection and reset the picker flag after processing
                    await MainActor.run {
                        selectedRecipePhotos = []
                        showPhotoPickerForDishImage = false
                    }
                }
            }
        }
    }
    
    private func handleInstructionPhotosChange(_ photos: [Int: PhotosPickerItem]) {
        for (index, item) in photos {
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    // Optimize image for display to reduce memory usage
                    let optimizedImage = ImageOptimizer.resizeForDisplay(image, maxDimension: 600)
                    viewModel.setInstructionImage(optimizedImage, at: index)
                    selectedInstructionPhotos.removeValue(forKey: index)
                }
            }
        }
    }
    
    @ViewBuilder
    private func makeRecipeForm() -> some View {
        let dishIngredientMethods = makeDishIngredientMethods()
        let marinadeIngredientMethods = makeMarinadeIngredientMethods()
        let seasoningIngredientMethods = makeSeasoningIngredientMethods()
        let doughBatterFillingIngredientMethods = makeDoughBatterFillingIngredientMethods()
        let sauceIngredientMethods = makeSauceIngredientMethods()
        let toppingIngredientMethods = makeToppingIngredientMethods()
        let garnishIngredientMethods = makeGarnishIngredientMethods()
        
        RecipeEditForm(
            title: $viewModel.title,
            titleEnglish: .constant(nil),
            titleLocal: .constant(nil),
            titleOriginal: .constant(nil),
            description: $viewModel.description,
            cuisine: $viewModel.cuisine,
            prepTime: $viewModel.prepTime,
            cookTime: $viewModel.cookTime,
            servings: $viewModel.servings,
            difficulty: $viewModel.difficulty,
            spicyLevel: $viewModel.spicyLevel,
            tips: $viewModel.tips,
            dishIngredients: $viewModel.dishIngredients,
            marinadeIngredients: $viewModel.marinadeIngredients,
            seasoningIngredients: $viewModel.seasoningIngredients,
            doughBatterFillingIngredients: $viewModel.doughBatterFillingIngredients,
            sauceIngredients: $viewModel.sauceIngredients,
            toppingIngredients: $viewModel.toppingIngredients,
            garnishIngredients: $viewModel.garnishIngredients,
            mainRecipeImages: $viewModel.mainRecipeImages,
            isGeneratingDescription: viewModel.isGeneratingDescription,
            isDetectingCuisine: viewModel.isDetectingCuisine,
            errorMessage: viewModel.errorMessage,
            addDishIngredient: dishIngredientMethods.add,
            removeDishIngredient: dishIngredientMethods.remove,
            updateDishIngredientAmount: dishIngredientMethods.updateAmount,
            updateDishIngredientUnit: dishIngredientMethods.updateUnit,
            updateDishIngredientName: dishIngredientMethods.updateName,
            moveDishIngredient: dishIngredientMethods.move,
            addMarinadeIngredient: marinadeIngredientMethods.add,
            removeMarinadeIngredient: marinadeIngredientMethods.remove,
            updateMarinadeIngredientAmount: marinadeIngredientMethods.updateAmount,
            updateMarinadeIngredientUnit: marinadeIngredientMethods.updateUnit,
            updateMarinadeIngredientName: marinadeIngredientMethods.updateName,
            moveMarinadeIngredient: marinadeIngredientMethods.move,
            addSeasoningIngredient: seasoningIngredientMethods.add,
            removeSeasoningIngredient: seasoningIngredientMethods.remove,
            updateSeasoningIngredientAmount: seasoningIngredientMethods.updateAmount,
            updateSeasoningIngredientUnit: seasoningIngredientMethods.updateUnit,
            updateSeasoningIngredientName: seasoningIngredientMethods.updateName,
            moveSeasoningIngredient: seasoningIngredientMethods.move,
            addDoughBatterFillingIngredient: doughBatterFillingIngredientMethods.add,
            removeDoughBatterFillingIngredient: doughBatterFillingIngredientMethods.remove,
            updateDoughBatterFillingIngredientAmount: doughBatterFillingIngredientMethods.updateAmount,
            updateDoughBatterFillingIngredientUnit: doughBatterFillingIngredientMethods.updateUnit,
            updateDoughBatterFillingIngredientName: doughBatterFillingIngredientMethods.updateName,
            moveDoughBatterFillingIngredient: doughBatterFillingIngredientMethods.move,
            addSauceIngredient: sauceIngredientMethods.add,
            removeSauceIngredient: sauceIngredientMethods.remove,
            updateSauceIngredientAmount: sauceIngredientMethods.updateAmount,
            updateSauceIngredientUnit: sauceIngredientMethods.updateUnit,
            updateSauceIngredientName: sauceIngredientMethods.updateName,
            moveSauceIngredient: sauceIngredientMethods.move,
            addToppingIngredient: toppingIngredientMethods.add,
            removeToppingIngredient: toppingIngredientMethods.remove,
            updateToppingIngredientAmount: toppingIngredientMethods.updateAmount,
            updateToppingIngredientUnit: toppingIngredientMethods.updateUnit,
            updateToppingIngredientName: toppingIngredientMethods.updateName,
            moveToppingIngredient: toppingIngredientMethods.move,
            addGarnishIngredient: garnishIngredientMethods.add,
            removeGarnishIngredient: garnishIngredientMethods.remove,
            updateGarnishIngredientAmount: garnishIngredientMethods.updateAmount,
            updateGarnishIngredientUnit: garnishIngredientMethods.updateUnit,
            updateGarnishIngredientName: garnishIngredientMethods.updateName,
            moveGarnishIngredient: garnishIngredientMethods.move,
            addRecipeImage: { viewModel.addRecipeImage($0) },
            removeRecipeImage: { viewModel.removeRecipeImage(at: $0) },
            generateDescription: { await viewModel.generateDescription() },
            showCuisineSelection: $showCuisineSelection,
            showFullScreenImage: $showFullScreenImage,
            fullScreenImage: $fullScreenImage,
            selectedRecipePhotos: $selectedRecipePhotos,
            onTakePicture: {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    showCameraForDishImage = true
                }
            },
            onSelectFromLibrary: {
                showPhotoPickerForDishImage = true
            },
            moveIngredientBetweenCategories: { fromCategory, fromIndex, toCategory, toIndex in
                viewModel.moveIngredient(from: fromCategory, sourceIndex: fromIndex, to: toCategory, destinationIndex: toIndex)
            },
            instructionsContent: {
                makeInstructionsContent()
            },
            optionalContent: {
                EmptyView()
            }
        )
    }
    
    private struct IngredientMethods {
        let add: () -> Void
        let remove: (Int) -> Void
        let updateAmount: (String, Int) -> Void
        let updateUnit: (String, Int) -> Void
        let updateName: (String, Int) -> Void
        let move: (Int, Int) -> Void
    }
    
    private func makeDishIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addDishIngredient() },
            remove: { viewModel.removeDishIngredient(at: $0) },
            updateAmount: { viewModel.updateDishIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateDishIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateDishIngredientName($0, at: $1) },
            move: { _, _ in } // No-op for now
        )
    }
    
    private func makeMarinadeIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addMarinadeIngredient() },
            remove: { viewModel.removeMarinadeIngredient(at: $0) },
            updateAmount: { viewModel.updateMarinadeIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateMarinadeIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateMarinadeIngredientName($0, at: $1) },
            move: { _, _ in } // No-op for now
        )
    }
    
    private func makeSeasoningIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addSeasoningIngredient() },
            remove: { viewModel.removeSeasoningIngredient(at: $0) },
            updateAmount: { viewModel.updateSeasoningIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateSeasoningIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateSeasoningIngredientName($0, at: $1) },
            move: { _, _ in } // No-op for now
        )
    }
    
    private func makeDoughBatterFillingIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addDoughBatterFillingIngredient() },
            remove: { viewModel.removeDoughBatterFillingIngredient(at: $0) },
            updateAmount: { viewModel.updateDoughBatterFillingIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateDoughBatterFillingIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateDoughBatterFillingIngredientName($0, at: $1) },
            move: { _, _ in } // No-op for now
        )
    }
    
    private func makeSauceIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addSauceIngredient() },
            remove: { viewModel.removeSauceIngredient(at: $0) },
            updateAmount: { viewModel.updateSauceIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateSauceIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateSauceIngredientName($0, at: $1) },
            move: { _, _ in } // No-op for now
        )
    }
    
    private func makeToppingIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addToppingIngredient() },
            remove: { viewModel.removeToppingIngredient(at: $0) },
            updateAmount: { viewModel.updateToppingIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateToppingIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateToppingIngredientName($0, at: $1) },
            move: { _, _ in } // No-op for now
        )
    }
    
    private func makeGarnishIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addGarnishIngredient() },
            remove: { viewModel.removeGarnishIngredient(at: $0) },
            updateAmount: { viewModel.updateGarnishIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateGarnishIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateGarnishIngredientName($0, at: $1) },
            move: { _, _ in } // No-op for now
        )
    }
    
    @ViewBuilder
    private func makeInstructionsContent() -> some View {
        ForEach(Array(viewModel.instructions.enumerated()), id: \.offset) { index, instruction in
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 16) {
                    // Blue circle with number (matching ModernRecipeDetailView style)
                    Text("\(index + 1)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                    
                    let stepBinding = Binding<String>(
                        get: { viewModel.instructions[index].text },
                        set: { viewModel.instructions[index].text = $0 }
                    )
                    TextField(LocalizedString("Step", comment: "Step placeholder"), text: stepBinding, axis: .vertical)
                        .lineLimit(2...6)
                        .focused($focusedInstructionField, equals: index)
                }
                
                // Instruction Image/Video
                if let image = instruction.image {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 150)
                            .clipped()
                            .cornerRadius(8)
                        
                        Button(action: {
                            viewModel.removeInstructionMedia(at: index)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .padding(6)
                        }
                    }
                } else if instruction.videoURL != nil {
                    HStack {
                        Image(systemName: "video.fill")
                        Text(LocalizedString("Video attached", comment: "Video attached label"))
                            .font(.caption)
                        Spacer()
                        Button(LocalizedString("Remove", comment: "Remove button")) {
                            viewModel.removeInstructionMedia(at: index)
                        }
                        .font(.caption)
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            .padding(.vertical, 4)
        }
        .onDelete { indexSet in
            for index in indexSet.sorted(by: >) {
                viewModel.removeInstruction(at: index)
            }
        }
        .onMove { source, destination in
            viewModel.moveInstruction(from: source, to: destination)
        }
        
        Button(action: {
            viewModel.addInstruction()
        }) {
            Label(LocalizedString("Add Step", comment: "Add step button"), systemImage: "plus.circle")
        }
    }
}

// Helper extension for safe array access
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// Wrapper to make Int Identifiable for sheet
extension Int: @retroactive Identifiable {
    public var id: Int { self }
}

// Video Picker View
struct VideoPickerView: UIViewControllerRepresentable {
    @Binding var selectedVideoURL: URL?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.mediaTypes = ["public.movie"]
        picker.videoQuality = .typeHigh
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoPickerView
        
        init(_ parent: VideoPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                parent.selectedVideoURL = videoURL
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    UploadRecipeView()
}

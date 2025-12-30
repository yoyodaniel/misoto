//
//  ExtractMenuFromImageView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import PhotosUI

struct ExtractMenuFromImageView: View {
    // Unit mapping: singular form -> display name with abbreviation in brackets
    private let unitDisplayNames: [String: String] = [
        "": "-",
        "x": "x",
        "tsp": "Teaspoon (tsp)",
        "tbsp": "Tablespoon (tbsp)",
        "cup": "Cup",
        "oz": "Ounce (oz)",
        "lb": "Pound (lb)",
        "g": "Gram (g)",
        "kg": "Kilogram (kg)",
        "ml": "Milliliter (ml)",
        "l": "Liter (l)",
        "pinch": "Pinch",
        "piece": "Piece",
        "pcs": "Pieces (pcs)",
        "pc": "Piece (pc)",
        "slice": "Slice",
        "clove": "Clove",
        "bunch": "Bunch",
        "head": "Head",
        "strand": "Strand",
        "strands": "Strands"
    ]
    
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
        "strand": "strands"
    ]
    
    // Common units (singular forms only)
    private var commonUnits: [String] {
        Array(unitDisplayNames.keys).sorted { unit1, unit2 in
            // Sort: empty first, then "x", then alphabetically
            if unit1.isEmpty { return true }
            if unit2.isEmpty { return false }
            if unit1 == "x" { return true }
            if unit2 == "x" { return false }
            return unit1 < unit2
        }
    }
    
    // Get display name for a unit (pluralizes if amount > 1, shows abbreviation)
    private func displayName(for unit: String, amount: String) -> String {
        if unit.isEmpty {
            return "-"
        }
        
        // Check if amount is greater than 1
        if let amountValue = Double(amount.trimmingCharacters(in: .whitespaces)), amountValue > 1 {
            // Pluralize if needed
            if let plural = pluralForms[unit] {
                return plural
            }
        }
        
        return unit
    }
    
    // Get full display name with abbreviation (for dropdown menu)
    private func menuDisplayName(for unit: String) -> String {
        return unitDisplayNames[unit] ?? unit
    }
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ExtractMenuFromImageViewModel()
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var selectedRecipePhotos: [PhotosPickerItem] = []
    @State private var showCuisineSelection = false
    @State private var cuisineDetectionTask: Task<Void, Never>?
    @State private var showFullScreenImage = false
    @State private var fullScreenImage: UIImage?
    @State private var selectedInstructionPhotos: [Int: PhotosPickerItem] = [:]
    @State private var showingImagePickerForIndex: Int? = nil
    @State private var showCamera = false
    
    let initialImage: UIImage?
    
    init(initialImage: UIImage? = nil) {
        self.initialImage = initialImage
        // Initialize selectedImages with initialImage if provided
        if let image = initialImage {
            _selectedImages = State(initialValue: [image])
        }
    }
    @FocusState private var focusedAmountField: Int?
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    @FocusState private var focusedIngredientNameField: Int?
    @FocusState private var focusedInstructionField: Int?
    
    // Collapse/expand state for sections
    @State private var isTitleExpanded = true
    @State private var isDescriptionExpanded = true
    @State private var isMarinadeExpanded = false
    @State private var isSeasoningExpanded = false
    @State private var isBatterExpanded = false
    @State private var isSauceExpanded = false
    @State private var isBaseExpanded = false
    @State private var isDoughExpanded = false
    @State private var isToppingExpanded = false
    @State private var isDishExpanded = true
    @State private var isInstructionsExpanded = true
    @State private var isSourceExpanded = true
    @State private var isRecipeImagesExpanded = true
    @State private var isDifficultyExpanded = true
    
    // Dismiss all keyboards
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
    
    private var titleSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isTitleExpanded) {
                TextField(NSLocalizedString("Title", comment: "Title placeholder"), text: $viewModel.title)
                    .focused($isTitleFocused)
            } label: {
                Text(NSLocalizedString("Recipe Title", comment: "Recipe title section"))
                    .font(.headline)
            }
        }
    }
    
    private var descriptionSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isDescriptionExpanded) {
                VStack(alignment: .leading, spacing: 8) {
                    TextField(NSLocalizedString("Description", comment: "Description placeholder"), text: $viewModel.description, axis: .vertical)
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
                            Text(NSLocalizedString("Regenerate Description", comment: "Regenerate description button"))
                        }
                        .font(.caption)
                    }
                    .disabled(viewModel.isGeneratingDescription || viewModel.title.isEmpty)
                    .foregroundColor(viewModel.isGeneratingDescription || viewModel.title.isEmpty ? .secondary : .accentColor)
                }
            } label: {
                Text(NSLocalizedString("Description", comment: "Description section"))
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
                    Text(NSLocalizedString("Cuisine", comment: "Cuisine label"))
                        .foregroundColor(.primary)
                    Spacer()
                    if viewModel.isDetectingCuisine {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if let cuisine = viewModel.cuisine, !cuisine.isEmpty {
                        Text(cuisine)
                            .foregroundColor(.secondary)
                    } else {
                        Text(NSLocalizedString("Select Cuisine", comment: "Select cuisine placeholder"))
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
                if viewModel.isExtractingTime {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(NSLocalizedString("Extracting time from instructions...", comment: "Extracting time message"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("Preparation Time", comment: "Preparation time label"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TimePickerView(totalMinutes: $viewModel.prepTime)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("Cooking Time", comment: "Cooking time label"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TimePickerView(totalMinutes: $viewModel.cookTime)
                    }
                }
            }
            .padding(.vertical, 2)
        } header: {
            Text(NSLocalizedString("Time", comment: "Time section header"))
        }
    }
    
    private var servingsSection: some View {
        Section {
            HStack {
                Text(NSLocalizedString("Servings", comment: "Servings label"))
                    .foregroundColor(.primary)
                Spacer()
                ServingsPickerView(servings: $viewModel.servings)
            }
        }
    }
    
    private var difficultySection: some View {
        Section {
            DisclosureGroup(isExpanded: $isDifficultyExpanded) {
                VStack(alignment: .leading, spacing: 12) {
                    if viewModel.isDetectingDifficulty {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(NSLocalizedString("Detecting difficulty level...", comment: "Detecting difficulty message"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    DifficultyLevelView(
                        difficulty: viewModel.difficulty,
                        selectedDifficulty: $viewModel.difficulty
                    )
                }
                .padding(.vertical, 4)
            } label: {
                Text(NSLocalizedString("Difficulty", comment: "Difficulty section header"))
                    .font(.headline)
            }
        }
    }
    
    private var sourceSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isSourceExpanded) {
                let sourceImages = !selectedImages.isEmpty ? selectedImages : (initialImage != nil ? [initialImage!] : [])
                
                if !sourceImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(sourceImages.enumerated()), id: \.offset) { index, sourceImage in
                                Button(action: {
                                    fullScreenImage = sourceImage
                                    showFullScreenImage = true
                                }) {
                                    Image(uiImage: sourceImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipped()
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    
                    Text(sourceImages.count > 1 ? 
                         NSLocalizedString("Source images used for recipe extraction", comment: "Source images description") :
                         NSLocalizedString("Source image used for recipe extraction", comment: "Source image description"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 4)
                } else {
                    Text(NSLocalizedString("No source image available", comment: "No source image text"))
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            } label: {
                Text(NSLocalizedString("Source", comment: "Source section"))
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
                            PhotosPicker(
                                selection: $selectedRecipePhotos,
                                maxSelectionCount: 5 - viewModel.mainRecipeImages.count,
                                matching: .images
                            ) {
                                VStack(spacing: 6) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 20))
                                        .foregroundColor(.accentColor)
                                    Text(NSLocalizedString("Add", comment: "Add image button"))
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
                Text(NSLocalizedString("Dish Images", comment: "Dish images section"))
                    .font(.headline)
            }
        } footer: {
            Text(NSLocalizedString("Dish images can be added later as required", comment: "Dish images footer"))
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
                    Label(NSLocalizedString("Add Marinade Ingredient", comment: "Add marinade ingredient button"), systemImage: "plus.circle")
                }
            } label: {
                Text(NSLocalizedString("Marinade Ingredients", comment: "Marinade ingredients section"))
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
                    Label(NSLocalizedString("Add Seasoning Ingredient", comment: "Add seasoning ingredient button"), systemImage: "plus.circle")
                }
            } label: {
                Text(NSLocalizedString("Seasoning Ingredients", comment: "Seasoning ingredients section"))
                    .font(.headline)
            }
        }
    }
    
    private var batterIngredientsSection: some View {
        Section {
            DisclosureGroup(isExpanded: Binding(
                get: { isBatterExpanded || !viewModel.batterIngredients.isEmpty },
                set: { isBatterExpanded = $0 }
            )) {
                ForEach(Array(viewModel.batterIngredients.enumerated()), id: \.offset) { index, ingredient in
                    batterIngredientRow(at: index)
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        viewModel.removeBatterIngredient(at: index)
                    }
                }
                
                Button(action: {
                    viewModel.addBatterIngredient()
                    isBatterExpanded = true
                }) {
                    Label(NSLocalizedString("Add Batter Ingredient", comment: "Add batter ingredient button"), systemImage: "plus.circle")
                }
            } label: {
                Text(NSLocalizedString("Batter Ingredients", comment: "Batter ingredients section"))
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
                    Label(NSLocalizedString("Add Sauce Ingredient", comment: "Add sauce ingredient button"), systemImage: "plus.circle")
                }
            } label: {
                Text(NSLocalizedString("Sauce Ingredients", comment: "Sauce ingredients section"))
                    .font(.headline)
            }
        }
    }
    
    private var baseIngredientsSection: some View {
        Section {
            DisclosureGroup(isExpanded: Binding(
                get: { isBaseExpanded || !viewModel.baseIngredients.isEmpty },
                set: { isBaseExpanded = $0 }
            )) {
                ForEach(Array(viewModel.baseIngredients.enumerated()), id: \.offset) { index, ingredient in
                    baseIngredientRow(at: index)
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        viewModel.removeBaseIngredient(at: index)
                    }
                }
                
                Button(action: {
                    viewModel.addBaseIngredient()
                    isBaseExpanded = true
                }) {
                    Label(NSLocalizedString("Add Base Ingredient", comment: "Add base ingredient button"), systemImage: "plus.circle")
                }
            } label: {
                Text(NSLocalizedString("Base Ingredients", comment: "Base ingredients section"))
                    .font(.headline)
            }
        }
    }
    
    private var doughIngredientsSection: some View {
        Section {
            DisclosureGroup(isExpanded: Binding(
                get: { isDoughExpanded || !viewModel.doughIngredients.isEmpty },
                set: { isDoughExpanded = $0 }
            )) {
                ForEach(Array(viewModel.doughIngredients.enumerated()), id: \.offset) { index, ingredient in
                    doughIngredientRow(at: index)
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        viewModel.removeDoughIngredient(at: index)
                    }
                }
                
                Button(action: {
                    viewModel.addDoughIngredient()
                    isDoughExpanded = true
                }) {
                    Label(NSLocalizedString("Add Dough Ingredient", comment: "Add dough ingredient button"), systemImage: "plus.circle")
                }
            } label: {
                Text(NSLocalizedString("Dough Ingredients", comment: "Dough ingredients section"))
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
                    Label(NSLocalizedString("Add Topping Ingredient", comment: "Add topping ingredient button"), systemImage: "plus.circle")
                }
            } label: {
                Text(NSLocalizedString("Topping Ingredients", comment: "Topping ingredients section"))
                    .font(.headline)
            }
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
                    Label(NSLocalizedString("Add Dish Ingredient", comment: "Add dish ingredient button"), systemImage: "plus.circle")
                }
            } label: {
                Text(NSLocalizedString("Dish Ingredients", comment: "Dish ingredients section"))
                    .font(.headline)
            }
        }
    }
    
    private func errorSection(_ message: String) -> some View {
        Section {
            Text(message)
                .foregroundColor(.red)
                .font(.caption)
        }
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
            amountIndex: index + 500, // Offset to avoid conflicts
            nameIndex: index + 500
        )
    }
    
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
    
    private func batterIngredientRow(at index: Int) -> some View {
        ingredientRow(
            amount: Binding(
                get: { viewModel.batterIngredients[index].amount },
                set: { viewModel.updateBatterIngredientAmount($0, at: index) }
            ),
            unit: Binding(
                get: { viewModel.batterIngredients[index].unit },
                set: { viewModel.updateBatterIngredientUnit($0, at: index) }
            ),
            name: Binding(
                get: { viewModel.batterIngredients[index].name },
                set: { viewModel.updateBatterIngredientName($0, at: index) }
            ),
            amountIndex: index + 2000,
            nameIndex: index + 2000
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
    
    private func baseIngredientRow(at index: Int) -> some View {
        ingredientRow(
            amount: Binding(
                get: { viewModel.baseIngredients[index].amount },
                set: { viewModel.updateBaseIngredientAmount($0, at: index) }
            ),
            unit: Binding(
                get: { viewModel.baseIngredients[index].unit },
                set: { viewModel.updateBaseIngredientUnit($0, at: index) }
            ),
            name: Binding(
                get: { viewModel.baseIngredients[index].name },
                set: { viewModel.updateBaseIngredientName($0, at: index) }
            ),
            amountIndex: index + 4000,
            nameIndex: index + 4000
        )
    }
    
    private func doughIngredientRow(at index: Int) -> some View {
        ingredientRow(
            amount: Binding(
                get: { viewModel.doughIngredients[index].amount },
                set: { viewModel.updateDoughIngredientAmount($0, at: index) }
            ),
            unit: Binding(
                get: { viewModel.doughIngredients[index].unit },
                set: { viewModel.updateDoughIngredientUnit($0, at: index) }
            ),
            name: Binding(
                get: { viewModel.doughIngredients[index].name },
                set: { viewModel.updateDoughIngredientName($0, at: index) }
            ),
            amountIndex: index + 5000,
            nameIndex: index + 5000
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
            TextField(NSLocalizedString("Ingredient", comment: "Ingredient placeholder"), text: name)
                .autocapitalization(.words)
                .focused($focusedIngredientNameField, equals: nameIndex)
        }
    }
    
    var body: some View {
        NavigationStack {
            if viewModel.showEditRecipe {
                recipeEditView
            } else {
                imageSelectionView
            }
        }
    }
    
    private var imageSelectionView: some View {
        Form {
            Section(header: Text(NSLocalizedString("Select Dish images", comment: "Select dish images section"))) {
                if !selectedImages.isEmpty {
                    VStack(spacing: 12) {
                        // Display selected images in a scrollable horizontal view
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 120, height: 160)
                                            .clipped()
                                            .cornerRadius(8)
                                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        
                                        Button(action: {
                                            selectedImages.remove(at: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .background(Color.black.opacity(0.6))
                                                .clipShape(Circle())
                                                .padding(4)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        
                        // Option to take another picture (only if less than 10 images)
                        if selectedImages.count < 10 {
                            Button(action: {
                                showCamera = true
                            }) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                    Text(NSLocalizedString("Take another picture", comment: "Take another picture button"))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                    }
                } else {
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 10,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                            Text(NSLocalizedString("Select Dish images", comment: "Select dish images button"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            if viewModel.isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Text(selectedImages.count > 1 ? 
                             NSLocalizedString("Extracting recipe from images...", comment: "Extracting recipe from multiple images message") :
                             NSLocalizedString("Extracting recipe from image...", comment: "Extracting recipe message"))
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(NSLocalizedString("Extract from Image", comment: "Extract from image title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(NSLocalizedString("Extract", comment: "Extract button")) {
                    if !selectedImages.isEmpty {
                        Task {
                            await viewModel.extractText(from: selectedImages)
                        }
                    }
                }
                .disabled(selectedImages.isEmpty || viewModel.isLoading)
            }
        }
        .onChange(of: selectedPhotos) { oldValue, newItems in
            // Process when user finishes selecting images
            guard !newItems.isEmpty else { return }
            
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        // Optimize image for display to reduce memory usage
                        let optimizedImage = await ImageOptimizer.resizeForDisplay(image, maxDimension: 800)
                        await MainActor.run {
                            selectedImages.append(optimizedImage)
                        }
                    }
                }
                // Clear selection after processing to allow selecting again
                await MainActor.run {
                    selectedPhotos = []
                }
            }
        }
        .onChange(of: selectedRecipePhotos) { oldValue, newItems in
            // Process when user finishes selecting images
            guard !newItems.isEmpty else { return }
            
            // Process all items - PhotosPicker provides all selected items when user presses Done
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        // Optimize image for display and add to recipe images
                        let optimizedImage = await ImageOptimizer.resizeForDisplay(image, maxDimension: 1200)
                        await MainActor.run {
                            // addRecipeImage has a guard to prevent more than 5 images total
                            viewModel.addRecipeImage(optimizedImage)
                        }
                    }
                }
                // Clear selection after processing to allow selecting again
                await MainActor.run {
                    selectedRecipePhotos = []
                }
            }
        }
        .task {
            // Optimize initial image if provided (from camera capture)
            // This reduces memory usage while keeping the image visible
            if let initialImage = initialImage, selectedImages.isEmpty {
                // Optimize image for display to reduce memory usage
                let optimizedImage = await ImageOptimizer.resizeForDisplay(initialImage, maxDimension: 800)
                await MainActor.run {
                    selectedImages = [optimizedImage]
                }
            }
        }
        .onAppear {
            // Also check on appear in case initialImage was set after view initialization
            if let initialImage = initialImage, selectedImages.isEmpty {
                // Set image immediately (will be optimized in task if needed)
                selectedImages = [initialImage]
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView { image in
                // Add the captured image to selectedImages
                Task {
                    // Optimize image for display to reduce memory usage
                    let optimizedImage = await ImageOptimizer.resizeForDisplay(image, maxDimension: 800)
                    await MainActor.run {
                        if selectedImages.count < 10 {
                            selectedImages.append(optimizedImage)
                        }
                    }
                }
            }
            .ignoresSafeArea(.all)
        }
    }
    
    private var recipeEditView: some View {
        makeRecipeForm()
        .sheet(isPresented: $showCuisineSelection) {
            CuisineSelectionView(selectedCuisine: $viewModel.cuisine)
        }
        .navigationTitle(NSLocalizedString("Edit Recipe", comment: "Edit recipe title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(NSLocalizedString("Done", comment: "Done button")) {
                    dismissKeyboard()
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    dismissKeyboard()
                    Task {
                        // Don't pass selectedImage - it's the extraction image, not a main recipe image
                        let success = await viewModel.saveRecipe(image: nil)
                        if success {
                            await authViewModel.reloadUserData()
                            dismiss()
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(NSLocalizedString("Save", comment: "Save button"))
                    }
                }
                .disabled(viewModel.isLoading || viewModel.title.isEmpty)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .sheet(isPresented: $showFullScreenImage) {
            if let image = fullScreenImage {
                ZoomableImageView(image: image)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .ignoresSafeArea(.all)
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
        .onChange(of: selectedInstructionPhotos) { photos in
            handleInstructionPhotosChange(photos)
        }
        .onChange(of: viewModel.title) { _ in
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
        .onChange(of: viewModel.dishIngredients) { _ in
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
        .onChange(of: selectedRecipePhotos) { oldValue, newItems in
            // Process when user finishes selecting images
            guard !newItems.isEmpty else { return }
            
            // Process all items - PhotosPicker provides all selected items when user presses Done
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        // Optimize image for display and add to recipe images
                        let optimizedImage = await ImageOptimizer.resizeForDisplay(image, maxDimension: 1200)
                        await MainActor.run {
                            // addRecipeImage has a guard to prevent more than 5 images total
                            viewModel.addRecipeImage(optimizedImage)
                        }
                    }
                }
                // Clear selection after processing to allow selecting again
                await MainActor.run {
                    selectedRecipePhotos = []
                }
            }
        }
    }
    
    @ViewBuilder
    private func makeRecipeForm() -> some View {
        let dishIngredientMethods = makeDishIngredientMethods()
        let marinadeIngredientMethods = makeMarinadeIngredientMethods()
        let seasoningIngredientMethods = makeSeasoningIngredientMethods()
        let batterIngredientMethods = makeBatterIngredientMethods()
        let sauceIngredientMethods = makeSauceIngredientMethods()
        let baseIngredientMethods = makeBaseIngredientMethods()
        let doughIngredientMethods = makeDoughIngredientMethods()
        let toppingIngredientMethods = makeToppingIngredientMethods()
        
        RecipeEditForm(
            title: $viewModel.title,
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
            batterIngredients: $viewModel.batterIngredients,
            sauceIngredients: $viewModel.sauceIngredients,
            baseIngredients: $viewModel.baseIngredients,
            doughIngredients: $viewModel.doughIngredients,
            toppingIngredients: $viewModel.toppingIngredients,
            mainRecipeImages: $viewModel.mainRecipeImages,
            isGeneratingDescription: viewModel.isGeneratingDescription,
            isDetectingCuisine: viewModel.isDetectingCuisine,
            errorMessage: viewModel.errorMessage,
            addDishIngredient: dishIngredientMethods.add,
            removeDishIngredient: dishIngredientMethods.remove,
            updateDishIngredientAmount: dishIngredientMethods.updateAmount,
            updateDishIngredientUnit: dishIngredientMethods.updateUnit,
            updateDishIngredientName: dishIngredientMethods.updateName,
            addMarinadeIngredient: marinadeIngredientMethods.add,
            removeMarinadeIngredient: marinadeIngredientMethods.remove,
            updateMarinadeIngredientAmount: marinadeIngredientMethods.updateAmount,
            updateMarinadeIngredientUnit: marinadeIngredientMethods.updateUnit,
            updateMarinadeIngredientName: marinadeIngredientMethods.updateName,
            addSeasoningIngredient: seasoningIngredientMethods.add,
            removeSeasoningIngredient: seasoningIngredientMethods.remove,
            updateSeasoningIngredientAmount: seasoningIngredientMethods.updateAmount,
            updateSeasoningIngredientUnit: seasoningIngredientMethods.updateUnit,
            updateSeasoningIngredientName: seasoningIngredientMethods.updateName,
            addBatterIngredient: batterIngredientMethods.add,
            removeBatterIngredient: batterIngredientMethods.remove,
            updateBatterIngredientAmount: batterIngredientMethods.updateAmount,
            updateBatterIngredientUnit: batterIngredientMethods.updateUnit,
            updateBatterIngredientName: batterIngredientMethods.updateName,
            addSauceIngredient: sauceIngredientMethods.add,
            removeSauceIngredient: sauceIngredientMethods.remove,
            updateSauceIngredientAmount: sauceIngredientMethods.updateAmount,
            updateSauceIngredientUnit: sauceIngredientMethods.updateUnit,
            updateSauceIngredientName: sauceIngredientMethods.updateName,
            addBaseIngredient: baseIngredientMethods.add,
            removeBaseIngredient: baseIngredientMethods.remove,
            updateBaseIngredientAmount: baseIngredientMethods.updateAmount,
            updateBaseIngredientUnit: baseIngredientMethods.updateUnit,
            updateBaseIngredientName: baseIngredientMethods.updateName,
            addDoughIngredient: doughIngredientMethods.add,
            removeDoughIngredient: doughIngredientMethods.remove,
            updateDoughIngredientAmount: doughIngredientMethods.updateAmount,
            updateDoughIngredientUnit: doughIngredientMethods.updateUnit,
            updateDoughIngredientName: doughIngredientMethods.updateName,
            addToppingIngredient: toppingIngredientMethods.add,
            removeToppingIngredient: toppingIngredientMethods.remove,
            updateToppingIngredientAmount: toppingIngredientMethods.updateAmount,
            updateToppingIngredientUnit: toppingIngredientMethods.updateUnit,
            updateToppingIngredientName: toppingIngredientMethods.updateName,
            addRecipeImage: { viewModel.addRecipeImage($0) },
            removeRecipeImage: { viewModel.removeRecipeImage(at: $0) },
            generateDescription: { await viewModel.generateDescription() },
            showCuisineSelection: $showCuisineSelection,
            showFullScreenImage: $showFullScreenImage,
            fullScreenImage: $fullScreenImage,
            selectedRecipePhotos: $selectedRecipePhotos,
            instructionsContent: {
                makeInstructionsContent()
            },
            optionalContent: {
                makeOptionalContent()
            }
        )
    }
    
    private struct IngredientMethods {
        let add: () -> Void
        let remove: (Int) -> Void
        let updateAmount: (String, Int) -> Void
        let updateUnit: (String, Int) -> Void
        let updateName: (String, Int) -> Void
    }
    
    private func makeDishIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addDishIngredient() },
            remove: { viewModel.removeDishIngredient(at: $0) },
            updateAmount: { viewModel.updateDishIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateDishIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateDishIngredientName($0, at: $1) }
        )
    }
    
    private func makeMarinadeIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addMarinadeIngredient() },
            remove: { viewModel.removeMarinadeIngredient(at: $0) },
            updateAmount: { viewModel.updateMarinadeIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateMarinadeIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateMarinadeIngredientName($0, at: $1) }
        )
    }
    
    private func makeSeasoningIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addSeasoningIngredient() },
            remove: { viewModel.removeSeasoningIngredient(at: $0) },
            updateAmount: { viewModel.updateSeasoningIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateSeasoningIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateSeasoningIngredientName($0, at: $1) }
        )
    }
    
    private func makeBatterIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addBatterIngredient() },
            remove: { viewModel.removeBatterIngredient(at: $0) },
            updateAmount: { viewModel.updateBatterIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateBatterIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateBatterIngredientName($0, at: $1) }
        )
    }
    
    private func makeSauceIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addSauceIngredient() },
            remove: { viewModel.removeSauceIngredient(at: $0) },
            updateAmount: { viewModel.updateSauceIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateSauceIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateSauceIngredientName($0, at: $1) }
        )
    }
    
    private func makeBaseIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addBaseIngredient() },
            remove: { viewModel.removeBaseIngredient(at: $0) },
            updateAmount: { viewModel.updateBaseIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateBaseIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateBaseIngredientName($0, at: $1) }
        )
    }
    
    private func makeDoughIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addDoughIngredient() },
            remove: { viewModel.removeDoughIngredient(at: $0) },
            updateAmount: { viewModel.updateDoughIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateDoughIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateDoughIngredientName($0, at: $1) }
        )
    }
    
    private func makeToppingIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addToppingIngredient() },
            remove: { viewModel.removeToppingIngredient(at: $0) },
            updateAmount: { viewModel.updateToppingIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateToppingIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateToppingIngredientName($0, at: $1) }
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
                    TextField(NSLocalizedString("Step", comment: "Step placeholder"), text: stepBinding, axis: .vertical)
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
                        Text(NSLocalizedString("Video attached", comment: "Video attached label"))
                            .font(.caption)
                        Spacer()
                        Button(NSLocalizedString("Remove", comment: "Remove button")) {
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
            Label(NSLocalizedString("Add Step", comment: "Add step button"), systemImage: "plus.circle")
        }
    }
    
    private func handleInstructionPhotosChange(_ photos: [Int: PhotosPickerItem]) {
        for (index, item) in photos {
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    // Optimize image for display to reduce memory usage
                    let optimizedImage = await ImageOptimizer.resizeForDisplay(image, maxDimension: 600)
                    viewModel.setInstructionImage(optimizedImage, at: index)
                    selectedInstructionPhotos.removeValue(forKey: index)
                }
            }
        }
    }
    
    @ViewBuilder
    private func makeOptionalContent() -> some View {
        let sourceImages = !selectedImages.isEmpty ? selectedImages : (initialImage != nil ? [initialImage!] : [])
        
        if !sourceImages.isEmpty {
            Section {
                DisclosureGroup(isExpanded: $isSourceExpanded) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(sourceImages.enumerated()), id: \.offset) { index, sourceImage in
                                Button(action: {
                                    fullScreenImage = sourceImage
                                    showFullScreenImage = true
                                }) {
                                    Image(uiImage: sourceImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 80)
                                        .clipped()
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    
                    Text(sourceImages.count > 1 ? 
                         NSLocalizedString("Source images used for recipe extraction", comment: "Source images description") :
                         NSLocalizedString("Source image used for recipe extraction", comment: "Source image description"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 4)
                } label: {
                    Text(NSLocalizedString("Source", comment: "Source section"))
                        .font(.headline)
                }
            }
        }
    }
}

#Preview {
    ExtractMenuFromImageView()
}

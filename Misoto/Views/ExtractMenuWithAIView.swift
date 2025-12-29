//
//  ExtractMenuWithAIView.swift
//  Misoto
//
//  View for extracting recipes from images using OpenAI
//

import SwiftUI
import PhotosUI

struct ExtractMenuWithAIView: View {
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
        
        if let amountValue = Double(amount.trimmingCharacters(in: .whitespaces)), amountValue > 1 {
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
    @StateObject private var viewModel = ExtractMenuWithAIViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var selectedRecipePhotos: [PhotosPickerItem] = []
    @State private var showCuisineSelection = false
    @State private var cuisineDetectionTask: Task<Void, Never>?
    @State private var showFullScreenImage = false
    @State private var fullScreenImage: UIImage?
    
    let initialImage: UIImage?
    
    init(initialImage: UIImage? = nil) {
        self.initialImage = initialImage
        _selectedImage = State(initialValue: initialImage)
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
        focusedAmountField = nil
        isTitleFocused = false
        isDescriptionFocused = false
        focusedIngredientNameField = nil
        focusedInstructionField = nil
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
                if let sourceImage = selectedImage ?? initialImage {
                    HStack(spacing: 12) {
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
                        
                        Text(NSLocalizedString("Source image used for recipe extraction", comment: "Source image description"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
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
    
    private var instructionsSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isInstructionsExpanded) {
                ForEach(Array(viewModel.instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top, spacing: 16) {
                        // Number circle (matching UploadRecipeView style)
                        Text("\(index + 1)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                        
                        TextField(NSLocalizedString("Step", comment: "Step placeholder"), text: Binding(
                            get: { viewModel.instructions[index] },
                            set: { viewModel.updateInstruction($0, at: index) }
                        ), axis: .vertical)
                        .lineLimit(2...6)
                        .focused($focusedInstructionField, equals: index)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        viewModel.removeInstruction(at: index)
                    }
                }
                
                Button(action: {
                    viewModel.addInstruction()
                }) {
                    Label(NSLocalizedString("Add Step", comment: "Add step button"), systemImage: "plus.circle")
                }
            } label: {
                Text(NSLocalizedString("Instructions", comment: "Instructions section"))
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
            amountIndex: index + 500,
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
            // Amount field
            TextField("0", text: amount)
                .frame(width: 30, height: 44)
                .font(.system(size: 14))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(maxHeight: .infinity, alignment: .center)
                .focused($focusedAmountField, equals: amountIndex)
            
            // Unit field - dropdown picker
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
            
            // Ingredient name field
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
            Section(header: Text(NSLocalizedString("Select Menu Image", comment: "Select menu image section"))) {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .padding(.vertical, 8)
                    
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                            Text(NSLocalizedString("Change Image", comment: "Change image button"))
                        }
                    }
                } else {
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                            Text(NSLocalizedString("Select Menu Image", comment: "Select image button"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                errorSection(errorMessage)
            }
            
            Section {
                Button(action: {
                    if let image = selectedImage {
                        Task {
                            await viewModel.extractRecipe(from: image)
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        Text(NSLocalizedString("Extract Recipe with AI", comment: "Extract recipe button"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(viewModel.isLoading || selectedImage == nil ? Color.gray : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(viewModel.isLoading || selectedImage == nil)
            }
        }
        .navigationTitle(NSLocalizedString("Extract with AI", comment: "Extract with AI title"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhoto) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    // Optimize image for display to reduce memory usage
                    selectedImage = await ImageOptimizer.resizeForDisplay(image, maxDimension: 800)
                }
            }
        }
        .onAppear {
            if let initialImage = initialImage {
                selectedImage = initialImage
            }
        }
    }
    
    private var recipeEditView: some View {
        Form {
            titleSection
            descriptionSection
            cuisineSection
            timeSection
            servingsSection
            difficultySection
            recipeImagesSection
            dishIngredientsSection
            marinadeIngredientsSection
            seasoningIngredientsSection
            batterIngredientsSection
            sauceIngredientsSection
            baseIngredientsSection
            doughIngredientsSection
            toppingIngredientsSection
            instructionsSection
            sourceSection
            if let errorMessage = viewModel.errorMessage {
                errorSection(errorMessage)
            }
        }
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
                Button(NSLocalizedString("Save", comment: "Save button")) {
                    Task {
                        // Don't pass selectedImage - it's the extraction image, not a main recipe image
                        let success = await viewModel.saveRecipe(image: nil)
                        if success {
                            await authViewModel.reloadUserData()
                            dismiss()
                        }
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
}

#Preview {
    ExtractMenuWithAIView()
}

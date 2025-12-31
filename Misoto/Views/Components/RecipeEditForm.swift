//
//  RecipeEditForm.swift
//  Misoto
//
//  Shared recipe editing form component used by both manual entry and extraction views
//

import SwiftUI
import PhotosUI

struct RecipeEditForm<InstructionsContent: View, OptionalContent: View>: View {
    // Unit mapping: singular form -> display name with abbreviation in brackets
    private let unitDisplayNames: [String: String] = [
        "": "-",
        "x": "x",
        "tsp": "Teaspoon (tsp)",
        "tbsp": "Tablespoon (tbsp)",
        "cup": "Cup",
        "oz": "Ounce (oz)",
        "fl_oz": "Fluid Ounce (fl oz)",
        "lb": "Pound (lb)",
        "g": "Gram (g)",
        "kg": "Kilogram (kg)",
        "ml": "Milliliter (ml)",
        "l": "Liter (l)",
        "pinch": "Pinch",
        "pcs": "Pieces (pcs)",
        "pc": "Piece (pc)",
        "slice": "Slice",
        "clove": "Clove",
        "bunch": "Bunch",
        "head": "Head",
        "strand": "Strand"
    ]
    
    // Unit abbreviation mapping: internal unit -> display abbreviation when in use
    private let unitAbbreviations: [String: String] = [
        "fl_oz": "Oz",
        "oz": "oz"
    ]
    
    // Pluralization mapping for units that need to be pluralized
    private let pluralForms: [String: String] = [
        "cup": "cups",
        "pinch": "pinches",
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
        
        // Check if this unit has a specific abbreviation for display (e.g., fl_oz -> Oz, wt_oz -> Oz)
        if let abbreviation = unitAbbreviations[unit] {
            return abbreviation
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
    
    // MARK: - Bindings and Closures
    
    @Binding var title: String
    @Binding var description: String
    @Binding var cuisine: String?
    @Binding var prepTime: Int
    @Binding var cookTime: Int
    @Binding var servings: Int
    @Binding var difficulty: Recipe.Difficulty
    @Binding var spicyLevel: Recipe.SpicyLevel
    @Binding var tips: [String]
    @Binding var dishIngredients: [RecipeTextParser.IngredientItem]
    @Binding var marinadeIngredients: [RecipeTextParser.IngredientItem]
    @Binding var seasoningIngredients: [RecipeTextParser.IngredientItem]
    @Binding var batterIngredients: [RecipeTextParser.IngredientItem]
    @Binding var sauceIngredients: [RecipeTextParser.IngredientItem]
    @Binding var baseIngredients: [RecipeTextParser.IngredientItem]
    @Binding var doughIngredients: [RecipeTextParser.IngredientItem]
    @Binding var toppingIngredients: [RecipeTextParser.IngredientItem]
    @Binding var mainRecipeImages: [UIImage]
    
    var isGeneratingDescription: Bool
    var isDetectingCuisine: Bool
    var errorMessage: String?
    
    // Method closures
    var addDishIngredient: () -> Void
    var removeDishIngredient: (Int) -> Void
    var updateDishIngredientAmount: (String, Int) -> Void
    var updateDishIngredientUnit: (String, Int) -> Void
    var updateDishIngredientName: (String, Int) -> Void
    
    var addMarinadeIngredient: () -> Void
    var removeMarinadeIngredient: (Int) -> Void
    var updateMarinadeIngredientAmount: (String, Int) -> Void
    var updateMarinadeIngredientUnit: (String, Int) -> Void
    var updateMarinadeIngredientName: (String, Int) -> Void
    
    var addSeasoningIngredient: () -> Void
    var removeSeasoningIngredient: (Int) -> Void
    var updateSeasoningIngredientAmount: (String, Int) -> Void
    var updateSeasoningIngredientUnit: (String, Int) -> Void
    var updateSeasoningIngredientName: (String, Int) -> Void
    
    var addBatterIngredient: () -> Void
    var removeBatterIngredient: (Int) -> Void
    var updateBatterIngredientAmount: (String, Int) -> Void
    var updateBatterIngredientUnit: (String, Int) -> Void
    var updateBatterIngredientName: (String, Int) -> Void
    
    var addSauceIngredient: () -> Void
    var removeSauceIngredient: (Int) -> Void
    var updateSauceIngredientAmount: (String, Int) -> Void
    var updateSauceIngredientUnit: (String, Int) -> Void
    var updateSauceIngredientName: (String, Int) -> Void
    
    var addBaseIngredient: () -> Void
    var removeBaseIngredient: (Int) -> Void
    var updateBaseIngredientAmount: (String, Int) -> Void
    var updateBaseIngredientUnit: (String, Int) -> Void
    var updateBaseIngredientName: (String, Int) -> Void
    
    var addDoughIngredient: () -> Void
    var removeDoughIngredient: (Int) -> Void
    var updateDoughIngredientAmount: (String, Int) -> Void
    var updateDoughIngredientUnit: (String, Int) -> Void
    var updateDoughIngredientName: (String, Int) -> Void
    
    var addToppingIngredient: () -> Void
    var removeToppingIngredient: (Int) -> Void
    var updateToppingIngredientAmount: (String, Int) -> Void
    var updateToppingIngredientUnit: (String, Int) -> Void
    var updateToppingIngredientName: (String, Int) -> Void
    
    var addRecipeImage: (UIImage) -> Void
    var removeRecipeImage: (Int) -> Void
    var generateDescription: () async -> Void
    
    // External bindings
    @Binding var showCuisineSelection: Bool
    @Binding var showFullScreenImage: Bool
    @Binding var fullScreenImage: UIImage?
    @Binding var selectedRecipePhotos: [PhotosPickerItem]
    
    // Instructions content builder
    let instructionsContent: () -> InstructionsContent
    
    // Optional additional content (e.g., source section for extraction views)
    let optionalContent: (() -> OptionalContent)?
    
    // Initializer
    init(
        title: Binding<String>,
        description: Binding<String>,
        cuisine: Binding<String?>,
        prepTime: Binding<Int>,
        cookTime: Binding<Int>,
        servings: Binding<Int>,
        difficulty: Binding<Recipe.Difficulty>,
        spicyLevel: Binding<Recipe.SpicyLevel>,
        tips: Binding<[String]>,
        dishIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        marinadeIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        seasoningIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        batterIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        sauceIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        baseIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        doughIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        toppingIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        mainRecipeImages: Binding<[UIImage]>,
        isGeneratingDescription: Bool,
        isDetectingCuisine: Bool,
        errorMessage: String?,
        addDishIngredient: @escaping () -> Void,
        removeDishIngredient: @escaping (Int) -> Void,
        updateDishIngredientAmount: @escaping (String, Int) -> Void,
        updateDishIngredientUnit: @escaping (String, Int) -> Void,
        updateDishIngredientName: @escaping (String, Int) -> Void,
        addMarinadeIngredient: @escaping () -> Void,
        removeMarinadeIngredient: @escaping (Int) -> Void,
        updateMarinadeIngredientAmount: @escaping (String, Int) -> Void,
        updateMarinadeIngredientUnit: @escaping (String, Int) -> Void,
        updateMarinadeIngredientName: @escaping (String, Int) -> Void,
        addSeasoningIngredient: @escaping () -> Void,
        removeSeasoningIngredient: @escaping (Int) -> Void,
        updateSeasoningIngredientAmount: @escaping (String, Int) -> Void,
        updateSeasoningIngredientUnit: @escaping (String, Int) -> Void,
        updateSeasoningIngredientName: @escaping (String, Int) -> Void,
        addBatterIngredient: @escaping () -> Void,
        removeBatterIngredient: @escaping (Int) -> Void,
        updateBatterIngredientAmount: @escaping (String, Int) -> Void,
        updateBatterIngredientUnit: @escaping (String, Int) -> Void,
        updateBatterIngredientName: @escaping (String, Int) -> Void,
        addSauceIngredient: @escaping () -> Void,
        removeSauceIngredient: @escaping (Int) -> Void,
        updateSauceIngredientAmount: @escaping (String, Int) -> Void,
        updateSauceIngredientUnit: @escaping (String, Int) -> Void,
        updateSauceIngredientName: @escaping (String, Int) -> Void,
        addBaseIngredient: @escaping () -> Void,
        removeBaseIngredient: @escaping (Int) -> Void,
        updateBaseIngredientAmount: @escaping (String, Int) -> Void,
        updateBaseIngredientUnit: @escaping (String, Int) -> Void,
        updateBaseIngredientName: @escaping (String, Int) -> Void,
        addDoughIngredient: @escaping () -> Void,
        removeDoughIngredient: @escaping (Int) -> Void,
        updateDoughIngredientAmount: @escaping (String, Int) -> Void,
        updateDoughIngredientUnit: @escaping (String, Int) -> Void,
        updateDoughIngredientName: @escaping (String, Int) -> Void,
        addToppingIngredient: @escaping () -> Void,
        removeToppingIngredient: @escaping (Int) -> Void,
        updateToppingIngredientAmount: @escaping (String, Int) -> Void,
        updateToppingIngredientUnit: @escaping (String, Int) -> Void,
        updateToppingIngredientName: @escaping (String, Int) -> Void,
        addRecipeImage: @escaping (UIImage) -> Void,
        removeRecipeImage: @escaping (Int) -> Void,
        generateDescription: @escaping () async -> Void,
        showCuisineSelection: Binding<Bool>,
        showFullScreenImage: Binding<Bool>,
        fullScreenImage: Binding<UIImage?>,
        selectedRecipePhotos: Binding<[PhotosPickerItem]>,
        @ViewBuilder instructionsContent: @escaping () -> InstructionsContent,
        optionalContent: (() -> OptionalContent)? = nil
    ) {
        _title = title
        _description = description
        _cuisine = cuisine
        _prepTime = prepTime
        _cookTime = cookTime
        _servings = servings
        _difficulty = difficulty
        _spicyLevel = spicyLevel
        _tips = tips
        _dishIngredients = dishIngredients
        _marinadeIngredients = marinadeIngredients
        _seasoningIngredients = seasoningIngredients
        _batterIngredients = batterIngredients
        _sauceIngredients = sauceIngredients
        _baseIngredients = baseIngredients
        _doughIngredients = doughIngredients
        _toppingIngredients = toppingIngredients
        _mainRecipeImages = mainRecipeImages
        self.isGeneratingDescription = isGeneratingDescription
        self.isDetectingCuisine = isDetectingCuisine
        self.errorMessage = errorMessage
        self.addDishIngredient = addDishIngredient
        self.removeDishIngredient = removeDishIngredient
        self.updateDishIngredientAmount = updateDishIngredientAmount
        self.updateDishIngredientUnit = updateDishIngredientUnit
        self.updateDishIngredientName = updateDishIngredientName
        self.addMarinadeIngredient = addMarinadeIngredient
        self.removeMarinadeIngredient = removeMarinadeIngredient
        self.updateMarinadeIngredientAmount = updateMarinadeIngredientAmount
        self.updateMarinadeIngredientUnit = updateMarinadeIngredientUnit
        self.updateMarinadeIngredientName = updateMarinadeIngredientName
        self.addSeasoningIngredient = addSeasoningIngredient
        self.removeSeasoningIngredient = removeSeasoningIngredient
        self.updateSeasoningIngredientAmount = updateSeasoningIngredientAmount
        self.updateSeasoningIngredientUnit = updateSeasoningIngredientUnit
        self.updateSeasoningIngredientName = updateSeasoningIngredientName
        self.addBatterIngredient = addBatterIngredient
        self.removeBatterIngredient = removeBatterIngredient
        self.updateBatterIngredientAmount = updateBatterIngredientAmount
        self.updateBatterIngredientUnit = updateBatterIngredientUnit
        self.updateBatterIngredientName = updateBatterIngredientName
        self.addSauceIngredient = addSauceIngredient
        self.removeSauceIngredient = removeSauceIngredient
        self.updateSauceIngredientAmount = updateSauceIngredientAmount
        self.updateSauceIngredientUnit = updateSauceIngredientUnit
        self.updateSauceIngredientName = updateSauceIngredientName
        self.addBaseIngredient = addBaseIngredient
        self.removeBaseIngredient = removeBaseIngredient
        self.updateBaseIngredientAmount = updateBaseIngredientAmount
        self.updateBaseIngredientUnit = updateBaseIngredientUnit
        self.updateBaseIngredientName = updateBaseIngredientName
        self.addDoughIngredient = addDoughIngredient
        self.removeDoughIngredient = removeDoughIngredient
        self.updateDoughIngredientAmount = updateDoughIngredientAmount
        self.updateDoughIngredientUnit = updateDoughIngredientUnit
        self.updateDoughIngredientName = updateDoughIngredientName
        self.addToppingIngredient = addToppingIngredient
        self.removeToppingIngredient = removeToppingIngredient
        self.updateToppingIngredientAmount = updateToppingIngredientAmount
        self.updateToppingIngredientUnit = updateToppingIngredientUnit
        self.updateToppingIngredientName = updateToppingIngredientName
        self.addRecipeImage = addRecipeImage
        self.removeRecipeImage = removeRecipeImage
        self.generateDescription = generateDescription
        _showCuisineSelection = showCuisineSelection
        _showFullScreenImage = showFullScreenImage
        _fullScreenImage = fullScreenImage
        _selectedRecipePhotos = selectedRecipePhotos
        self.instructionsContent = instructionsContent
        self.optionalContent = optionalContent
    }
    
    @FocusState private var focusedAmountField: Int?
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    @FocusState private var focusedIngredientNameField: Int?
    @FocusState private var focusedTipField: Int?
    
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
    @State private var isRecipeImagesExpanded = true
    @State private var isDifficultyExpanded = true
    @State private var isSpicyLevelExpanded = true
    @State private var isTipsExpanded = false
    
    // Dismiss all keyboards
    private func dismissKeyboard() {
        focusedAmountField = nil
        isTitleFocused = false
        isDescriptionFocused = false
        focusedIngredientNameField = nil
        focusedTipField = nil
    }
    
    // Tips management methods
    private func addTip() {
        tips.append("")
        isTipsExpanded = true
    }
    
    private func removeTip(at index: Int) {
        guard index >= 0 && index < tips.count else { return }
        tips.remove(at: index)
    }
    
    private func updateTip(_ text: String, at index: Int) {
        guard index >= 0 && index < tips.count else { return }
        tips[index] = text
    }
    
    private var tipsSection: some View {
        Section {
            DisclosureGroup(isExpanded: Binding(
                get: { isTipsExpanded || !tips.isEmpty },
                set: { isTipsExpanded = $0 }
            )) {
                ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                    HStack(alignment: .top, spacing: 16) {
                        // Bullet point instead of number
                        Text("•")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.accentColor)
                            .frame(width: 32, height: 32)
                        
                        let tipBinding = Binding<String>(
                            get: { tips[index] },
                            set: { updateTip($0, at: index) }
                        )
                        TextField(NSLocalizedString("Tip", comment: "Tip placeholder"), text: tipBinding, axis: .vertical)
                            .lineLimit(2...6)
                            .focused($focusedTipField, equals: index)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        removeTip(at: index)
                    }
                }
                
                Button(action: {
                    addTip()
                }) {
                    Label(NSLocalizedString("Add Tip", comment: "Add tip button"), systemImage: "plus.circle")
                }
            } label: {
                Text(NSLocalizedString("Additional Tips", comment: "Additional tips section"))
                    .font(.headline)
            }
        }
    }
    
    private var titleSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isTitleExpanded) {
                TextField(NSLocalizedString("Title", comment: "Title placeholder"), text: $title)
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
                    TextField(NSLocalizedString("Description", comment: "Description placeholder"), text: $description, axis: .vertical)
                        .lineLimit(1...)
                        .focused($isDescriptionFocused)
                    
                    Button(action: {
                        Task {
                            await generateDescription()
                        }
                    }) {
                        HStack {
                            if isGeneratingDescription {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(NSLocalizedString("Regenerate Description", comment: "Regenerate description button"))
                        }
                        .font(.caption)
                    }
                    .disabled(isGeneratingDescription || title.isEmpty)
                    .foregroundColor(isGeneratingDescription || title.isEmpty ? .secondary : .accentColor)
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
                    if isDetectingCuisine {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if let cuisine = cuisine, !cuisine.isEmpty {
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
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("Preparation Time", comment: "Preparation time label"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TimePickerView(totalMinutes: $prepTime)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("Cooking Time", comment: "Cooking time label"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TimePickerView(totalMinutes: $cookTime)
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
                ServingsPickerView(servings: $servings)
            }
        }
    }
    
    private var difficultySection: some View {
        Section {
            DisclosureGroup(isExpanded: $isDifficultyExpanded) {
                DifficultyLevelView(
                    difficulty: difficulty,
                    selectedDifficulty: $difficulty
                )
                .padding(.vertical, 4)
            } label: {
                Text(NSLocalizedString("Difficulty", comment: "Difficulty section header"))
                    .font(.headline)
            }
        }
    }
    
    private var spicyLevelSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isSpicyLevelExpanded) {
                SpicyLevelView(
                    spicyLevel: spicyLevel,
                    selectedSpicyLevel: $spicyLevel
                )
                .padding(.vertical, 4)
            } label: {
                Text(NSLocalizedString("Spicy Level", comment: "Spicy level section header"))
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
                        ForEach(Array(mainRecipeImages.enumerated()), id: \.offset) { index, image in
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
                                    removeRecipeImage(index)
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
                        if mainRecipeImages.count < 5 {
                            PhotosPicker(
                                selection: $selectedRecipePhotos,
                                maxSelectionCount: 5 - mainRecipeImages.count,
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
    
    private var dishIngredientsSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isDishExpanded) {
                ForEach(Array(dishIngredients.enumerated()), id: \.offset) { index, ingredient in
                    dishIngredientRow(at: index)
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        removeDishIngredient(index)
                    }
                }
                
                Button(action: {
                    addDishIngredient()
                }) {
                    Label(NSLocalizedString("Add Dish Ingredient", comment: "Add dish ingredient button"), systemImage: "plus.circle")
                }
            } label: {
                Text(NSLocalizedString("Dish Ingredients", comment: "Dish ingredients section"))
                    .font(.headline)
            }
        }
    }
    
    private var marinadeIngredientsSection: some View {
        Section {
            DisclosureGroup(isExpanded: Binding(
                get: { isMarinadeExpanded || !marinadeIngredients.isEmpty },
                set: { isMarinadeExpanded = $0 }
            )) {
                ForEach(Array(marinadeIngredients.enumerated()), id: \.offset) { index, ingredient in
                    marinadeIngredientRow(at: index)
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        removeMarinadeIngredient(index)
                    }
                }
                
                Button(action: {
                    addMarinadeIngredient()
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
                get: { isSeasoningExpanded || !seasoningIngredients.isEmpty },
                set: { isSeasoningExpanded = $0 }
            )) {
                ForEach(Array(seasoningIngredients.enumerated()), id: \.offset) { index, ingredient in
                    seasoningIngredientRow(at: index)
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        removeSeasoningIngredient(index)
                    }
                }
                
                Button(action: {
                    addSeasoningIngredient()
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
                get: { isBatterExpanded || !batterIngredients.isEmpty },
                set: { isBatterExpanded = $0 }
            )) {
                ForEach(Array(batterIngredients.enumerated()), id: \.offset) { index, ingredient in
                    batterIngredientRow(at: index)
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        removeBatterIngredient(index)
                    }
                }
                
                Button(action: {
                    addBatterIngredient()
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
                get: { isSauceExpanded || !sauceIngredients.isEmpty },
                set: { isSauceExpanded = $0 }
            )) {
                ForEach(Array(sauceIngredients.enumerated()), id: \.offset) { index, ingredient in
                    sauceIngredientRow(at: index)
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        removeSauceIngredient(index)
                    }
                }
                
                Button(action: {
                    addSauceIngredient()
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
                get: { isBaseExpanded || !baseIngredients.isEmpty },
                set: { isBaseExpanded = $0 }
            )) {
                ForEach(Array(baseIngredients.enumerated()), id: \.offset) { index, ingredient in
                    baseIngredientRow(at: index)
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        removeBaseIngredient(index)
                    }
                }
                
                Button(action: {
                    addBaseIngredient()
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
                get: { isDoughExpanded || !doughIngredients.isEmpty },
                set: { isDoughExpanded = $0 }
            )) {
                ForEach(Array(doughIngredients.enumerated()), id: \.offset) { index, ingredient in
                    doughIngredientRow(at: index)
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        removeDoughIngredient(index)
                    }
                }
                
                Button(action: {
                    addDoughIngredient()
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
                get: { isToppingExpanded || !toppingIngredients.isEmpty },
                set: { isToppingExpanded = $0 }
            )) {
                ForEach(Array(toppingIngredients.enumerated()), id: \.offset) { index, ingredient in
                    toppingIngredientRow(at: index)
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        removeToppingIngredient(index)
                    }
                }
                
                Button(action: {
                    addToppingIngredient()
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
    
    // MARK: - Ingredient Row Helpers
    
    private func dishIngredientRow(at index: Int) -> some View {
        ingredientRow(
            amount: Binding(
                get: { dishIngredients[index].amount },
                set: { updateDishIngredientAmount($0, index) }
            ),
            unit: Binding(
                get: { dishIngredients[index].unit },
                set: { updateDishIngredientUnit($0, index) }
            ),
            name: Binding(
                get: { dishIngredients[index].name },
                set: { updateDishIngredientName($0, index) }
            ),
            amountIndex: index + 1000,
            nameIndex: index + 1000
        )
    }
    
    private func marinadeIngredientRow(at index: Int) -> some View {
        ingredientRow(
            amount: Binding(
                get: { marinadeIngredients[index].amount },
                set: { updateMarinadeIngredientAmount($0, index) }
            ),
            unit: Binding(
                get: { marinadeIngredients[index].unit },
                set: { updateMarinadeIngredientUnit($0, index) }
            ),
            name: Binding(
                get: { marinadeIngredients[index].name },
                set: { updateMarinadeIngredientName($0, index) }
            ),
            amountIndex: index,
            nameIndex: index
        )
    }
    
    private func seasoningIngredientRow(at index: Int) -> some View {
        ingredientRow(
            amount: Binding(
                get: { seasoningIngredients[index].amount },
                set: { updateSeasoningIngredientAmount($0, index) }
            ),
            unit: Binding(
                get: { seasoningIngredients[index].unit },
                set: { updateSeasoningIngredientUnit($0, index) }
            ),
            name: Binding(
                get: { seasoningIngredients[index].name },
                set: { updateSeasoningIngredientName($0, index) }
            ),
            amountIndex: index + 500,
            nameIndex: index + 500
        )
    }
    
    private func batterIngredientRow(at index: Int) -> some View {
        ingredientRow(
            amount: Binding(
                get: { batterIngredients[index].amount },
                set: { updateBatterIngredientAmount($0, index) }
            ),
            unit: Binding(
                get: { batterIngredients[index].unit },
                set: { updateBatterIngredientUnit($0, index) }
            ),
            name: Binding(
                get: { batterIngredients[index].name },
                set: { updateBatterIngredientName($0, index) }
            ),
            amountIndex: index + 2000,
            nameIndex: index + 2000
        )
    }
    
    private func sauceIngredientRow(at index: Int) -> some View {
        ingredientRow(
            amount: Binding(
                get: { sauceIngredients[index].amount },
                set: { updateSauceIngredientAmount($0, index) }
            ),
            unit: Binding(
                get: { sauceIngredients[index].unit },
                set: { updateSauceIngredientUnit($0, index) }
            ),
            name: Binding(
                get: { sauceIngredients[index].name },
                set: { updateSauceIngredientName($0, index) }
            ),
            amountIndex: index + 3000,
            nameIndex: index + 3000
        )
    }
    
    private func baseIngredientRow(at index: Int) -> some View {
        ingredientRow(
            amount: Binding(
                get: { baseIngredients[index].amount },
                set: { updateBaseIngredientAmount($0, index) }
            ),
            unit: Binding(
                get: { baseIngredients[index].unit },
                set: { updateBaseIngredientUnit($0, index) }
            ),
            name: Binding(
                get: { baseIngredients[index].name },
                set: { updateBaseIngredientName($0, index) }
            ),
            amountIndex: index + 4000,
            nameIndex: index + 4000
        )
    }
    
    private func doughIngredientRow(at index: Int) -> some View {
        ingredientRow(
            amount: Binding(
                get: { doughIngredients[index].amount },
                set: { updateDoughIngredientAmount($0, index) }
            ),
            unit: Binding(
                get: { doughIngredients[index].unit },
                set: { updateDoughIngredientUnit($0, index) }
            ),
            name: Binding(
                get: { doughIngredients[index].name },
                set: { updateDoughIngredientName($0, index) }
            ),
            amountIndex: index + 5000,
            nameIndex: index + 5000
        )
    }
    
    private func toppingIngredientRow(at index: Int) -> some View {
        ingredientRow(
            amount: Binding(
                get: { toppingIngredients[index].amount },
                set: { updateToppingIngredientAmount($0, index) }
            ),
            unit: Binding(
                get: { toppingIngredients[index].unit },
                set: { updateToppingIngredientUnit($0, index) }
            ),
            name: Binding(
                get: { toppingIngredients[index].name },
                set: { updateToppingIngredientName($0, index) }
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
        Form {
            titleSection
            descriptionSection
            cuisineSection
            timeSection
            servingsSection
            difficultySection
            spicyLevelSection
            recipeImagesSection
            
            dishIngredientsSection
            marinadeIngredientsSection
            seasoningIngredientsSection
            batterIngredientsSection
            sauceIngredientsSection
            baseIngredientsSection
            doughIngredientsSection
            toppingIngredientsSection
            
            // Instructions section - provided by parent view
            Section {
                DisclosureGroup(isExpanded: $isInstructionsExpanded) {
                    instructionsContent()
                } label: {
                    Text(NSLocalizedString("Instructions", comment: "Instructions section"))
                        .font(.headline)
                }
            }
            
            // Tips section
            tipsSection
            
            // Optional additional content (e.g., source section) - after tips
            if let optionalContent = optionalContent {
                optionalContent()
            }
            
            if let errorMessage = errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
    }
}

// Convenience initializer without optional content
extension RecipeEditForm where OptionalContent == EmptyView {
    init(
        title: Binding<String>,
        description: Binding<String>,
        cuisine: Binding<String?>,
        prepTime: Binding<Int>,
        cookTime: Binding<Int>,
        servings: Binding<Int>,
        difficulty: Binding<Recipe.Difficulty>,
        spicyLevel: Binding<Recipe.SpicyLevel>,
        tips: Binding<[String]>,
        dishIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        marinadeIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        seasoningIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        batterIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        sauceIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        baseIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        doughIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        toppingIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        mainRecipeImages: Binding<[UIImage]>,
        isGeneratingDescription: Bool,
        isDetectingCuisine: Bool,
        errorMessage: String?,
        addDishIngredient: @escaping () -> Void,
        removeDishIngredient: @escaping (Int) -> Void,
        updateDishIngredientAmount: @escaping (String, Int) -> Void,
        updateDishIngredientUnit: @escaping (String, Int) -> Void,
        updateDishIngredientName: @escaping (String, Int) -> Void,
        addMarinadeIngredient: @escaping () -> Void,
        removeMarinadeIngredient: @escaping (Int) -> Void,
        updateMarinadeIngredientAmount: @escaping (String, Int) -> Void,
        updateMarinadeIngredientUnit: @escaping (String, Int) -> Void,
        updateMarinadeIngredientName: @escaping (String, Int) -> Void,
        addSeasoningIngredient: @escaping () -> Void,
        removeSeasoningIngredient: @escaping (Int) -> Void,
        updateSeasoningIngredientAmount: @escaping (String, Int) -> Void,
        updateSeasoningIngredientUnit: @escaping (String, Int) -> Void,
        updateSeasoningIngredientName: @escaping (String, Int) -> Void,
        addBatterIngredient: @escaping () -> Void,
        removeBatterIngredient: @escaping (Int) -> Void,
        updateBatterIngredientAmount: @escaping (String, Int) -> Void,
        updateBatterIngredientUnit: @escaping (String, Int) -> Void,
        updateBatterIngredientName: @escaping (String, Int) -> Void,
        addSauceIngredient: @escaping () -> Void,
        removeSauceIngredient: @escaping (Int) -> Void,
        updateSauceIngredientAmount: @escaping (String, Int) -> Void,
        updateSauceIngredientUnit: @escaping (String, Int) -> Void,
        updateSauceIngredientName: @escaping (String, Int) -> Void,
        addBaseIngredient: @escaping () -> Void,
        removeBaseIngredient: @escaping (Int) -> Void,
        updateBaseIngredientAmount: @escaping (String, Int) -> Void,
        updateBaseIngredientUnit: @escaping (String, Int) -> Void,
        updateBaseIngredientName: @escaping (String, Int) -> Void,
        addDoughIngredient: @escaping () -> Void,
        removeDoughIngredient: @escaping (Int) -> Void,
        updateDoughIngredientAmount: @escaping (String, Int) -> Void,
        updateDoughIngredientUnit: @escaping (String, Int) -> Void,
        updateDoughIngredientName: @escaping (String, Int) -> Void,
        addToppingIngredient: @escaping () -> Void,
        removeToppingIngredient: @escaping (Int) -> Void,
        updateToppingIngredientAmount: @escaping (String, Int) -> Void,
        updateToppingIngredientUnit: @escaping (String, Int) -> Void,
        updateToppingIngredientName: @escaping (String, Int) -> Void,
        addRecipeImage: @escaping (UIImage) -> Void,
        removeRecipeImage: @escaping (Int) -> Void,
        generateDescription: @escaping () async -> Void,
        showCuisineSelection: Binding<Bool>,
        showFullScreenImage: Binding<Bool>,
        fullScreenImage: Binding<UIImage?>,
        selectedRecipePhotos: Binding<[PhotosPickerItem]>,
        @ViewBuilder instructionsContent: @escaping () -> InstructionsContent
    ) {
        self.init(
            title: title,
            description: description,
            cuisine: cuisine,
            prepTime: prepTime,
            cookTime: cookTime,
            servings: servings,
            difficulty: difficulty,
            spicyLevel: spicyLevel,
            tips: tips,
            dishIngredients: dishIngredients,
            marinadeIngredients: marinadeIngredients,
            seasoningIngredients: seasoningIngredients,
            batterIngredients: batterIngredients,
            sauceIngredients: sauceIngredients,
            baseIngredients: baseIngredients,
            doughIngredients: doughIngredients,
            toppingIngredients: toppingIngredients,
            mainRecipeImages: mainRecipeImages,
            isGeneratingDescription: isGeneratingDescription,
            isDetectingCuisine: isDetectingCuisine,
            errorMessage: errorMessage,
            addDishIngredient: addDishIngredient,
            removeDishIngredient: removeDishIngredient,
            updateDishIngredientAmount: updateDishIngredientAmount,
            updateDishIngredientUnit: updateDishIngredientUnit,
            updateDishIngredientName: updateDishIngredientName,
            addMarinadeIngredient: addMarinadeIngredient,
            removeMarinadeIngredient: removeMarinadeIngredient,
            updateMarinadeIngredientAmount: updateMarinadeIngredientAmount,
            updateMarinadeIngredientUnit: updateMarinadeIngredientUnit,
            updateMarinadeIngredientName: updateMarinadeIngredientName,
            addSeasoningIngredient: addSeasoningIngredient,
            removeSeasoningIngredient: removeSeasoningIngredient,
            updateSeasoningIngredientAmount: updateSeasoningIngredientAmount,
            updateSeasoningIngredientUnit: updateSeasoningIngredientUnit,
            updateSeasoningIngredientName: updateSeasoningIngredientName,
            addBatterIngredient: addBatterIngredient,
            removeBatterIngredient: removeBatterIngredient,
            updateBatterIngredientAmount: updateBatterIngredientAmount,
            updateBatterIngredientUnit: updateBatterIngredientUnit,
            updateBatterIngredientName: updateBatterIngredientName,
            addSauceIngredient: addSauceIngredient,
            removeSauceIngredient: removeSauceIngredient,
            updateSauceIngredientAmount: updateSauceIngredientAmount,
            updateSauceIngredientUnit: updateSauceIngredientUnit,
            updateSauceIngredientName: updateSauceIngredientName,
            addBaseIngredient: addBaseIngredient,
            removeBaseIngredient: removeBaseIngredient,
            updateBaseIngredientAmount: updateBaseIngredientAmount,
            updateBaseIngredientUnit: updateBaseIngredientUnit,
            updateBaseIngredientName: updateBaseIngredientName,
            addDoughIngredient: addDoughIngredient,
            removeDoughIngredient: removeDoughIngredient,
            updateDoughIngredientAmount: updateDoughIngredientAmount,
            updateDoughIngredientUnit: updateDoughIngredientUnit,
            updateDoughIngredientName: updateDoughIngredientName,
            addToppingIngredient: addToppingIngredient,
            removeToppingIngredient: removeToppingIngredient,
            updateToppingIngredientAmount: updateToppingIngredientAmount,
            updateToppingIngredientUnit: updateToppingIngredientUnit,
            updateToppingIngredientName: updateToppingIngredientName,
            addRecipeImage: addRecipeImage,
            removeRecipeImage: removeRecipeImage,
            generateDescription: generateDescription,
            showCuisineSelection: showCuisineSelection,
            showFullScreenImage: showFullScreenImage,
            fullScreenImage: fullScreenImage,
            selectedRecipePhotos: selectedRecipePhotos,
            instructionsContent: instructionsContent,
            optionalContent: nil
        )
    }
}


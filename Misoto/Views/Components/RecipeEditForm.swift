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
        "strand": "Strand",
        "large": "Large",
        "small": "Small"
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
    
    // Get localized unit display name for dropdown menu
    private func menuDisplayName(for unit: String) -> String {
        return UnitTranslations.translatedName(for: unit)
    }
    
    // Extract abbreviation from unit display name (the part in parentheses)
    private func extractAbbreviation(from displayName: String) -> String? {
        if let openParen = displayName.firstIndex(of: "("),
           let closeParen = displayName.firstIndex(of: ")") {
            let abbreviation = String(displayName[displayName.index(after: openParen)..<closeParen])
            return abbreviation.trimmingCharacters(in: .whitespaces)
        }
        return nil
    }
    
    // Get abbreviation for a unit (for display when selected)
    private func unitAbbreviation(for unit: String, amount: String? = nil) -> String {
        // Use UnitTranslations to get the language-specific abbreviation with pluralization support
        return UnitTranslations.abbreviation(for: unit, amount: amount)
    }
    
    // Get display name for a unit (shows abbreviation when selected, pluralizes if amount > 1)
    private func displayName(for unit: String, amount: String) -> String {
        if unit.isEmpty {
            return "-"
        }
        
        // Return the abbreviation for the selected unit (with pluralization if needed)
        return unitAbbreviation(for: unit, amount: amount)
    }
    
    
    // MARK: - Bindings and Closures
    
    @Binding var title: String
    @Binding var titleEnglish: String?
    @Binding var titleLocal: String?
    @Binding var titleOriginal: String?
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
    @Binding var doughBatterFillingIngredients: [RecipeTextParser.IngredientItem]
    @Binding var sauceIngredients: [RecipeTextParser.IngredientItem]
    @Binding var toppingIngredients: [RecipeTextParser.IngredientItem]
    @Binding var garnishIngredients: [RecipeTextParser.IngredientItem]
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
    var moveDishIngredient: (Int, Int) -> Void
    
    var addMarinadeIngredient: () -> Void
    var removeMarinadeIngredient: (Int) -> Void
    var updateMarinadeIngredientAmount: (String, Int) -> Void
    var updateMarinadeIngredientUnit: (String, Int) -> Void
    var updateMarinadeIngredientName: (String, Int) -> Void
    var moveMarinadeIngredient: (Int, Int) -> Void
    
    var addSeasoningIngredient: () -> Void
    var removeSeasoningIngredient: (Int) -> Void
    var updateSeasoningIngredientAmount: (String, Int) -> Void
    var updateSeasoningIngredientUnit: (String, Int) -> Void
    var updateSeasoningIngredientName: (String, Int) -> Void
    var moveSeasoningIngredient: (Int, Int) -> Void
    
    var addDoughBatterFillingIngredient: () -> Void
    var removeDoughBatterFillingIngredient: (Int) -> Void
    var updateDoughBatterFillingIngredientAmount: (String, Int) -> Void
    var updateDoughBatterFillingIngredientUnit: (String, Int) -> Void
    var updateDoughBatterFillingIngredientName: (String, Int) -> Void
    var moveDoughBatterFillingIngredient: (Int, Int) -> Void
    
    var addSauceIngredient: () -> Void
    var removeSauceIngredient: (Int) -> Void
    var updateSauceIngredientAmount: (String, Int) -> Void
    var updateSauceIngredientUnit: (String, Int) -> Void
    var updateSauceIngredientName: (String, Int) -> Void
    var moveSauceIngredient: (Int, Int) -> Void
    
    var addToppingIngredient: () -> Void
    var removeToppingIngredient: (Int) -> Void
    var updateToppingIngredientAmount: (String, Int) -> Void
    var updateToppingIngredientUnit: (String, Int) -> Void
    var updateToppingIngredientName: (String, Int) -> Void
    var moveToppingIngredient: (Int, Int) -> Void
    
    var addGarnishIngredient: () -> Void
    var removeGarnishIngredient: (Int) -> Void
    var updateGarnishIngredientAmount: (String, Int) -> Void
    var updateGarnishIngredientUnit: (String, Int) -> Void
    var updateGarnishIngredientName: (String, Int) -> Void
    var moveGarnishIngredient: (Int, Int) -> Void
    
    // Optional: Method to move ingredient between categories (for EditRecipeView)
    var moveIngredientBetweenCategories: ((Ingredient.Category, Int, Ingredient.Category, Int) -> Void)?
    
    var addRecipeImage: (UIImage) -> Void
    var removeRecipeImage: (Int) -> Void
    var generateDescription: () async -> Void
    
    // External bindings
    @Binding var showCuisineSelection: Bool
    @Binding var showFullScreenImage: Bool
    @Binding var fullScreenImage: UIImage?
    @Binding var selectedRecipePhotos: [PhotosPickerItem]
    
    // Optional callbacks for when add image button is tapped
    let onTakePicture: (() -> Void)?
    let onSelectFromLibrary: (() -> Void)?
    
    @State private var showImageSourceOptions = false
    
    // Instructions content builder
    let instructionsContent: () -> InstructionsContent
    
    // Optional AI Editor for instructions
    let onEditInstructionsWithAI: (() async -> Void)?
    let isEditingInstructions: Bool
    let hasNonEmptyInstructions: Bool
    
    // Optional additional content (e.g., source section for extraction views)
    let optionalContent: (() -> OptionalContent)?
    
    // Initializer
    init(
        title: Binding<String>,
        titleEnglish: Binding<String?>,
        titleLocal: Binding<String?>,
        titleOriginal: Binding<String?>,
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
        doughBatterFillingIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        sauceIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        toppingIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        garnishIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        mainRecipeImages: Binding<[UIImage]>,
        isGeneratingDescription: Bool,
        isDetectingCuisine: Bool,
        errorMessage: String?,
        addDishIngredient: @escaping () -> Void,
        removeDishIngredient: @escaping (Int) -> Void,
        updateDishIngredientAmount: @escaping (String, Int) -> Void,
        updateDishIngredientUnit: @escaping (String, Int) -> Void,
        updateDishIngredientName: @escaping (String, Int) -> Void,
        moveDishIngredient: @escaping (Int, Int) -> Void,
        addMarinadeIngredient: @escaping () -> Void,
        removeMarinadeIngredient: @escaping (Int) -> Void,
        updateMarinadeIngredientAmount: @escaping (String, Int) -> Void,
        updateMarinadeIngredientUnit: @escaping (String, Int) -> Void,
        updateMarinadeIngredientName: @escaping (String, Int) -> Void,
        moveMarinadeIngredient: @escaping (Int, Int) -> Void,
        addSeasoningIngredient: @escaping () -> Void,
        removeSeasoningIngredient: @escaping (Int) -> Void,
        updateSeasoningIngredientAmount: @escaping (String, Int) -> Void,
        updateSeasoningIngredientUnit: @escaping (String, Int) -> Void,
        updateSeasoningIngredientName: @escaping (String, Int) -> Void,
        moveSeasoningIngredient: @escaping (Int, Int) -> Void,
        addDoughBatterFillingIngredient: @escaping () -> Void,
        removeDoughBatterFillingIngredient: @escaping (Int) -> Void,
        updateDoughBatterFillingIngredientAmount: @escaping (String, Int) -> Void,
        updateDoughBatterFillingIngredientUnit: @escaping (String, Int) -> Void,
        updateDoughBatterFillingIngredientName: @escaping (String, Int) -> Void,
        moveDoughBatterFillingIngredient: @escaping (Int, Int) -> Void,
        addSauceIngredient: @escaping () -> Void,
        removeSauceIngredient: @escaping (Int) -> Void,
        updateSauceIngredientAmount: @escaping (String, Int) -> Void,
        updateSauceIngredientUnit: @escaping (String, Int) -> Void,
        updateSauceIngredientName: @escaping (String, Int) -> Void,
        moveSauceIngredient: @escaping (Int, Int) -> Void,
        addToppingIngredient: @escaping () -> Void,
        removeToppingIngredient: @escaping (Int) -> Void,
        updateToppingIngredientAmount: @escaping (String, Int) -> Void,
        updateToppingIngredientUnit: @escaping (String, Int) -> Void,
        updateToppingIngredientName: @escaping (String, Int) -> Void,
        moveToppingIngredient: @escaping (Int, Int) -> Void,
        addGarnishIngredient: @escaping () -> Void,
        removeGarnishIngredient: @escaping (Int) -> Void,
        updateGarnishIngredientAmount: @escaping (String, Int) -> Void,
        updateGarnishIngredientUnit: @escaping (String, Int) -> Void,
        updateGarnishIngredientName: @escaping (String, Int) -> Void,
        moveGarnishIngredient: @escaping (Int, Int) -> Void,
        addRecipeImage: @escaping (UIImage) -> Void,
        removeRecipeImage: @escaping (Int) -> Void,
        generateDescription: @escaping () async -> Void,
        showCuisineSelection: Binding<Bool>,
        showFullScreenImage: Binding<Bool>,
        fullScreenImage: Binding<UIImage?>,
        selectedRecipePhotos: Binding<[PhotosPickerItem]>,
        onTakePicture: (() -> Void)? = nil,
        onSelectFromLibrary: (() -> Void)? = nil,
        moveIngredientBetweenCategories: ((Ingredient.Category, Int, Ingredient.Category, Int) -> Void)? = nil,
        onEditInstructionsWithAI: (() async -> Void)? = nil,
        isEditingInstructions: Bool = false,
        hasNonEmptyInstructions: Bool = false,
        @ViewBuilder instructionsContent: @escaping () -> InstructionsContent,
        optionalContent: (() -> OptionalContent)? = nil
    ) {
        _title = title
        _titleEnglish = titleEnglish
        _titleLocal = titleLocal
        _titleOriginal = titleOriginal
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
        _doughBatterFillingIngredients = doughBatterFillingIngredients
        _sauceIngredients = sauceIngredients
        _toppingIngredients = toppingIngredients
        _garnishIngredients = garnishIngredients
        _mainRecipeImages = mainRecipeImages
        self.isGeneratingDescription = isGeneratingDescription
        self.isDetectingCuisine = isDetectingCuisine
        self.errorMessage = errorMessage
        self.addDishIngredient = addDishIngredient
        self.removeDishIngredient = removeDishIngredient
        self.updateDishIngredientAmount = updateDishIngredientAmount
        self.updateDishIngredientUnit = updateDishIngredientUnit
        self.updateDishIngredientName = updateDishIngredientName
        self.moveDishIngredient = moveDishIngredient
        self.addMarinadeIngredient = addMarinadeIngredient
        self.removeMarinadeIngredient = removeMarinadeIngredient
        self.updateMarinadeIngredientAmount = updateMarinadeIngredientAmount
        self.updateMarinadeIngredientUnit = updateMarinadeIngredientUnit
        self.updateMarinadeIngredientName = updateMarinadeIngredientName
        self.moveMarinadeIngredient = moveMarinadeIngredient
        self.addSeasoningIngredient = addSeasoningIngredient
        self.removeSeasoningIngredient = removeSeasoningIngredient
        self.updateSeasoningIngredientAmount = updateSeasoningIngredientAmount
        self.updateSeasoningIngredientUnit = updateSeasoningIngredientUnit
        self.updateSeasoningIngredientName = updateSeasoningIngredientName
        self.moveSeasoningIngredient = moveSeasoningIngredient
        self.addDoughBatterFillingIngredient = addDoughBatterFillingIngredient
        self.removeDoughBatterFillingIngredient = removeDoughBatterFillingIngredient
        self.updateDoughBatterFillingIngredientAmount = updateDoughBatterFillingIngredientAmount
        self.updateDoughBatterFillingIngredientUnit = updateDoughBatterFillingIngredientUnit
        self.updateDoughBatterFillingIngredientName = updateDoughBatterFillingIngredientName
        self.moveDoughBatterFillingIngredient = moveDoughBatterFillingIngredient
        self.addSauceIngredient = addSauceIngredient
        self.removeSauceIngredient = removeSauceIngredient
        self.updateSauceIngredientAmount = updateSauceIngredientAmount
        self.updateSauceIngredientUnit = updateSauceIngredientUnit
        self.updateSauceIngredientName = updateSauceIngredientName
        self.moveSauceIngredient = moveSauceIngredient
        self.addToppingIngredient = addToppingIngredient
        self.removeToppingIngredient = removeToppingIngredient
        self.updateToppingIngredientAmount = updateToppingIngredientAmount
        self.updateToppingIngredientUnit = updateToppingIngredientUnit
        self.updateToppingIngredientName = updateToppingIngredientName
        self.moveToppingIngredient = moveToppingIngredient
        self.addGarnishIngredient = addGarnishIngredient
        self.removeGarnishIngredient = removeGarnishIngredient
        self.updateGarnishIngredientAmount = updateGarnishIngredientAmount
        self.updateGarnishIngredientUnit = updateGarnishIngredientUnit
        self.updateGarnishIngredientName = updateGarnishIngredientName
        self.moveGarnishIngredient = moveGarnishIngredient
        self.moveIngredientBetweenCategories = moveIngredientBetweenCategories
        self.addRecipeImage = addRecipeImage
        self.removeRecipeImage = removeRecipeImage
        self.generateDescription = generateDescription
        _showCuisineSelection = showCuisineSelection
        _showFullScreenImage = showFullScreenImage
        _fullScreenImage = fullScreenImage
        _selectedRecipePhotos = selectedRecipePhotos
        self.onTakePicture = onTakePicture
        self.onSelectFromLibrary = onSelectFromLibrary
        self.onEditInstructionsWithAI = onEditInstructionsWithAI
        self.isEditingInstructions = isEditingInstructions
        self.hasNonEmptyInstructions = hasNonEmptyInstructions
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
    @State private var isDoughBatterFillingExpanded = false
    @State private var isSauceExpanded = false
    @State private var isToppingExpanded = false
    @State private var isGarnishExpanded = false
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
                        TextField(LocalizedString("Tip", comment: "Tip placeholder"), text: tipBinding, axis: .vertical)
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
                    Label(LocalizedString("Add Tip", comment: "Add tip button"), systemImage: "plus.circle")
                }
            } label: {
                Text(LocalizedString("Additional Tips", comment: "Additional tips section"))
                    .font(.headline)
            }
        }
    }
    
    private var titleSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isTitleExpanded) {
                VStack(alignment: .leading, spacing: 12) {
                    // Main editable title field (system language or English)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedString("Main Title", comment: "Main title label"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField(LocalizedString("Title", comment: "Title placeholder"), text: $title)
                            .focused($isTitleFocused)
                    }
                    
                    // All three titles (editable)
                    VStack(alignment: .leading, spacing: 12) {
                        // English title (always show if exists, or allow creation)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedString("English", comment: "English language label"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField(LocalizedString("Enter title", comment: "Enter title placeholder"), text: Binding(
                                get: { titleEnglish ?? "" },
                                set: { titleEnglish = $0.isEmpty ? nil : $0 }
                            ))
                        }
                        
                        // System language title (always show if exists, or allow creation)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedString("System Language", comment: "System language label"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField(LocalizedString("Enter title", comment: "Enter title placeholder"), text: Binding(
                                get: { titleLocal ?? "" },
                                set: { titleLocal = $0.isEmpty ? nil : $0 }
                            ))
                        }
                        
                        // Original language title (always show if exists, or allow creation)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedString("Original Language", comment: "Original language label"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField(LocalizedString("Enter title", comment: "Enter title placeholder"), text: Binding(
                                get: { titleOriginal ?? "" },
                                set: { titleOriginal = $0.isEmpty ? nil : $0 }
                            ))
                        }
                    }
                    .padding(.top, 4)
                }
            } label: {
                Text(LocalizedString("Recipe Title", comment: "Recipe title section"))
                    .font(.headline)
            }
        }
    }
    
    private var descriptionSection: some View {
        Section {
            DisclosureGroup(isExpanded: $isDescriptionExpanded) {
                TextField(LocalizedString("Description", comment: "Description placeholder"), text: $description, axis: .vertical)
                    .lineLimit(1...)
                    .focused($isDescriptionFocused)
            } label: {
                HStack {
                    Text(LocalizedString("Description", comment: "Description section"))
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        HapticFeedback.importantAction()
                        Task {
                            await generateDescription()
                        }
                    }) {
                        HStack(spacing: 4) {
                            if isGeneratingDescription {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.purple)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(LocalizedString("AI", comment: "AI button for description"))
                                .font(.subheadline.bold())
                        }
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(LavaLampBackground())
                    }
                    .disabled(isGeneratingDescription || title.isEmpty)
                    .opacity((isGeneratingDescription || title.isEmpty) ? 0.4 : 1.0)
                }
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
                    if isDetectingCuisine {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if let cuisine = cuisine, !cuisine.isEmpty {
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
                        TimePickerView(totalMinutes: $prepTime)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedString("Cooking Time", comment: "Cooking time label"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TimePickerView(totalMinutes: $cookTime)
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
                Text(LocalizedString("Difficulty", comment: "Difficulty section header"))
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
                Text(LocalizedString("Spicy Level", comment: "Spicy level section header"))
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
                            if onTakePicture != nil || onSelectFromLibrary != nil {
                                // Use callbacks if provided (show dropdown menu)
                                Button(action: {
                                    showImageSourceOptions = true
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
                                .confirmationDialog(
                                    LocalizedString("Add Dish Image", comment: "Add dish image dialog title"),
                                    isPresented: $showImageSourceOptions,
                                    titleVisibility: .visible
                                ) {
                                    if UIImagePickerController.isSourceTypeAvailable(.camera), let onTakePicture = onTakePicture {
                                        Button(LocalizedString("Take picture", comment: "Take picture option")) {
                                            onTakePicture()
                                        }
                                    }
                                    
                                    if let onSelectFromLibrary = onSelectFromLibrary {
                                        Button(LocalizedString("Select from Photo Library", comment: "Select from photo library option")) {
                                            onSelectFromLibrary()
                                        }
                                    }
                                    
                                    Button(LocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {}
                                }
                            } else {
                                // Fallback to PhotosPicker if no callbacks provided
                                PhotosPicker(
                                    selection: $selectedRecipePhotos,
                                    maxSelectionCount: 5 - mainRecipeImages.count,
                                    matching: .images
                                ) {
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
                ForEach(Array(dishIngredients.enumerated()), id: \.offset) { index, ingredient in
                    dishIngredientRow(at: index)
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        removeDishIngredient(index)
                    }
                }
                .onMove { source, destination in
                    if let firstIndex = source.first {
                        moveDishIngredient(firstIndex, destination)
                    }
                }
                
                Button(action: {
                    addDishIngredient()
                }) {
                    Label(LocalizedString("Add ingredient", comment: "Add ingredient button"), systemImage: "plus.circle")
                }
            } label: {
                Text(LocalizedString("For the main ingredients", comment: "Main ingredients section"))
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
                .onMove { source, destination in
                    if let firstIndex = source.first {
                        moveMarinadeIngredient(firstIndex, destination)
                    }
                }
                
                Button(action: {
                    addMarinadeIngredient()
                    isMarinadeExpanded = true
                }) {
                    Label(LocalizedString("Add ingredient", comment: "Add ingredient button"), systemImage: "plus.circle")
                }
            } label: {
                Text(LocalizedString("For the marinade / brine", comment: "Marinade ingredients section"))
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
                .onMove { source, destination in
                    if let firstIndex = source.first {
                        moveSeasoningIngredient(firstIndex, destination)
                    }
                }
                
                Button(action: {
                    addSeasoningIngredient()
                    isSeasoningExpanded = true
                }) {
                    Label(LocalizedString("Add ingredient", comment: "Add ingredient button"), systemImage: "plus.circle")
                }
            } label: {
                Text(LocalizedString("For seasoning during cooking", comment: "Seasoning ingredients section"))
                    .font(.headline)
            }
        }
    }
    
    private var doughBatterFillingIngredientsSection: some View {
        Section {
            DisclosureGroup(isExpanded: Binding(
                get: { isDoughBatterFillingExpanded || !doughBatterFillingIngredients.isEmpty },
                set: { isDoughBatterFillingExpanded = $0 }
            )) {
                ForEach(Array(doughBatterFillingIngredients.enumerated()), id: \.offset) { index, ingredient in
                    doughBatterFillingIngredientRow(at: index)
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        removeDoughBatterFillingIngredient(index)
                    }
                }
                .onMove { source, destination in
                    if let firstIndex = source.first {
                        moveDoughBatterFillingIngredient(firstIndex, destination)
                    }
                }
                
                Button(action: {
                    addDoughBatterFillingIngredient()
                    isDoughBatterFillingExpanded = true
                }) {
                    Label(LocalizedString("Add ingredient", comment: "Add ingredient button"), systemImage: "plus.circle")
                }
            } label: {
                Text(LocalizedString("For the dough / batter / filling", comment: "Dough batter filling ingredients section"))
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
                .onMove { source, destination in
                    if let firstIndex = source.first {
                        moveSauceIngredient(firstIndex, destination)
                    }
                }
                
                Button(action: {
                    addSauceIngredient()
                    isSauceExpanded = true
                }) {
                    Label(LocalizedString("Add ingredient", comment: "Add ingredient button"), systemImage: "plus.circle")
                }
            } label: {
                Text(LocalizedString("For the sauce", comment: "Sauce ingredients section"))
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
                .onMove { source, destination in
                    if let firstIndex = source.first {
                        moveToppingIngredient(firstIndex, destination)
                    }
                }
                
                Button(action: {
                    addToppingIngredient()
                    isToppingExpanded = true
                }) {
                    Label(LocalizedString("Add ingredient", comment: "Add ingredient button"), systemImage: "plus.circle")
                }
            } label: {
                Text(LocalizedString("For the toppings", comment: "Topping ingredients section"))
                    .font(.headline)
            }
        }
    }
    
    private var garnishIngredientsSection: some View {
        Section {
            DisclosureGroup(isExpanded: Binding(
                get: { isGarnishExpanded || !garnishIngredients.isEmpty },
                set: { isGarnishExpanded = $0 }
            )) {
                ForEach(Array(garnishIngredients.enumerated()), id: \.offset) { index, ingredient in
                    garnishIngredientRow(at: index)
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        removeGarnishIngredient(index)
                    }
                }
                .onMove { source, destination in
                    if let firstIndex = source.first {
                        moveGarnishIngredient(firstIndex, destination)
                    }
                }
                
                Button(action: {
                    addGarnishIngredient()
                    isGarnishExpanded = true
                }) {
                    Label(LocalizedString("Add ingredient", comment: "Add ingredient button"), systemImage: "plus.circle")
                }
            } label: {
                Text(LocalizedString("To finish / To garnish", comment: "Garnish ingredients section"))
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
            nameIndex: index + 1000,
            currentCategory: .dish,
            ingredientIndex: index
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
            nameIndex: index,
            currentCategory: .marinade,
            ingredientIndex: index
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
            nameIndex: index + 500,
            currentCategory: .seasoning,
            ingredientIndex: index
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
            nameIndex: index + 3000,
            currentCategory: .sauce,
            ingredientIndex: index
        )
    }
    
    private func doughBatterFillingIngredientRow(at index: Int) -> some View {
        ingredientRow(
            amount: Binding(
                get: { doughBatterFillingIngredients[index].amount },
                set: { updateDoughBatterFillingIngredientAmount($0, index) }
            ),
            unit: Binding(
                get: { doughBatterFillingIngredients[index].unit },
                set: { updateDoughBatterFillingIngredientUnit($0, index) }
            ),
            name: Binding(
                get: { doughBatterFillingIngredients[index].name },
                set: { updateDoughBatterFillingIngredientName($0, index) }
            ),
            amountIndex: index + 2000,
            nameIndex: index + 2000,
            currentCategory: .dough,
            ingredientIndex: index
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
            nameIndex: index + 6000,
            currentCategory: .topping,
            ingredientIndex: index
        )
    }
    
    private func garnishIngredientRow(at index: Int) -> some View {
        ingredientRow(
            amount: Binding(
                get: { garnishIngredients[index].amount },
                set: { updateGarnishIngredientAmount($0, index) }
            ),
            unit: Binding(
                get: { garnishIngredients[index].unit },
                set: { updateGarnishIngredientUnit($0, index) }
            ),
            name: Binding(
                get: { garnishIngredients[index].name },
                set: { updateGarnishIngredientName($0, index) }
            ),
            amountIndex: index + 8000,
            nameIndex: index + 8000,
            currentCategory: .garnish,
            ingredientIndex: index
        )
    }
    
    // Reusable ingredient row view
    private func ingredientRow(
        amount: Binding<String>,
        unit: Binding<String>,
        name: Binding<String>,
        amountIndex: Int,
        nameIndex: Int,
        currentCategory: Ingredient.Category? = nil,
        ingredientIndex: Int = 0
    ) -> some View {
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
            
            // Category picker button (only show if moveIngredientBetweenCategories is available)
            if let moveIngredient = moveIngredientBetweenCategories, let category = currentCategory {
                Menu {
                    // Header text (non-clickable)
                    Label {
                        Text(LocalizedString("Move Ingredient to", comment: "Menu header for moving ingredient"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } icon: {
                        EmptyView()
                    }
                    .disabled(true)
                    
                    Divider()
                    
                    let allCategories: [Ingredient.Category] = [.dish, .marinade, .seasoning, .dough, .sauce, .topping, .garnish]
                    ForEach(allCategories, id: \.self) { targetCategory in
                        if targetCategory != category {
                            Button(action: {
                                // Expand the target section if it's collapsed
                                switch targetCategory {
                                case .dish:
                                    isDishExpanded = true
                                case .marinade:
                                    isMarinadeExpanded = true
                                case .seasoning:
                                    isSeasoningExpanded = true
                                case .batter, .base, .dough, .filling:
                                    isDoughBatterFillingExpanded = true
                                case .sauce:
                                    isSauceExpanded = true
                                case .topping:
                                    isToppingExpanded = true
                                case .garnish:
                                    isGarnishExpanded = true
                                }
                                
                                // Move to the end of the target category (index is ignored, always appends)
                                moveIngredient(category, ingredientIndex, targetCategory, 0)
                            }) {
                                HStack {
                                    Text(sectionName(for: targetCategory))
                                    Spacer()
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.right.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // Helper to get section name for category
    private func sectionName(for category: Ingredient.Category) -> String {
        switch category {
        case .dish:
            return LocalizedString("For the main ingredients", comment: "Main ingredients section")
        case .marinade:
            return LocalizedString("For the marinade", comment: "Marinade section")
        case .seasoning:
            return LocalizedString("For the seasoning", comment: "Seasoning section")
        case .batter, .base, .dough, .filling:
            return LocalizedString("For the dough/batter/filling", comment: "Dough/batter/filling section")
        case .sauce:
            return LocalizedString("For the sauce", comment: "Sauce section")
        case .topping:
            return LocalizedString("For the topping", comment: "Topping section")
        case .garnish:
            return LocalizedString("For the garnish", comment: "Garnish section")
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
            doughBatterFillingIngredientsSection
            sauceIngredientsSection
            toppingIngredientsSection
            garnishIngredientsSection
            
            // Instructions section - provided by parent view
            Section {
                DisclosureGroup(isExpanded: $isInstructionsExpanded) {
                    instructionsContent()
                } label: {
                    HStack {
                        Text(LocalizedString("Instructions", comment: "Instructions section"))
                            .font(.headline)
                        
                        if let onEditInstructionsWithAI = onEditInstructionsWithAI {
                            Spacer()
                            
                            Button(action: {
                                HapticFeedback.importantAction()
                                Task {
                                    await onEditInstructionsWithAI()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    if isEditingInstructions {
                                        ProgressView()
                                            .controlSize(.small)
                                            .tint(.purple)
                                    } else {
                                        Image(systemName: "sparkles")
                                    }
                                    Text(LocalizedString("AI", comment: "AI button for instructions"))
                                        .font(.subheadline.bold())
                                }
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(LavaLampBackground())
                            }
                            .disabled(isEditingInstructions || !hasNonEmptyInstructions)
                            .opacity((isEditingInstructions || !hasNonEmptyInstructions) ? 0.4 : 1.0)
                        }
                    }
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
        titleEnglish: Binding<String?>,
        titleLocal: Binding<String?>,
        titleOriginal: Binding<String?>,
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
        doughBatterFillingIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        sauceIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        toppingIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        garnishIngredients: Binding<[RecipeTextParser.IngredientItem]>,
        mainRecipeImages: Binding<[UIImage]>,
        isGeneratingDescription: Bool,
        isDetectingCuisine: Bool,
        errorMessage: String?,
        addDishIngredient: @escaping () -> Void,
        removeDishIngredient: @escaping (Int) -> Void,
        updateDishIngredientAmount: @escaping (String, Int) -> Void,
        updateDishIngredientUnit: @escaping (String, Int) -> Void,
        updateDishIngredientName: @escaping (String, Int) -> Void,
        moveDishIngredient: @escaping (Int, Int) -> Void,
        addMarinadeIngredient: @escaping () -> Void,
        removeMarinadeIngredient: @escaping (Int) -> Void,
        updateMarinadeIngredientAmount: @escaping (String, Int) -> Void,
        updateMarinadeIngredientUnit: @escaping (String, Int) -> Void,
        updateMarinadeIngredientName: @escaping (String, Int) -> Void,
        moveMarinadeIngredient: @escaping (Int, Int) -> Void,
        addSeasoningIngredient: @escaping () -> Void,
        removeSeasoningIngredient: @escaping (Int) -> Void,
        updateSeasoningIngredientAmount: @escaping (String, Int) -> Void,
        updateSeasoningIngredientUnit: @escaping (String, Int) -> Void,
        updateSeasoningIngredientName: @escaping (String, Int) -> Void,
        moveSeasoningIngredient: @escaping (Int, Int) -> Void,
        addDoughBatterFillingIngredient: @escaping () -> Void,
        removeDoughBatterFillingIngredient: @escaping (Int) -> Void,
        updateDoughBatterFillingIngredientAmount: @escaping (String, Int) -> Void,
        updateDoughBatterFillingIngredientUnit: @escaping (String, Int) -> Void,
        updateDoughBatterFillingIngredientName: @escaping (String, Int) -> Void,
        moveDoughBatterFillingIngredient: @escaping (Int, Int) -> Void,
        addSauceIngredient: @escaping () -> Void,
        removeSauceIngredient: @escaping (Int) -> Void,
        updateSauceIngredientAmount: @escaping (String, Int) -> Void,
        updateSauceIngredientUnit: @escaping (String, Int) -> Void,
        updateSauceIngredientName: @escaping (String, Int) -> Void,
        moveSauceIngredient: @escaping (Int, Int) -> Void,
        addToppingIngredient: @escaping () -> Void,
        removeToppingIngredient: @escaping (Int) -> Void,
        updateToppingIngredientAmount: @escaping (String, Int) -> Void,
        updateToppingIngredientUnit: @escaping (String, Int) -> Void,
        updateToppingIngredientName: @escaping (String, Int) -> Void,
        moveToppingIngredient: @escaping (Int, Int) -> Void,
        addGarnishIngredient: @escaping () -> Void,
        removeGarnishIngredient: @escaping (Int) -> Void,
        updateGarnishIngredientAmount: @escaping (String, Int) -> Void,
        updateGarnishIngredientUnit: @escaping (String, Int) -> Void,
        updateGarnishIngredientName: @escaping (String, Int) -> Void,
        moveGarnishIngredient: @escaping (Int, Int) -> Void,
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
            titleEnglish: titleEnglish,
            titleLocal: titleLocal,
            titleOriginal: titleOriginal,
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
            doughBatterFillingIngredients: doughBatterFillingIngredients,
            sauceIngredients: sauceIngredients,
            toppingIngredients: toppingIngredients,
            garnishIngredients: garnishIngredients,
            mainRecipeImages: mainRecipeImages,
            isGeneratingDescription: isGeneratingDescription,
            isDetectingCuisine: isDetectingCuisine,
            errorMessage: errorMessage,
            addDishIngredient: addDishIngredient,
            removeDishIngredient: removeDishIngredient,
            updateDishIngredientAmount: updateDishIngredientAmount,
            updateDishIngredientUnit: updateDishIngredientUnit,
            updateDishIngredientName: updateDishIngredientName,
            moveDishIngredient: moveDishIngredient,
            addMarinadeIngredient: addMarinadeIngredient,
            removeMarinadeIngredient: removeMarinadeIngredient,
            updateMarinadeIngredientAmount: updateMarinadeIngredientAmount,
            updateMarinadeIngredientUnit: updateMarinadeIngredientUnit,
            updateMarinadeIngredientName: updateMarinadeIngredientName,
            moveMarinadeIngredient: moveMarinadeIngredient,
            addSeasoningIngredient: addSeasoningIngredient,
            removeSeasoningIngredient: removeSeasoningIngredient,
            updateSeasoningIngredientAmount: updateSeasoningIngredientAmount,
            updateSeasoningIngredientUnit: updateSeasoningIngredientUnit,
            updateSeasoningIngredientName: updateSeasoningIngredientName,
            moveSeasoningIngredient: moveSeasoningIngredient,
            addDoughBatterFillingIngredient: addDoughBatterFillingIngredient,
            removeDoughBatterFillingIngredient: removeDoughBatterFillingIngredient,
            updateDoughBatterFillingIngredientAmount: updateDoughBatterFillingIngredientAmount,
            updateDoughBatterFillingIngredientUnit: updateDoughBatterFillingIngredientUnit,
            updateDoughBatterFillingIngredientName: updateDoughBatterFillingIngredientName,
            moveDoughBatterFillingIngredient: moveDoughBatterFillingIngredient,
            addSauceIngredient: addSauceIngredient,
            removeSauceIngredient: removeSauceIngredient,
            updateSauceIngredientAmount: updateSauceIngredientAmount,
            updateSauceIngredientUnit: updateSauceIngredientUnit,
            updateSauceIngredientName: updateSauceIngredientName,
            moveSauceIngredient: moveSauceIngredient,
            addToppingIngredient: addToppingIngredient,
            removeToppingIngredient: removeToppingIngredient,
            updateToppingIngredientAmount: updateToppingIngredientAmount,
            updateToppingIngredientUnit: updateToppingIngredientUnit,
            updateToppingIngredientName: updateToppingIngredientName,
            moveToppingIngredient: moveToppingIngredient,
            addGarnishIngredient: addGarnishIngredient,
            removeGarnishIngredient: removeGarnishIngredient,
            updateGarnishIngredientAmount: updateGarnishIngredientAmount,
            updateGarnishIngredientUnit: updateGarnishIngredientUnit,
            updateGarnishIngredientName: updateGarnishIngredientName,
            moveGarnishIngredient: moveGarnishIngredient,
            addRecipeImage: addRecipeImage,
            removeRecipeImage: removeRecipeImage,
            generateDescription: generateDescription,
            showCuisineSelection: showCuisineSelection,
            showFullScreenImage: showFullScreenImage,
            fullScreenImage: fullScreenImage,
            selectedRecipePhotos: selectedRecipePhotos,
            onTakePicture: nil,
            onSelectFromLibrary: nil,
            onEditInstructionsWithAI: nil,
            isEditingInstructions: false,
            hasNonEmptyInstructions: false,
            instructionsContent: instructionsContent,
            optionalContent: nil
        )
    }
}


// MARK: - Lava Lamp AI Button Background

struct LavaLampBackground: View {
    @State private var animate = false

    // Randomised direction multipliers for each blob (-1 or 1)
    @State private var blob1DirX: CGFloat = 1
    @State private var blob1DirY: CGFloat = 1
    @State private var blob2DirX: CGFloat = 1
    @State private var blob2DirY: CGFloat = 1
    @State private var blob3DirX: CGFloat = 1
    @State private var blob3DirY: CGFloat = 1

    // Randomised magnitude jitter (0.8...1.2) so distances vary
    @State private var blob1Jitter: CGFloat = 1
    @State private var blob2Jitter: CGFloat = 1
    @State private var blob3Jitter: CGFloat = 1

    // Randomised opacity multipliers (0.8...1.2 of base opacity)
    @State private var blob1Opacity: CGFloat = 1
    @State private var blob2Opacity: CGFloat = 1
    @State private var blob3Opacity: CGFloat = 1

    // Randomised size multipliers (0.8...1.2 of base size)
    @State private var blob1Size: CGFloat = 1
    @State private var blob2Size: CGFloat = 1
    @State private var blob3Size: CGFloat = 1

    // Randomised animation duration (0.8...1.2 of base 6s)
    @State private var animationDuration: Double = 6.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base gradient fill
                LinearGradient(
                    colors: [.blue.opacity(0.10), .purple.opacity(0.10)],
                    startPoint: .leading,
                    endPoint: .trailing
                )

                // Blob 1 - large, slow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue.opacity(0.35 * blob1Opacity), .blue.opacity(0.0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.4 * blob1Size
                        )
                    )
                    .frame(width: geo.size.width * 0.7 * blob1Size, height: geo.size.height * 1.6 * blob1Size)
                    .offset(
                        x: animate ? geo.size.width * 0.15 * blob1DirX * blob1Jitter : -geo.size.width * 0.25 * blob1DirX * blob1Jitter,
                        y: animate ? -geo.size.height * 0.1 * blob1DirY * blob1Jitter : geo.size.height * 0.1 * blob1DirY * blob1Jitter
                    )

                // Blob 2 - medium, opposite direction
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(0.4 * blob2Opacity), .purple.opacity(0.0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.35 * blob2Size
                        )
                    )
                    .frame(width: geo.size.width * 0.6 * blob2Size, height: geo.size.height * 1.4 * blob2Size)
                    .offset(
                        x: animate ? -geo.size.width * 0.15 * blob2DirX * blob2Jitter : geo.size.width * 0.2 * blob2DirX * blob2Jitter,
                        y: animate ? geo.size.height * 0.15 * blob2DirY * blob2Jitter : -geo.size.height * 0.1 * blob2DirY * blob2Jitter
                    )

                // Blob 3 - small accent
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.indigo.opacity(0.3 * blob3Opacity), .indigo.opacity(0.0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.25 * blob3Size
                        )
                    )
                    .frame(width: geo.size.width * 0.45 * blob3Size, height: geo.size.height * 1.2 * blob3Size)
                    .offset(
                        x: animate ? geo.size.width * 0.1 * blob3DirX * blob3Jitter : -geo.size.width * 0.1 * blob3DirX * blob3Jitter,
                        y: animate ? geo.size.height * 0.05 * blob3DirY * blob3Jitter : -geo.size.height * 0.15 * blob3DirY * blob3Jitter
                    )
            }
        }
        .clipShape(Capsule())
        .onAppear {
            // Randomise direction for each blob axis
            blob1DirX = Bool.random() ? 1 : -1
            blob1DirY = Bool.random() ? 1 : -1
            blob2DirX = Bool.random() ? 1 : -1
            blob2DirY = Bool.random() ? 1 : -1
            blob3DirX = Bool.random() ? 1 : -1
            blob3DirY = Bool.random() ? 1 : -1

            // Randomise magnitude slightly so each instance looks different
            blob1Jitter = CGFloat.random(in: 0.8...1.2)
            blob2Jitter = CGFloat.random(in: 0.8...1.2)
            blob3Jitter = CGFloat.random(in: 0.8...1.2)

            // Randomise opacity (+/- 20% of base)
            blob1Opacity = CGFloat.random(in: 0.8...1.2)
            blob2Opacity = CGFloat.random(in: 0.8...1.2)
            blob3Opacity = CGFloat.random(in: 0.8...1.2)

            // Randomise size (+/- 20% of base)
            blob1Size = CGFloat.random(in: 0.8...1.2)
            blob2Size = CGFloat.random(in: 0.8...1.2)
            blob3Size = CGFloat.random(in: 0.8...1.2)

            // Randomise speed (+/- 20% of base 6s)
            animationDuration = Double.random(in: 4.8...7.2)

            withAnimation(
                .easeInOut(duration: animationDuration)
                .repeatForever(autoreverses: true)
            ) {
                animate = true
            }
        }
    }
}

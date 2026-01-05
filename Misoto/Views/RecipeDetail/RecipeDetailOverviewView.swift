//
//  RecipeDetailOverviewView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import FirebaseAuth
import Combine

struct RecipeDetailOverviewView: View {
    @StateObject private var viewModel: RecipeDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    // TODO: Update this link when Misoto app is available on the App Store
    
    // MARK: - Helper Functions
    
    /// Get spicy level description
    private func spicyLevelDescription(for level: Recipe.SpicyLevel) -> String {
        switch level {
        case .none:
            return LocalizedString("None", comment: "No spice level")
        case .one:
            return LocalizedString("Mild", comment: "Mild spice level")
        case .two:
            return LocalizedString("Hot", comment: "Hot spice level")
        case .three:
            return LocalizedString("Very Hot", comment: "Very hot spice level")
        case .four:
            return LocalizedString("Extreme", comment: "Extreme spice level")
        case .five:
            return LocalizedString("Insane", comment: "Insane spice level")
        }
    }
    private let misotoAppStoreURL = "https://apps.apple.com/app/game-timer/id6746631584"
    
    @State private var showWriteNote = false
    @State private var showNotesList = false
    @State private var showStepView = false
    @State private var showRelatedRecipes = false
    @State private var showMenu = false
    @State private var showDeleteConfirmation = false
    @State private var showReportSheet = false
    @State private var showShareSheet = false
    @State private var showEditRecipe = false
    @State private var noteToEdit: RecipeNote?
    @State private var noteToDelete: RecipeNote?
    @State private var showDeleteNoteConfirmation = false
    @State private var scrollOffset: CGFloat = 0
    @State private var shareImage: UIImage?
    @State private var isPreparingShare = false
    
    private var isAuthor: Bool {
        guard let userID = Auth.auth().currentUser?.uid else { return false }
        return viewModel.recipe.authorID == userID
    }
    
    init(recipe: Recipe) {
        _viewModel = StateObject(wrappedValue: RecipeDetailViewModel(recipe: recipe))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                GeometryReader { geometry in
                    let imageHeight: CGFloat = 400
                    let minImageHeight: CGFloat = 200
                    let maxImageHeight: CGFloat = 600
                    
                    // Calculate dynamic image height based on scroll
                    let dynamicImageHeight = max(minImageHeight, min(maxImageHeight, imageHeight - scrollOffset))
                    let stretchAmount = max(0, -scrollOffset) // Only stretch when dragging down
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // Ensure full width constraint
                            Color.clear
                                .frame(width: geometry.size.width, height: 0)
                            
                            // Sticky Hero Image (extends to top, ignoring safe area)
                            ZStack(alignment: .top) {
                                // Recipe Image with stretch effect (extends to top)
                                if let imageURL = viewModel.recipe.imageURL, let url = URL(string: imageURL) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .overlay {
                                                ProgressView()
                                                    .tint(.white)
                                            }
                                    }
                                    .frame(width: geometry.size.width, height: dynamicImageHeight + stretchAmount + geometry.safeAreaInsets.top)
                                    .frame(width: stretchAmount > 0 ? geometry.size.width + (stretchAmount * 0.5) : geometry.size.width)
                                    .clipped()
                                    .offset(y: stretchAmount > 0 ? stretchAmount * 0.3 : -geometry.safeAreaInsets.top) // Extend to top, accounting for safe area
                                } else {
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.3)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: geometry.size.width, height: dynamicImageHeight + stretchAmount + geometry.safeAreaInsets.top)
                                        .frame(width: stretchAmount > 0 ? geometry.size.width + (stretchAmount * 0.5) : geometry.size.width)
                                        .offset(y: -geometry.safeAreaInsets.top) // Extend to top
                                        .overlay {
                                            Image(systemName: "photo")
                                                .font(.system(size: 60))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                }
                                
                                // Gradient Overlay
                                LinearGradient(
                                    colors: [Color.clear, Color.black.opacity(0.7)],
                                    startPoint: .center,
                                    endPoint: .bottom
                                )
                                .frame(height: dynamicImageHeight + stretchAmount + geometry.safeAreaInsets.top)
                                .offset(y: -geometry.safeAreaInsets.top) // Extend to top
                                
                                // Title and Metadata Overlay (positioned just above ingredients card)
                                VStack {
                                    Spacer()
                                    
                                    VStack(alignment: .leading, spacing: 12) {
                                        // Recipe Title
                                        Text(viewModel.recipe.title)
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        // Metadata Rows
                                        VStack(alignment: .leading, spacing: 8) {
                                            // First Row: Time, Servings, Difficulty, Spicy Level, Cuisine (wraps if needed)
                                            HStack(alignment: .top, spacing: 16) {
                                                // Time
                                                HStack(spacing: 4) {
                                                    Image(systemName: "clock")
                                                        .font(.system(size: 14))
                                                    Text("\(viewModel.totalTime) \(LocalizedString("min", comment: "Minutes abbreviation"))")
                                                        .font(.system(size: 14))
                                                }
                                                
                                                // Servings
                                                HStack(spacing: 4) {
                                                    Image(systemName: "person.2")
                                                        .font(.system(size: 14))
                                                    Text("\(viewModel.recipe.servings)")
                                                        .font(.system(size: 14))
                                                }
                                                
                                                // Difficulty
                                                HStack(spacing: 4) {
                                                    Image(systemName: "chart.bar")
                                                        .font(.system(size: 14))
                                                    Text(viewModel.recipe.difficulty.rawValue)
                                                        .font(.system(size: 14))
                                                }
                                                
                                                // Spicy Level (if > 0)
                                                if viewModel.recipe.spicyLevel != .none {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "flame.fill")
                                                            .font(.system(size: 14))
                                                            .foregroundColor(.orange)
                                                        Text(spicyLevelDescription(for: viewModel.recipe.spicyLevel))
                                                            .font(.system(size: 14))
                                                    }
                                                }
                                                
                                                // Cuisine (if available) - now on same row
                                                if let cuisine = viewModel.recipe.displayCuisine {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "globe")
                                                            .font(.system(size: 14))
                                                        Text(cuisine)
                                                            .font(.system(size: 14))
                                                    }
                                                }
                                            }
                                        }
                                        .foregroundColor(.white.opacity(0.9))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 140) // Position closer to ingredients card
                                }
                            }
                            .frame(width: geometry.size.width, height: dynamicImageHeight + stretchAmount + geometry.safeAreaInsets.top)
                            .background(
                                GeometryReader { imageGeometry in
                                    Color.clear
                                        .preference(key: ScrollOffsetPreferenceKey.self, value: imageGeometry.frame(in: .named("scroll")).minY)
                                }
                            )
                            
                            // Ingredients Card (overlaps image more significantly)
                            VStack(alignment: .leading, spacing: 16) {
                                // Header
                                Text(String(format: LocalizedString("Ingredients for %d servings", comment: "Ingredients header"), viewModel.recipe.servings))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                // Ingredients List grouped by category
                                VStack(alignment: .leading, spacing: 20) {
                                    let sortedCategories = groupedIngredients.keys.sorted(by: { categoryOrder($0) < categoryOrder($1) })
                                    ForEach(Array(sortedCategories.enumerated()), id: \.offset) { index, category in
                                        if let ingredients = groupedIngredients[category], !ingredients.isEmpty {
                                            // Section Header
                                            Text(sectionHeader(for: category))
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.secondary)
                                                .padding(.top, index == 0 ? 0 : 8)
                                            
                                            // Ingredients in this category
                                            VStack(alignment: .leading, spacing: 12) {
                                                ForEach(Array(ingredients.enumerated()), id: \.offset) { ingredientIndex, ingredient in
                                                    IngredientRowView(ingredient: ingredient)
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // Dotted Line Separator
                                if !viewModel.recipe.instructions.isEmpty {
                                    dottedLineSeparator
                                        .padding(.vertical, 20)
                                    
                                    // Instructions Section
                                    VStack(alignment: .leading, spacing: 20) {
                                        Text(LocalizedString("Steps", comment: "Steps header"))
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.primary)
                                        
                                        ForEach(Array(viewModel.recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                                            HStack(alignment: .top, spacing: 16) {
                                                // Blue circle with number
                                                Text("\(index + 1)")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .frame(width: 32, height: 32)
                                                    .background(Color.accentColor)
                                                    .clipShape(Circle())
                                                
                                                Text(instruction.text)
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.primary)
                                                    .lineSpacing(4)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                        }
                                    }
                                    
                                    // Dotted Line Separator before Tips
                                    if !viewModel.recipe.tips.isEmpty {
                                        dottedLineSeparator
                                            .padding(.vertical, 20)
                                        
                                        // Tips Section
                                        VStack(alignment: .leading, spacing: 16) {
                                            Text(LocalizedString("Tips", comment: "Tips header"))
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.primary)
                                            
                                            ForEach(Array(viewModel.recipe.tips.enumerated()), id: \.offset) { index, tip in
                                                if !tip.trimmingCharacters(in: .whitespaces).isEmpty {
                                                    HStack(alignment: .top, spacing: 12) {
                                                        // Bullet point
                                                        Text("•")
                                                            .font(.system(size: 18, weight: .semibold))
                                                            .foregroundColor(.secondary)
                                                            .padding(.top, 2)
                                                        
                                                        Text(tip)
                                                            .font(.system(size: 16))
                                                            .foregroundColor(.primary)
                                                            .lineSpacing(4)
                                                            .fixedSize(horizontal: false, vertical: true)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Dotted Line Separator before User Notes
                                    if !viewModel.userNotes.isEmpty {
                                        dottedLineSeparator
                                            .padding(.vertical, 20)
                                        
                                        // User Notes Section
                                        VStack(alignment: .leading, spacing: 16) {
                                            Text(LocalizedString("My Notes", comment: "My notes header"))
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.primary)
                                            
                                            ForEach(viewModel.userNotes) { note in
                                                VStack(alignment: .leading, spacing: 8) {
                                                    // Note content
                                                    Text(note.content)
                                                        .font(.custom("Caveat", size: 16))
                                                        .foregroundColor(.primary)
                                                        .lineSpacing(4)
                                                        .multilineTextAlignment(.leading)
                                                        .frame(maxWidth: .infinity, alignment: .leading)
                                                    
                                                    // Note metadata
                                                    HStack {
                                                        if note.updatedAt != note.createdAt {
                                                            Text(LocalizedString("Edited", comment: "Edited label"))
                                                                .font(.system(size: 12))
                                                                .foregroundColor(.secondary)
                                                        }
                                                        
                                                        Spacer()
                                                        
                                                        Text(formatDate(note.updatedAt))
                                                            .font(.system(size: 12))
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(16)
                                                .background(Color(.systemGray6))
                                                .cornerRadius(12)
                                                .contextMenu {
                                                    // Edit option
                                                    Button(action: {
                                                        HapticFeedback.buttonTap()
                                                        noteToEdit = note
                                                        showWriteNote = true
                                                    }) {
                                                        Label(LocalizedString("Edit", comment: "Edit button"), systemImage: "pencil")
                                                    }
                                                    
                                                    // Delete option
                                                    Button(role: .destructive, action: {
                                                        HapticFeedback.buttonTap()
                                                        noteToDelete = note
                                                        showDeleteNoteConfirmation = true
                                                    }) {
                                                        Label(LocalizedString("Delete", comment: "Delete button"), systemImage: "trash")
                                                    }
                                                }
                                            }
                                            
                                            // Load More Button
                                            if viewModel.hasMoreNotes {
                                                Button(action: {
                                                    HapticFeedback.buttonTap()
                                                    Task {
                                                        await viewModel.loadMoreUserNotes()
                                                    }
                                                }) {
                                                    HStack {
                                                        if viewModel.isLoadingMoreNotes {
                                                            ProgressView()
                                                                .progressViewStyle(CircularProgressViewStyle())
                                                        } else {
                                                            Text(LocalizedString("Load More", comment: "Load more notes button"))
                                                                .font(.system(size: 14, weight: .medium))
                                                        }
                                                    }
                                                    .frame(maxWidth: .infinity)
                                                    .padding(.vertical, 12)
                                                    .background(Color(.systemGray5))
                                                    .cornerRadius(12)
                                                }
                                                .disabled(viewModel.isLoadingMoreNotes)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(Color(.systemBackground))
                            .cornerRadius(24)
                            .offset(y: -120) // Move up significantly to overlap more of the image
                            .padding(.bottom, -120)
                            
                            // Action Buttons Section
                            VStack(spacing: 12) {
                                // Notes Button (if notes exist)
                                if viewModel.noteCount > 0 {
                                    Button(action: {
                                        showNotesList = true
                                    }) {
                                        HStack {
                                            Text(LocalizedString("All", comment: "All notes prefix"))
                                            Text("\(viewModel.noteCount)")
                                            Text(LocalizedString("notes", comment: "Notes label"))
                                        }
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                    }
                                }
                                
                                // Write Note Button
                                Button(action: {
                                    HapticFeedback.buttonTap()
                                    showWriteNote = true
                                }) {
                                    Text(LocalizedString("Write a Note", comment: "Write note button"))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                }
                                
                                // Start Cooking Button (hidden for now)
                                // TODO: Re-enable when Start Cooking feature is ready
                                /*
                                if !viewModel.recipe.instructions.isEmpty {
                                    Button(action: {
                                        HapticFeedback.importantAction()
                                        showStepView = true
                                    }) {
                                        Text(LocalizedString("Start Cooking", comment: "Start cooking button"))
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 56)
                                            .background(Color.accentColor)
                                            .cornerRadius(16)
                                    }
                                }
                                */
                            }
                            .frame(width: geometry.size.width)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                        }
                        .frame(width: geometry.size.width)
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        scrollOffset = value
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        HapticFeedback.buttonTap()
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Favorite/Like Button
                    Button(action: {
                        HapticFeedback.importantAction()
                        Task {
                            await viewModel.toggleFavorite()
                        }
                    }) {
                        Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundColor(viewModel.isFavorite ? .red : .white)
                            .frame(width: 34, height: 34)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    
                    // Menu Button
                    Menu {
                        if isAuthor {
                            // For user's own posts: Edit, Share, Delete
                            Button(action: {
                                HapticFeedback.importantAction()
                                showEditRecipe = true
                                showMenu = false
                            }) {
                                Label(LocalizedString("Edit", comment: "Edit button"), systemImage: "pencil")
                            }
                            
                            Button(action: {
                                Task {
                                    await prepareShareContent()
                                    showShareSheet = true
                                }
                                showMenu = false
                            }) {
                                Label(LocalizedString("Share", comment: "Share button"), systemImage: "square.and.arrow.up")
                            }
                            
                            Button(role: .destructive, action: {
                                showDeleteConfirmation = true
                                showMenu = false
                            }) {
                                Label(LocalizedString("Delete", comment: "Delete button"), systemImage: "trash")
                            }
                        } else {
                            // For posts not owned by user: Share, Save, Report
                            Button(action: {
                                Task {
                                    await prepareShareContent()
                                    showShareSheet = true
                                }
                                showMenu = false
                            }) {
                                Label(LocalizedString("Share", comment: "Share button"), systemImage: "square.and.arrow.up")
                            }
                            
                            Button(action: {
                                HapticFeedback.importantAction()
                                Task {
                                    await viewModel.toggleFavorite()
                                }
                                showMenu = false
                            }) {
                                Label(
                                    viewModel.isFavorite ? LocalizedString("Unsave Recipe", comment: "Unsave button") : LocalizedString("Save Recipe", comment: "Save button"),
                                    systemImage: viewModel.isFavorite ? "bookmark.fill" : "bookmark"
                                )
                            }
                            
                            Button(role: .destructive, action: {
                                showReportSheet = true
                                showMenu = false
                            }) {
                                Label(LocalizedString("Report", comment: "Report button"), systemImage: "exclamationmark.triangle")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task {
            await viewModel.loadData()
        }
        .sheet(isPresented: $showWriteNote) {
            WriteNoteView(recipeID: viewModel.recipe.id, existingNote: noteToEdit) {
                Task {
                    // Add a small delay to allow Firestore to propagate the write
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    await viewModel.loadNoteCount()
                    await viewModel.loadUserNotes()
                }
                // Reset noteToEdit after saving
                noteToEdit = nil
            }
            .id(noteToEdit?.id ?? "new-note") // Force view recreation when note changes
            .onDisappear {
                // Reset noteToEdit when sheet is dismissed
                noteToEdit = nil
            }
        }
        .sheet(isPresented: $showNotesList) {
            RecipeNotesView(recipeID: viewModel.recipe.id)
        }
        .fullScreenCover(isPresented: $showStepView) {
            RecipeStepView(recipe: viewModel.recipe, initialStepIndex: 0)
        }
        .sheet(isPresented: $showRelatedRecipes) {
            RelatedRecipesView(recipe: viewModel.recipe)
        }
        .alert(
            LocalizedString("Delete Recipe", comment: "Delete confirmation title"),
            isPresented: $showDeleteConfirmation
        ) {
            Button(LocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {
                showDeleteConfirmation = false
            }
            Button(LocalizedString("Delete", comment: "Delete button"), role: .destructive) {
                Task {
                    await deleteRecipe()
                }
            }
        } message: {
            Text(LocalizedString("Are you sure you want to delete this recipe? This action cannot be undone.", comment: "Delete confirmation message"))
        }
        .alert(
            LocalizedString("Delete Note", comment: "Delete note confirmation title"),
            isPresented: $showDeleteNoteConfirmation
        ) {
            Button(LocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {
                noteToDelete = nil
            }
            Button(LocalizedString("Delete", comment: "Delete button"), role: .destructive) {
                if let note = noteToDelete {
                    Task {
                        await viewModel.deleteNote(note)
                        noteToDelete = nil
                    }
                }
            }
        } message: {
            Text(LocalizedString("Are you sure you want to delete this note? This action cannot be undone.", comment: "Delete note confirmation message"))
        }
        .alert(
            LocalizedString("Delete Note", comment: "Delete note confirmation title"),
            isPresented: $showDeleteNoteConfirmation
        ) {
            Button(LocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {
                noteToDelete = nil
            }
            Button(LocalizedString("Delete", comment: "Delete button"), role: .destructive) {
                if let note = noteToDelete {
                    Task {
                        await viewModel.deleteNote(note)
                        noteToDelete = nil
                    }
                }
            }
        } message: {
            Text(LocalizedString("Are you sure you want to delete this note? This action cannot be undone.", comment: "Delete note confirmation message"))
        }
        .sheet(isPresented: $showReportSheet) {
            ReportView(recipeID: viewModel.recipe.id, userID: viewModel.recipe.authorID)
        }
        .sheet(isPresented: $showShareSheet) {
            let shareItems = createShareItems()
            ShareSheet(activityItems: shareItems)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showEditRecipe) {
            NavigationStack {
                EditRecipeView(recipe: viewModel.recipe)
            }
            .onDisappear {
                // Refresh recipe when edit sheet is dismissed
                Task {
                    await viewModel.refreshRecipe()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RecipeSaved"))) { _ in
            // Refresh recipe when saved notification is received
            Task {
                await viewModel.refreshRecipe()
            }
        }
    }
    
    // MARK: - Date Formatting
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy HH:mm"
        
        // Get locale based on current language setting
        let currentLanguage = LocalizationManager.shared.currentLanguage
        let localeIdentifier: String
        
        switch currentLanguage {
        case .english:
            localeIdentifier = "en_US"
        case .system:
            // Use system locale
            localeIdentifier = Locale.current.identifier
        case .spanish:
            localeIdentifier = "es_ES"
        case .french:
            localeIdentifier = "fr_FR"
        case .german:
            localeIdentifier = "de_DE"
        case .italian:
            localeIdentifier = "it_IT"
        case .portuguese:
            localeIdentifier = "pt_PT"
        case .dutch:
            localeIdentifier = "nl_NL"
        case .russian:
            localeIdentifier = "ru_RU"
        case .japanese:
            localeIdentifier = "ja_JP"
        case .korean:
            localeIdentifier = "ko_KR"
        case .thai:
            localeIdentifier = "th_TH"
        case .vietnamese:
            localeIdentifier = "vi_VN"
        case .indonesian:
            localeIdentifier = "id_ID"
        case .malay:
            localeIdentifier = "ms_MY"
        case .filipino:
            localeIdentifier = "fil_PH"
        case .hindi:
            localeIdentifier = "hi_IN"
        case .chineseSimplified:
            localeIdentifier = "zh_Hans_CN"
        case .chineseTraditional:
            localeIdentifier = "zh_Hant_TW"
        case .arabic:
            localeIdentifier = "ar_SA"
        case .hebrew:
            localeIdentifier = "he_IL"
        }
        
        formatter.locale = Locale(identifier: localeIdentifier)
        return formatter.string(from: date)
    }
    
    // MARK: - Helper Methods
    
    // Dotted line separator
    private var dottedLineSeparator: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
            }
            .strokedPath(StrokeStyle(lineWidth: 1, dash: [5, 3]))
            .foregroundColor(Color.secondary.opacity(0.3))
        }
        .frame(height: 1)
    }
    
    // Group ingredients by category
    private var groupedIngredients: [Ingredient.Category?: [Ingredient]] {
        Dictionary(grouping: viewModel.recipe.ingredients) { ingredient in
            ingredient.category
        }
    }
    
    // Get section header text for a category
    private func sectionHeader(for category: Ingredient.Category?) -> String {
        guard let category = category else {
            return LocalizedString("Ingredients", comment: "Default ingredients header")
        }
        
        switch category {
        case .dish:
            return LocalizedString("For the main ingredients", comment: "Main ingredients section header")
        case .marinade:
            return LocalizedString("For the marinade / brine", comment: "Marinade section header")
        case .seasoning:
            return LocalizedString("For seasoning during cooking", comment: "Seasoning section header")
        case .batter, .dough, .filling, .base:
            return LocalizedString("For the dough / batter / filling", comment: "Dough batter filling section header")
        case .sauce:
            return LocalizedString("For the sauce", comment: "Sauce section header")
        case .topping:
            return LocalizedString("For the toppings", comment: "Toppings section header")
        case .garnish:
            return LocalizedString("To finish / To garnish", comment: "Garnish section header")
        }
    }
    
    // Get order for category sorting (lower number = appears first)
    private func categoryOrder(_ category: Ingredient.Category?) -> Int {
        guard let category = category else {
            return 999 // Unknown categories go last
        }
        
        switch category {
        case .dish:
            return 1
        case .marinade:
            return 2
        case .seasoning:
            return 3
        case .batter, .dough, .filling, .base:
            return 4
        case .sauce:
            return 5
        case .topping:
            return 6
        case .garnish:
            return 7
        }
    }
    
    private func formatIngredientAmount(_ ingredient: Ingredient) -> String {
        if ingredient.unit.isEmpty {
            return ingredient.amount
        } else {
            let translatedUnit = UnitTranslations.abbreviation(for: ingredient.unit, amount: ingredient.amount)
            return "\(ingredient.amount) \(translatedUnit)"
        }
    }
    
    private func deleteRecipe() async {
        guard isAuthor else { return }
        
        do {
            let recipeService = RecipeService()
            try await recipeService.deleteRecipe(recipeID: viewModel.recipe.id)
            dismiss()
        } catch {
            print("❌ Error deleting recipe: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Share Methods
    
    private func prepareShareContent() async {
        isPreparingShare = true
        shareImage = nil
        
        // Load recipe image if available
        if let imageURL = viewModel.recipe.imageURL, let url = URL(string: imageURL) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    shareImage = image
                }
            } catch {
                print("⚠️ Failed to load image for sharing: \(error.localizedDescription)")
            }
        }
        
        isPreparingShare = false
    }
    
    private func createShareItems() -> [Any] {
        var items: [Any] = []
        
        // Add formatted recipe text
        let recipeText = formatRecipeForSharing()
        items.append(recipeText)
        
        // Add image if available
        if let image = shareImage {
            items.append(image)
        }
        
        return items
    }
    
    private func formatRecipeForSharing() -> String {
        var text = ""
        
        // Title
        text += "\(viewModel.recipe.title)\n\n"
        
        // Description
        if !viewModel.recipe.description.isEmpty {
            text += "\(viewModel.recipe.description)\n\n"
        }
        
        // Recipe Info
        text += "\(LocalizedString("Prep Time", comment: "Prep time label")): \(viewModel.recipe.prepTime) \(LocalizedString("min", comment: "Minutes abbreviation"))\n"
        text += "\(LocalizedString("Cook Time", comment: "Cook time label")): \(viewModel.recipe.cookTime) \(LocalizedString("min", comment: "Minutes abbreviation"))\n"
        text += "\(LocalizedString("Total Time", comment: "Total time label")): \(viewModel.totalTime) \(LocalizedString("min", comment: "Minutes abbreviation"))\n"
        text += "\(LocalizedString("Servings", comment: "Servings label")): \(viewModel.recipe.servings)\n"
        text += "\(LocalizedString("Difficulty", comment: "Difficulty label")): \(viewModel.recipe.difficulty.rawValue)\n"
        
        if let cuisine = viewModel.recipe.cuisine, !cuisine.isEmpty {
            text += "\(LocalizedString("Cuisine", comment: "Cuisine label")): \(cuisine)\n"
        }
        
        text += "\n"
        
        // Ingredients
        text += String(format: LocalizedString("Ingredients for %d servings", comment: "Ingredients header"), viewModel.recipe.servings)
        text += "\n\n"
        
        let sortedCategories = groupedIngredients.keys.sorted(by: { categoryOrder($0) < categoryOrder($1) })
        for category in sortedCategories {
            if let ingredients = groupedIngredients[category], !ingredients.isEmpty {
                // Section Header
                text += "\(sectionHeader(for: category))\n"
                
                // Ingredients in this category
                for ingredient in ingredients {
                    let amount = ingredient.amount.isEmpty ? "" : "\(ingredient.amount) "
                    let unit = ingredient.unit.isEmpty ? "" : "\(UnitTranslations.abbreviation(for: ingredient.unit, amount: ingredient.amount)) "
                    text += "• \(amount)\(unit)\(ingredient.name)\n"
                }
                text += "\n"
            }
        }
        
        // Instructions
        if !viewModel.recipe.instructions.isEmpty {
            text += "\(LocalizedString("Steps", comment: "Steps header"))\n\n"
            
            for (index, instruction) in viewModel.recipe.instructions.enumerated() {
                text += "\(index + 1). \(instruction.text)\n\n"
            }
        }
        
        // Tips
        if !viewModel.recipe.tips.isEmpty {
            text += "\(LocalizedString("Tips", comment: "Tips header"))\n\n"
            for tip in viewModel.recipe.tips {
                if !tip.trimmingCharacters(in: .whitespaces).isEmpty {
                    text += "• \(tip)\n"
                }
            }
        }
        
        // App Store link - formatted as plain text with app name and link
        text += "\n\n"
        text += LocalizedString("Create your own recipe with", comment: "App store link prefix")
        text += " 🍽️ Misoto App"
        text += "\n"
        text += misotoAppStoreURL
        
        return text
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    RecipeDetailOverviewView(recipe: Recipe(
        title: "Runderborst Kleipot",
        description: "A delicious recipe",
        ingredients: [
            Ingredient(amount: "1", unit: "lb", name: "Runderborst"),
            Ingredient(amount: "8", unit: "", name: "Waterkastanjes"),
            Ingredient(amount: "1", unit: "pack", name: "Gefrituurde bamboescheuten"),
            Ingredient(amount: "8", unit: "", name: "Gedroogde Shiitake paddenstoelen")
        ],
        instructions: [
            Instruction(text: "Prepare ingredients"),
            Instruction(text: "Cook the dish")
        ],
        prepTime: 15,
        cookTime: 120,
        servings: 3,
        difficulty: .a,
        authorID: "123",
        authorName: "Chef"
    ))
}

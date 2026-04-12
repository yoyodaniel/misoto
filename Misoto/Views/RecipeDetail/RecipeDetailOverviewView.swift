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
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showLoginSheet = false
    
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
    private let misotoAppStoreURL = "https://apps.apple.com/app/misoto/id6757369965"
    
    @State private var showWriteNote = false
    @State private var showNotesList = false
    @State private var showStepView = false
    @State private var showRelatedRecipes = false
    @State private var showMenu = false
    @State private var showDeleteConfirmation = false
    @State private var showMakePublicConfirmation = false
    @State private var showReportSheet = false
    @State private var showShareSheet = false
    @State private var showShareWithUsers = false
    @State private var showEditRecipe = false
    @State private var noteToEdit: RecipeNote?
    @State private var noteToDelete: RecipeNote?
    @State private var showDeleteNoteConfirmation = false
    @State private var scrollOffset: CGFloat = 0
    @State private var shareImage: UIImage?
    @State private var isPreparingShare = false
    @State private var adjustedServings: Int = 1
    
    // Comments
    @State private var showWriteComment = false
    @State private var showAllReviews = false
    @State private var commentToEdit: RecipeComment?
    @State private var commentToDelete: RecipeComment?
    @State private var showDeleteCommentConfirmation = false
    
    private var isAuthor: Bool {
        guard let userID = Auth.auth().currentUser?.uid else { return false }
        return viewModel.recipe.authorID == userID
    }
    
    init(recipe: Recipe) {
        _viewModel = StateObject(wrappedValue: RecipeDetailViewModel(recipe: recipe))
        _adjustedServings = State(initialValue: recipe.servings)
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
                                        
                                        // Metadata Row — horizontally scrollable
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                // Time
                                                HStack(spacing: 4) {
                                                    Image(systemName: durationIcon(for: viewModel.totalTime))
                                                        .font(.system(size: 14))
                                                        .foregroundColor(viewModel.totalTime >= 1440 ? .yellow : .white)
                                                    Text(formatDuration(viewModel.totalTime))
                                                        .font(.system(size: 14))
                                                }
                                                
                                                // Servings
                                                HStack(spacing: 4) {
                                                    Image(systemName: "person.2")
                                                        .font(.system(size: 14))
                                                    Text("\(adjustedServings)")
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
                                                
                                                // Cuisine (if available)
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
                                // Header with Servings Picker
                                HStack {
                                    Text(String(format: LocalizedString("Ingredients for %d servings", comment: "Ingredients header"), adjustedServings))
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    // Servings Picker
                                    Menu {
                                        ForEach(1...20, id: \.self) { servings in
                                            Button(action: {
                                                adjustedServings = servings
                                            }) {
                                                HStack {
                                                    Text("\(servings)")
                                                    Spacer()
                                                    if adjustedServings == servings {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "person.2")
                                                .font(.system(size: 14))
                                            Text("\(adjustedServings)")
                                                .font(.system(size: 16, weight: .medium))
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                }
                                
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
                                                    IngredientRowView(ingredient: adjustedIngredient(ingredient))
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
                                                
                                                Text(adjustedInstructionText(instruction))
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
                                        
                                        // Dotted Line Separator before Description
                                        if !viewModel.recipe.description.trimmingCharacters(in: .whitespaces).isEmpty {
                                            dottedLineSeparator
                                                .padding(.vertical, 20)
                                            
                                            // Description Section
                                            VStack(alignment: .leading, spacing: 12) {
                                                Text(LocalizedString("Description", comment: "Description header"))
                                                    .font(.system(size: 20, weight: .bold))
                                                    .foregroundColor(.primary)
                                                
                                                Text(viewModel.recipe.description)
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.primary)
                                                    .lineSpacing(4)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                        }
                                    } else {
                                        // If no tips, show description directly after Chef section
                                        if !viewModel.recipe.description.trimmingCharacters(in: .whitespaces).isEmpty {
                                            dottedLineSeparator
                                                .padding(.vertical, 20)
                                            
                                            // Description Section
                                            VStack(alignment: .leading, spacing: 12) {
                                                Text(LocalizedString("Description", comment: "Description header"))
                                                    .font(.system(size: 20, weight: .bold))
                                                    .foregroundColor(.primary)
                                                
                                                Text(viewModel.recipe.description)
                                                    .font(.system(size: 16))
                                                    .foregroundColor(.primary)
                                                    .lineSpacing(4)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                        }
                                    }
                                    
                                    // Dotted Line Separator before Nutrition Section
                                    dottedLineSeparator
                                        .padding(.vertical, 20)
                                    
                                    // Nutrition Section
                                    nutritionSection
                                    
                                    // Dotted Line Separator before Chef Section
                                    dottedLineSeparator
                                        .padding(.vertical, 20)
                                    
                                    // Chef Section
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text(LocalizedString("Chef", comment: "Chef section header"))
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.primary)
                                        
                                        ChefSectionView(
                                            creatorID: viewModel.recipe.authorID,
                                            creatorName: viewModel.recipe.authorName,
                                            creatorUsername: viewModel.recipe.authorUsername,
                                            hasNotes: !viewModel.userNotes.isEmpty,
                                            showLoginSheet: $showLoginSheet
                                        )
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
                                    
                                    // MARK: - Reviews Section
                                    commentsSection
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
                                        .cornerRadius(24)
                                    }
                                }
                                
                                // Write Note Button (requires authentication)
                                Button(action: {
                                    HapticFeedback.buttonTap()
                                    if Auth.auth().currentUser != nil {
                                        showWriteNote = true
                                    } else {
                                        showLoginSheet = true
                                    }
                                }) {
                                    Text(LocalizedString("Write a Note to Self", comment: "Write note button"))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(24)
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
                            .padding(.horizontal, UIDevice.current.userInterfaceIdiom == .pad ? 40 : 20)
                            .padding(.top, UIDevice.current.userInterfaceIdiom == .pad ? 24 : 20)
                            .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 48 : 40)
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
                    // Privacy Button (for own recipes) or Favorite/Like Button (for others)
                    if isAuthor {
                        // Show privacy button for own recipes to toggle privacy or view sharing
                        // If shared with users, show person.2.fill and open sharing view instead of toggling
                        Button(action: {
                            HapticFeedback.importantAction()
                            if viewModel.recipe.isPrivate && !viewModel.recipe.sharedWith.isEmpty {
                                // Recipe is shared - show list of users with access
                                showShareWithUsers = true
                            } else if viewModel.recipe.isPrivate {
                                // Recipe is private (not shared) - show confirmation when making public
                                showMakePublicConfirmation = true
                            } else {
                                // Recipe is public - make private to all (clear sharedWith, only owner can see)
                                Task {
                                    await viewModel.togglePrivacy(clearSharedWith: true)
                                }
                            }
                        }) {
                            Image(systemName: viewModel.recipe.isPrivate 
                                ? (!viewModel.recipe.sharedWith.isEmpty ? "person.2.fill" : "eye.slash.fill") 
                                : "globe")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(width: 34, height: 34)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                    } else {
                        // Show heart button for other users' recipes
                        Button(action: {
                            HapticFeedback.importantAction()
                            if Auth.auth().currentUser != nil {
                                Task {
                                    await viewModel.toggleFavorite()
                                }
                            } else {
                                showLoginSheet = true
                            }
                        }) {
                            Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 16))
                                .foregroundColor(viewModel.isFavorite ? .red : .white)
                                .frame(width: 34, height: 34)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                    }
                    
                    // Menu Button
                    Menu {
                        if isAuthor {
                            // For user's own posts: Edit, Privacy Toggle, Private Sharing (all recipes), Share, Delete (all require authentication)
                            if Auth.auth().currentUser != nil {
                                Button(action: {
                                    HapticFeedback.importantAction()
                                    showEditRecipe = true
                                    showMenu = false
                                }) {
                                    Label(LocalizedString("Edit", comment: "Edit button"), systemImage: "pencil")
                                }
                                
                                Button(action: {
                                    HapticFeedback.importantAction()
                                    if viewModel.recipe.isPrivate {
                                        // Show confirmation alert when making public
                                        showMakePublicConfirmation = true
                                    } else {
                                        // Make private to all (clear sharedWith, only owner can see)
                                        Task {
                                            await viewModel.togglePrivacy(clearSharedWith: true)
                                        }
                                    }
                                    showMenu = false
                                }) {
                                    Label(
                                        viewModel.recipe.isPrivate ? LocalizedString("Make Public", comment: "Make recipe public") : LocalizedString("Make Private", comment: "Make recipe private"),
                                        systemImage: viewModel.recipe.isPrivate ? "globe" : "eye.slash.fill"
                                    )
                                }
                                
                                // Show "Private Sharing" option for all recipes
                                // If recipe is public, it will be made private when opening private sharing
                                Button(action: {
                                    HapticFeedback.importantAction()
                                    // If recipe is public, make it private first before showing sharing options
                                    // Preserve sharedWith when making private for sharing (don't clear it)
                                    if !viewModel.recipe.isPrivate {
                                        Task {
                                            // Make private first (preserve sharedWith, don't clear)
                                            await viewModel.togglePrivacy(clearSharedWith: false)
                                            // Refresh recipe to get updated state with preserved sharedWith
                                            await viewModel.refreshRecipe()
                                            // Small delay to ensure recipe object is fully updated
                                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                                            // Now show sharing - recipe should have preserved sharedWith
                                            showShareWithUsers = true
                                        }
                                    } else {
                                        // Recipe is already private - ensure we have latest recipe state
                                        Task {
                                            await viewModel.refreshRecipe()
                                            showShareWithUsers = true
                                        }
                                    }
                                    showMenu = false
                                }) {
                                    if viewModel.recipe.hasSharedUsers {
                                        Label(
                                            String(format: LocalizedString("Private Sharing (%d)", comment: "Private sharing button with count"), viewModel.recipe.effectiveSharedCount),
                                            systemImage: "person.2.fill"
                                        )
                                    } else {
                                        Label(
                                            LocalizedString("Private Sharing", comment: "Private sharing button"),
                                            systemImage: "person.2.fill"
                                        )
                                    }
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
                            }
                        } else {
                            // For posts not owned by user: Share (no auth needed), Save, Report (both require auth)
                            Button(action: {
                                Task {
                                    await prepareShareContent()
                                    showShareSheet = true
                                }
                                showMenu = false
                            }) {
                                Label(LocalizedString("Share", comment: "Share button"), systemImage: "square.and.arrow.up")
                            }
                            
                            if Auth.auth().currentUser != nil {
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
                            } else {
                                Button(action: {
                                    showLoginSheet = true
                                    showMenu = false
                                }) {
                                    Label(LocalizedString("Save Recipe", comment: "Save recipe button"), systemImage: "bookmark")
                                }
                                
                                Button(action: {
                                    showLoginSheet = true
                                    showMenu = false
                                }) {
                                    Label(LocalizedString("Report", comment: "Report button"), systemImage: "exclamationmark.triangle")
                                }
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
        .sheet(isPresented: $showShareWithUsers) {
            // Ensure we use the latest recipe state with preserved sharedWith
            ShareRecipeView(recipe: viewModel.recipe) { sharedUserIDs in
                Task {
                    await viewModel.updateSharing(sharedWith: sharedUserIDs)
                    // Refresh recipe to get updated state
                    await viewModel.refreshRecipe()
                }
            }
            .onAppear {
                // Debug: Log the sharedWith array when sheet appears
                print("📋 ShareRecipeView opened with recipe.sharedWith: \(viewModel.recipe.sharedWith.count) users")
            }
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
            LocalizedString("Make Recipe Public", comment: "Make recipe public confirmation title"),
            isPresented: $showMakePublicConfirmation
        ) {
            Button(LocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {
                showMakePublicConfirmation = false
            }
            Button(LocalizedString("Make Public", comment: "Make public button")) {
                Task {
                    await viewModel.togglePrivacy()
                }
            }
        } message: {
            Text(LocalizedString("Are you sure you want to make this recipe public?", comment: "Make recipe public confirmation message"))
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
        .sheet(isPresented: $showLoginSheet) {
            LoginView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showWriteComment) {
            WriteCommentView(
                recipeID: viewModel.recipe.id,
                existingComment: commentToEdit
            ) { content, rating in
                Task {
                    if let existing = commentToEdit {
                        await viewModel.updateComment(comment: existing, content: content, rating: rating)
                    } else {
                        await viewModel.submitComment(content: content, rating: rating)
                    }
                    commentToEdit = nil
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showAllReviews) {
            AllReviewsView(viewModel: viewModel, showLoginSheet: $showLoginSheet)
        }
        .alert(
            LocalizedString("Delete Review", comment: "Delete review confirmation title"),
            isPresented: $showDeleteCommentConfirmation
        ) {
            Button(LocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {
                commentToDelete = nil
            }
            Button(LocalizedString("Delete", comment: "Delete button"), role: .destructive) {
                if let comment = commentToDelete {
                    Task {
                        await viewModel.deleteComment(comment)
                        commentToDelete = nil
                    }
                }
            }
        } message: {
            Text(LocalizedString("Are you sure you want to delete this review? This action cannot be undone.", comment: "Delete review confirmation message"))
        }
        .sheet(isPresented: $showShareWithUsers) {
            NavigationStack {
                ShareRecipeView(recipe: viewModel.recipe) { sharedUserIDs in
                    Task {
                        await viewModel.updateSharing(sharedWith: sharedUserIDs)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RecipeSaved"))) { _ in
            // Refresh recipe when saved notification is received
            Task {
                await viewModel.refreshRecipe()
                // Reset adjusted servings to recipe's original servings after refresh
                adjustedServings = viewModel.recipe.servings
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RecipePrivacyChanged"))) { notification in
            // Update recipe detail view when privacy changes (from grid view or detail view)
            Task {
                let recipeID = notification.userInfo?["recipeID"] as? String
                let isPrivate = notification.userInfo?["isPrivate"] as? Bool ?? false
                let clearSharedWith = notification.userInfo?["clearSharedWith"] as? Bool ?? false
                
                if let recipeID = recipeID, recipeID == viewModel.recipe.id {
                    // Optimistic update: Update UI immediately
                    let currentSharedWith = viewModel.recipe.sharedWith
                    viewModel.recipe.isPrivate = isPrivate
                    
                    // If making private and clearSharedWith is true: Save current sharedWith to preservedSharedWith, then clear sharedWith
                    if isPrivate && clearSharedWith {
                        // Save current sharedWith to preservedSharedWith before clearing (if it has users)
                        if !currentSharedWith.isEmpty {
                            viewModel.recipe.preservedSharedWith = currentSharedWith
                        }
                        // Always clear sharedWith when making "Private to All" (removes access)
                        viewModel.recipe.sharedWith = []
                    }
                    // When making public: Restore preservedSharedWith to sharedWith if it exists
                    else if !isPrivate {
                        // Restore preserved sharedWith list if it exists
                        if let preserved = viewModel.recipe.preservedSharedWith, !preserved.isEmpty {
                            viewModel.recipe.sharedWith = preserved
                            viewModel.recipe.preservedSharedWith = nil // Clear preserved list after restore
                        }
                        // If no preserved list, keep current sharedWith as-is
                    }
                    
                    // Refresh recipe from server to ensure consistency
                    await viewModel.refreshRecipe()
                    print("✅ RecipeDetailView: Recipe privacy updated - isPrivate: \(isPrivate), sharedWith: \(viewModel.recipe.sharedWith.count) users, preserved: \(viewModel.recipe.preservedSharedWith?.count ?? 0) users")
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RecipeSharingChanged"))) { notification in
            // Update recipe detail view when sharing changes (from grid view or detail view)
            Task {
                let recipeID = notification.userInfo?["recipeID"] as? String
                let sharedWith = notification.userInfo?["sharedWith"] as? [String] ?? []
                
                if let recipeID = recipeID, recipeID == viewModel.recipe.id {
                    // Optimistic update: Update UI immediately
                    viewModel.recipe.sharedWith = sharedWith
                    viewModel.recipe.isPrivate = true // Must be private to share with specific users
                    
                    // Refresh recipe from server to ensure consistency
                    await viewModel.refreshRecipe()
                    print("✅ RecipeDetailView: Recipe sharing updated - sharedWith: \(sharedWith.count) users")
                }
            }
        }
        .onChange(of: viewModel.recipe.servings) { oldValue, newServings in
            // Reset adjusted servings when recipe servings change
            adjustedServings = newServings
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
    
    // MARK: - Nutrition Section
    
    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                Text(LocalizedString("Nutrition (BETA)", comment: "Nutrition section header"))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if viewModel.nutritionInfo == nil && !viewModel.isLoadingNutrition {
                    Button(action: {
                        HapticFeedback.buttonTap()
                        Task {
                            await viewModel.estimateNutrition()
                        }
                    }) {
                        Text(LocalizedString("Estimate", comment: "Estimate nutrition button"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
            }
            
            if viewModel.isLoadingNutrition {
                // Loading state
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text(LocalizedString("Estimating nutrition…", comment: "Nutrition loading text"))
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
            } else if let nutrition = viewModel.nutritionInfo {
                // Nutrition content
                VStack(spacing: 16) {
                    // Per serving disclaimer
                    Text(LocalizedString("Per serving · AI estimated", comment: "Nutrition disclaimer"))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Calories hero
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(nutrition.calories)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.primary)
                            Text("kcal")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Macro rings (% of daily reference based on 2,000 kcal diet)
                        HStack(spacing: 20) {
                            macroRing(
                                value: nutrition.protein,
                                label: LocalizedString("Protein", comment: "Protein nutrient label"),
                                dailyValueFraction: nutrition.proteinDV,
                                color: .blue
                            )
                            macroRing(
                                value: nutrition.carbohydrates,
                                label: LocalizedString("Carbs", comment: "Carbs nutrient label"),
                                dailyValueFraction: nutrition.carbsDV,
                                color: .orange
                            )
                            macroRing(
                                value: nutrition.fat,
                                label: LocalizedString("Fat", comment: "Fat nutrient label"),
                                dailyValueFraction: nutrition.fatDV,
                                color: .red
                            )
                        }
                    }
                    
                    // Detail rows
                    VStack(spacing: 0) {
                        nutritionRow(
                            label: LocalizedString("Saturated Fat", comment: "Saturated fat nutrient label"),
                            value: String(format: "%.1fg", nutrition.saturatedFat),
                            dvPercent: Int(round(nutrition.saturatedFatDV * 100)),
                            isLast: false
                        )
                        nutritionRow(
                            label: LocalizedString("Fiber", comment: "Fiber nutrient label"),
                            value: String(format: "%.1fg", nutrition.fiber),
                            dvPercent: Int(round(nutrition.fiberDV * 100)),
                            isLast: false
                        )
                        nutritionRow(
                            label: LocalizedString("Sugar", comment: "Sugar nutrient label"),
                            value: String(format: "%.1fg", nutrition.sugar),
                            dvPercent: Int(round(nutrition.sugarDV * 100)),
                            isLast: false
                        )
                        nutritionRow(
                            label: LocalizedString("Sodium", comment: "Sodium nutrient label"),
                            value: "\(nutrition.sodium)mg",
                            dvPercent: Int(round(nutrition.sodiumDV * 100)),
                            isLast: true
                        )
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Daily value footnote + AI disclaimer
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedString("% Daily Value based on a 2,000 kcal diet", comment: "Daily value footnote"))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        Text(LocalizedString("Nutritional values are AI-estimated and may not be accurate. For dietary or health-related decisions, always consult a qualified nutritionist or healthcare professional.", comment: "AI nutrition disclaimer"))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.8))
                            .lineSpacing(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if let error = viewModel.nutritionError {
                // Error state
                VStack(spacing: 8) {
                    Text(LocalizedString("Could not estimate nutrition", comment: "Nutrition error title"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        HapticFeedback.buttonTap()
                        Task {
                            await viewModel.estimateNutrition()
                        }
                    }) {
                        Text(LocalizedString("Try Again", comment: "Retry button"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                // Initial state - prompt to estimate
                Text(LocalizedString("Tap Estimate to get AI-powered nutrition information for this recipe.", comment: "Nutrition prompt text"))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
        }
    }
    
    // MARK: - Nutrition Helper Views
    
    private func macroRing(value: Double, label: String, dailyValueFraction: Double, color: Color) -> some View {
        let dvPercent = Int(round(dailyValueFraction * 100))
        
        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 5)
                    .frame(width: 48, height: 48)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(dailyValueFraction, 1.0)))
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))
                
                Text("\(dvPercent)%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 52)
            
            Text(String(format: "%.0fg", value))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
    
    private func nutritionRow(label: String, value: String, dvPercent: Int, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("\(dvPercent)%")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 44, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            if !isLast {
                Divider()
                    .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Comments Section
    
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            dottedLineSeparator
                .padding(.vertical, 20)
            
            // Header with review count and average rating
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Text(LocalizedString("Reviews", comment: "Reviews section header"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if viewModel.commentCount > 0 {
                        Text("(\(viewModel.commentCount))")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if viewModel.ratingCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                        Text(String(format: "%.1f", viewModel.averageRating))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
            
            // Write Review button (only if user hasn't commented yet and is not the author)
            if Auth.auth().currentUser != nil && viewModel.existingUserComment == nil && !isAuthor {
                Button(action: {
                    HapticFeedback.buttonTap()
                    commentToEdit = nil
                    showWriteComment = true
                }) {
                    HStack {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 14))
                        Text(LocalizedString("Write a Review", comment: "Write review button"))
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundColor(.accentColor)
                    .cornerRadius(12)
                }
            } else if Auth.auth().currentUser == nil {
                Button(action: {
                    showLoginSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 14))
                        Text(LocalizedString("Write a Review", comment: "Write review button"))
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundColor(.accentColor)
                    .cornerRadius(12)
                }
            }
            
            // Show only the latest comment
            if viewModel.comments.isEmpty {
                Text(LocalizedString("No reviews yet. Be the first to share your thoughts!", comment: "No reviews placeholder"))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                // Latest comment
                if let latestComment = viewModel.comments.first {
                    commentCard(latestComment)
                }
                
                // View All Reviews button
                if viewModel.commentCount > 1 {
                    Button(action: {
                        HapticFeedback.buttonTap()
                        showAllReviews = true
                    }) {
                        Text(String(format: LocalizedString("View All %d Reviews", comment: "View all reviews button"), viewModel.commentCount))
                            .font(.system(size: 14, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private func commentCard(_ comment: RecipeComment) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Profile photo, name, time
            HStack(alignment: .top, spacing: 10) {
                // Profile photo
                if let imageURL = comment.profileImageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.secondary)
                        .frame(width: 36, height: 36)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    // Display name
                    Text(comment.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    // Username
                    if let username = comment.username, !username.isEmpty {
                        Text("@\(username)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Time ago
                Text(comment.timeAgo)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            // Star rating
            if comment.rating > 0 {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= comment.rating ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(star <= comment.rating ? .orange : .secondary.opacity(0.3))
                    }
                }
            }
            
            // Comment text (using Caveat font, same as notes)
            Text(comment.content)
                .font(.custom("Caveat", size: 16))
                .foregroundColor(.primary)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .contextMenu {
            // Only show edit/delete for own comments
            if comment.userID == Auth.auth().currentUser?.uid {
                Button(action: {
                    HapticFeedback.buttonTap()
                    commentToEdit = comment
                    showWriteComment = true
                }) {
                    Label(LocalizedString("Edit", comment: "Edit button"), systemImage: "pencil")
                }
                
                Button(role: .destructive, action: {
                    HapticFeedback.buttonTap()
                    commentToDelete = comment
                    showDeleteCommentConfirmation = true
                }) {
                    Label(LocalizedString("Delete", comment: "Delete button"), systemImage: "trash")
                }
            }
        }
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
    
    // MARK: - Servings Adjustment
    
    /// Parse ingredient amount string to a numeric value
    /// Handles whole numbers, decimals, fractions (1/2, 1 1/2), Unicode fractions (½, ¾, etc.), and text amounts (适量, to taste, etc.)
    private func parseAmount(_ amountString: String) -> Double? {
        var trimmed = amountString.trimmingCharacters(in: .whitespaces)
        
        // Check for text amounts that shouldn't be scaled (适量, to taste, etc.)
        let textAmounts = ["适量", "to taste", "as needed", "optional", "a pinch", "as desired", "q.s.", "qs"]
        if textAmounts.contains(where: { trimmed.lowercased().contains($0.lowercased()) }) {
            return nil // Return nil to indicate this shouldn't be scaled
        }
        
        // Convert Unicode fraction characters to their decimal equivalents
        // Common Unicode fractions: ½, ⅓, ⅔, ¼, ¾, ⅕, ⅖, ⅗, ⅘, ⅙, ⅚, ⅛, ⅜, ⅝, ⅞
        let unicodeFractions: [String: Double] = [
            "½": 0.5,
            "⅓": 0.333,
            "⅔": 0.667,
            "¼": 0.25,
            "¾": 0.75,
            "⅕": 0.2,
            "⅖": 0.4,
            "⅗": 0.6,
            "⅘": 0.8,
            "⅙": 0.167,
            "⅚": 0.833,
            "⅛": 0.125,
            "⅜": 0.375,
            "⅝": 0.625,
            "⅞": 0.875
        ]
        
        // Replace Unicode fractions with their decimal equivalents
        for (unicode, decimal) in unicodeFractions {
            trimmed = trimmed.replacingOccurrences(of: unicode, with: String(decimal))
        }
        
        // Pattern: mixed number with Unicode fraction already converted "1 0.5" or "1 0.25"
        // Also handle "1-2 0.333" (range format)
        let mixedPattern = "^\\s*(\\d+)(?:\\s*-\\s*(\\d+))?\\s+(\\d+(?:\\.\\d+)?)\\s*$"
        if let regex = try? NSRegularExpression(pattern: mixedPattern, options: []),
           let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count)),
           match.numberOfRanges >= 3 {
            
            if let wholeRange = Range(match.range(at: 1), in: trimmed),
               let whole = Double(String(trimmed[wholeRange])) {
                
                // Check if there's a range (e.g., "2-2 0.333")
                if match.numberOfRanges >= 4 && match.range(at: 2).location != NSNotFound {
                    if let secondWholeRange = Range(match.range(at: 2), in: trimmed),
                       let secondWhole = Double(String(trimmed[secondWholeRange])),
                       let fractionRange = Range(match.range(at: 3), in: trimmed),
                       let fraction = Double(String(trimmed[fractionRange])) {
                        // For ranges, use the higher value
                        return max(whole + fraction, secondWhole + fraction)
                    }
                } else if let fractionRange = Range(match.range(at: 3), in: trimmed),
                          let fraction = Double(String(trimmed[fractionRange])) {
                    return whole + fraction
                }
            }
        }
        
        // Pattern: mixed number "1 1/2" (after Unicode conversion, this should be rare but keep for compatibility)
        let mixedPattern2 = "^\\s*(\\d+)\\s+(\\d+)/(\\d+)\\s*$"
        if let regex = try? NSRegularExpression(pattern: mixedPattern2, options: []),
           let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count)),
           match.numberOfRanges >= 4,
           let wholeRange = Range(match.range(at: 1), in: trimmed),
           let numeratorRange = Range(match.range(at: 2), in: trimmed),
           let denominatorRange = Range(match.range(at: 3), in: trimmed),
           let whole = Double(String(trimmed[wholeRange])),
           let numerator = Double(String(trimmed[numeratorRange])),
           let denominator = Double(String(trimmed[denominatorRange])),
           denominator != 0 {
            return whole + (numerator / denominator)
        }
        
        // Pattern: simple fraction "1/2"
        let fractionPattern = "^\\s*(\\d+)/(\\d+)\\s*$"
        if let regex = try? NSRegularExpression(pattern: fractionPattern, options: []),
           let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count)),
           match.numberOfRanges >= 3,
           let numeratorRange = Range(match.range(at: 1), in: trimmed),
           let denominatorRange = Range(match.range(at: 2), in: trimmed),
           let numerator = Double(String(trimmed[numeratorRange])),
           let denominator = Double(String(trimmed[denominatorRange])),
           denominator != 0 {
            return numerator / denominator
        }
        
        // Pattern: range format "2-2" or "⅛-¼" (after Unicode conversion)
        let rangePattern = "^\\s*(\\d+(?:\\.\\d+)?)\\s*-\\s*(\\d+(?:\\.\\d+)?)\\s*$"
        if let regex = try? NSRegularExpression(pattern: rangePattern, options: []),
           let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count)),
           match.numberOfRanges >= 3,
           let firstRange = Range(match.range(at: 1), in: trimmed),
           let secondRange = Range(match.range(at: 2), in: trimmed),
           let first = Double(String(trimmed[firstRange])),
           let second = Double(String(trimmed[secondRange])) {
            // For ranges, use the higher value
            return max(first, second)
        }
        
        // Try parsing as a decimal number
        if let value = Double(trimmed) {
            return value
        }
        
        // If we can't parse it, return nil (don't scale)
        return nil
    }
    
    /// Format a numeric value to a string, using decimals instead of fractions
    private func formatAmount(_ value: Double) -> String {
        // Check for whole numbers
        let tolerance = 0.001
        if abs(value.truncatingRemainder(dividingBy: 1)) < tolerance {
            return String(format: "%.0f", value)
        }
        
        // Format as decimal with up to 2 decimal places, removing trailing zeros
        var formatted = String(format: "%.2f", value)
        while formatted.hasSuffix("0") && formatted.contains(".") {
            formatted = String(formatted.dropLast())
        }
        if formatted.hasSuffix(".") {
            formatted = String(formatted.dropLast())
        }
        return formatted
    }
    
    /// Calculate adjusted ingredient amount based on servings ratio
    private func adjustedIngredientAmount(_ ingredient: Ingredient) -> String {
        // If servings haven't changed, return original amount
        if adjustedServings == viewModel.recipe.servings {
            return ingredient.amount
        }
        
        // Parse the original amount
        guard let originalValue = parseAmount(ingredient.amount) else {
            // Can't parse (text amount like "适量"), return original
            return ingredient.amount
        }
        
        // Calculate ratio
        let ratio = Double(adjustedServings) / Double(viewModel.recipe.servings)
        let adjustedValue = originalValue * ratio
        
        // Format the adjusted value
        return formatAmount(adjustedValue)
    }
    
    /// Get adjusted ingredient with recalculated amount
    private func adjustedIngredient(_ ingredient: Ingredient) -> Ingredient {
        var adjusted = ingredient
        adjusted.amount = adjustedIngredientAmount(ingredient)
        return adjusted
    }
    
    /// Adjust instruction text to recalculate amounts based on servings
    private func adjustedInstructionText(_ instruction: Instruction) -> String {
        // If servings haven't changed, return original text
        if adjustedServings == viewModel.recipe.servings {
            return instruction.text
        }
        
        var adjustedText = instruction.text
        let ratio = Double(adjustedServings) / Double(viewModel.recipe.servings)
        
        // Pattern to match: amount (number, fraction, or mixed) followed by unit
        // Examples: "2 cups", "1/2 teaspoon", "1 1/2 tablespoons", "0.5 cup", "3 tablespoons of"
        // This pattern matches: number/fraction/decimal, space, then unit word(s)
        let amountUnitPattern = #"(\d+(?:\s+\d+/\d+)?|\d+/\d+|\d+\.\d+)\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)*)"#
        
        // Try to match and replace amounts in the instruction text
        // Match pattern: amount + unit (e.g., "2 cups", "1/2 teaspoon", "1.5 tablespoons")
        if let regex = try? NSRegularExpression(pattern: amountUnitPattern, options: [.caseInsensitive]) {
            let matches = regex.matches(in: adjustedText, options: [], range: NSRange(location: 0, length: adjustedText.utf16.count))
            
            // Process matches in reverse order to maintain correct string indices
            for match in matches.reversed() {
                if match.numberOfRanges >= 3 {
                    if let amountRange = Range(match.range(at: 1), in: adjustedText),
                       let unitRange = Range(match.range(at: 2), in: adjustedText) {
                        
                        let amountString = String(adjustedText[amountRange])
                        let unitString = String(adjustedText[unitRange])
                        
                        // Check if this unit appears in any ingredient (to ensure it's a cooking unit, not just any word)
                        // This helps avoid recalculating non-cooking amounts like "2 minutes" or "350 degrees"
                        let isCookingUnit = viewModel.recipe.ingredients.contains { ingredient in
                            let ingredientUnit = ingredient.unit.lowercased().trimmingCharacters(in: .whitespaces)
                            let instructionUnit = unitString.lowercased().trimmingCharacters(in: .whitespaces)
                            
                            // Skip if ingredient has no unit
                            guard !ingredientUnit.isEmpty else { return false }
                            
                            // Get unit variations for matching
                            let ingredientAbbrev = UnitTranslations.abbreviation(for: ingredient.unit, amount: ingredient.amount).lowercased()
                            let ingredientTranslated = UnitTranslations.translatedName(for: ingredient.unit, amount: ingredient.amount).lowercased()
                            
                            // Try multiple matching strategies
                            return ingredientUnit == instructionUnit ||
                                ingredientAbbrev == instructionUnit ||
                                ingredientTranslated == instructionUnit ||
                                // Handle plural/singular variations (e.g., "cup" vs "cups")
                                (instructionUnit.hasSuffix("s") && ingredientUnit == String(instructionUnit.dropLast())) ||
                                (ingredientUnit.hasSuffix("s") && instructionUnit == String(ingredientUnit.dropLast())) ||
                                // Partial matches for compound units (e.g., "fluid ounce" contains "ounce")
                                instructionUnit.contains(ingredientUnit) ||
                                ingredientUnit.contains(instructionUnit)
                        }
                        
                        // Only recalculate if it's a cooking unit (found in ingredients)
                        // This prevents recalculating time units, temperature, etc.
                        if isCookingUnit {
                            // Parse and recalculate amount
                            if let originalValue = parseAmount(amountString) {
                                let adjustedValue = originalValue * ratio
                                let adjustedAmountString = formatAmount(adjustedValue)
                                
                                // Replace the amount in the text
                                if let fullMatchRange = Range(match.range, in: adjustedText) {
                                    let replacement = "\(adjustedAmountString) \(unitString)"
                                    adjustedText.replaceSubrange(fullMatchRange, with: replacement)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return adjustedText
    }
    
    private func deleteRecipe() async {
        guard isAuthor else { return }
        
        do {
            let recipeID = viewModel.recipe.id
            try await RecipeService.shared.deleteRecipe(recipeID: recipeID)
            
            // Post notification to refresh feeds/views before dismissing
            NotificationCenter.default.post(name: NSNotification.Name("RecipeDeleted"), object: nil, userInfo: ["recipeID": recipeID])
            
            // Reload user data to update recipe count
            await authViewModel.reloadUserData()
            
            dismiss()
        } catch {
            print("❌ Error deleting recipe: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Share Methods
    
    private func prepareShareContent() async {
        isPreparingShare = true
        shareImage = nil
        
        // Load the best available recipe image (prefer imageURLs array, fall back to imageURL)
        let imageURLString = viewModel.recipe.imageURLs.first ?? viewModel.recipe.imageURL
        if let urlString = imageURLString, let url = URL(string: urlString) {
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
        let recipeText = formatRecipeForSharing()
        
        if let image = shareImage {
            // Use custom item sources — image as primary, text as secondary caption
            let imageItem = RecipeImageItemSource(image: image, caption: recipeText)
            let textItem = RecipeTextItemSource(text: recipeText)
            return [imageItem, textItem]
        } else {
            // No image — just share text
            return [recipeText]
        }
    }
    
    private func formatRecipeForSharing() -> String {
        var text = ""
        
        // Title
        text += "\(viewModel.recipe.title)\n\n"
        
        // Recipe Info
        text += "\(LocalizedString("Prep Time", comment: "Prep time label")): \(formatDuration(viewModel.recipe.prepTime))\n"
        text += "\(LocalizedString("Cook Time", comment: "Cook time label")): \(formatDuration(viewModel.recipe.cookTime))\n"
        text += "\(LocalizedString("Total Time", comment: "Total time label")): \(formatDuration(viewModel.totalTime))\n"
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
        
        // App Store link
        text += "\n"
        text += "🍽️ "
        text += LocalizedString("Shared via Misoto", comment: "Short sharing attribution")
        text += "\n"
        text += misotoAppStoreURL
        
        return text
    }
}

// MARK: - Recipe Image Share Item Source

/// Custom UIActivityItemSource that presents an image as the primary share content
/// with recipe text as a caption. This ensures WhatsApp, iMessage, etc. show the
/// dish photo first instead of a wall of text.
class RecipeImageItemSource: NSObject, UIActivityItemSource {
    let image: UIImage
    let caption: String
    
    init(image: UIImage, caption: String) {
        self.image = image
        self.caption = caption
        super.init()
    }
    
    // Placeholder tells the system what type of content to expect (image)
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return image
    }
    
    // Return the actual item — image for most apps, text for copy
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        // For copy-to-clipboard, provide the text instead
        if activityType == .copyToPasteboard {
            return caption
        }
        return image
    }
    
    // Provide the recipe text as the subject line (used by Mail, some messaging apps)
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        // Return just the recipe title as subject
        return caption.components(separatedBy: "\n").first ?? ""
    }
    
    // Provide caption text for apps that support it (WhatsApp, iMessage, etc.)
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "public.image"
    }
}

/// Secondary text item source — provides the recipe text alongside the image
class RecipeTextItemSource: NSObject, UIActivityItemSource {
    let text: String
    
    init(text: String) {
        self.text = text
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return text
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
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

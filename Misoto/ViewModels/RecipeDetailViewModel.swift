//
//  RecipeDetailViewModel.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class RecipeDetailViewModel: ObservableObject {
    @Published var recipe: Recipe
    @Published var isFavorite: Bool = false
    @Published var isLoading: Bool = false
    @Published var noteCount: Int = 0
    @Published var userNotes: [RecipeNote] = []
    @Published var errorMessage: String?
    @Published var isLoadingMoreNotes: Bool = false
    @Published var hasMoreNotes: Bool = false
    @Published var nutritionInfo: NutritionInfo?
    @Published var isLoadingNutrition: Bool = false
    @Published var nutritionError: String?
    
    // Comments
    @Published var comments: [RecipeComment] = []
    @Published var commentCount: Int = 0
    @Published var averageRating: Double = 0
    @Published var ratingCount: Int = 0
    @Published var isLoadingComments: Bool = false
    @Published var isLoadingMoreComments: Bool = false
    @Published var hasMoreComments: Bool = false
    @Published var existingUserComment: RecipeComment?
    
    private let recipeService = RecipeService.shared
    private let noteService = RecipeNoteService()
    private let commentService = RecipeCommentService()
    private let changeProposalService = RecipeChangeProposalService()
    private let notesPerPage = 5
    private let commentsPerPage = 5
    private var lastNoteDocument: DocumentSnapshot?
    private var lastCommentDocument: DocumentSnapshot?
    private let firestore = FirebaseManager.shared.firestore
    private var favoriteListener: ListenerRegistration?
    
    init(recipe: Recipe) {
        self.recipe = recipe
        // Pre-populate nutritionInfo from stored recipe data if available
        self.nutritionInfo = recipe.nutritionInfo
    }
    
    deinit {
        favoriteListener?.remove()
    }
    
    // MARK: - Computed Properties
    
    var totalTime: Int {
        recipe.prepTime + recipe.cookTime
    }
    
    var difficultyDisplay: String {
        recipe.difficulty.rawValue
    }
    
    var difficultyDescription: String {
        switch recipe.difficulty {
        case .c:
            return LocalizedString("Zero cooking skills", comment: "Difficulty C description")
        case .b:
            return LocalizedString("Beginner", comment: "Difficulty B description")
        case .a:
            return LocalizedString("Intermediate", comment: "Difficulty A description")
        case .s:
            return LocalizedString("Advanced", comment: "Difficulty S description")
        case .ss:
            return LocalizedString("Expert", comment: "Difficulty SS description")
        }
    }
    
    // MARK: - Methods
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        // Lazy update: Refresh author info if stale (cost-effective approach)
        // This only updates the recipe if author info changed, and only when viewed
        do {
            recipe = try await recipeService.refreshRecipeAuthorInfoIfNeeded(recipe)
        } catch {
            // Log error but don't fail the load
            print("⚠️ Error refreshing recipe author info: \(error.localizedDescription)")
        }
        
        await checkFavoriteStatus()
        await loadNoteCount()
        await loadUserNotes()
        await loadComments()
        await loadCommentStats()
        
        isLoading = false
    }
    
    func checkFavoriteStatus() async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        do {
            isFavorite = try await recipeService.isFavorite(recipeID: recipe.id, userID: userID)
            // Set up real-time listener for favorite status
            setupFavoriteListener(userID: userID, recipeID: recipe.id)
        } catch {
            // Silently fail
            print("⚠️ Error checking favorite status: \(error.localizedDescription)")
        }
    }
    
    private func setupFavoriteListener(userID: String, recipeID: String) {
        // Remove existing listener if any
        favoriteListener?.remove()
        
        // Set up real-time listener for the favorite document
        let query = firestore.collection("favorites")
            .whereField("userID", isEqualTo: userID)
            .whereField("recipeID", isEqualTo: recipeID)
            .limit(to: 1)
        
        favoriteListener = query.addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let error = error {
                    print("⚠️ Error listening to favorite status: \(error.localizedDescription)")
                    return
                }
                
                // Update isFavorite based on whether documents exist
                self.isFavorite = !(snapshot?.documents.isEmpty ?? true)
                print("🔄 Favorite status updated: \(self.isFavorite)")
            }
        }
    }
    
    func toggleFavorite() async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        do {
            if isFavorite {
                try await recipeService.removeFavorite(recipeID: recipe.id, userID: userID)
                recipe.favoriteCount = max(0, recipe.favoriteCount - 1)
            } else {
                try await recipeService.addFavorite(recipeID: recipe.id, userID: userID)
                recipe.favoriteCount += 1
            }
        } catch {
            errorMessage = error.localizedDescription
            print("⚠️ Error toggling favorite: \(error.localizedDescription)")
        }
    }
    
    func loadNoteCount() async {
        do {
            noteCount = try await noteService.getNoteCount(for: recipe.id)
        } catch {
            // Silently fail
            print("⚠️ Error loading note count: \(error.localizedDescription)")
        }
    }
    
    func loadUserNotes() async {
        guard let userID = Auth.auth().currentUser?.uid else {
            userNotes = []
            hasMoreNotes = false
            lastNoteDocument = nil
            return
        }
        
        // Reset pagination
        lastNoteDocument = nil
        userNotes = []
        
        do {
            let result = try await noteService.fetchUserNotes(
                for: recipe.id,
                userID: userID,
                limit: notesPerPage,
                startAfter: nil
            )
            userNotes = result.notes
            lastNoteDocument = result.lastDocument
            hasMoreNotes = result.hasMore
            print("✅ Loaded \(result.notes.count) user notes for recipe \(recipe.id), hasMore: \(result.hasMore)")
        } catch {
            print("⚠️ Error loading user notes: \(error.localizedDescription)")
            // If there's an error, it might be a missing Firestore index
            // Try again after a short delay
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            do {
                let result = try await noteService.fetchUserNotes(
                    for: recipe.id,
                    userID: userID,
                    limit: notesPerPage,
                    startAfter: nil
                )
                userNotes = result.notes
                lastNoteDocument = result.lastDocument
                hasMoreNotes = result.hasMore
                print("✅ Loaded \(result.notes.count) user notes after retry, hasMore: \(result.hasMore)")
            } catch {
                print("⚠️ Error loading user notes after retry: \(error.localizedDescription)")
                userNotes = []
                hasMoreNotes = false
                lastNoteDocument = nil
            }
        }
    }
    
    func loadMoreUserNotes() async {
        guard let userID = Auth.auth().currentUser?.uid,
              let lastDoc = lastNoteDocument,
              !isLoadingMoreNotes else {
            return
        }
        
        isLoadingMoreNotes = true
        
        do {
            let result = try await noteService.fetchUserNotes(
                for: recipe.id,
                userID: userID,
                limit: notesPerPage,
                startAfter: lastDoc
            )
            userNotes.append(contentsOf: result.notes)
            lastNoteDocument = result.lastDocument
            hasMoreNotes = result.hasMore
            print("✅ Loaded \(result.notes.count) more notes, total: \(userNotes.count), hasMore: \(result.hasMore)")
        } catch {
            print("⚠️ Error loading more notes: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoadingMoreNotes = false
    }
    
    func refreshRecipe() async {
        do {
            if var updatedRecipe = try await recipeService.fetchRecipe(byID: recipe.id) {
                // Lazy update: Refresh author info if stale (cost-effective approach)
                updatedRecipe = try await recipeService.refreshRecipeAuthorInfoIfNeeded(updatedRecipe)
                recipe = updatedRecipe
                // Refresh related data (notes, comments, favorite status) without re-fetching recipe
                await checkFavoriteStatus()
                await loadNoteCount()
                await loadUserNotes()
                await loadComments()
                await loadCommentStats()
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error refreshing recipe: \(error.localizedDescription)")
        }
    }
    
    func togglePrivacy(clearSharedWith: Bool = false) async {
        guard let userID = Auth.auth().currentUser?.uid,
              recipe.authorID == userID else {
            return
        }
        
        let newPrivacyStatus = !recipe.isPrivate
        
        // Optimistic update: Update UI immediately
        let currentSharedWith = recipe.sharedWith
        recipe.isPrivate = newPrivacyStatus
        
        // If making private and clearSharedWith is true: Save current sharedWith to preservedSharedWith, then clear sharedWith
        if newPrivacyStatus && clearSharedWith {
            // Save current sharedWith to preservedSharedWith before clearing (if it has users)
            if !currentSharedWith.isEmpty {
                recipe.preservedSharedWith = currentSharedWith
            }
            // Always clear sharedWith when making "Private to All" (removes access)
            recipe.sharedWith = []
        }
        // When making public: Restore preservedSharedWith to sharedWith if it exists
        else if !newPrivacyStatus {
            // Restore preserved sharedWith list if it exists
            if let preserved = recipe.preservedSharedWith, !preserved.isEmpty {
                recipe.sharedWith = preserved
                recipe.preservedSharedWith = nil // Clear preserved list after restore
            }
            // If no preserved list, keep current sharedWith as-is
        }
        // When making private with clearSharedWith=false: Preserve sharedWith (for "Private Sharing" flow)
        //   No changes needed - sharedWith is already set correctly
        
        // Update backend
        do {
            try await recipeService.toggleRecipePrivacy(recipeID: recipe.id, isPrivate: newPrivacyStatus, clearSharedWith: clearSharedWith)
            print("✅ Recipe privacy updated to: \(newPrivacyStatus ? "private" : "public"), sharedWith cleared: \(clearSharedWith)")
        } catch {
            // Revert optimistic update on error
            recipe.isPrivate = !newPrivacyStatus
            if newPrivacyStatus && clearSharedWith {
                // Would need to restore original sharedWith, but we'll refresh from server instead
            }
            errorMessage = error.localizedDescription
            print("❌ Error toggling recipe privacy: \(error.localizedDescription)")
        }
    }
    
    func updateSharing(sharedWith: [String]) async {
        guard let userID = Auth.auth().currentUser?.uid,
              recipe.authorID == userID else {
            return
        }
        
        // Optimistic update: Update UI immediately
        recipe.sharedWith = sharedWith
        recipe.isPrivate = true // Must be private to share with specific users
        recipe.preservedSharedWith = nil // Clear preserved list when user explicitly sets sharing
        
        // Update backend
        do {
            try await recipeService.updateRecipeSharing(recipeID: recipe.id, sharedWith: sharedWith)
            print("✅ Recipe sharing updated. Shared with \(sharedWith.count) user(s)")
        } catch {
            // Revert optimistic update on error - would need to reload from server
            errorMessage = error.localizedDescription
            print("❌ Error updating recipe sharing: \(error.localizedDescription)")
            // Reload recipe to get correct state
            if let updatedRecipe = try? await recipeService.fetchRecipe(byID: recipe.id) {
                recipe = updatedRecipe
            }
        }
    }
    
    // MARK: - Nutrition Estimation
    
    private let nutritionCalculator = NutritionCalculator()
    
    /// Estimate nutrition using USDA database (primary) with AI fallback, then persist to Firestore
    func estimateNutrition() async {
        guard !recipe.ingredients.isEmpty else { return }
        guard !isLoadingNutrition else { return }
        
        isLoadingNutrition = true
        nutritionError = nil
        
        // 1. Try USDA-based calculation (accurate, database-backed)
        print("🍽️ Starting nutrition estimation for '\(recipe.title)' (\(recipe.ingredients.count) ingredients, \(recipe.servings) servings)")
        if let usdaInfo = await nutritionCalculator.calculateNutrition(
            title: recipe.title,
            ingredients: recipe.ingredients,
            servings: recipe.servings
        ) {
            print("✅ Nutrition calculated via USDA database: \(usdaInfo.calories) kcal | P:\(usdaInfo.protein)g C:\(usdaInfo.carbohydrates)g F:\(usdaInfo.fat)g")
            nutritionInfo = usdaInfo
            recipe.nutritionInfo = usdaInfo
            
            // Only persist to Firestore if user owns this recipe
            if let uid = Auth.auth().currentUser?.uid, recipe.authorID == uid {
                do {
                    try await recipeService.saveNutritionInfo(recipeID: recipe.id, nutritionInfo: usdaInfo)
                } catch {
                    print("⚠️ Failed to persist nutrition to Firestore: \(error.localizedDescription)")
                }
            } else {
                print("ℹ️ Not persisting nutrition — user is not the recipe author")
            }
            
            isLoadingNutrition = false
            return
        }
        
        // 2. Fallback: AI estimation
        print("ℹ️ Falling back to AI nutrition estimation")
        do {
            let info = try await OpenAIService.estimateNutrition(
                title: recipe.title,
                ingredients: recipe.ingredients,
                servings: recipe.servings
            )
            nutritionInfo = info
            recipe.nutritionInfo = info
            
            // Only persist to Firestore if user owns this recipe
            if let uid = Auth.auth().currentUser?.uid, recipe.authorID == uid {
                do {
                    try await recipeService.saveNutritionInfo(recipeID: recipe.id, nutritionInfo: info)
                } catch {
                    print("⚠️ Failed to persist nutrition to Firestore: \(error.localizedDescription)")
                }
            } else {
                print("ℹ️ Not persisting nutrition — user is not the recipe author")
            }
        } catch {
            nutritionError = error.localizedDescription
            print("⚠️ Error estimating nutrition: \(error.localizedDescription)")
        }
        
        isLoadingNutrition = false
    }
    
    // MARK: - Comment Management
    
    func loadComments() async {
        lastCommentDocument = nil
        comments = []
        
        do {
            let result = try await commentService.fetchComments(
                for: recipe.id,
                limit: commentsPerPage,
                startAfter: nil
            )
            comments = result.comments
            lastCommentDocument = result.lastDocument
            hasMoreComments = result.hasMore
            
            // Check if current user already commented
            existingUserComment = try await commentService.hasUserCommented(recipeID: recipe.id)
        } catch {
            print("⚠️ Error loading comments: \(error.localizedDescription)")
        }
    }
    
    func loadMoreComments() async {
        guard let lastDoc = lastCommentDocument, !isLoadingMoreComments else { return }
        
        isLoadingMoreComments = true
        
        do {
            let result = try await commentService.fetchComments(
                for: recipe.id,
                limit: commentsPerPage,
                startAfter: lastDoc
            )
            comments.append(contentsOf: result.comments)
            lastCommentDocument = result.lastDocument
            hasMoreComments = result.hasMore
        } catch {
            print("⚠️ Error loading more comments: \(error.localizedDescription)")
        }
        
        isLoadingMoreComments = false
    }
    
    func loadCommentStats() async {
        do {
            let stats = try await commentService.getAverageRating(for: recipe.id)
            averageRating = stats.average
            ratingCount = stats.count
            commentCount = try await commentService.getCommentCount(for: recipe.id)
        } catch {
            print("⚠️ Error loading comment stats: \(error.localizedDescription)")
        }
    }
    
    func submitComment(content: String, rating: Int) async {
        guard let user = Auth.auth().currentUser else { return }
        
        // Fetch full user profile for photo/username
        var displayName = user.displayName ?? "Anonymous"
        var username: String?
        var profileImageURL: String?
        
        do {
            let doc = try await firestore.collection("users").document(user.uid).getDocument()
            if let appUser = try? doc.data(as: AppUser.self) {
                displayName = appUser.displayName
                username = appUser.username
                profileImageURL = appUser.profileImageURL
            }
        } catch {
            print("⚠️ Could not fetch user profile: \(error.localizedDescription)")
        }
        
        let comment = RecipeComment(
            recipeID: recipe.id,
            userID: user.uid,
            displayName: displayName,
            username: username,
            profileImageURL: profileImageURL,
            content: String(content.prefix(250)),
            rating: rating
        )
        
        do {
            let savedComment = try await commentService.createComment(comment)
            // Insert at top since sorted by newest
            comments.insert(savedComment, at: 0)
            existingUserComment = savedComment
            commentCount += 1
            await loadCommentStats()
        } catch {
            errorMessage = error.localizedDescription
            print("⚠️ Error submitting comment: \(error.localizedDescription)")
        }
    }
    
    func updateComment(comment: RecipeComment, content: String, rating: Int) async {
        var updated = comment
        updated.content = String(content.prefix(250))
        updated.rating = rating
        
        do {
            try await commentService.updateComment(updated)
            // Update in local array
            if let index = comments.firstIndex(where: { $0.id == comment.id }) {
                updated.updatedAt = Date()
                comments[index] = updated
            }
            existingUserComment = updated
            await loadCommentStats()
        } catch {
            errorMessage = error.localizedDescription
            print("⚠️ Error updating comment: \(error.localizedDescription)")
        }
    }
    
    func deleteComment(_ comment: RecipeComment) async {
        do {
            try await commentService.deleteComment(commentID: comment.id)
            comments.removeAll { $0.id == comment.id }
            existingUserComment = nil
            commentCount = max(0, commentCount - 1)
            await loadCommentStats()
        } catch {
            errorMessage = error.localizedDescription
            print("⚠️ Error deleting comment: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Change Proposals (viewer suggestions)
    
    /// Submits a structured change proposal. Returns `nil` on success, otherwise a user-facing error string.
    func submitChangeProposal(draft: RecipeChangeProposalDraft, proposal: String) async -> String? {
        guard let user = Auth.auth().currentUser else {
            return LocalizedString("You must be signed in to send a suggestion.", comment: "Suggestion not signed in")
        }
        
        guard user.uid != recipe.authorID else {
            return LocalizedString("You cannot suggest changes to your own recipe", comment: "Own recipe suggestion error")
        }
        
        let trimmedProposal = proposal.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedProposal.isEmpty else {
            return LocalizedString("Please enter your suggestion.", comment: "Empty proposal error")
        }
        
        var displayName = user.displayName ?? "Anonymous"
        var username: String?
        var profileImageURL: String?
        
        do {
            let doc = try await firestore.collection("users").document(user.uid).getDocument()
            if let appUser = try? doc.data(as: AppUser.self) {
                displayName = appUser.displayName
                username = appUser.username
                profileImageURL = appUser.profileImageURL
            }
        } catch {
            print("⚠️ Could not fetch user profile for change proposal: \(error.localizedDescription)")
        }
        
        let snapshot = String(draft.contextSnapshot.prefix(500))
        
        let model = RecipeChangeProposal(
            recipeID: recipe.id,
            recipeAuthorID: recipe.authorID,
            userID: user.uid,
            displayName: displayName,
            username: username,
            profileImageURL: profileImageURL,
            targetKind: draft.targetKind,
            targetIndex: draft.targetIndex,
            contextSnapshot: snapshot,
            proposal: String(trimmedProposal.prefix(1_000))
        )
        
        do {
            _ = try await changeProposalService.createProposal(model)
            print("✅ Recipe change proposal saved: \(model.id)")
            return nil
        } catch {
            print("⚠️ Error submitting change proposal: \(error.localizedDescription)")
            return error.localizedDescription
        }
    }
    
    // MARK: - Note Management
    
    func deleteNote(_ note: RecipeNote) async {
        do {
            try await noteService.deleteNote(noteID: note.id)
            // Remove note from local array
            userNotes.removeAll { $0.id == note.id }
            // Reload notes to refresh pagination state
            await loadUserNotes()
            await loadNoteCount()
        } catch {
            errorMessage = error.localizedDescription
            print("⚠️ Error deleting note: \(error.localizedDescription)")
        }
    }
}


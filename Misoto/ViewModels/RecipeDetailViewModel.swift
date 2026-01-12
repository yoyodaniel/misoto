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
    
    private let recipeService = RecipeService.shared
    private let noteService = RecipeNoteService()
    private let notesPerPage = 5
    private var lastNoteDocument: DocumentSnapshot?
    
    init(recipe: Recipe) {
        self.recipe = recipe
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
        
        isLoading = false
    }
    
    func checkFavoriteStatus() async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        do {
            isFavorite = try await recipeService.isFavorite(recipeID: recipe.id, userID: userID)
        } catch {
            // Silently fail
            print("⚠️ Error checking favorite status: \(error.localizedDescription)")
        }
    }
    
    func toggleFavorite() async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        // Update state optimistically for immediate UI feedback
        let wasFavorite = isFavorite
        isFavorite.toggle()
        if wasFavorite {
            recipe.favoriteCount = max(0, recipe.favoriteCount - 1)
        } else {
            recipe.favoriteCount += 1
        }
        
        do {
            if wasFavorite {
                try await recipeService.removeFavorite(recipeID: recipe.id, userID: userID)
            } else {
                try await recipeService.addFavorite(recipeID: recipe.id, userID: userID)
            }
        } catch {
            // Revert state on error
            isFavorite = wasFavorite
            if wasFavorite {
                recipe.favoriteCount += 1
            } else {
                recipe.favoriteCount = max(0, recipe.favoriteCount - 1)
            }
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
                // Refresh related data (notes, favorite status) without re-fetching recipe
                await checkFavoriteStatus()
                await loadNoteCount()
                await loadUserNotes()
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


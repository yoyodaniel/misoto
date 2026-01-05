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
    
    private let recipeService = RecipeService()
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
        
        async let favoriteCheck = checkFavoriteStatus()
        async let noteCountCheck = loadNoteCount()
        async let userNotesCheck = loadUserNotes()
        
        await favoriteCheck
        await noteCountCheck
        await userNotesCheck
        
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
        
        do {
            if isFavorite {
                try await recipeService.removeFavorite(recipeID: recipe.id, userID: userID)
                isFavorite = false
                recipe.favoriteCount = max(0, recipe.favoriteCount - 1)
            } else {
                try await recipeService.addFavorite(recipeID: recipe.id, userID: userID)
                isFavorite = true
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
            if let updatedRecipe = try await recipeService.fetchRecipe(byID: recipe.id) {
                recipe = updatedRecipe
                await loadData()
            }
        } catch {
            errorMessage = error.localizedDescription
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


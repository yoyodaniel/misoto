//
//  RecipeNotesViewModel.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class RecipeNotesViewModel: ObservableObject {
    @Published var notes: [RecipeNote] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    let recipeID: String
    private let noteService = RecipeNoteService()
    
    init(recipeID: String) {
        self.recipeID = recipeID
    }
    
    // MARK: - Methods
    
    func loadNotes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            notes = try await noteService.fetchNotes(for: recipeID)
        } catch {
            errorMessage = error.localizedDescription
            print("⚠️ Error loading notes: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func deleteNote(_ note: RecipeNote) async {
        do {
            try await noteService.deleteNote(noteID: note.id)
            await loadNotes()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    
    func canEditNote(_ note: RecipeNote) -> Bool {
        guard let userID = currentUserID else { return false }
        return note.userID == userID
    }
}


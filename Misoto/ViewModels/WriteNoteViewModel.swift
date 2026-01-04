//
//  WriteNoteViewModel.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class WriteNoteViewModel: ObservableObject {
    @Published var content: String = ""
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    
    let recipeID: String
    let existingNote: RecipeNote?
    
    private let noteService = RecipeNoteService()
    
    init(recipeID: String, existingNote: RecipeNote? = nil) {
        self.recipeID = recipeID
        self.existingNote = existingNote
        self.content = existingNote?.content ?? ""
    }
    
    // MARK: - Methods
    
    func saveNote() async -> Bool {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = LocalizedString("Note content cannot be empty", comment: "Empty note error")
            return false
        }
        
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = LocalizedString("You must be logged in to save a note", comment: "Not logged in error")
            return false
        }
        
        isSaving = true
        errorMessage = nil
        
        do {
            if let existingNote = existingNote {
                // Update existing note
                var updatedNote = existingNote
                updatedNote.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
                try await noteService.updateNote(updatedNote)
            } else {
                // Create new note
                let userName = Auth.auth().currentUser?.displayName ?? 
                              Auth.auth().currentUser?.email ?? 
                              "Anonymous"
                
                let newNote = RecipeNote(
                    recipeID: recipeID,
                    userID: userID,
                    userName: userName,
                    content: content.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                try await noteService.createNote(newNote)
            }
            
            isSaving = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
            return false
        }
    }
}


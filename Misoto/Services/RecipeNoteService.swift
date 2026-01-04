//
//  RecipeNoteService.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class RecipeNoteService {
    private let firestore = FirebaseManager.shared.firestore
    private let notesCollection = "recipeNotes"
    
    // MARK: - Fetch Notes
    
    func fetchNotes(for recipeID: String) async throws -> [RecipeNote] {
        let snapshot = try await firestore.collection(notesCollection)
            .whereField("recipeID", isEqualTo: recipeID)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        var notes: [RecipeNote] = []
        for document in snapshot.documents {
            do {
                var note = try document.data(as: RecipeNote.self)
                note.id = document.documentID
                notes.append(note)
            } catch {
                print("⚠️ Failed to decode note \(document.documentID): \(error.localizedDescription)")
            }
        }
        
        return notes
    }
    
    func getNoteCount(for recipeID: String) async throws -> Int {
        let snapshot = try await firestore.collection(notesCollection)
            .whereField("recipeID", isEqualTo: recipeID)
            .getDocuments()
        
        return snapshot.documents.count
    }
    
    // MARK: - Create Note
    
    func createNote(_ note: RecipeNote) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw RecipeNoteError.unauthorized
        }
        
        var newNote = note
        newNote.userID = userID
        newNote.id = UUID().uuidString
        newNote.createdAt = Date()
        newNote.updatedAt = Date()
        
        // Get user name if not provided
        if newNote.userName.isEmpty {
            if let user = Auth.auth().currentUser {
                newNote.userName = user.displayName ?? user.email ?? "Anonymous"
            }
        }
        
        let noteRef = firestore.collection(notesCollection).document(newNote.id)
        try noteRef.setData(from: newNote)
    }
    
    // MARK: - Update Note
    
    func updateNote(_ note: RecipeNote) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw RecipeNoteError.unauthorized
        }
        
        // Verify ownership
        guard note.userID == userID else {
            throw RecipeNoteError.unauthorized
        }
        
        var updatedNote = note
        updatedNote.updatedAt = Date()
        
        let noteRef = firestore.collection(notesCollection).document(note.id)
        try noteRef.setData(from: updatedNote, merge: true)
    }
    
    // MARK: - Delete Note
    
    func deleteNote(noteID: String) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw RecipeNoteError.unauthorized
        }
        
        // Verify ownership
        let noteRef = firestore.collection(notesCollection).document(noteID)
        let document = try await noteRef.getDocument()
        
        guard let note = try? document.data(as: RecipeNote.self),
              note.userID == userID else {
            throw RecipeNoteError.unauthorized
        }
        
        try await noteRef.delete()
    }
}

enum RecipeNoteError: LocalizedError {
    case unauthorized
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return LocalizedString("You are not authorized to perform this action", comment: "Unauthorized error")
        case .notFound:
            return LocalizedString("Note not found", comment: "Note not found error")
        }
    }
}


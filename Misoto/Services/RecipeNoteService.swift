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
    
    /// Fetch all notes for a recipe (all users)
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
    
    /// Fetch notes for a specific user and recipe with pagination
    func fetchUserNotes(
        for recipeID: String,
        userID: String,
        limit: Int = 5,
        startAfter: DocumentSnapshot? = nil
    ) async throws -> (notes: [RecipeNote], lastDocument: DocumentSnapshot?, hasMore: Bool) {
        print("🔍 Fetching user notes for recipeID: \(recipeID), userID: \(userID), limit: \(limit)")
        
        // Try with ordering first (requires composite index)
        do {
            var query = firestore.collection(notesCollection)
                .whereField("recipeID", isEqualTo: recipeID)
                .whereField("userID", isEqualTo: userID)
                .order(by: "createdAt", descending: true)
                .limit(to: limit + 1) // Fetch one extra to check if there are more
            
            if let startAfter = startAfter {
                query = query.start(afterDocument: startAfter)
            }
            
            let snapshot = try await query.getDocuments()
            
            var notes: [RecipeNote] = []
            var lastDoc: DocumentSnapshot?
            
            // Check if we have more than the limit
            let hasMore = snapshot.documents.count > limit
            let documentsToProcess = hasMore ? Array(snapshot.documents.prefix(limit)) : snapshot.documents
            
            for document in documentsToProcess {
                do {
                    var note = try document.data(as: RecipeNote.self)
                    note.id = document.documentID
                    notes.append(note)
                    lastDoc = document
                } catch {
                    print("⚠️ Failed to decode note \(document.documentID): \(error.localizedDescription)")
                }
            }
            
            print("✅ Found \(notes.count) notes with ordering, hasMore: \(hasMore)")
            return (notes, lastDoc, hasMore)
        } catch {
            print("⚠️ Query with ordering failed: \(error.localizedDescription)")
            print("🔄 Trying fallback query without ordering...")
            
            // Fallback: query without ordering (doesn't require composite index)
            var query = firestore.collection(notesCollection)
                .whereField("recipeID", isEqualTo: recipeID)
                .whereField("userID", isEqualTo: userID)
                .limit(to: limit + 1) // Fetch one extra to check if there are more
            
            if let startAfter = startAfter {
                query = query.start(afterDocument: startAfter)
            }
            
            let snapshot = try await query.getDocuments()
            
            var notes: [RecipeNote] = []
            var lastDoc: DocumentSnapshot?
            
            // Check if we have more than the limit
            let hasMore = snapshot.documents.count > limit
            let documentsToProcess = hasMore ? Array(snapshot.documents.prefix(limit)) : snapshot.documents
            
            for document in documentsToProcess {
                do {
                    var note = try document.data(as: RecipeNote.self)
                    note.id = document.documentID
                    notes.append(note)
                    lastDoc = document
                } catch {
                    print("⚠️ Failed to decode note \(document.documentID): \(error.localizedDescription)")
                }
            }
            
            // Sort manually by createdAt
            notes.sort { $0.createdAt > $1.createdAt }
            
            print("✅ Found \(notes.count) notes with fallback query, hasMore: \(hasMore)")
            return (notes, lastDoc, hasMore)
        }
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
        // Ensure both userID and recipeID are set (note is linked to both user and recipe)
        newNote.userID = userID
        newNote.recipeID = note.recipeID // Ensure recipeID is set
        newNote.id = UUID().uuidString
        newNote.createdAt = Date()
        newNote.updatedAt = Date()
        
        // Get user name if not provided
        if newNote.userName.isEmpty {
            if let user = Auth.auth().currentUser {
                newNote.userName = user.displayName ?? user.email ?? "Anonymous"
            }
        }
        
        print("💾 Saving note with ID: \(newNote.id), recipeID: \(newNote.recipeID), userID: \(newNote.userID)")
        
        // Save note to collection - document contains both userID and recipeID for proper linking
        let noteRef = firestore.collection(notesCollection).document(newNote.id)
        try noteRef.setData(from: newNote)
        
        print("✅ Note saved successfully to document: \(newNote.id)")
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


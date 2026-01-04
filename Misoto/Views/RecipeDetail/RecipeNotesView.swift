//
//  RecipeNotesView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

struct RecipeNotesView: View {
    @StateObject private var viewModel: RecipeNotesViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showWriteNote = false
    @State private var noteToEdit: RecipeNote?
    @State private var showDeleteConfirmation = false
    @State private var noteToDelete: RecipeNote?
    
    init(recipeID: String) {
        _viewModel = StateObject(wrappedValue: RecipeNotesViewModel(recipeID: recipeID))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.notes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "note.text")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text(LocalizedString("No notes yet", comment: "No notes message"))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showWriteNote = true
                        }) {
                            Text(LocalizedString("Write First Note", comment: "Write first note button"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.accentColor)
                                .cornerRadius(12)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.notes) { note in
                                RecipeNoteCard(
                                    note: note,
                                    canEdit: viewModel.canEditNote(note),
                                    onEdit: {
                                        noteToEdit = note
                                        showWriteNote = true
                                    },
                                    onDelete: {
                                        noteToDelete = note
                                        showDeleteConfirmation = true
                                    }
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle(LocalizedString("Notes", comment: "Notes title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text(LocalizedString("Close", comment: "Close button"))
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        noteToEdit = nil
                        showWriteNote = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.primary)
                    }
                }
            }
            .task {
                await viewModel.loadNotes()
            }
            .sheet(isPresented: $showWriteNote) {
                WriteNoteView(
                    recipeID: viewModel.recipeID,
                    existingNote: noteToEdit
                ) {
                    Task {
                        await viewModel.loadNotes()
                    }
                }
            }
            .confirmationDialog(
                LocalizedString("Delete Note", comment: "Delete confirmation title"),
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(LocalizedString("Delete", comment: "Delete button"), role: .destructive) {
                    if let note = noteToDelete {
                        Task {
                            await viewModel.deleteNote(note)
                        }
                    }
                }
                Button(LocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {
                    showDeleteConfirmation = false
                    noteToDelete = nil
                }
            } message: {
                Text(LocalizedString("Are you sure you want to delete this note?", comment: "Delete confirmation message"))
            }
        }
    }
}

#Preview {
    RecipeNotesView(recipeID: "123")
}


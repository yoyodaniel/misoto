//
//  WriteNoteView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

struct WriteNoteView: View {
    @StateObject private var viewModel: WriteNoteViewModel
    @Environment(\.dismiss) private var dismiss
    
    let onSave: () -> Void
    
    @FocusState private var isContentFocused: Bool
    
    init(recipeID: String, existingNote: RecipeNote? = nil, onSave: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: WriteNoteViewModel(recipeID: recipeID, existingNote: existingNote))
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Text Editor with rounded rectangle background
                ZStack(alignment: .topLeading) {
                    // Rounded rectangle background (adapts to dark mode)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .frame(maxWidth: .infinity, minHeight: 200)
                    
                    // Text Editor with indentation
                    TextEditor(text: $viewModel.content)
                        .font(.custom("Caveat", size: 18))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .scrollContentBackground(.hidden) // Hide TextEditor's default background
                        .background(Color.clear)
                        .focused($isContentFocused)
                        .frame(maxWidth: .infinity, minHeight: 200)
                }
                .frame(maxWidth: .infinity)
                
                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Dismiss keyboard when tapping on the spacer area
                        isContentFocused = false
                    }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .navigationTitle(viewModel.existingNote != nil ? 
                            LocalizedString("Edit Note", comment: "Edit note title") :
                            LocalizedString("Write a Note to Self", comment: "Write note title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text(LocalizedString("Cancel", comment: "Cancel button"))
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            let success = await viewModel.saveNote()
                            if success {
                                onSave()
                                dismiss()
                            }
                        }
                    }) {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text(LocalizedString("Save", comment: "Save button"))
                                .foregroundColor(.primary)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(viewModel.isSaving || viewModel.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                // Focus text editor after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isContentFocused = true
                }
            }
        }
    }
}

#Preview {
    WriteNoteView(recipeID: "123")
}


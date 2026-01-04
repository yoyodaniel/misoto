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
            VStack(spacing: 20) {
                // Text Editor
                TextEditor(text: $viewModel.content)
                    .font(.system(size: 16))
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .focused($isContentFocused)
                    .frame(minHeight: 200)
                
                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle(viewModel.existingNote != nil ? 
                            LocalizedString("Edit Note", comment: "Edit note title") :
                            LocalizedString("Write Note", comment: "Write note title"))
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


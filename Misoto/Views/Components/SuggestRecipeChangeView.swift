//
//  SuggestRecipeChangeView.swift
//  Misoto
//
//  Sheet for submitting a structured change suggestion while viewing a recipe.
//

import SwiftUI

struct RecipeChangeProposalDraft: Identifiable, Equatable {
    let id = UUID()
    let targetKind: RecipeChangeProposal.TargetKind
    let targetIndex: Int?
    let contextTitle: String
    let contextSnapshot: String
    
    static func == (lhs: RecipeChangeProposalDraft, rhs: RecipeChangeProposalDraft) -> Bool {
        lhs.id == rhs.id
    }
}

struct SuggestRecipeChangeView: View {
    let draft: RecipeChangeProposalDraft
    let onSubmit: (String) async -> String?
    
    @Environment(\.dismiss) private var dismiss
    @State private var proposalText: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @FocusState private var editorFocused: Bool
    
    private let maxLength = 1_000
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(draft.contextTitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(draft.contextSnapshot)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedString("Your suggested change", comment: "Proposal editor label"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        ZStack(alignment: .topLeading) {
                            if proposalText.isEmpty {
                                Text(LocalizedString("Describe what you would change and why…", comment: "Proposal placeholder"))
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary.opacity(0.55))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 14)
                            }
                            
                            TextEditor(text: $proposalText)
                                .font(.system(size: 16))
                                .lineSpacing(4)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .frame(minHeight: 160)
                                .focused($editorFocused)
                                .onChange(of: proposalText) { _, newValue in
                                    if newValue.count > maxLength {
                                        proposalText = String(newValue.prefix(maxLength))
                                    }
                                }
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        HStack {
                            Spacer()
                            Text("\(proposalText.count)/\(maxLength)")
                                .font(.system(size: 12))
                                .foregroundColor(proposalText.count >= maxLength ? .red : .secondary)
                        }
                    }
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                }
                .padding(20)
            }
            .navigationTitle(LocalizedString("Suggest a change", comment: "Suggest change sheet title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedString("Cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task { await submit() }
                    }) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text(LocalizedString("Send", comment: "Send suggestion button"))
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .disabled(isSubmitting || proposalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                editorFocused = true
            }
        }
    }
    
    private func submit() async {
        let trimmed = proposalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        isSubmitting = true
        errorMessage = nil
        HapticFeedback.importantAction()
        
        let err = await onSubmit(trimmed)
        isSubmitting = false
        
        if let err {
            errorMessage = err
        } else {
            HapticFeedback.play(.success)
            dismiss()
        }
    }
}

#if DEBUG
#Preview {
    SuggestRecipeChangeView(
        draft: RecipeChangeProposalDraft(
            targetKind: .ingredient,
            targetIndex: 0,
            contextTitle: LocalizedString("Ingredient", comment: "Preview"),
            contextSnapshot: "2 cups flour"
        ),
        onSubmit: { _ in nil }
    )
}
#endif

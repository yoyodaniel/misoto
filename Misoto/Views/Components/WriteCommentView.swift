//
//  WriteCommentView.swift
//  Misoto
//
//  Created by Daniel Chan on 14.02.2026.
//

import SwiftUI

struct WriteCommentView: View {
    let recipeID: String
    let existingComment: RecipeComment?
    let onSubmit: (String, Int) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var content: String = ""
    @State private var rating: Int = 0
    @FocusState private var isTextFieldFocused: Bool
    
    private let characterLimit = 250
    
    init(recipeID: String, existingComment: RecipeComment? = nil, onSubmit: @escaping (String, Int) -> Void) {
        self.recipeID = recipeID
        self.existingComment = existingComment
        self.onSubmit = onSubmit
        
        if let existing = existingComment {
            _content = State(initialValue: existing.content)
            _rating = State(initialValue: existing.rating)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // Star Rating
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedString("Rating", comment: "Rating label"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: {
                                HapticFeedback.buttonTap()
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    if rating == star {
                                        rating = 0 // Tap again to deselect
                                    } else {
                                        rating = star
                                    }
                                }
                            }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.system(size: 28))
                                    .foregroundColor(star <= rating ? .orange : .secondary.opacity(0.3))
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Spacer()
                        
                        if rating > 0 {
                            Text(ratingLabel)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .transition(.opacity)
                        }
                    }
                }
                
                // Comment Text
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedString("Your Review", comment: "Review text label"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text(LocalizedString("Share your thoughts about this recipe...", comment: "Review placeholder"))
                                .font(.custom("Caveat", size: 16))
                                .foregroundColor(.secondary.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                        }
                        
                        TextEditor(text: $content)
                            .font(.custom("Caveat", size: 16))
                            .lineSpacing(4)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .frame(minHeight: 100, maxHeight: 150)
                            .focused($isTextFieldFocused)
                            .onChange(of: content) { _, newValue in
                                if newValue.count > characterLimit {
                                    content = String(newValue.prefix(characterLimit))
                                }
                            }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Character count
                    HStack {
                        Spacer()
                        Text("\(content.count)/\(characterLimit)")
                            .font(.system(size: 12))
                            .foregroundColor(content.count >= characterLimit ? .red : .secondary)
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle(existingComment != nil ? LocalizedString("Edit Review", comment: "Edit review title") : LocalizedString("Write a Review", comment: "Write review title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedString("Cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticFeedback.importantAction()
                        onSubmit(content.trimmingCharacters(in: .whitespacesAndNewlines), rating)
                        dismiss()
                    }) {
                        Text(existingComment != nil ? LocalizedString("Update", comment: "Update button") : LocalizedString("Post", comment: "Post button"))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
    
    private var ratingLabel: String {
        switch rating {
        case 1: return LocalizedString("Poor", comment: "Rating 1 star")
        case 2: return LocalizedString("Fair", comment: "Rating 2 stars")
        case 3: return LocalizedString("Good", comment: "Rating 3 stars")
        case 4: return LocalizedString("Very Good", comment: "Rating 4 stars")
        case 5: return LocalizedString("Excellent", comment: "Rating 5 stars")
        default: return ""
        }
    }
}

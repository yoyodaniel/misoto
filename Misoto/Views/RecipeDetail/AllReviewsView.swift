//
//  AllReviewsView.swift
//  Misoto
//
//  Created by Daniel Chan on 14.02.2026.
//

import SwiftUI
import FirebaseAuth

struct AllReviewsView: View {
    @ObservedObject var viewModel: RecipeDetailViewModel
    @Binding var showLoginSheet: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var showWriteComment = false
    @State private var commentToEdit: RecipeComment?
    @State private var commentToDelete: RecipeComment?
    @State private var showDeleteConfirmation = false
    
    private var isAuthor: Bool {
        guard let userID = Auth.auth().currentUser?.uid else { return false }
        return viewModel.recipe.authorID == userID
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.comments.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text(LocalizedString("No reviews yet. Be the first to share your thoughts!", comment: "No reviews placeholder"))
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Average rating summary
                            if viewModel.ratingCount > 0 {
                                HStack(spacing: 12) {
                                    VStack(spacing: 4) {
                                        Text(String(format: "%.1f", viewModel.averageRating))
                                            .font(.system(size: 36, weight: .bold))
                                            .foregroundColor(.primary)
                                        
                                        HStack(spacing: 2) {
                                            ForEach(1...5, id: \.self) { star in
                                                Image(systemName: star <= Int(viewModel.averageRating.rounded()) ? "star.fill" : (Double(star) - 0.5 <= viewModel.averageRating ? "star.leadinghalf.filled" : "star"))
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.orange)
                                            }
                                        }
                                        
                                        Text(String(format: LocalizedString("%d reviews", comment: "Review count"), viewModel.commentCount))
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .padding(.horizontal, 20)
                            }
                            
                            // All comments
                            ForEach(viewModel.comments) { comment in
                                reviewCard(comment)
                                    .padding(.horizontal, 20)
                            }
                            
                            // Load More
                            if viewModel.hasMoreComments {
                                Button(action: {
                                    HapticFeedback.buttonTap()
                                    Task {
                                        await viewModel.loadMoreComments()
                                    }
                                }) {
                                    HStack {
                                        if viewModel.isLoadingMoreComments {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle())
                                        } else {
                                            Text(LocalizedString("Load More", comment: "Load more button"))
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(12)
                                }
                                .disabled(viewModel.isLoadingMoreComments)
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle(LocalizedString("Reviews", comment: "Reviews section header"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text(LocalizedString("Close", comment: "Close button"))
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if Auth.auth().currentUser != nil && viewModel.existingUserComment == nil && !isAuthor {
                        Button(action: {
                            commentToEdit = nil
                            showWriteComment = true
                        }) {
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showWriteComment) {
                WriteCommentView(
                    recipeID: viewModel.recipe.id,
                    existingComment: commentToEdit
                ) { content, rating in
                    Task {
                        if let existing = commentToEdit {
                            await viewModel.updateComment(comment: existing, content: content, rating: rating)
                        } else {
                            await viewModel.submitComment(content: content, rating: rating)
                        }
                        commentToEdit = nil
                    }
                }
                .presentationDetents([.medium])
            }
            .alert(
                LocalizedString("Delete Review", comment: "Delete review confirmation title"),
                isPresented: $showDeleteConfirmation
            ) {
                Button(LocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {
                    commentToDelete = nil
                }
                Button(LocalizedString("Delete", comment: "Delete button"), role: .destructive) {
                    if let comment = commentToDelete {
                        Task {
                            await viewModel.deleteComment(comment)
                            commentToDelete = nil
                        }
                    }
                }
            } message: {
                Text(LocalizedString("Are you sure you want to delete this review? This action cannot be undone.", comment: "Delete review confirmation message"))
            }
        }
    }
    
    private func reviewCard(_ comment: RecipeComment) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Profile photo, name, time
            HStack(alignment: .top, spacing: 10) {
                // Profile photo
                if let imageURL = comment.profileImageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.secondary)
                        .frame(width: 36, height: 36)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if let username = comment.username, !username.isEmpty {
                        Text("@\(username)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(comment.timeAgo)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            // Star rating
            if comment.rating > 0 {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= comment.rating ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(star <= comment.rating ? .orange : .secondary.opacity(0.3))
                    }
                }
            }
            
            // Comment text (using Caveat font, same as notes)
            Text(comment.content)
                .font(.custom("Caveat", size: 16))
                .foregroundColor(.primary)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .contextMenu {
            if comment.userID == Auth.auth().currentUser?.uid {
                Button(action: {
                    HapticFeedback.buttonTap()
                    commentToEdit = comment
                    showWriteComment = true
                }) {
                    Label(LocalizedString("Edit", comment: "Edit button"), systemImage: "pencil")
                }
                
                Button(role: .destructive, action: {
                    HapticFeedback.buttonTap()
                    commentToDelete = comment
                    showDeleteConfirmation = true
                }) {
                    Label(LocalizedString("Delete", comment: "Delete button"), systemImage: "trash")
                }
            }
        }
    }
}

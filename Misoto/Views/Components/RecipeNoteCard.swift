//
//  RecipeNoteCard.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

struct RecipeNoteCard: View {
    let note: RecipeNote
    let canEdit: Bool
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.userName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(formatDate(note.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if canEdit {
                    Menu {
                        if let onEdit = onEdit {
                            Button(action: onEdit) {
                                Label(LocalizedString("Edit", comment: "Edit button"), systemImage: "pencil")
                            }
                        }
                        
                        if let onDelete = onDelete {
                            Button(role: .destructive, action: onDelete) {
                                Label(LocalizedString("Delete", comment: "Delete button"), systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .padding(8)
                    }
                }
            }
            
            // Content
            Text(note.content)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    RecipeNoteCard(
        note: RecipeNote(
            recipeID: "123",
            userID: "user1",
            userName: "John Doe",
            content: "This recipe is amazing! I added a bit more salt and it turned out perfect."
        ),
        canEdit: true,
        onEdit: {},
        onDelete: {}
    )
    .padding()
}


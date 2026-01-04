//
//  RelatedRecipeCard.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

struct RelatedRecipeCard: View {
    let recipe: Recipe
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            if let imageURL = recipe.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            ProgressView()
                        }
                }
                .frame(height: 150)
                .clipped()
                .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 150)
                    .cornerRadius(12)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 30))
                            .foregroundColor(.secondary)
                    }
            }
            
            // Title
            Text(recipe.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    RelatedRecipeCard(
        recipe: Recipe(
            title: "软!糯!鲜!香!粉蒸排骨",
            description: "A delicious dish",
            ingredients: [],
            instructions: [],
            prepTime: 15,
            cookTime: 30,
            servings: 2,
            difficulty: .a,
            authorID: "123",
            authorName: "Chef"
        ),
        onTap: {}
    )
    .frame(width: 150)
    .padding()
}


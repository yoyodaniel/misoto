//
//  RecipeCard.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import FirebaseAuth

struct RecipeCard: View {
    let recipe: Recipe
    @StateObject private var recipeService = RecipeService()
    @State private var isFavorite = false
    @State private var isLoadingFavorite = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder
            if let imageURL = recipe.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        }
                }
                .frame(height: 200)
                .clipped()
                .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                    }
                    .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(recipe.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(recipe.prepTime + recipe.cookTime) min", systemImage: "clock")
                    Label("\(recipe.servings)", systemImage: "person.2")
                    Label(recipe.difficulty.rawValue, systemImage: "chart.bar")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                HStack {
                    Text(recipe.authorName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(isFavorite ? .red : .secondary)
                        Text("\(recipe.favoriteCount)")
                            .font(.caption)
                    }
                    .onTapGesture {
                        toggleFavorite()
                    }
                    .disabled(isLoadingFavorite)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .task {
            await checkFavoriteStatus()
        }
    }
    
    private func checkFavoriteStatus() async {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        
        do {
            isFavorite = try await recipeService.isFavorite(recipeID: recipe.id, userID: userID)
        } catch {
            // Silently fail
        }
    }
    
    private func toggleFavorite() {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        
        isLoadingFavorite = true
        
        Task {
            do {
                if isFavorite {
                    try await recipeService.removeFavorite(recipeID: recipe.id, userID: userID)
                    isFavorite = false
                } else {
                    try await recipeService.addFavorite(recipeID: recipe.id, userID: userID)
                    isFavorite = true
                }
            } catch {
                // Silently fail
            }
            
            isLoadingFavorite = false
        }
    }
}

#Preview {
    RecipeCard(recipe: Recipe(
        title: "Delicious Pasta",
        description: "A classic Italian pasta dish",
        ingredients: ["Pasta", "Tomato", "Garlic"],
        instructions: [
            Instruction(text: "Boil water"),
            Instruction(text: "Cook pasta"),
            Instruction(text: "Add sauce")
        ],
        prepTime: 10,
        cookTime: 20,
        servings: 4,
        difficulty: .c,
        authorID: "123",
        authorName: "Chef John"
    ))
    .padding()
}


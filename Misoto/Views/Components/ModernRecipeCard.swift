//
//  ModernRecipeCard.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import FirebaseAuth

struct ModernRecipeCard: View {
    let recipe: Recipe
    @StateObject private var recipeService = RecipeService()
    @State private var isFavorite = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Large Image
            ZStack(alignment: .bottomLeading) {
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
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)
                            }
                    }
                    .frame(height: 280)
                    .clipped()
                } else {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 280)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.6))
                        }
                }
                
                // Favorite Button Overlay
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            toggleFavorite()
                        }) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .padding(16)
                    }
                    Spacer()
                }
                
                // Title Overlay
                VStack(alignment: .leading) {
                    Spacer()
                    Text(recipe.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .shadow(color: Color.black.opacity(0.5), radius: 4, x: 0, y: 2)
                }
            }
            
            // Recipe Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("\(recipe.prepTime + recipe.cookTime) min", systemImage: "clock")
                    Spacer()
                    Label("\(recipe.servings)", systemImage: "person.2")
                    Spacer()
                    Label(recipe.difficulty.rawValue, systemImage: "chart.bar")
                }
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                
                if !recipe.description.isEmpty {
                    Text(recipe.description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
        }
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .task {
            await checkFavoriteStatus()
        }
    }
    
    private func checkFavoriteStatus() async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        do {
            isFavorite = try await recipeService.isFavorite(recipeID: recipe.id, userID: userID)
        } catch {
            // Silently fail
        }
    }
    
    private func toggleFavorite() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
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
        }
    }
}

#Preview {
    ModernRecipeCard(recipe: Recipe(
        title: "Fresh & Firm! Salt-Baked Crab & Shrimp",
        description: "A delicious seafood dish with perfect texture",
        ingredients: [
            Ingredient(amount: "", unit: "", name: "Sea salt", category: .dish),
            Ingredient(amount: "", unit: "", name: "Crabs", category: .dish),
            Ingredient(amount: "", unit: "", name: "Shrimp", category: .dish)
        ],
        instructions: [
            Instruction(text: "Prepare ingredients"),
            Instruction(text: "Bake with salt")
        ],
        prepTime: 15,
        cookTime: 30,
        servings: 2,
        difficulty: .a,
        authorID: "123",
        authorName: "Chef"
    ))
    .padding()
}


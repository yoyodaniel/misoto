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
            // Large Image with Overlays - Rounded Square
            GeometryReader { geometry in
                let squareSize = geometry.size.width
                
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
                        .frame(width: squareSize, height: squareSize)
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
                            .frame(width: squareSize, height: squareSize)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                    }
                    
                    // Gradient overlay for better text readability
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: squareSize, height: squareSize)
                    
                    // Favorite Button in Top Right
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                toggleFavorite()
                            }) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 16)
                            .padding(.top, 16)
                        }
                        Spacer()
                    }
                    
                    // Text Overlay - Primary and Secondary Titles
                    VStack(alignment: .leading, spacing: 4) {
                        Spacer()
                        
                        // Primary Title (larger, white with shadow)
                        Text(primaryTitle)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.leading, 20)
                            .padding(.trailing, 20)
                            .shadow(color: Color.black.opacity(0.5), radius: 3, x: 0, y: 2)
                        
                        // Secondary Title (smaller, white with shadow)
                        if let secondaryTitle = secondaryTitle, !secondaryTitle.isEmpty {
                            Text(secondaryTitle)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.leading, 20)
                                .padding(.trailing, 20)
                                .shadow(color: Color.black.opacity(0.5), radius: 3, x: 0, y: 2)
                        }
                        
                        // Author Caption
                        if !recipe.authorName.isEmpty {
                            HStack(spacing: 4) {
                                Text(LocalizedString("by", comment: "Author by prefix"))
                                    .font(.caption)
                                Text(recipe.authorName)
                                    .font(.custom("Caveat", size: 16))
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.leading, 20)
                            .padding(.trailing, 20)
                            .padding(.top, 4)
                            .shadow(color: Color.black.opacity(0.5), radius: 3, x: 0, y: 2)
                        }
                        
                        // Bottom padding
                        Spacer()
                            .frame(height: 16)
                    }
                }
                .cornerRadius(16)
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
        .task {
            await checkFavoriteStatus()
        }
    }
    
    // MARK: - Computed Properties
    
    /// Primary title to display (large text) - Show local system language or English based on settings
    private var primaryTitle: String {
        let currentLanguage = LocalizationManager.shared.currentLanguage
        
        // If user is using English, show English title as primary
        if currentLanguage == .english {
            return recipe.titleEnglish ?? recipe.title
        } else {
            // If user is using system language, show local title as primary
            return recipe.titleLocal ?? recipe.titleEnglish ?? recipe.title
        }
    }
    
    /// Secondary title to display (small text) - Show original language name
    private var secondaryTitle: String? {
        // Show original language as secondary if it exists and is different from primary
        if let titleOriginal = recipe.titleOriginal,
           !titleOriginal.isEmpty,
           titleOriginal != primaryTitle {
            return titleOriginal
        }
        return nil
    }
    
    private var titleColor: Color {
        // Use different colors based on recipe characteristics
        // You can customize this based on cuisine, spicy level, etc.
        if recipe.spicyLevel.rawValue >= 3 {
            return Color.red
        } else if recipe.cuisine?.lowercased().contains("curry") == true {
            return Color.orange
        } else {
            return Color.yellow
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


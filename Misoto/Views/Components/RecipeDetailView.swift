//
//  RecipeDetailView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import FirebaseAuth

struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    private let recipeService = RecipeService.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var isFavorite = false
    @State private var isLoadingFavorite = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
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
                                    Image(systemName: "photo")
                                        .foregroundColor(.secondary)
                                }
                        }
                        .frame(height: 300)
                        .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 300)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Title and Author
                        VStack(alignment: .leading, spacing: 8) {
                            Text(recipe.title)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text(LocalizedString("By \(recipe.authorName)", comment: "Recipe author"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Chef Section
                        ChefSectionView(
                            creatorID: recipe.authorID,
                            creatorName: recipe.authorName,
                            creatorUsername: recipe.authorUsername
                        )
                        
                        // Stats
                        HStack(spacing: 20) {
                            Label("\(recipe.prepTime) \(LocalizedString("min", comment: "Minutes abbreviation"))", systemImage: "timer")
                            Label("\(recipe.cookTime) \(LocalizedString("min", comment: "Minutes abbreviation"))", systemImage: "flame")
                            Label("\(recipe.servings)", systemImage: "person.2")
                            Label(recipe.difficulty.rawValue, systemImage: "chart.bar")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        
                        Divider()
                        
                        // Description
                        if !recipe.description.isEmpty {
                            Text(recipe.description)
                                .font(.body)
                        }
                        
                        Divider()
                        
                        // Ingredients
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("Ingredients", comment: "Ingredients section"))
                                .font(.headline)
                            
                            ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 6))
                                        .foregroundColor(.accentColor)
                                        .padding(.top, 6)
                                    Text(ingredient.displayString)
                                        .font(.body)
                                }
                            }
                            .id(localizationManager.currentLanguage)
                        }
                        
                        Divider()
                        
                        // Instructions
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("Instructions", comment: "Instructions section"))
                                .font(.headline)
                            
                            ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top, spacing: 12) {
                                        Text("\(index + 1).")
                                            .font(.headline)
                                            .foregroundColor(.accentColor)
                                            .frame(width: 30, alignment: .leading)
                                        Text(instruction.text)
                                            .font(.body)
                                    }
                                    
                                    // Instruction Image
                                    if let imageURL = instruction.imageURL, let url = URL(string: imageURL) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .frame(height: 150)
                                        .clipped()
                                        .cornerRadius(8)
                                    }
                                    
                                    // Instruction Video
                                    if let videoURL = instruction.videoURL, let url = URL(string: videoURL) {
                                        Link(destination: url) {
                                            HStack {
                                                Image(systemName: "play.circle.fill")
                                                Text(LocalizedString("Watch Video", comment: "Watch video link"))
                                            }
                                            .foregroundColor(.accentColor)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        toggleFavorite()
                    }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : .primary)
                    }
                    .disabled(isLoadingFavorite)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedString("Close", comment: "Close button")) {
                        dismiss()
                    }
                }
            }
            .task {
                await checkFavoriteStatus()
            }
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
        
        // Update state optimistically for immediate UI feedback
        let wasFavorite = isFavorite
        isFavorite.toggle()
        isLoadingFavorite = true
        
        Task {
            do {
                if wasFavorite {
                    try await recipeService.removeFavorite(recipeID: recipe.id, userID: userID)
                } else {
                    try await recipeService.addFavorite(recipeID: recipe.id, userID: userID)
                }
            } catch {
                // Revert state on error
                isFavorite = wasFavorite
                print("⚠️ Error toggling favorite: \(error.localizedDescription)")
            }
            
            isLoadingFavorite = false
        }
    }
}

#Preview {
    RecipeDetailView(recipe: Recipe(
        title: "Delicious Pasta",
        description: "A classic Italian pasta dish that's perfect for any occasion.",
        ingredients: [
            Ingredient(amount: "500", unit: "g", name: "pasta", category: .dish),
            Ingredient(amount: "400", unit: "g", name: "tomatoes", category: .dish),
            Ingredient(amount: "3", unit: "cloves", name: "garlic", category: .dish),
            Ingredient(amount: "", unit: "", name: "Olive oil", category: .dish),
            Ingredient(amount: "", unit: "", name: "Salt and pepper", category: .seasoning)
        ],
        instructions: [
            Instruction(text: "Bring a large pot of salted water to a boil"),
            Instruction(text: "Add pasta and cook according to package instructions"),
            Instruction(text: "Heat olive oil in a pan and sauté garlic"),
            Instruction(text: "Add tomatoes and cook until soft"),
            Instruction(text: "Drain pasta and mix with sauce"),
            Instruction(text: "Season with salt and pepper to taste")
        ],
        prepTime: 10,
        cookTime: 20,
        servings: 4,
        difficulty: .c,
        authorID: "123",
        authorName: "Chef John"
    ))
}


//
//  ModernRecipeDetailView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import FirebaseAuth

struct ModernRecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recipeService = RecipeService()
    @State private var isFavorite = false
    @State private var currentStep = 0
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deleteError: String?
    
    private var isAuthor: Bool {
        guard let userID = FirebaseAuth.Auth.auth().currentUser?.uid else { return false }
        return recipe.authorID == userID
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // Full Screen Image/Video Area
                        ZStack(alignment: .top) {
                            if let imageURL = recipe.imageURL, let url = URL(string: imageURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
                                .clipped()
                            } else {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.3)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
                                    .overlay {
                                        Image(systemName: "photo")
                                            .font(.system(size: 60))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                            }
                            
                            // Overlay Gradient
                            LinearGradient(
                                colors: [Color.clear, Color.black.opacity(0.7)],
                                startPoint: .center,
                                endPoint: .bottom
                            )
                            .frame(height: geometry.size.height * 0.6)
                            
                            // Top Bar
                            VStack {
                                HStack {
                                    Button(action: { dismiss() }) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(12)
                                            .background(Color.black.opacity(0.4))
                                            .clipShape(Circle())
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 12) {
                                        // Delete button (only show if user is author)
                                        if isAuthor {
                                            Button(action: {
                                                showDeleteConfirmation = true
                                            }) {
                                                Image(systemName: "trash")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.white)
                                                    .padding(12)
                                                    .background(Color.red.opacity(0.7))
                                                    .clipShape(Circle())
                                            }
                                        }
                                        
                                        Button(action: { toggleFavorite() }) {
                                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                                .font(.system(size: 20))
                                                .foregroundColor(isFavorite ? .red : .white)
                                                .padding(12)
                                                .background(Color.black.opacity(0.4))
                                                .clipShape(Circle())
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                
                                Spacer()
                                
                                // Title Overlay
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(recipe.title)
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    HStack(spacing: 16) {
                                        Label("\(recipe.prepTime + recipe.cookTime) min", systemImage: "clock")
                                            .font(.system(size: 14))
                                        Label("\(recipe.servings)", systemImage: "person.2")
                                            .font(.system(size: 14))
                                        Label(recipe.difficulty.rawValue, systemImage: "chart.bar")
                                            .font(.system(size: 14))
                                    }
                                    .foregroundColor(.white.opacity(0.9))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 24)
                            }
                        }
                        .frame(height: geometry.size.height * 0.6)
                        
                        // Content Section
                        VStack(alignment: .leading, spacing: 24) {
                            // Ingredients Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text(NSLocalizedString("Ingredients for \(recipe.servings) servings", comment: "Ingredients header"))
                                    .font(.system(size: 20, weight: .bold))
                                
                                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                                    HStack(alignment: .top, spacing: 12) {
                                        Circle()
                                            .fill(Color.accentColor)
                                            .frame(width: 6, height: 6)
                                            .padding(.top, 8)
                                        
                                        Text(ingredient.displayString)
                                            .font(.system(size: 16))
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(16)
                            
                            // Instructions Section
                            VStack(alignment: .leading, spacing: 20) {
                                Text(NSLocalizedString("Steps", comment: "Steps header"))
                                    .font(.system(size: 20, weight: .bold))
                                
                                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack(alignment: .top, spacing: 16) {
                                            Text("\(index + 1)")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(width: 32, height: 32)
                                                .background(Color.accentColor)
                                                .clipShape(Circle())
                                            
                                            Text(instruction.text)
                                                .font(.system(size: 16))
                                                .lineSpacing(4)
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
                                            .frame(height: 200)
                                            .clipped()
                                            .cornerRadius(12)
                                        }
                                        
                                        // Instruction Video
                                        if let videoURL = instruction.videoURL, let url = URL(string: videoURL) {
                                            // Video player would go here
                                            Link(destination: url) {
                                                HStack {
                                                    Image(systemName: "play.circle.fill")
                                                    Text(NSLocalizedString("Watch Video", comment: "Watch video link"))
                                                }
                                                .foregroundColor(.accentColor)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            .padding(20)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(16)
                            
                            // Description
                            if !recipe.description.isEmpty {
                                Text(recipe.description)
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                    .padding(20)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(16)
                            }
                        }
                        .padding(20)
                        .background(Color(.systemBackground))
                        .cornerRadius(24, corners: [.topLeft, .topRight])
                        .offset(y: -24)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await checkFavoriteStatus()
        }
        .confirmationDialog(
            NSLocalizedString("Delete Recipe", comment: "Delete confirmation title"),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(NSLocalizedString("Delete", comment: "Delete button"), role: .destructive) {
                Task {
                    await deleteRecipe()
                }
            }
            Button(NSLocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {}
        } message: {
            Text(NSLocalizedString("Are you sure you want to delete this recipe? This action cannot be undone.", comment: "Delete confirmation message"))
        }
        .alert("Error", isPresented: .constant(deleteError != nil)) {
            Button("OK", role: .cancel) {
                deleteError = nil
            }
        } message: {
            if let error = deleteError {
                Text(error)
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
    
    private func deleteRecipe() async {
        guard isAuthor else { return }
        
        isDeleting = true
        deleteError = nil
        
        do {
            try await recipeService.deleteRecipe(recipeID: recipe.id)
            // Dismiss the view after successful deletion
            dismiss()
        } catch {
            deleteError = error.localizedDescription
            print("❌ Error deleting recipe: \(error.localizedDescription)")
        }
        
        isDeleting = false
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ModernRecipeDetailView(recipe: Recipe(
        title: "Fresh & Firm! Salt-Baked Crab & Shrimp",
        description: "A delicious seafood dish with perfect texture and flavor",
        ingredients: [
            Ingredient(amount: "500", unit: "g", name: "Sea salt", category: .dish),
            Ingredient(amount: "4", unit: "pieces", name: "Crabs", category: .dish),
            Ingredient(amount: "500", unit: "g", name: "Shrimp", category: .dish)
        ],
        instructions: [
            Instruction(text: "Prepare a non-stick wok or pot"),
            Instruction(text: "Add coarse sea salt and heat"),
            Instruction(text: "Place crabs and shrimp on the salt"),
            Instruction(text: "Cover and cook for 20 minutes"),
            Instruction(text: "Serve hot with your favorite dipping sauce")
        ],
        prepTime: 15,
        cookTime: 30,
        servings: 2,
        difficulty: .a,
        authorID: "123",
        authorName: "Chef"
    ))
}


//
//  RecipeStepView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

struct RecipeStepView: View {
    @StateObject private var viewModel: RecipeStepViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showWriteNote = false
    @State private var showRelatedRecipes = false
    
    init(recipe: Recipe, initialStepIndex: Int = 0) {
        _viewModel = StateObject(wrappedValue: RecipeStepViewModel(recipe: recipe, initialStepIndex: initialStepIndex))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Step Header
                    Text(LocalizedString("Step", comment: "Step label") + " \(viewModel.stepNumber)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Video/Image Thumbnail
                    if let currentStep = viewModel.currentStep {
                        StepVideoThumbnail(
                            imageURL: currentStep.imageURL,
                            videoURL: currentStep.videoURL,
                            onPlayTapped: {
                                if let videoURL = currentStep.videoURL, let url = URL(string: videoURL) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        )
                        .padding(.horizontal, 20)
                        
                        // Instruction Text
                        Text(currentStep.text)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                            .padding(.horizontal, 20)
                    }
                    
                    // Action Buttons
                    RecipeActionButtons(
                        isFavorite: viewModel.isFavorite,
                        onFavoriteTapped: {
                            Task {
                                await viewModel.toggleFavorite()
                            }
                        },
                        onWriteNoteTapped: {
                            showWriteNote = true
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Next Step Indicator
                    if viewModel.hasNextStep {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedString("Step", comment: "Step label") + " \(viewModel.stepNumber + 1)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if viewModel.hasPreviousStep {
                            viewModel.previousStep()
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showRelatedRecipes = true
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("\(viewModel.stepNumber) / \(viewModel.totalSteps)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .task {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showWriteNote) {
                WriteNoteView(recipeID: viewModel.recipe.id)
            }
            .sheet(isPresented: $showRelatedRecipes) {
                RelatedRecipesView(recipe: viewModel.recipe)
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width > 100 && viewModel.hasPreviousStep {
                            viewModel.previousStep()
                        } else if value.translation.width < -100 && viewModel.hasNextStep {
                            viewModel.nextStep()
                        }
                    }
            )
        }
    }
}

#Preview {
    RecipeStepView(recipe: Recipe(
        title: "Test Recipe",
        description: "Test",
        ingredients: [],
        instructions: [
            Instruction(text: "热锅喷油,挤两根日本豆腐切成小块,摇晃 均匀,打入四颗鸡蛋,再放占虾仁", imageURL: nil, videoURL: nil),
            Instruction(text: "再来一包韩餐店同款铁板鱿鱼酱", imageURL: nil, videoURL: nil)
        ],
        prepTime: 5,
        cookTime: 10,
        servings: 1,
        difficulty: .c,
        authorID: "123",
        authorName: "Chef"
    ))
}


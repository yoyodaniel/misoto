//
//  EditRecipeView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import PhotosUI

struct EditRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditRecipeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedRecipePhotos: [PhotosPickerItem] = []
    @State private var showCuisineSelection = false
    @State private var showFullScreenImage = false
    @State private var fullScreenImage: UIImage?
    @State private var selectedInstructionPhotos: [Int: PhotosPickerItem] = [:]
    @State private var showingImagePickerForIndex: Int? = nil
    @State private var showDishImageOptions = false
    @State private var showCameraForDishImage = false
    @State private var showPhotoPickerForDishImage = false
    
    @FocusState private var focusedAmountField: Int?
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    @FocusState private var focusedIngredientNameField: Int?
    @FocusState private var focusedInstructionField: Int?
    
    init(recipe: Recipe) {
        _viewModel = StateObject(wrappedValue: EditRecipeViewModel(recipe: recipe))
    }
    
    // Dismiss keyboard
    private func dismissKeyboard() {
        // Clear all focus states
        focusedAmountField = nil
        isTitleFocused = false
        isDescriptionFocused = false
        focusedIngredientNameField = nil
        focusedInstructionField = nil
        
        // Dismiss keyboard using window's endEditing method (more reliable)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.endEditing(true)
        } else {
            // Fallback method
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    var body: some View {
        NavigationView {
            makeRecipeForm()
                .sheet(isPresented: $showCuisineSelection) {
                    CuisineSelectionView(selectedCuisine: $viewModel.cuisine)
                }
                .navigationTitle(LocalizedString("Edit Recipe", comment: "Edit recipe title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button(LocalizedString("Done", comment: "Done button")) {
                            dismissKeyboard()
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(LocalizedString("Cancel", comment: "Cancel button")) {
                            HapticFeedback.buttonTap()
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            HapticFeedback.importantAction()
                            dismissKeyboard()
                            Task {
                                let success = await viewModel.updateRecipe()
                                if success {
                                    HapticFeedback.play(.success)
                                    await authViewModel.reloadUserData()
                                    dismiss()
                                } else {
                                    HapticFeedback.play(.error)
                                }
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                Text(LocalizedString("Save", comment: "Save button"))
                            }
                        }
                        .disabled(viewModel.isLoading || viewModel.title.isEmpty)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: selectedRecipePhotos) { oldValue, newItems in
                    Task {
                        for item in newItems {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                viewModel.addRecipeImage(image)
                            }
                        }
                        selectedRecipePhotos = []
                    }
                }
                .confirmationDialog("Add Dish Image", isPresented: $showDishImageOptions, titleVisibility: .visible) {
                    Button("Take picture") {
                        showCameraForDishImage = true
                    }
                    Button("Select image") {
                        showPhotoPickerForDishImage = true
                    }
                    Button("Cancel", role: .cancel) {}
                }
                .fullScreenCover(isPresented: $showCameraForDishImage) {
                    CameraCaptureView(onImageCaptured: { image in
                        viewModel.addRecipeImage(image)
                        showCameraForDishImage = false
                    })
                }
        }
    }
    
    @ViewBuilder
    private func makeRecipeForm() -> some View {
        let dishIngredientMethods = makeDishIngredientMethods()
        let marinadeIngredientMethods = makeMarinadeIngredientMethods()
        let seasoningIngredientMethods = makeSeasoningIngredientMethods()
        let batterIngredientMethods = makeBatterIngredientMethods()
        let sauceIngredientMethods = makeSauceIngredientMethods()
        let baseIngredientMethods = makeBaseIngredientMethods()
        let doughIngredientMethods = makeDoughIngredientMethods()
        let toppingIngredientMethods = makeToppingIngredientMethods()
        
        RecipeEditForm(
            title: $viewModel.title,
            description: $viewModel.description,
            cuisine: $viewModel.cuisine,
            prepTime: $viewModel.prepTime,
            cookTime: $viewModel.cookTime,
            servings: $viewModel.servings,
            difficulty: $viewModel.difficulty,
            spicyLevel: $viewModel.spicyLevel,
            tips: $viewModel.tips,
            dishIngredients: $viewModel.dishIngredients,
            marinadeIngredients: $viewModel.marinadeIngredients,
            seasoningIngredients: $viewModel.seasoningIngredients,
            batterIngredients: $viewModel.batterIngredients,
            sauceIngredients: $viewModel.sauceIngredients,
            baseIngredients: $viewModel.baseIngredients,
            doughIngredients: $viewModel.doughIngredients,
            toppingIngredients: $viewModel.toppingIngredients,
            mainRecipeImages: $viewModel.mainRecipeImages,
            isGeneratingDescription: viewModel.isGeneratingDescription,
            isDetectingCuisine: viewModel.isDetectingCuisine,
            errorMessage: viewModel.errorMessage,
            addDishIngredient: dishIngredientMethods.add,
            removeDishIngredient: dishIngredientMethods.remove,
            updateDishIngredientAmount: dishIngredientMethods.updateAmount,
            updateDishIngredientUnit: dishIngredientMethods.updateUnit,
            updateDishIngredientName: dishIngredientMethods.updateName,
            addMarinadeIngredient: marinadeIngredientMethods.add,
            removeMarinadeIngredient: marinadeIngredientMethods.remove,
            updateMarinadeIngredientAmount: marinadeIngredientMethods.updateAmount,
            updateMarinadeIngredientUnit: marinadeIngredientMethods.updateUnit,
            updateMarinadeIngredientName: marinadeIngredientMethods.updateName,
            addSeasoningIngredient: seasoningIngredientMethods.add,
            removeSeasoningIngredient: seasoningIngredientMethods.remove,
            updateSeasoningIngredientAmount: seasoningIngredientMethods.updateAmount,
            updateSeasoningIngredientUnit: seasoningIngredientMethods.updateUnit,
            updateSeasoningIngredientName: seasoningIngredientMethods.updateName,
            addBatterIngredient: batterIngredientMethods.add,
            removeBatterIngredient: batterIngredientMethods.remove,
            updateBatterIngredientAmount: batterIngredientMethods.updateAmount,
            updateBatterIngredientUnit: batterIngredientMethods.updateUnit,
            updateBatterIngredientName: batterIngredientMethods.updateName,
            addSauceIngredient: sauceIngredientMethods.add,
            removeSauceIngredient: sauceIngredientMethods.remove,
            updateSauceIngredientAmount: sauceIngredientMethods.updateAmount,
            updateSauceIngredientUnit: sauceIngredientMethods.updateUnit,
            updateSauceIngredientName: sauceIngredientMethods.updateName,
            addBaseIngredient: baseIngredientMethods.add,
            removeBaseIngredient: baseIngredientMethods.remove,
            updateBaseIngredientAmount: baseIngredientMethods.updateAmount,
            updateBaseIngredientUnit: baseIngredientMethods.updateUnit,
            updateBaseIngredientName: baseIngredientMethods.updateName,
            addDoughIngredient: doughIngredientMethods.add,
            removeDoughIngredient: doughIngredientMethods.remove,
            updateDoughIngredientAmount: doughIngredientMethods.updateAmount,
            updateDoughIngredientUnit: doughIngredientMethods.updateUnit,
            updateDoughIngredientName: doughIngredientMethods.updateName,
            addToppingIngredient: toppingIngredientMethods.add,
            removeToppingIngredient: toppingIngredientMethods.remove,
            updateToppingIngredientAmount: toppingIngredientMethods.updateAmount,
            updateToppingIngredientUnit: toppingIngredientMethods.updateUnit,
            updateToppingIngredientName: toppingIngredientMethods.updateName,
            addRecipeImage: { image in
                viewModel.addRecipeImage(image)
            },
            removeRecipeImage: { index in
                viewModel.removeRecipeImage(at: index)
            },
            generateDescription: {
                await viewModel.generateDescription()
            },
            showCuisineSelection: $showCuisineSelection,
            showFullScreenImage: $showFullScreenImage,
            fullScreenImage: $fullScreenImage,
            selectedRecipePhotos: $selectedRecipePhotos,
            instructionsContent: {
                makeInstructionsContent()
            },
            optionalContent: {
                Group {
                    makeSourceSection()
                    makeDatesSection()
                }
            }
        )
        .sheet(isPresented: $showFullScreenImage) {
            if let image = fullScreenImage {
                ZoomableImageView(image: image)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .ignoresSafeArea(.all)
            }
        }
    }
    
    // Helper structs for ingredient methods
    private struct IngredientMethods {
        let add: () -> Void
        let remove: (Int) -> Void
        let updateAmount: (String, Int) -> Void
        let updateUnit: (String, Int) -> Void
        let updateName: (String, Int) -> Void
    }
    
    private func makeDishIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addDishIngredient() },
            remove: { viewModel.removeDishIngredient(at: $0) },
            updateAmount: { viewModel.updateDishIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateDishIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateDishIngredientName($0, at: $1) }
        )
    }
    
    private func makeMarinadeIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addMarinadeIngredient() },
            remove: { viewModel.removeMarinadeIngredient(at: $0) },
            updateAmount: { viewModel.updateMarinadeIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateMarinadeIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateMarinadeIngredientName($0, at: $1) }
        )
    }
    
    private func makeSeasoningIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addSeasoningIngredient() },
            remove: { viewModel.removeSeasoningIngredient(at: $0) },
            updateAmount: { viewModel.updateSeasoningIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateSeasoningIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateSeasoningIngredientName($0, at: $1) }
        )
    }
    
    private func makeBatterIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addBatterIngredient() },
            remove: { viewModel.removeBatterIngredient(at: $0) },
            updateAmount: { viewModel.updateBatterIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateBatterIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateBatterIngredientName($0, at: $1) }
        )
    }
    
    private func makeSauceIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addSauceIngredient() },
            remove: { viewModel.removeSauceIngredient(at: $0) },
            updateAmount: { viewModel.updateSauceIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateSauceIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateSauceIngredientName($0, at: $1) }
        )
    }
    
    private func makeBaseIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addBaseIngredient() },
            remove: { viewModel.removeBaseIngredient(at: $0) },
            updateAmount: { viewModel.updateBaseIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateBaseIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateBaseIngredientName($0, at: $1) }
        )
    }
    
    private func makeDoughIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addDoughIngredient() },
            remove: { viewModel.removeDoughIngredient(at: $0) },
            updateAmount: { viewModel.updateDoughIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateDoughIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateDoughIngredientName($0, at: $1) }
        )
    }
    
    private func makeToppingIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addToppingIngredient() },
            remove: { viewModel.removeToppingIngredient(at: $0) },
            updateAmount: { viewModel.updateToppingIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateToppingIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateToppingIngredientName($0, at: $1) }
        )
    }
    
    @ViewBuilder
    private func makeInstructionsContent() -> some View {
        ForEach(Array(viewModel.instructions.enumerated()), id: \.offset) { index, instruction in
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 16) {
                    // Blue circle with number (matching UploadRecipeView style)
                    Text("\(index + 1)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                    
                    TextField(
                        LocalizedString("Step", comment: "Step placeholder"),
                        text: Binding(
                            get: { instruction.text },
                            set: { viewModel.setInstructionText($0, at: index) }
                        ),
                        axis: .vertical
                    )
                    .lineLimit(2...6)
                    .focused($focusedInstructionField, equals: index)
                }
                
                // Display existing or new media
                if let existingImageURL = instruction.existingImageURL, instruction.image == nil {
                    AsyncImage(url: URL(string: existingImageURL)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                                .onTapGesture {
                                    // Load UIImage from URL for full screen view
                                    Task {
                                        if let url = URL(string: existingImageURL),
                                           let (data, _) = try? await URLSession.shared.data(from: url),
                                           let uiImage = UIImage(data: data) {
                                            fullScreenImage = uiImage
                                            showFullScreenImage = true
                                        }
                                    }
                                }
                        }
                    }
                } else if let image = instruction.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                        .onTapGesture {
                            fullScreenImage = image
                            showFullScreenImage = true
                        }
                }
                
                if let existingVideoURL = instruction.existingVideoURL, instruction.videoURL == nil,
                   let url = URL(string: existingVideoURL) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text(LocalizedString("View Video", comment: "View video link"))
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                } else if let videoURL = instruction.videoURL {
                    Link(destination: videoURL) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text(LocalizedString("View Video", comment: "View video link"))
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                }
                
                // Remove media button if there's any media
                if instruction.image != nil || instruction.videoURL != nil || instruction.existingImageURL != nil || instruction.existingVideoURL != nil {
                    Button(action: {
                        viewModel.removeInstructionMedia(at: index)
                    }) {
                        Label(LocalizedString("Remove Media", comment: "Remove media button"), systemImage: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .onDelete { indexSet in
            for index in indexSet.sorted(by: >) {
                viewModel.removeInstruction(at: index)
            }
        }
        
        Button(action: {
            viewModel.addInstruction()
        }) {
            Label(LocalizedString("Add Step", comment: "Add step button"), systemImage: "plus.circle")
        }
    }
    
    @ViewBuilder
    private func makeSourceSection() -> some View {
        if !viewModel.sourceImageURLs.isEmpty {
            Section {
                DisclosureGroup {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(viewModel.sourceImageURLs.enumerated()), id: \.offset) { index, imageURL in
                                Button(action: {
                                    // Load image from URL for full screen view
                                    Task {
                                        if let url = URL(string: imageURL),
                                           let (data, _) = try? await URLSession.shared.data(from: url),
                                           let uiImage = UIImage(data: data) {
                                            fullScreenImage = uiImage
                                            showFullScreenImage = true
                                        }
                                    }
                                }) {
                                    AsyncImage(url: URL(string: imageURL)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 80, height: 80)
                                                .clipped()
                                                .cornerRadius(8)
                                        case .failure(_), .empty:
                                            Rectangle()
                                                .fill(Color(.systemGray6))
                                                .frame(width: 80, height: 80)
                                                .cornerRadius(8)
                                                .overlay {
                                                    ProgressView()
                                                }
                                        @unknown default:
                                            Rectangle()
                                                .fill(Color(.systemGray6))
                                                .frame(width: 80, height: 80)
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    
                    Text(viewModel.sourceImageURLs.count > 1 ? 
                         LocalizedString("Source images used for recipe extraction", comment: "Source images description") :
                         LocalizedString("Source image used for recipe extraction", comment: "Source image description"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 4)
                } label: {
                    Text(LocalizedString("Source", comment: "Source section"))
                        .font(.headline)
                }
            }
        }
    }
    
    @ViewBuilder
    private func makeDatesSection() -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(LocalizedString("Created on:", comment: "Created on label"))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatDate(viewModel.recipe.createdAt))
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text(LocalizedString("Updated on:", comment: "Updated on label"))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatDate(viewModel.recipe.updatedAt))
                        .foregroundColor(.primary)
                }
            }
            .font(.caption)
        }
    }
    
    // Format date as dd-mmm-yyyy (e.g., 25-Dec-2025)
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MMM-yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}


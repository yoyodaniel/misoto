//
//  ExtractMenuWithAIView.swift
//  Misoto
//
//  View for extracting recipes from images using OpenAI
//

import SwiftUI
import PhotosUI

struct ExtractMenuWithAIView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ExtractMenuWithAIViewModel()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var selectedRecipePhotos: [PhotosPickerItem] = []
    @State private var showCuisineSelection = false
    @State private var cuisineDetectionTask: Task<Void, Never>?
    @State private var showFullScreenImage = false
    @State private var fullScreenImage: UIImage?
    @State private var showCameraForDishImage = false
    @State private var showPhotoPickerForDishImage = false
    
    let initialImage: UIImage?
    
    init(initialImage: UIImage? = nil) {
        self.initialImage = initialImage
        _selectedImage = State(initialValue: initialImage)
    }
    
    @FocusState private var focusedInstructionField: Int?
    @State private var isSourceExpanded = true
    
    // Dismiss all keyboards
    private func dismissKeyboard() {
        // Clear all focus states
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
    
    private func errorSection(_ message: String) -> some View {
        Section {
            Text(message)
                .foregroundColor(.red)
                .font(.caption)
        }
    }
    
    var body: some View {
        NavigationStack {
            if viewModel.showEditRecipe {
                recipeEditView
            } else {
                imageSelectionView
            }
        }
    }
    
    private var imageSelectionView: some View {
        Form {
            Section(header: Text(LocalizedString("Select Menu Image", comment: "Select menu image section"))) {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .padding(.vertical, 8)
                    
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                            Text(LocalizedString("Change Image", comment: "Change image button"))
                        }
                    }
                } else {
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                            Text(LocalizedString("Select Menu Image", comment: "Select image button"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                errorSection(errorMessage)
            }
            
            Section {
                Button(action: {
                    if let image = selectedImage {
                        Task {
                            await viewModel.extractRecipe(from: image)
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        Text(LocalizedString("Extract Recipe with AI", comment: "Extract recipe button"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(viewModel.isLoading || selectedImage == nil ? Color.gray : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(viewModel.isLoading || selectedImage == nil)
            }
        }
        .navigationTitle(LocalizedString("Extract with AI", comment: "Extract with AI title"))
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhoto) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    // Optimize image for display to reduce memory usage
                    selectedImage = ImageOptimizer.resizeForDisplay(image, maxDimension: 800)
                }
            }
        }
        .onAppear {
            if let initialImage = initialImage {
                selectedImage = initialImage
            }
        }
    }
    
    private var recipeEditView: some View {
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
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    dismissKeyboard()
                    Task {
                        // Don't pass selectedImage - it's the extraction image, not a main recipe image
                        let success = await viewModel.saveRecipe(image: nil)
                        if success {
                            await authViewModel.reloadUserData()
                            dismiss()
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
        .sheet(isPresented: $showFullScreenImage) {
            if let image = fullScreenImage {
                ZoomableImageView(image: image)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .ignoresSafeArea(.all)
            }
        }
        .background {
            PhotoLibraryPickerView(
                isPresented: $showPhotoPickerForDishImage,
                maxSelectionCount: 5 - viewModel.mainRecipeImages.count
            ) { images in
                // Process selected images
                Task {
                    for image in images {
                        // Optimize image for display to reduce memory usage
                        let optimizedImage = ImageOptimizer.resizeForDisplay(image, maxDimension: 1200)
                        await MainActor.run {
                            // addRecipeImage has a guard to prevent more than 5 images total
                            viewModel.addRecipeImage(optimizedImage)
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCameraForDishImage) {
            CameraCaptureView { image in
                // Add the captured image to recipe images
                Task {
                    // Optimize image for display to reduce memory usage
                    let optimizedImage = ImageOptimizer.resizeForDisplay(image, maxDimension: 1200)
                    await MainActor.run {
                        // addRecipeImage has a guard to prevent more than 5 images total
                        viewModel.addRecipeImage(optimizedImage)
                        showCameraForDishImage = false
                    }
                }
            }
            .ignoresSafeArea(.all)
        }
        .onChange(of: viewModel.title) {
            // Auto-detect cuisine when title changes (with debounce)
            cuisineDetectionTask?.cancel()
            cuisineDetectionTask = Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 second debounce
                guard !Task.isCancelled else { return }
                if !viewModel.title.isEmpty && (viewModel.cuisine == nil || viewModel.cuisine?.isEmpty == true) {
                    await viewModel.detectCuisine()
                }
            }
        }
        .onChange(of: viewModel.dishIngredients) {
            // Auto-detect cuisine when ingredients change (with debounce)
            cuisineDetectionTask?.cancel()
            cuisineDetectionTask = Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 second debounce
                guard !Task.isCancelled else { return }
                if !viewModel.title.isEmpty && (viewModel.cuisine == nil || viewModel.cuisine?.isEmpty == true) {
                    await viewModel.detectCuisine()
                }
            }
        }
        .onChange(of: selectedRecipePhotos) { oldValue, newItems in
            // Process when user finishes selecting images
            guard !newItems.isEmpty else { return }
            
            // Process all items - PhotosPicker provides all selected items when user presses Done
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        // Optimize image for display and add to recipe images
                        let optimizedImage = ImageOptimizer.resizeForDisplay(image, maxDimension: 1200)
                        await MainActor.run {
                            // addRecipeImage has a guard to prevent more than 5 images total
                            viewModel.addRecipeImage(optimizedImage)
                        }
                    }
                }
                // Clear selection after processing to allow selecting again
                await MainActor.run {
                    selectedRecipePhotos = []
                }
            }
        }
        .onDisappear {
            // Cancel cuisine detection task when view disappears
            cuisineDetectionTask?.cancel()
        }
    }
    
    @ViewBuilder
    private func makeRecipeForm() -> some View {
        let dishIngredientMethods = makeDishIngredientMethods()
        let marinadeIngredientMethods = makeMarinadeIngredientMethods()
        let seasoningIngredientMethods = makeSeasoningIngredientMethods()
        let doughBatterFillingIngredientMethods = makeDoughBatterFillingIngredientMethods()
        let sauceIngredientMethods = makeSauceIngredientMethods()
        let toppingIngredientMethods = makeToppingIngredientMethods()
        let garnishIngredientMethods = makeGarnishIngredientMethods()
        
        RecipeEditForm(
            title: $viewModel.title,
            titleEnglish: .constant(nil),
            titleLocal: .constant(nil),
            titleOriginal: .constant(nil),
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
            doughBatterFillingIngredients: $viewModel.doughBatterFillingIngredients,
            sauceIngredients: $viewModel.sauceIngredients,
            toppingIngredients: $viewModel.toppingIngredients,
            garnishIngredients: $viewModel.garnishIngredients,
            mainRecipeImages: $viewModel.mainRecipeImages,
            isGeneratingDescription: viewModel.isGeneratingDescription,
            isDetectingCuisine: viewModel.isDetectingCuisine,
            errorMessage: viewModel.errorMessage,
            addDishIngredient: dishIngredientMethods.add,
            removeDishIngredient: dishIngredientMethods.remove,
            updateDishIngredientAmount: dishIngredientMethods.updateAmount,
            updateDishIngredientUnit: dishIngredientMethods.updateUnit,
            updateDishIngredientName: dishIngredientMethods.updateName,
            moveDishIngredient: dishIngredientMethods.move,
            addMarinadeIngredient: marinadeIngredientMethods.add,
            removeMarinadeIngredient: marinadeIngredientMethods.remove,
            updateMarinadeIngredientAmount: marinadeIngredientMethods.updateAmount,
            updateMarinadeIngredientUnit: marinadeIngredientMethods.updateUnit,
            updateMarinadeIngredientName: marinadeIngredientMethods.updateName,
            moveMarinadeIngredient: marinadeIngredientMethods.move,
            addSeasoningIngredient: seasoningIngredientMethods.add,
            removeSeasoningIngredient: seasoningIngredientMethods.remove,
            updateSeasoningIngredientAmount: seasoningIngredientMethods.updateAmount,
            updateSeasoningIngredientUnit: seasoningIngredientMethods.updateUnit,
            updateSeasoningIngredientName: seasoningIngredientMethods.updateName,
            moveSeasoningIngredient: seasoningIngredientMethods.move,
            addDoughBatterFillingIngredient: doughBatterFillingIngredientMethods.add,
            removeDoughBatterFillingIngredient: doughBatterFillingIngredientMethods.remove,
            updateDoughBatterFillingIngredientAmount: doughBatterFillingIngredientMethods.updateAmount,
            updateDoughBatterFillingIngredientUnit: doughBatterFillingIngredientMethods.updateUnit,
            updateDoughBatterFillingIngredientName: doughBatterFillingIngredientMethods.updateName,
            moveDoughBatterFillingIngredient: doughBatterFillingIngredientMethods.move,
            addSauceIngredient: sauceIngredientMethods.add,
            removeSauceIngredient: sauceIngredientMethods.remove,
            updateSauceIngredientAmount: sauceIngredientMethods.updateAmount,
            updateSauceIngredientUnit: sauceIngredientMethods.updateUnit,
            updateSauceIngredientName: sauceIngredientMethods.updateName,
            moveSauceIngredient: sauceIngredientMethods.move,
            addToppingIngredient: toppingIngredientMethods.add,
            removeToppingIngredient: toppingIngredientMethods.remove,
            updateToppingIngredientAmount: toppingIngredientMethods.updateAmount,
            updateToppingIngredientUnit: toppingIngredientMethods.updateUnit,
            updateToppingIngredientName: toppingIngredientMethods.updateName,
            moveToppingIngredient: toppingIngredientMethods.move,
            addGarnishIngredient: garnishIngredientMethods.add,
            removeGarnishIngredient: garnishIngredientMethods.remove,
            updateGarnishIngredientAmount: garnishIngredientMethods.updateAmount,
            updateGarnishIngredientUnit: garnishIngredientMethods.updateUnit,
            updateGarnishIngredientName: garnishIngredientMethods.updateName,
            moveGarnishIngredient: garnishIngredientMethods.move,
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
            onTakePicture: {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    showCameraForDishImage = true
                }
            },
            onSelectFromLibrary: {
                showPhotoPickerForDishImage = true
            },
            moveIngredientBetweenCategories: { fromCategory, fromIndex, toCategory, toIndex in
                viewModel.moveIngredient(from: fromCategory, sourceIndex: fromIndex, to: toCategory, destinationIndex: toIndex)
            },
            instructionsContent: {
                makeInstructionsContent()
            },
            optionalContent: {
                makeSourceSection()
            }
        )
    }
    
    private struct IngredientMethods {
        let add: () -> Void
        let remove: (Int) -> Void
        let updateAmount: (String, Int) -> Void
        let updateUnit: (String, Int) -> Void
        let updateName: (String, Int) -> Void
        let move: (Int, Int) -> Void
    }
    
    private func makeDishIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addDishIngredient() },
            remove: { viewModel.removeDishIngredient(at: $0) },
            updateAmount: { viewModel.updateDishIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateDishIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateDishIngredientName($0, at: $1) },
            move: { _, _ in } // No-op for now
        )
    }
    
    private func makeMarinadeIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addMarinadeIngredient() },
            remove: { viewModel.removeMarinadeIngredient(at: $0) },
            updateAmount: { viewModel.updateMarinadeIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateMarinadeIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateMarinadeIngredientName($0, at: $1) },
            move: { _, _ in } // No-op for now
        )
    }
    
    private func makeSeasoningIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addSeasoningIngredient() },
            remove: { viewModel.removeSeasoningIngredient(at: $0) },
            updateAmount: { viewModel.updateSeasoningIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateSeasoningIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateSeasoningIngredientName($0, at: $1) },
            move: { _, _ in } // No-op for now
        )
    }
    
    private func makeSauceIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addSauceIngredient() },
            remove: { viewModel.removeSauceIngredient(at: $0) },
            updateAmount: { viewModel.updateSauceIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateSauceIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateSauceIngredientName($0, at: $1) },
            move: { _, _ in } // No-op for now
        )
    }
    
    private func makeDoughBatterFillingIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addDoughBatterFillingIngredient() },
            remove: { viewModel.removeDoughBatterFillingIngredient(at: $0) },
            updateAmount: { viewModel.updateDoughBatterFillingIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateDoughBatterFillingIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateDoughBatterFillingIngredientName($0, at: $1) },
            move: { _, _ in } // No-op for now
        )
    }
    
    private func makeToppingIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addToppingIngredient() },
            remove: { viewModel.removeToppingIngredient(at: $0) },
            updateAmount: { viewModel.updateToppingIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateToppingIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateToppingIngredientName($0, at: $1) },
            move: { _, _ in } // No-op for now
        )
    }
    
    private func makeGarnishIngredientMethods() -> IngredientMethods {
        IngredientMethods(
            add: { viewModel.addGarnishIngredient() },
            remove: { viewModel.removeGarnishIngredient(at: $0) },
            updateAmount: { viewModel.updateGarnishIngredientAmount($0, at: $1) },
            updateUnit: { viewModel.updateGarnishIngredientUnit($0, at: $1) },
            updateName: { viewModel.updateGarnishIngredientName($0, at: $1) },
            move: { _, _ in } // No-op for now
        )
    }
    
    @ViewBuilder
    private func makeInstructionsContent() -> some View {
        ForEach(Array(viewModel.instructions.enumerated()), id: \.offset) { index, instruction in
            HStack(alignment: .top, spacing: 16) {
                // Blue circle with number (matching ModernRecipeDetailView style)
                Text("\(index + 1)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                
                TextField(LocalizedString("Step", comment: "Step placeholder"), text: Binding(
                    get: { viewModel.instructions[index] },
                    set: { viewModel.updateInstruction($0, at: index) }
                ), axis: .vertical)
                .lineLimit(2...6)
                .focused($focusedInstructionField, equals: index)
            }
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
        if let sourceImage = selectedImage ?? initialImage {
            Section {
                DisclosureGroup(isExpanded: $isSourceExpanded) {
                    HStack(spacing: 12) {
                        Button(action: {
                            fullScreenImage = sourceImage
                            showFullScreenImage = true
                        }) {
                            Image(uiImage: sourceImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipped()
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 4)
                    
                    Text(LocalizedString("Source image used for recipe extraction", comment: "Source image description"))
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
}

#Preview {
    ExtractMenuWithAIView()
}

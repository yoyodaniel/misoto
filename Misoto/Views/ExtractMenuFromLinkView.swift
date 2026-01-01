//
//  ExtractMenuFromLinkView.swift
//  Misoto
//
//  View for extracting recipes from URLs using OpenAI
//

import SwiftUI
import PhotosUI

struct ExtractMenuFromLinkView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ExtractMenuFromLinkViewModel()
    @State private var menuURL: String = ""
    @State private var selectedRecipePhotos: [PhotosPickerItem] = []
    @State private var showCuisineSelection = false
    @State private var cuisineDetectionTask: Task<Void, Never>?
    @State private var showFullScreenImage = false
    @State private var fullScreenImage: UIImage?
    
    @FocusState private var focusedInstructionField: Int?
    
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
                urlInputView
            }
        }
    }
    
    private var urlInputView: some View {
        Form {
            Section(header: Text(LocalizedString("Enter Menu URL", comment: "Enter menu URL section"))) {
                TextField(LocalizedString("Menu URL", comment: "Menu URL placeholder"), text: $menuURL)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
            }
            
            Section(footer: Text(LocalizedString("Paste a link to a recipe webpage to extract recipe information automatically using AI.", comment: "Menu URL help text"))) {
                EmptyView()
            }
            
            if let errorMessage = viewModel.errorMessage {
                errorSection(errorMessage)
            }
            
            Section {
                Button(action: {
                    Task {
                        await viewModel.extractRecipe(from: menuURL)
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        Text(LocalizedString("Extract Recipe", comment: "Extract recipe button"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(viewModel.isLoading || menuURL.isEmpty ? Color.gray : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(menuURL.isEmpty || viewModel.isLoading)
            }
        }
        .navigationTitle(LocalizedString("Extract from Link", comment: "Extract from link title"))
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
        }
    }
    
    private var recipeEditView: some View {
        makeRecipeForm()
        .sheet(isPresented: $showCuisineSelection) {
            CuisineSelectionView(selectedCuisine: $viewModel.cuisine)
        }
        .sheet(isPresented: $showFullScreenImage) {
            if let image = fullScreenImage {
                ZoomableImageView(image: image)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .ignoresSafeArea(.all)
            }
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
                        let success = await viewModel.saveRecipe()
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
                        let optimizedImage = await ImageOptimizer.resizeForDisplay(image, maxDimension: 1200)
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
                EmptyView()
            }
        )
    }
    
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
}

#Preview {
    ExtractMenuFromLinkView()
}



//
//  ExtractMenuFromWebsiteView.swift
//  Misoto
//
//  View for extracting recipes from websites using web browser
//

import SwiftUI
import WebKit
import PhotosUI
import Combine

struct ExtractMenuFromWebsiteView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ExtractMenuFromWebsiteViewModel()
    @State private var urlString: String = ""
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var isLoading = false
    @State private var hasLoadedContent = false
    @State private var isRecipeDetected = false
    @State private var isDetectingRecipe = false
    @State private var selectedRecipePhotos: [PhotosPickerItem] = []
    @State private var showCuisineSelection = false
    @State private var cuisineDetectionTask: Task<Void, Never>?
    @State private var showFullScreenImage = false
    @State private var fullScreenImage: UIImage?
    @State private var showSourceWebsite = false
    @StateObject private var webViewStore = WebViewStore()
    
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
                webBrowserView
            }
        }
    }
    
    private var webBrowserView: some View {
        VStack(spacing: 0) {
            // Native Search Bar with Navigation
            VStack(spacing: 0) {
                // Navigation buttons and search bar
                HStack(spacing: 12) {
                    Button(action: {
                        webViewStore.goBack()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(canGoBack ? .accentColor : .gray)
                            .frame(width: 32, height: 32)
                    }
                    .disabled(!canGoBack)
                    
                    Button(action: {
                        webViewStore.goForward()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(canGoForward ? .accentColor : .gray)
                            .frame(width: 32, height: 32)
                    }
                    .disabled(!canGoForward)
                    
                    // Native UISearchBar
                    NativeSearchBar(
                        text: $urlString,
                        placeholder: LocalizedString("Search or enter website name", comment: "Search bar placeholder"),
                        onSearchButtonClicked: {
                            loadURL()
                        }
                    )
                    .frame(height: 36)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 20)
                .background(Color(.systemBackground))
            }
            
            Divider()
            
                // Web View with Instructions Overlay
            ZStack {
                // Web View (always present, but may be empty initially)
                WebViewRepresentable(
                    urlString: $urlString,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward,
                    isLoading: $isLoading,
                    webViewStore: webViewStore,
                    onContentLoaded: {
                        hasLoadedContent = true
                    },
                    onRecipeDetectionRequested: {
                        Task {
                            await detectRecipeOnPage()
                        }
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Instructions overlay (shown when no content has loaded)
                if !hasLoadedContent && !isLoading {
                    initialInstructionsView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Extract Button (only shown when content is loaded, enabled when recipe detected)
            if hasLoadedContent {
                VStack(spacing: 8) {
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    if isDetectingRecipe {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text(LocalizedString("Detecting recipe...", comment: "Detecting recipe message"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    } else if !isRecipeDetected {
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.caption)
                            Text(LocalizedString("No recipe detected on this page", comment: "No recipe detected message"))
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    
                    Button(action: {
                        Task {
                            if let webView = webViewStore.webView {
                                await viewModel.extractRecipe(from: webView)
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isExtractingContent || viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            }
                            Text(LocalizedString("Extract Recipe", comment: "Extract recipe button"))
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(isButtonEnabled ? Color.accentColor : Color.gray.opacity(0.3))
                        .foregroundColor(isButtonEnabled ? .white : .secondary)
                        .cornerRadius(8)
                    }
                    .disabled(!isButtonEnabled)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
                .background(Color(.systemBackground))
            }
        }
        .navigationTitle(LocalizedString("Extract from Website", comment: "Extract from website title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(LocalizedString("Cancel", comment: "Cancel button")) {
                    dismiss()
                }
            }
        }
    }
    
    private func loadURL() {
        let input = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        
        var urlToLoad: String
        
        // Check if it's already a valid URL
        if input.contains("://") {
            urlToLoad = input
        } else if isValidURL(input) {
            // It's a URL without scheme
            urlToLoad = "https://\(input)"
        } else {
            // Treat as search query (like Safari)
            let encodedQuery = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? input
            urlToLoad = "https://www.google.com/search?q=\(encodedQuery)"
        }
        
        if let url = URL(string: urlToLoad) {
            // Reset recipe detection when loading a new URL
            isRecipeDetected = false
            isDetectingRecipe = false
            webViewStore.loadURL(url)
        }
    }
    
    private func isValidURL(_ string: String) -> Bool {
        // Check if it looks like a URL (has domain-like structure)
        let urlPattern = #"^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$"#
        let regex = try? NSRegularExpression(pattern: urlPattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: string.utf16.count)
        return regex?.firstMatch(in: string, options: [], range: range) != nil
    }
    
    /// Computed property to determine if the Extract Recipe button should be enabled
    private var isButtonEnabled: Bool {
        // Button is only enabled when:
        // 1. A recipe has been detected
        // 2. Not currently extracting content
        // 3. Not currently loading
        return isRecipeDetected && !viewModel.isExtractingContent && !viewModel.isLoading && !isLoading
    }
    
    /// Detect if the current page contains a recipe using on-device Foundation models
    /// This is called automatically when the page finishes loading
    private func detectRecipeOnPage() async {
        guard let webView = webViewStore.webView else {
            await MainActor.run {
                isRecipeDetected = false
                isDetectingRecipe = false
            }
            return
        }
        
        await MainActor.run {
            isDetectingRecipe = true
            isRecipeDetected = false // Reset detection state
        }
        
        // Small delay to ensure page content is fully rendered
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Use on-device Foundation models to detect recipe
        // This now translates non-English text to English before detection
        let detected = await RecipeDetector.detectRecipe(on: webView)
        
        await MainActor.run {
            isRecipeDetected = detected
            isDetectingRecipe = false
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
        .sheet(isPresented: $showSourceWebsite) {
            if let sourceURL = viewModel.sourceURL, let url = URL(string: sourceURL) {
                SourceWebsiteView(url: url)
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
        .onChange(of: viewModel.title) { _ in
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
        .onChange(of: viewModel.dishIngredients) { _ in
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
    
    @ViewBuilder
    private func makeSourceSection() -> some View {
        if let sourceURL = viewModel.sourceURL, !sourceURL.isEmpty {
            Section(header: Text(LocalizedString("Source", comment: "Source section header"))) {
                Button(action: {
                    showSourceWebsite = true
                }) {
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedString("View Source Website", comment: "View source website button"))
                                .foregroundColor(.primary)
                                .font(.body)
                            Text(sourceURL)
                                .foregroundColor(.secondary)
                                .font(.caption)
                                .lineLimit(2)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    private var initialInstructionsView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.accentColor.opacity(0.6))
            
            // Title
            Text(LocalizedString("Find a Recipe", comment: "Find a recipe title"))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Instructions
            VStack(spacing: 12) {
                Text(LocalizedString("Type a website URL or search for a recipe", comment: "Instructions text"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "link")
                            .foregroundColor(.accentColor)
                            .font(.caption)
                        Text(LocalizedString("Enter a website URL (e.g., example.com)", comment: "URL example"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.accentColor)
                            .font(.caption)
                        Text(LocalizedString("Or search for a recipe (e.g., chocolate cake recipe)", comment: "Search example"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - WebView Store

@MainActor
class WebViewStore: ObservableObject {
    @Published var webView: WKWebView?
    
    init() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        self.webView = webView
    }
    
    func loadURL(_ url: URL) {
        webView?.load(URLRequest(url: url))
    }
    
    func goBack() {
        webView?.goBack()
    }
    
    func goForward() {
        webView?.goForward()
    }
}

// MARK: - WebView Representable

struct WebViewRepresentable: UIViewRepresentable {
    @Binding var urlString: String
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool
    @ObservedObject var webViewStore: WebViewStore
    var onContentLoaded: (() -> Void)? = nil
    var onRecipeDetectionRequested: (() -> Void)? = nil
    
    func makeUIView(context: Context) -> WKWebView {
        guard let webView = webViewStore.webView else {
            let configuration = WKWebViewConfiguration()
            let webView = WKWebView(frame: .zero, configuration: configuration)
            webViewStore.webView = webView
            return webView
        }
        
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Update navigation state
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        isLoading = webView.isLoading
        
        // Update URL string if page changed
        if let currentURL = webView.url?.absoluteString, currentURL != urlString {
            urlString = currentURL
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewRepresentable
        
        init(_ parent: WebViewRepresentable) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            // Reset recipe detection when navigation starts
            // The detection will be triggered again when page finishes loading
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
            if let url = webView.url?.absoluteString {
                parent.urlString = url
            }
            // Notify that content has been loaded
            parent.onContentLoaded?()
            // Trigger recipe detection
            parent.onRecipeDetectionRequested?()
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}

// MARK: - Native Search Bar

struct NativeSearchBar: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onSearchButtonClicked: () -> Void
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.delegate = context.coordinator
        searchBar.placeholder = placeholder
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.keyboardType = .webSearch
        searchBar.returnKeyType = .go
        searchBar.enablesReturnKeyAutomatically = false
        
        // Customize appearance
        searchBar.barTintColor = .systemBackground
        searchBar.backgroundColor = .systemBackground
        searchBar.tintColor = .systemBlue
        
        // Remove background
        searchBar.backgroundImage = UIImage()
        searchBar.isTranslucent = true
        
        // Style the text field
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = UIColor.systemGray6
            textField.layer.cornerRadius = 10
            textField.clipsToBounds = true
            textField.font = .systemFont(ofSize: 16)
            textField.textColor = .label
        }
        
        return searchBar
    }
    
    func updateUIView(_ searchBar: UISearchBar, context: Context) {
        if searchBar.text != text {
            searchBar.text = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UISearchBarDelegate {
        var parent: NativeSearchBar
        
        init(_ parent: NativeSearchBar) {
            self.parent = parent
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            parent.text = searchText
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
            parent.onSearchButtonClicked()
        }
        
        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            // Select all text when user starts editing (like Safari)
            DispatchQueue.main.async {
                if let textField = searchBar.value(forKey: "searchField") as? UITextField {
                    textField.selectAll(nil)
                }
            }
        }
    }
}

// MARK: - Source Website View

struct SourceWebsiteView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @StateObject private var webViewStore = WebViewStore()
    @State private var urlString: String = ""
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Native Search Bar with Navigation
                VStack(spacing: 0) {
                    // Navigation buttons and search bar
                    HStack(spacing: 12) {
                        Button(action: {
                            webViewStore.goBack()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(canGoBack ? .accentColor : .gray)
                                .frame(width: 32, height: 32)
                        }
                        .disabled(!canGoBack)
                        
                        Button(action: {
                            webViewStore.goForward()
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(canGoForward ? .accentColor : .gray)
                                .frame(width: 32, height: 32)
                        }
                        .disabled(!canGoForward)
                        
                        // Native UISearchBar
                        NativeSearchBar(
                            text: $urlString,
                            placeholder: LocalizedString("Search or enter website name", comment: "Search bar placeholder"),
                            onSearchButtonClicked: {
                                loadURL()
                            }
                        )
                        .frame(height: 36)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                }
                
                Divider()
                
                // Web View
                WebViewRepresentable(
                    urlString: $urlString,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward,
                    isLoading: $isLoading,
                    webViewStore: webViewStore
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(LocalizedString("Source Website", comment: "Source website title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedString("Done", comment: "Done button")) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                urlString = url.absoluteString
                webViewStore.loadURL(url)
            }
        }
    }
    
    private func loadURL() {
        let input = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        
        var urlToLoad: String
        
        // Check if it's already a valid URL
        if input.contains("://") {
            urlToLoad = input
        } else if isValidURL(input) {
            // It's a URL without scheme
            urlToLoad = "https://\(input)"
        } else {
            // Treat as search query (like Safari)
            let encodedQuery = input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? input
            urlToLoad = "https://www.google.com/search?q=\(encodedQuery)"
        }
        
        if let url = URL(string: urlToLoad) {
            webViewStore.loadURL(url)
        }
    }
    
    private func isValidURL(_ string: String) -> Bool {
        // Check if it looks like a URL (has domain-like structure)
        let urlPattern = #"^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$"#
        let regex = try? NSRegularExpression(pattern: urlPattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: string.utf16.count)
        return regex?.firstMatch(in: string, options: [], range: range) != nil
    }
}

#Preview {
    ExtractMenuFromWebsiteView()
}


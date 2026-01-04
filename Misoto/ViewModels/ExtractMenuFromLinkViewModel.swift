//
//  ExtractMenuFromLinkViewModel.swift
//  Misoto
//
//  ViewModel for extracting recipes from URLs using OpenAI
//

import Foundation
import Combine
import FirebaseAuth
import UIKit
import WebKit
import NaturalLanguage

@MainActor
class ExtractMenuFromLinkViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showEditRecipe = false
    @Published var isGeneratingDescription = false
    @Published var isDetectingCuisine = false
    @Published var isExtractingTime = false
    @Published var isDetectingDifficulty = false
    @Published var isExtractingContent = false
    
    // Recipe fields for editing
    @Published var title = ""
    @Published var originalExtractedTitle: String? = nil // Preserve original title before translation
    @Published var titleEnglish: String? = nil
    @Published var titleLocal: String? = nil
    @Published var titleOriginal: String? = nil
    @Published var description = ""
    @Published var cuisine: String? = nil
    @Published var prepTime: Int = 15
    @Published var cookTime: Int = 30
    @Published var servings: Int = 4
    @Published var difficulty: Recipe.Difficulty = .c
    @Published var spicyLevel: Recipe.SpicyLevel = .none
    @Published var tips: [String] = []
    @Published var marinadeIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var seasoningIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var dishIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var doughBatterFillingIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var sauceIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var toppingIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var garnishIngredients: [RecipeTextParser.IngredientItem] = []
    @Published var instructions: [String] = []
    @Published var mainRecipeImages: [UIImage] = [] // Up to 5 images for the recipe
    @Published var sourceURL: String? = nil // URL from which recipe was extracted
    
    private let recipeService = RecipeService()
    private let storageService = StorageService()
    private let textProcessor = RecipeTextProcessor()
    
    /// Extract original title from web page - tries multiple strategies
    /// 1. Extract from HTML title/h1 tags via JavaScript
    /// 2. Extract from raw text (first meaningful line)
    private func extractOriginalTitle(from webView: WKWebView, rawText: String) async -> String? {
        // Strategy 1: Try to extract from HTML title/h1 tags (most reliable)
        if let htmlTitle = await extractTitleFromHTML(webView: webView) {
            print("✅ Found title from HTML: \(htmlTitle)")
            return htmlTitle
        }
        
        // Strategy 2: Extract from raw text
        if let textTitle = extractPotentialTitle(from: rawText) {
            print("✅ Found title from raw text: \(textTitle)")
            return textTitle
        }
        
        return nil
    }
    
    /// Extract title from HTML using JavaScript (tries title tag, h1, and recipe-specific selectors)
    private func extractTitleFromHTML(webView: WKWebView) async -> String? {
        let titleScript = """
        (function() {
            // Try multiple selectors in order of preference
            const selectors = [
                'h1.recipe-title',
                'h1[class*="recipe"]',
                '.recipe-title',
                '[class*="recipe-title"]',
                'h1',
                'title'
            ];
            
            for (const selector of selectors) {
                const element = document.querySelector(selector);
                if (element) {
                    const text = element.innerText || element.textContent || '';
                    const cleaned = text.trim();
                    if (cleaned.length > 0 && cleaned.length < 200) {
                        return cleaned;
                    }
                }
            }
            
            return null;
        })();
        """
        
        do {
            if let result = try await webView.evaluateJavaScript(titleScript) as? String,
               !result.isEmpty {
                return result
            }
        } catch {
            print("⚠️ Error extracting title from HTML: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Extract potential title from raw text (before translation)
    /// Looks for the first meaningful line that could be a recipe title
    private func extractPotentialTitle(from text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // Look for the first line that could be a title
        // Titles are usually:
        // - Short (less than 100 characters)
        // - Not starting with common recipe section keywords
        // - Not containing ingredient/instruction patterns
        let sectionKeywords = ["ingredients", "instructions", "method", "steps", "preparation", "cooking", "serves", "prep", "cook"]
        let ingredientPatterns = ["\\d+\\s*(tbsp|tsp|cup|g|kg|ml|l|oz|lb)", "\\d+/\\d+", "^\\d+\\s"]
        
        for line in lines.prefix(10) { // Check first 10 lines
            let lowercased = line.lowercased()
            
            // Skip if it's clearly a section header
            if sectionKeywords.contains(where: { lowercased.contains($0) }) {
                continue
            }
            
            // Skip if it looks like an ingredient line
            var looksLikeIngredient = false
            for pattern in ingredientPatterns {
                if line.range(of: pattern, options: .regularExpression) != nil {
                    looksLikeIngredient = true
                    break
                }
            }
            if looksLikeIngredient {
                continue
            }
            
            // Skip if it's too long (likely description)
            if line.count > 150 {
                continue
            }
            
            // Skip if it's too short (likely not a title)
            if line.count < 3 {
                continue
            }
            
            // This looks like a potential title
            return line
        }
        
        // Fallback: return first non-empty line if it's reasonable
        if let firstLine = lines.first, firstLine.count >= 3 && firstLine.count <= 150 {
            return firstLine
        }
        
        return nil
    }
    
    /// Extract recipe from URL by loading website in background WKWebView
    /// Uses the same extraction approach as ExtractMenuFromWebsiteViewModel
    func extractRecipe(from urlString: String) async {
        isExtractingContent = true
        isLoading = true
        errorMessage = nil
        
        // Store the URL as source
        sourceURL = urlString
        
        // Validate and prepare URL
        var urlToLoad = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !urlToLoad.contains("://") {
            urlToLoad = "https://\(urlToLoad)"
        }
        
        guard let url = URL(string: urlToLoad) else {
            isLoading = false
            isExtractingContent = false
            errorMessage = LocalizedString("Invalid URL", comment: "Invalid URL error")
            return
        }
        
        // Create a hidden WKWebView to load the website in the background
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        webView.isHidden = true // Hide the webView so it's not visible
        
        // Add webView to window hierarchy so it can load (required for WKWebView)
        // We'll remove it after extraction
        var containerView: UIView? = nil
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            containerView = UIView(frame: .zero)
            containerView?.isHidden = true
            containerView?.addSubview(webView)
            window.addSubview(containerView!)
        }
        
        // Set up navigation delegate to detect when loading completes
        let navigationDelegate = WebViewNavigationDelegate()
        webView.navigationDelegate = navigationDelegate
        
        do {
            // Load the URL
            let request = URLRequest(url: url)
            webView.load(request)
            
            // Wait for the page to finish loading with timeout
            let loadTimeout: TimeInterval = 15.0
            let startTime = Date()
            
            // Wait for navigation to complete or timeout
            while webView.isLoading {
                // Check for timeout
                if Date().timeIntervalSince(startTime) > loadTimeout {
                    // Clean up
                    containerView?.removeFromSuperview()
                    throw WebContentExtractorError.noContentFound
                }
                // Small delay before checking again
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            // Give additional time for JavaScript to execute and render content
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Step 1: Extract raw text from web page (uses cloneNode, doesn't modify DOM)
            var rawText = try await WebContentExtractor.extractText(from: webView)
            
            // Step 1.1: IMMEDIATELY extract original title from raw text (BEFORE any translation)
            // This is critical to preserve the original language (e.g., Dutch)
            print("🔍 Extracting original title from raw text (before translation)...")
            if let extracted = await extractOriginalTitle(from: webView, rawText: rawText) {
                originalExtractedTitle = RecipeTranslationService.capitalizeTitle(extracted)
            }
            
            if let originalTitle = originalExtractedTitle, !originalTitle.isEmpty {
                print("✅ Original title extracted: \(originalTitle)")
                // Detect language of original title for debugging
                if let detectedLang = TextTranslationService.detectLanguage(originalTitle) {
                    print("📝 Detected original title language: \(detectedLang.rawValue)")
                }
            } else {
                print("⚠️ WARNING: Could not extract original title from raw text")
            }
            
            // Step 1.5: Detect language and translate to English if needed
            print("🔍 Detecting language of extracted web content...")
            rawText = await TextTranslationService.translateToEnglish(rawText)
            print("✅ Web content ready for processing (translated to English if needed)")
            
            // Step 1.6: Extract recipe image from web page
            do {
                if let recipeImage = try await WebContentExtractor.extractRecipeImage(from: webView) {
                    // Only add if we don't already have 5 images
                    if mainRecipeImages.count < 5 {
                        addRecipeImage(recipeImage)
                        print("✅ Added recipe image to collection")
                    } else {
                        print("⚠️ Recipe image found but already have 5 images")
                    }
                } else {
                    print("⚠️ No recipe image found on webpage")
                }
            } catch {
                print("⚠️ Error extracting recipe image: \(error.localizedDescription)")
                // Continue with recipe extraction even if image extraction fails
            }
            
            // Step 2: Use on-device Foundation models to clean and process text
            // Note: rawText is already translated to English at this point
            let cleanedText = await textProcessor.processAndCorrectText(rawText)
            
            // Step 3: Send to OpenAI API for parsing into recipe structure
            let response = try await OpenAIService.parseRecipeFromText(cleanedText)
            
            // If we didn't extract the original title earlier, use the response title
            // (though it will be in English at this point)
            if originalExtractedTitle == nil {
                originalExtractedTitle = RecipeTranslationService.capitalizeTitle(response.title)
            }
            
            // Step 4: Translate recipe to user's selected language
            print("🌍 Translating extracted recipe to user's selected language...")
            let translated = await RecipeTranslationService.translateRecipe(
                title: response.title,
                description: response.description,
                dishIngredients: response.dishIngredients,
                marinadeIngredients: response.marinadeIngredients,
                seasoningIngredients: response.seasoningIngredients,
                batterIngredients: response.batterIngredients,
                sauceIngredients: response.sauceIngredients,
                baseIngredients: response.baseIngredients,
                doughIngredients: response.doughIngredients,
                toppingIngredients: response.toppingIngredients,
                instructions: response.instructions,
                tips: response.tips.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
                cuisine: nil // Will be detected later
            )
            
            // Populate fields with translated content (already capitalized by RecipeTranslationService)
            title = translated.title
            description = translated.description
            dishIngredients = translated.dishIngredients.isEmpty ? [RecipeTextParser.IngredientItem(amount: "", unit: "", name: "")] : translated.dishIngredients
            marinadeIngredients = translated.marinadeIngredients
            seasoningIngredients = translated.seasoningIngredients
            // Consolidate batter, base, and dough into doughBatterFillingIngredients
            // Note: fillingIngredients is not returned by translateRecipe, so we only consolidate the available types
            doughBatterFillingIngredients = translated.batterIngredients + translated.baseIngredients + translated.doughIngredients
            sauceIngredients = translated.sauceIngredients
            toppingIngredients = translated.toppingIngredients
            instructions = translated.instructions.isEmpty ? [""] : translated.instructions
            tips = translated.tips
            
            // Use extracted servings, prepTime, and cookTime if available (non-zero means found)
            if response.servings > 0 {
                servings = response.servings
            }
            if response.prepTime > 0 {
                prepTime = response.prepTime
            }
            if response.cookTime > 0 {
                cookTime = response.cookTime
            }
            
            // Auto-generate description, auto-detect cuisine, extract time (if not already extracted), and detect difficulty after extraction
            // Small delay to ensure all fields are properly set
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            await generateDescription()
            await detectCuisine()
            // Only extract time if it wasn't already extracted
            if response.prepTime == 0 && response.cookTime == 0 {
                await extractTime()
            }
            await detectDifficulty()
            
            showEditRecipe = true
            isLoading = false
            isExtractingContent = false
            
            // Clean up: remove webView from window hierarchy
            containerView?.removeFromSuperview()
        } catch {
            isLoading = false
            isExtractingContent = false
            
            // Clean up: remove webView from window hierarchy
            containerView?.removeFromSuperview()
            
            if let webError = error as? WebContentExtractorError {
                errorMessage = webError.localizedDescription
            } else if let openAIError = error as? OpenAIError {
                errorMessage = openAIError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Helper class for web view navigation
    
    private class WebViewNavigationDelegate: NSObject, WKNavigationDelegate {
        // This delegate can be extended if needed for more complex navigation handling
    }
    
    // MARK: - Ingredient Management
    
    func addDishIngredient() {
        dishIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func removeDishIngredient(at index: Int) {
        guard index >= 0 && index < dishIngredients.count else { return }
        dishIngredients.remove(at: index)
    }
    
    func updateDishIngredientAmount(_ amount: String, at index: Int) {
        guard index >= 0 && index < dishIngredients.count else { return }
        dishIngredients[index].amount = amount
    }
    
    func updateDishIngredientUnit(_ unit: String, at index: Int) {
        guard index >= 0 && index < dishIngredients.count else { return }
        dishIngredients[index].unit = unit
    }
    
    func updateDishIngredientName(_ name: String, at index: Int) {
        guard index >= 0 && index < dishIngredients.count else { return }
        dishIngredients[index].name = name
    }
    
    func addMarinadeIngredient() {
        marinadeIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func removeMarinadeIngredient(at index: Int) {
        guard index >= 0 && index < marinadeIngredients.count else { return }
        marinadeIngredients.remove(at: index)
    }
    
    func updateMarinadeIngredientAmount(_ amount: String, at index: Int) {
        guard index >= 0 && index < marinadeIngredients.count else { return }
        marinadeIngredients[index].amount = amount
    }
    
    func updateMarinadeIngredientUnit(_ unit: String, at index: Int) {
        guard index >= 0 && index < marinadeIngredients.count else { return }
        marinadeIngredients[index].unit = unit
    }
    
    func updateMarinadeIngredientName(_ name: String, at index: Int) {
        guard index >= 0 && index < marinadeIngredients.count else { return }
        marinadeIngredients[index].name = name
    }
    
    func addSeasoningIngredient() {
        seasoningIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func removeSeasoningIngredient(at index: Int) {
        guard index >= 0 && index < seasoningIngredients.count else { return }
        seasoningIngredients.remove(at: index)
    }
    
    func updateSeasoningIngredientAmount(_ amount: String, at index: Int) {
        guard index >= 0 && index < seasoningIngredients.count else { return }
        seasoningIngredients[index].amount = amount
    }
    
    func updateSeasoningIngredientUnit(_ unit: String, at index: Int) {
        guard index >= 0 && index < seasoningIngredients.count else { return }
        seasoningIngredients[index].unit = unit
    }
    
    func updateSeasoningIngredientName(_ name: String, at index: Int) {
        guard index >= 0 && index < seasoningIngredients.count else { return }
        seasoningIngredients[index].name = name
    }
    
    func updateInstruction(_ instruction: String, at index: Int) {
        guard index >= 0 && index < instructions.count else { return }
        instructions[index] = instruction
    }
    
    func addInstruction() {
        instructions.append("")
    }
    
    func removeInstruction(at index: Int) {
        guard index >= 0 && index < instructions.count else { return }
        instructions.remove(at: index)
    }
    
    // MARK: - Additional Ingredient Management (Batter and Sauce)
    
    func addDoughBatterFillingIngredient() {
        doughBatterFillingIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func removeDoughBatterFillingIngredient(at index: Int) {
        guard index >= 0 && index < doughBatterFillingIngredients.count else { return }
        doughBatterFillingIngredients.remove(at: index)
    }
    
    func updateDoughBatterFillingIngredientAmount(_ amount: String, at index: Int) {
        guard index >= 0 && index < doughBatterFillingIngredients.count else { return }
        doughBatterFillingIngredients[index].amount = amount
    }
    
    func updateDoughBatterFillingIngredientUnit(_ unit: String, at index: Int) {
        guard index >= 0 && index < doughBatterFillingIngredients.count else { return }
        doughBatterFillingIngredients[index].unit = unit
    }
    
    func updateDoughBatterFillingIngredientName(_ name: String, at index: Int) {
        guard index >= 0 && index < doughBatterFillingIngredients.count else { return }
        doughBatterFillingIngredients[index].name = name
    }
    
    func addSauceIngredient() {
        sauceIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func removeSauceIngredient(at index: Int) {
        guard index >= 0 && index < sauceIngredients.count else { return }
        sauceIngredients.remove(at: index)
    }
    
    func updateSauceIngredientAmount(_ amount: String, at index: Int) {
        guard index >= 0 && index < sauceIngredients.count else { return }
        sauceIngredients[index].amount = amount
    }
    
    func updateSauceIngredientUnit(_ unit: String, at index: Int) {
        guard index >= 0 && index < sauceIngredients.count else { return }
        sauceIngredients[index].unit = unit
    }
    
    func updateSauceIngredientName(_ name: String, at index: Int) {
        guard index >= 0 && index < sauceIngredients.count else { return }
        sauceIngredients[index].name = name
    }
    
    func addToppingIngredient() {
        toppingIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func removeToppingIngredient(at index: Int) {
        guard index >= 0 && index < toppingIngredients.count else { return }
        toppingIngredients.remove(at: index)
    }
    
    func updateToppingIngredientAmount(_ amount: String, at index: Int) {
        guard index >= 0 && index < toppingIngredients.count else { return }
        toppingIngredients[index].amount = amount
    }
    
    func updateToppingIngredientUnit(_ unit: String, at index: Int) {
        guard index >= 0 && index < toppingIngredients.count else { return }
        toppingIngredients[index].unit = unit
    }
    
    func updateToppingIngredientName(_ name: String, at index: Int) {
        guard index >= 0 && index < toppingIngredients.count else { return }
        toppingIngredients[index].name = name
    }
    
    func addGarnishIngredient() {
        garnishIngredients.append(RecipeTextParser.IngredientItem(amount: "", unit: "", name: ""))
    }
    
    func removeGarnishIngredient(at index: Int) {
        guard index >= 0 && index < garnishIngredients.count else { return }
        garnishIngredients.remove(at: index)
    }
    
    func updateGarnishIngredientAmount(_ amount: String, at index: Int) {
        guard index >= 0 && index < garnishIngredients.count else { return }
        garnishIngredients[index].amount = amount
    }
    
    func updateGarnishIngredientUnit(_ unit: String, at index: Int) {
        guard index >= 0 && index < garnishIngredients.count else { return }
        garnishIngredients[index].unit = unit
    }
    
    func updateGarnishIngredientName(_ name: String, at index: Int) {
        guard index >= 0 && index < garnishIngredients.count else { return }
        garnishIngredients[index].name = name
    }
    
    // MARK: - Recipe Image Management
    
    func addRecipeImage(_ image: UIImage) {
        guard mainRecipeImages.count < 5 else { return }
        mainRecipeImages.append(image)
    }
    
    func removeRecipeImage(at index: Int) {
        guard index >= 0 && index < mainRecipeImages.count else { return }
        mainRecipeImages.remove(at: index)
    }
    
    // MARK: - Save Recipe
    
    func saveRecipe(image: UIImage? = nil) async -> Bool {
        guard let userID = Auth.auth().currentUser?.uid,
              let displayName = Auth.auth().currentUser?.displayName else {
            errorMessage = LocalizedString("You must be logged in to save a recipe", comment: "Not logged in error")
            return false
        }
        
        // Get username from AuthService (ensure user data is loaded)
        let authService = AuthService()
        await authService.reloadUserData()
        let username = authService.currentUser?.username
        // Use username for authorName if available, otherwise fall back to displayName
        let authorName = username ?? displayName
        
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = LocalizedString("Title is required", comment: "Title required error")
            return false
        }
        
        // Combine all ingredient types, filter out empty ones
        let validMarinadeItems = marinadeIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validSeasoningItems = seasoningIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validDishItems = dishIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validDoughBatterFillingItems = doughBatterFillingIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validSauceItems = sauceIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validToppingItems = toppingIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let validGarnishItems = garnishIngredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard !validDishItems.isEmpty else {
            errorMessage = LocalizedString("At least one dish ingredient is required", comment: "Dish ingredients required error")
            return false
        }
        
        // Convert ingredient items to Ingredient objects with IDs and categories
        var ingredientObjects: [Ingredient] = []
        
        // Add ingredients with their respective categories
        ingredientObjects.append(contentsOf: validDishItems.map { 
            Ingredient(amount: $0.amount, unit: $0.unit, name: $0.name, category: .dish) 
        })
        ingredientObjects.append(contentsOf: validMarinadeItems.map { 
            Ingredient(amount: $0.amount, unit: $0.unit, name: $0.name, category: .marinade) 
        })
        ingredientObjects.append(contentsOf: validSeasoningItems.map { 
            Ingredient(amount: $0.amount, unit: $0.unit, name: $0.name, category: .seasoning) 
        })
        ingredientObjects.append(contentsOf: validDoughBatterFillingItems.map { 
            Ingredient(amount: $0.amount, unit: $0.unit, name: $0.name, category: .batter) // Default to .batter for consolidated dough/batter/filling section
        })
        ingredientObjects.append(contentsOf: validSauceItems.map { 
            Ingredient(amount: $0.amount, unit: $0.unit, name: $0.name, category: .sauce) 
        })
        ingredientObjects.append(contentsOf: validToppingItems.map { 
            Ingredient(amount: $0.amount, unit: $0.unit, name: $0.name, category: .topping) 
        })
        ingredientObjects.append(contentsOf: validGarnishItems.map { 
            Ingredient(amount: $0.amount, unit: $0.unit, name: $0.name, category: .garnish) 
        })
        
        let validInstructions = instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !validInstructions.isEmpty else {
            errorMessage = LocalizedString("At least one instruction is required", comment: "Instructions required error")
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Upload all recipe images (up to 5)
            var allImageURLs: [String] = []
            for image in mainRecipeImages {
                let imagePath = "recipes/\(UUID().uuidString).jpg"
                if let url = try? await storageService.uploadImage(image, path: imagePath) {
                    allImageURLs.append(url)
                }
            }
            
            // Use first image URL for backward compatibility
            let mainImageURL = allImageURLs.first
            
            // Convert instructions to Instruction objects
            let instructionObjects = validInstructions.map { text in
                Instruction(text: text.trimmingCharacters(in: .whitespaces))
            }
            
            // Translate title to English, local language, and preserve original
            // ALWAYS use original extracted title if available (before any translation)
            // This ensures we preserve the original language (e.g., Dutch)
            let titleToTranslate: String
            if let originalTitle = originalExtractedTitle, !originalTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                titleToTranslate = originalTitle.trimmingCharacters(in: .whitespaces)
                print("📝 Using original extracted title for translation: \(titleToTranslate)")
            } else {
                titleToTranslate = title.trimmingCharacters(in: .whitespaces)
                print("⚠️ No original title found, using current title: \(titleToTranslate)")
            }
            let (titleEnglish, titleLocal, titleOriginal) = await RecipeTranslationService.translateTitle(titleToTranslate)
            print("📝 Translation result - English: \(titleEnglish), Local: \(titleLocal), Original: \(titleOriginal ?? "nil")")
            
            // Update UI fields so they show in the edit form
            self.titleEnglish = titleEnglish
            self.titleLocal = titleLocal
            self.titleOriginal = titleOriginal
            // Set main title to local language (or English if local is not available)
            self.title = titleLocal.isEmpty ? titleEnglish : titleLocal
            
            // Create recipe - Use original language as primary title
            let primaryTitle = titleOriginal ?? (titleLocal.isEmpty ? titleEnglish : titleLocal)
            
            // Save cuisine in English (translations are handled by CuisineTranslations)
            let cuisineEnglish: String? = cuisine?.trimmingCharacters(in: .whitespaces).isEmpty == false ? cuisine?.trimmingCharacters(in: .whitespaces) : nil
            
            let recipe = Recipe(
                title: primaryTitle, // Use original language as primary
                titleEnglish: titleEnglish,
                titleLocal: titleLocal,
                titleOriginal: titleOriginal,
                description: description.trimmingCharacters(in: .whitespaces),
                ingredients: ingredientObjects,
                instructions: instructionObjects,
                prepTime: prepTime,
                cookTime: cookTime,
                servings: servings,
                difficulty: difficulty,
                spicyLevel: spicyLevel,
                tips: tips.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
                cuisine: cuisine?.trimmingCharacters(in: .whitespaces).isEmpty == false ? cuisine?.trimmingCharacters(in: .whitespaces) : nil,
                cuisineEnglish: cuisineEnglish,
                imageURL: mainImageURL, // For backward compatibility
                imageURLs: allImageURLs, // Array of all image URLs
                authorID: userID,
                authorName: authorName,
                authorUsername: username
            )
            
            try await recipeService.createRecipe(recipe)
            isLoading = false
            
            // Post notification to refresh account view
            NotificationCenter.default.post(name: NSNotification.Name("RecipeSaved"), object: nil)
            
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    private var pluralForms: [String: String] {
        [
            "cup": "cups",
            "pinch": "pinches",
            "piece": "pieces",
            "pc": "pieces",
            "slice": "slices",
            "clove": "cloves",
            "bunch": "bunches",
            "head": "heads",
            "strand": "strands"
        ]
    }
    
    // MARK: - AI Generation Methods
    
    /// Generate a description for the recipe using AI
    func generateDescription() async {
        guard !title.isEmpty else {
            errorMessage = LocalizedString("Please enter a recipe title first", comment: "Title required for description")
            return
        }
        
        isGeneratingDescription = true
        errorMessage = nil
        
        do {
            let allIngredients = (marinadeIngredients + seasoningIngredients + dishIngredients)
                .map { item in
                    if item.unit.isEmpty {
                        return item.amount.isEmpty ? item.name : "\(item.amount) \(item.name)"
                    } else {
                        return "\(item.amount) \(item.unit) \(item.name)"
                    }
                }
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            let generatedDescription = try await OpenAIService.generateRecipeDescription(
                title: title,
                ingredients: allIngredients,
                instructions: instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            )
            
            if !generatedDescription.isEmpty {
                description = generatedDescription
            }
        } catch {
            errorMessage = LocalizedString("Failed to generate description: \(error.localizedDescription)", comment: "Description generation error")
        }
        
        isGeneratingDescription = false
    }
    
    /// Detect and set the most suitable cuisine for the recipe
    func detectCuisine() async {
        guard !title.isEmpty else {
            return
        }
        
        // Only detect if cuisine is not already set
        guard cuisine == nil || cuisine?.isEmpty == true else {
            return
        }
        
        isDetectingCuisine = true
        
        do {
            let allIngredients = (marinadeIngredients + seasoningIngredients + dishIngredients)
                .map { item in
                    if item.unit.isEmpty {
                        return item.amount.isEmpty ? item.name : "\(item.amount) \(item.name)"
                    } else {
                        return "\(item.amount) \(item.unit) \(item.name)"
                    }
                }
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            if let detectedCuisine = try await OpenAIService.detectCuisine(
                title: title,
                ingredients: allIngredients,
                instructions: instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            ) {
                cuisine = detectedCuisine
            }
        } catch {
            // Silently fail for cuisine detection - it's not critical
            print("Failed to detect cuisine: \(error.localizedDescription)")
        }
        
        isDetectingCuisine = false
    }
    
    /// Extract preparation and cooking time from instructions
    func extractTime() async {
        guard !instructions.isEmpty else {
            return
        }
        
        isExtractingTime = true
        
        do {
            let (extractedPrepTime, extractedCookTime) = try await OpenAIService.extractTimeFromInstructions(
                title: title,
                instructions: instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            )
            prepTime = extractedPrepTime
            cookTime = extractedCookTime
        } catch {
            // Silently fail for time extraction - use defaults
            print("Failed to extract time: \(error.localizedDescription)")
        }
        
        isExtractingTime = false
    }
    
    /// Detect and set the difficulty level for the recipe
    func detectDifficulty() async {
        guard !title.isEmpty else {
            return
        }
        
        isDetectingDifficulty = true
        
        do {
            let allIngredients = (marinadeIngredients + seasoningIngredients + dishIngredients)
                .map { item in
                    if item.unit.isEmpty {
                        return item.amount.isEmpty ? item.name : "\(item.amount) \(item.name)"
                    } else {
                        return "\(item.amount) \(item.unit) \(item.name)"
                    }
                }
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            let detectedDifficulty = try await OpenAIService.detectDifficulty(
                title: title,
                ingredients: allIngredients,
                instructions: instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            )
            difficulty = detectedDifficulty
        } catch {
            // Silently fail for difficulty detection - use default
            print("Failed to detect difficulty: \(error.localizedDescription)")
        }
        
        isDetectingDifficulty = false
    }
}

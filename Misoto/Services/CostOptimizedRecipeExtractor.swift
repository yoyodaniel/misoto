//
//  CostOptimizedRecipeExtractor.swift
//  Misoto
//
//  Cost-optimized recipe extraction using iOS OCR + on-device parsing + optional OpenAI refinement
//

import Foundation
import UIKit

@MainActor
class CostOptimizedRecipeExtractor {
    private let visionExtractor = VisionTextExtractor()
    private let textParser = RecipeTextParser.self
    
    /// Extract recipe from images using OCR-first approach
    /// - Parameters:
    ///   - images: Images to extract from
    ///   - useOpenAIRefinement: If true, uses OpenAI to refine the parsed recipe (costs more but better quality)
    /// - Returns: Parsed recipe response
    func extractRecipe(
        from images: [UIImage],
        useOpenAIRefinement: Bool = false
    ) async throws -> OpenAIRecipeResponse {
        guard !images.isEmpty else {
            throw CostOptimizedExtractionError.noImages
        }
        
        // Step 1: Extract text using iOS OCR (FREE)
        var extractedText = try await visionExtractor.extractText(from: images)
        
        guard !extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CostOptimizedExtractionError.noTextExtracted
        }
        
        // Step 1.5: Detect language and translate to English if needed
        print("🔍 Detecting language of extracted text...")
        extractedText = await TextTranslationService.translateToEnglish(extractedText)
        print("✅ Text ready for processing (translated to English if needed)")
        
        // Step 2: Parse text using on-device parser (FREE)
        let parsedRecipe = textParser.parse(extractedText)
        
        // Step 3: Convert to OpenAIRecipeResponse format
        var response = convertToOpenAIResponse(from: parsedRecipe)
        
        // Step 4: Optional OpenAI refinement (COSTS MONEY but improves quality)
        if useOpenAIRefinement {
            do {
                // Use OpenAI to refine the parsed recipe from text (much cheaper than sending images)
                // Note: extractedText is already translated to English at this point
                let refinedResponse = try await OpenAIService.parseRecipeFromText(extractedText)
                
                // Merge refined response with parsed response (prefer refined data but keep what we have)
                response = mergeResponses(original: response, refined: refinedResponse)
            } catch {
                // If refinement fails, continue with on-device parsed result
                print("OpenAI refinement failed: \(error.localizedDescription), using on-device parsed result")
            }
        }
        
        return response
    }
    
    /// Convert RecipeTextParser.ParsedRecipe to OpenAIRecipeResponse
    private func convertToOpenAIResponse(from parsed: RecipeTextParser.ParsedRecipe) -> OpenAIRecipeResponse {
        // RecipeTextParser only supports dishIngredients, marinadeIngredients, and seasoningIngredients
        // Other categories (batter, sauce, base, dough, topping) will be populated by OpenAI refinement if enabled
        
        // Extract servings, prepTime, cookTime from text if possible
        let (servings, prepTime, cookTime) = extractMetadata(from: parsed)
        
        return OpenAIRecipeResponse(
            title: parsed.title,
            description: parsed.description,
            servings: servings,
            prepTime: prepTime,
            cookTime: cookTime,
            dishIngredients: parsed.dishIngredients,
            marinadeIngredients: parsed.marinadeIngredients,
            seasoningIngredients: parsed.seasoningIngredients,
            batterIngredients: [], // Will be populated by refinement if available
            sauceIngredients: [], // Will be populated by refinement if available
            baseIngredients: [], // Will be populated by refinement if available
            doughIngredients: [], // Will be populated by refinement if available
            toppingIngredients: [], // Will be populated by refinement if available
            instructions: parsed.instructions,
            tips: [] // Will be populated by refinement if available
        )
    }
    
    /// Extract metadata (servings, prepTime, cookTime) from parsed recipe
    private func extractMetadata(from parsed: RecipeTextParser.ParsedRecipe) -> (servings: Int, prepTime: Int, cookTime: Int) {
        let fullText = (parsed.title + " " + parsed.description + " " + parsed.instructions.joined(separator: " ")).lowercased()
        
        // Also include ingredient text for better metadata extraction
        let ingredientText = (parsed.dishIngredients + parsed.marinadeIngredients + parsed.seasoningIngredients)
            .map { "\($0.amount) \($0.unit) \($0.name)" }
            .joined(separator: " ")
        let combinedText = (fullText + " " + ingredientText).lowercased()
        
        var servings = 0
        var prepTime = 0
        var cookTime = 0
        
        // Extract servings
        let servingPatterns = [
            "serves\\s+(\\d+)",
            "(\\d+)\\s+servings",
            "serves\\s+(\\d+)\\s*-\\s*(\\d+)",
            "makes\\s+(\\d+)"
        ]
        
        for pattern in servingPatterns {
            if let range = combinedText.range(of: pattern, options: .regularExpression) {
                let matchString = String(combinedText[range])
                if let match = Int(matchString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                    servings = match
                    break
                }
            }
        }
        
        // Extract prep time
        let prepPatterns = [
            "prep\\s+time[:\\s]+(\\d+)\\s*(?:min|minute|mins)",
            "preparation\\s+time[:\\s]+(\\d+)\\s*(?:min|minute|mins)",
            "prep[:\\s]+(\\d+)\\s*(?:min|minute|mins)"
        ]
        
        for pattern in prepPatterns {
            if let range = combinedText.range(of: pattern, options: .regularExpression) {
                let matchString = String(combinedText[range])
                if let match = Int(matchString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                    prepTime = match
                    break
                }
            }
        }
        
        // Extract cook time
        let cookPatterns = [
            "cook\\s+time[:\\s]+(\\d+)\\s*(?:min|minute|mins)",
            "cooking\\s+time[:\\s]+(\\d+)\\s*(?:min|minute|mins)",
            "cook[:\\s]+(\\d+)\\s*(?:min|minute|mins)"
        ]
        
        for pattern in cookPatterns {
            if let range = combinedText.range(of: pattern, options: .regularExpression) {
                let matchString = String(combinedText[range])
                if let match = Int(matchString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
                    cookTime = match
                    break
                }
            }
        }
        
        return (servings, prepTime, cookTime)
    }
    
    /// Merge original and refined responses, preferring refined data
    private func mergeResponses(original: OpenAIRecipeResponse, refined: OpenAIRecipeResponse) -> OpenAIRecipeResponse {
        return OpenAIRecipeResponse(
            title: refined.title.isEmpty ? original.title : refined.title,
            description: refined.description.isEmpty ? original.description : refined.description,
            servings: refined.servings > 0 ? refined.servings : original.servings,
            prepTime: refined.prepTime > 0 ? refined.prepTime : original.prepTime,
            cookTime: refined.cookTime > 0 ? refined.cookTime : original.cookTime,
            dishIngredients: refined.dishIngredients.isEmpty ? original.dishIngredients : refined.dishIngredients,
            marinadeIngredients: refined.marinadeIngredients.isEmpty ? original.marinadeIngredients : refined.marinadeIngredients,
            seasoningIngredients: refined.seasoningIngredients.isEmpty ? original.seasoningIngredients : refined.seasoningIngredients,
            batterIngredients: refined.batterIngredients,
            sauceIngredients: refined.sauceIngredients,
            baseIngredients: refined.baseIngredients,
            doughIngredients: refined.doughIngredients,
            toppingIngredients: refined.toppingIngredients,
            instructions: refined.instructions.isEmpty ? original.instructions : refined.instructions,
            tips: refined.tips
        )
    }
}

enum CostOptimizedExtractionError: LocalizedError {
    case noImages
    case noTextExtracted
    case parsingFailed
    
    var errorDescription: String? {
        switch self {
        case .noImages:
            return LocalizedString("No images provided", comment: "No images error")
        case .noTextExtracted:
            return LocalizedString("No text could be extracted from images", comment: "No text extracted error")
        case .parsingFailed:
            return LocalizedString("Failed to parse recipe from extracted text", comment: "Parsing failed error")
        }
    }
}


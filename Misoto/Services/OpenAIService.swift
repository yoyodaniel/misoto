//
//  OpenAIService.swift
//  Misoto
//
//  Service for OpenAI API integration for recipe extraction
//

import Foundation
import UIKit
import NaturalLanguage

@MainActor
class OpenAIService {
    private static var apiKey: String {
        // Read from environment variable or Info.plist
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !key.isEmpty {
            return key
        }
        // Fallback to Info.plist if environment variable is not set
        if let key = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String, !key.isEmpty {
            return key
        }
        return ""
    }
    private static let baseURL = "https://api.openai.com/v1"
    
    /// Extract recipe information from an image using OpenAI Vision API
    static func extractRecipe(from image: UIImage) async throws -> OpenAIRecipeResponse {
        return try await extractRecipe(from: [image])
    }
    
    /// Extract recipe information from multiple images using OpenAI Vision API
    static func extractRecipe(from images: [UIImage]) async throws -> OpenAIRecipeResponse {
        guard !apiKey.isEmpty else {
            throw OpenAIError.apiKeyNotConfigured
        }
        
        guard !images.isEmpty else {
            throw OpenAIError.imageConversionFailed
        }
        
        // Process all images: optimize and convert to base64
        var imageContentItems: [[String: Any]] = []
        
        for image in images {
        // Optimize image before sending to API (resize and compress to reduce payload size)
        let optimizedImage = await ImageOptimizer.resizeForProcessing(image)
        
        // Convert image to base64 with compression (reduced quality slightly to save on tokens)
        guard let imageData = ImageOptimizer.compressImage(optimizedImage, quality: 0.75, maxFileSizeKB: 800) else {
                continue // Skip this image if conversion fails
            }
            let base64Image = imageData.base64EncodedString()
            
            imageContentItems.append([
                "type": "image_url",
                "image_url": [
                    "url": "data:image/jpeg;base64,\(base64Image)"
                ]
            ])
        }
        
        guard !imageContentItems.isEmpty else {
            throw OpenAIError.imageConversionFailed
        }
        
        // Create the request
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create the prompt for recipe extraction (optimized for cost)
        let systemPrompt = """
        Extract recipe from image(s). If multiple images are provided, combine information from all images to create a complete recipe. 
        IMPORTANT: Check ALL text in the images for references to other pages or recipes (e.g., "see page 245", "refer to page X"). 
        If ingredients mention other pages, those pages likely contain marinade/sauce/preparation recipes that must be included FIRST in the instructions.
        TRANSLATE ALL TEXT TO ENGLISH: If the recipe text is in any language other than English, translate it to English before extracting. 
        All extracted content (title, description, ingredients, instructions) must be in English. Return JSON only.
        
        Sections: dishIngredients, marinadeIngredients, seasoningIngredients, batterIngredients, sauceIngredients, baseIngredients, doughIngredients, toppingIngredients, instructions.
        Ingredients: amount (number/decimals), unit (tbsp/tsp/cup/g/kg/ml/l/oz/fl_oz/lb/piece/pinch), name (Capitalized Words).
        Note: "Oz" unit usage - CRITICAL DISTINCTION:
        - Use "fl_oz" (liquid ounces) ONLY for liquids: water, milk, oil, broth, juice, wine, vinegar, etc.
        - Use "oz" (weight ounces) ONLY for weight/solids: meat, flour, cheese, vegetables, fruits, etc.
        - NEVER use "oz" for liquids - always use "fl_oz" for liquids
        - NEVER use "fl_oz" for weight/solids - always use "oz" for weight/solids
        - If you see "oz" in the recipe text and it's a liquid, convert it to "fl_oz"
        - If you see "oz" in the recipe text and it's a solid/weight, use "oz"
        - If uncertain about a liquid vs solid, check the ingredient name (liquids: water, milk, oil, etc. → use "fl_oz"; solids: meat, flour, etc. → use "oz")
        IMPORTANT: Read the ENTIRE amount including ALL fractions before converting. Convert all fractions and mixed numbers to decimals:
        - "1/2" → "0.5"
        - "1/4" → "0.25"
        - "1/8" → "0.125"
        - "1/12" → "0.083" (approximately 0.083333...)
        - "1/3" → "0.333" (approximately 0.333333...)
        - "2/3" → "0.667" (approximately 0.666666...)
        - "3/4" → "0.75"
        - "1 1/2" or "1½" → "1.5" (read BOTH the whole number AND the fraction)
        - "1 1/4" → "1.25"
        - "2 1/4" → "2.25"
        - "3 1/2" or "3½" → "3.5"
        CRITICAL: When you see "1 1/2", you must read it as "one AND one-half" = 1.5, NOT just "1". The fraction part MUST be included.
        CRITICAL: When you see "1/12", you must read it as "one-twelfth" = 0.083, NOT "0.5" or any other value.
        Mixed numbers (whole number + fraction) must be converted to a single decimal number that includes BOTH parts.
        LANGUAGE PRESERVATION: Keep the same language as the images. Only translate if absolutely necessary for JSON structure compatibility. Preserve original wording and phrasing.
        
        INGREDIENT AMOUNT AND UNIT VALIDATION (CRITICAL - ACCURACY CHECK):
        - DOUBLE-CHECK: Before extracting an ingredient, carefully verify the exact amount and unit shown in the image. Do not guess or assume amounts.
        - READ ENTIRE AMOUNT: Read the COMPLETE amount including any fractions. If you see "1 1/2", read it as "one and one-half" = 1.5, NOT just "1". If you see "1/12", read it as "one-twelfth" = 0.083, NOT "0.5".
        - FRACTION CONVERSION VERIFICATION: After converting fractions, verify the conversion is correct:
          * "1 1/2" must become "1.5" (NOT "1" or "2")
          * "1/12" must become "0.083" (NOT "0.5" or any other value)
          * "1/8" must become "0.125"
          * "1/4" must become "0.25"
          * "1/3" must become "0.333"
          * "1/2" must become "0.5"
          * "2/3" must become "0.667"
          * "3/4" must become "0.75"
        - MIXED NUMBER VERIFICATION: For mixed numbers like "1 1/2", verify you captured BOTH the whole number (1) AND the fraction (1/2 = 0.5), resulting in 1.5 total.
        - Re-check all fraction conversions before finalizing.
        - QUALITATIVE MEASUREMENTS: If the recipe says "to taste", "as needed", "optional", "a pinch", or similar qualitative terms, use these exact terms:
          * For "to taste" or "as needed": amount = "0", unit = "", name = "Salt (to taste)" or "Salt (as needed)"
          * For "a pinch": amount = "1", unit = "pinch", name = "Salt"
          * DO NOT convert qualitative measurements to specific amounts (e.g., "salt to taste" should NOT become "1.5 tsp salt")
        - MISSING INGREDIENTS CHECK: After extraction, review the image again to ensure ALL ingredients listed in the recipe are captured. Do not skip any ingredients.
        - AMOUNT VERIFICATION: Cross-reference extracted amounts with what is actually visible in the image. If uncertain, extract exactly what is shown, do not estimate.
        - UNIT ACCURACY: Verify the unit matches what is written (tbsp vs tsp, cup vs cups, etc.). Pay attention to abbreviations and full words.
        - If an ingredient amount is unclear or not visible, use amount = "0" and include "(amount unclear)" in the name.
        
        INGREDIENT NAME ACCURACY (CRITICAL - EXACT WORD EXTRACTION):
        - EXTRACT EXACT WORDS: Extract ingredient names EXACTLY as written in the image. Do NOT substitute, assume, or change words.
        - NO WORD SUBSTITUTIONS: If the image says "sesame powder", extract "sesame powder" - NOT "sesame oil", "sesame seeds", or any other variation.
        - VERIFY EACH WORD: Read each word of the ingredient name carefully. "Powder" is NOT the same as "oil". "Fresh" is NOT the same as "dried". Extract exactly what is written.
        - DO NOT ASSUME: Do not assume similar ingredients. If you see "sesame powder", do not extract "sesame oil" thinking it's similar. They are different ingredients.
        - IF UNCERTAIN: If a word is unclear or partially visible, extract what you can see and mark uncertainty, but DO NOT substitute with a different word.
        - VERIFICATION STEP: After extracting each ingredient name, verify it matches exactly what is written in the image. If it doesn't match, correct it.
        - COMMON ERRORS TO AVOID: Do not confuse "powder" with "oil", "fresh" with "dried", "ground" with "whole", "chopped" with "whole", etc. Extract the exact word as written.
        
        INGREDIENT SECTION ASSIGNMENT RULES (CRITICAL - NO DUPLICATION):
        - marinadeIngredients: ONLY ingredients that are explicitly part of a marinade, sauce, or pre-soaking mixture. If an ingredient is mentioned as part of a marinade (e.g., "marinate with mirin, soy sauce, and sugar"), place it ONLY in marinadeIngredients, NOT in dishIngredients.
        - dishIngredients: ONLY ingredients that are used directly in the main cooking/preparation process, NOT ingredients that are already included in marinades.
        - seasoningIngredients: ONLY spices, herbs, salt, pepper, and other seasonings used for flavoring during cooking.
        - CHECK FOR DUPLICATION: Before placing an ingredient, verify it does not already exist in another section. If an ingredient is part of a marinade, it should ONLY appear in marinadeIngredients, never in dishIngredients.
        - If the recipe mentions "marinade" or "marinate", all ingredients listed in that marinade must go ONLY in marinadeIngredients.
        - Example: If mirin is used in a marinade, it should ONLY be in marinadeIngredients, NOT duplicated in dishIngredients.
        
        INSTRUCTIONS EXTRACTION GUIDELINES:
        - CHECK TEXT BEFORE WRITING: Carefully read and analyze ALL text in the images before extracting instructions. Look for references to other pages, recipes, or preparations (e.g., "see page 245", "refer to recipe on page X", "Nubo-style saikyo miso (see page 245)").
        - DETECT CROSS-PAGE REFERENCES: If an ingredient mentions another page or recipe (e.g., "miso (see page 245)", "marinade recipe on page 123"), this indicates a separate preparation that needs to be included.
        - SEQUENCE DETECTION AND ORDERING: Detect dependencies and order steps logically:
          * If a marinade, sauce, or preparation is referenced from another page, the preparation steps for that marinade/sauce MUST be the FIRST steps
          * After the marinade/sauce is prepared, then include steps to apply/use it
          * Follow the natural sequence: prepare dependencies → apply dependencies → main cooking → finish
        - USE ORIGINAL LANGUAGE: Keep the same language as the images. Preserve original terminology and key details.
        - FLOW AND CLARITY: You are allowed to rewrite and rephrase instructions for better flow and clarity while preserving the original meaning and key information.
        - STEP LIMIT: Keep instructions to a maximum of 10 steps (single digit preferred, ideally 5-8 steps). Combine related steps logically to achieve this.
        - RECIPE STRUCTURE AWARENESS: Pay attention to the logical order of the recipe:
          * Preparation steps (marinades, pre-soaking, pre-cooking preparations) should be in the FIRST steps
          * If a marinade is mentioned (either in the current page or referenced from another page), include its preparation as one of the first steps
          * Follow the natural cooking sequence: prep dependencies → apply dependencies → cook → finish
        - PRESERVE KEY DETAILS: Always preserve important details like temperatures, cooking times, techniques, and methods. Include these in your rewritten steps.
        - COMBINE LOGICALLY: Combine sequential actions that happen in the same phase (e.g., "Heat oil in pan, then add onions and cook until translucent").
        - REWRITE FOR CLARITY: You may rewrite steps to make them clearer and more actionable, but maintain the original meaning and all critical information.
        - GROUP RELATED STEPS: Group preparation steps together, cooking steps together, finishing steps together.
        - MULTI-PAGE RECIPES: When multiple images are provided, they may contain:
          * Main recipe on one page
          * Marinade/sauce/preparation recipe on another page
          * Combine information from all pages, placing preparation steps first, then application steps
        
        SERVINGS EXTRACTION:
        - Look for text indicating number of servings: "serves 4", "4 servings", "serves 4-6", "makes 4 servings", etc.
        - Extract the number as an integer. If a range is given (e.g., "4-6"), use the first number or average.
        - If no servings information is found, use 0 (will be set to default later).
        
        TIME EXTRACTION:
        - PREPARATION TIME: Look for "prep time", "preparation time", "prep", "marinate", "soak", "overnight", etc.
        - COOKING TIME: Look for "cook time", "cooking time", "cook for", "bake for", "simmer for", etc.
        - TIME UNITS: Extract time in minutes, but handle various formats:
          * "30 minutes" or "30 mins" → 30 minutes
          * "1 hour" or "1 hr" → 60 minutes
          * "1.5 hours" or "1 1/2 hours" → 90 minutes
          * "2 hours" → 120 minutes
          * "overnight" or "marinate overnight" → 1440 minutes (24 hours)
          * "1 day" → 1440 minutes
          * "2 days" → 2880 minutes
          * "30 seconds" → 0.5 minutes (round to 1 minute)
        - If time mentions "overnight" or "days", convert to minutes (1 day = 1440 minutes).
        - If no time information is found, use 0 for both prepTime and cookTime (will be extracted from instructions later if needed).
        
        TIPS EXTRACTION:
        - Look for sections labeled "Tips", "Notes", "Note", "Tip", "Helpful Tips", "Cooking Tips", "Chef's Tips", or similar headings
        - Extract any text that provides additional advice, variations, substitutions, storage tips, serving suggestions, or helpful information
        - Look for text in boxes, callouts, or special formatting that indicates tips or notes
        - Extract tips as an array of strings, with each tip as a separate item
        - If no tips are found, use an empty array []
        
        JSON format:
        {"title":"Recipe Title","description":"Description","servings":4,"prepTime":30,"cookTime":60,"dishIngredients":[{"amount":"12","unit":"","name":"Item"}],"marinadeIngredients":[],"seasoningIngredients":[],"batterIngredients":[],"sauceIngredients":[],"baseIngredients":[],"doughIngredients":[],"toppingIngredients":[],"instructions":["Step 1 with full details","Step 2 with full details"],"tips":["Tip 1","Tip 2"]}
        """
        
        let userPrompt = images.count > 1 ? "Extract recipe from all images. Check for cross-page references in ingredients (e.g., 'see page 245'). If a marinade/sauce is referenced from another page, include its preparation steps FIRST, then the steps to apply it. Also look for tips, notes, or helpful information sections and extract them into the tips array. Combine information from all pages to create a complete recipe. PRESERVE the original language. Rewrite instructions for better flow and clarity, keeping to a maximum of 10 steps. Ensure marinades and preparations are in the first steps, followed by application steps. Return JSON only." : "Extract recipe from image. Check for cross-page references in ingredients (e.g., 'see page 245'). If a marinade/sauce is referenced from another page, include its preparation steps FIRST, then the steps to apply it. Also look for tips, notes, or helpful information sections and extract them into the tips array. PRESERVE the original language. Rewrite instructions for better flow and clarity, keeping to a maximum of 10 steps. Ensure marinades and preparations are in the first steps, followed by application steps. Return JSON only."
        
        // Build content array: text prompt first, then all images
        var contentArray: [[String: Any]] = [
            [
                "type": "text",
                "text": userPrompt
            ]
        ]
        contentArray.append(contentsOf: imageContentItems)
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini", // Cheaper vision model (supports images)
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": contentArray
                ]
            ],
            "response_format": ["type": "json_object"],
            "max_tokens": 2000,
            "temperature": 0.1
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw OpenAIError.requestSerializationFailed
        }
        request.httpBody = httpBody
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIError.apiError(message)
            }
            throw OpenAIError.httpError(httpResponse.statusCode)
        }
        
        // Parse the response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        // Extract JSON from the response (it might be wrapped in markdown code blocks)
        let jsonString = extractJSON(from: content)
        
        // Parse the recipe data
        guard let jsonData = jsonString.data(using: .utf8),
              let recipeDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw OpenAIError.jsonParsingFailed
        }
        
        return try parseRecipeResponse(from: recipeDict)
    }
    
    /// Parse recipe from extracted text (for cost-optimized flow: OCR -> local parsing -> optional OpenAI refinement)
    /// This is much cheaper than sending images to OpenAI Vision API
    static func parseRecipeFromText(_ extractedText: String) async throws -> OpenAIRecipeResponse {
        guard !apiKey.isEmpty else {
            throw OpenAIError.apiKeyNotConfigured
        }
        
        guard !extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OpenAIError.invalidResponse
        }
        
        // Create the request
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Use the same system prompt as extractRecipe(fromURL:) since it's text-based
        let systemPrompt = """
        Extract recipe from text. PRESERVE THE ORIGINAL LANGUAGE from the text - do NOT translate to English unless the language is not supported. Return JSON only.
        
        IMPORTANT: Ingredients may be formatted with bullet points, dashes, or hyphens (e.g., "- 500gr bakkeljauw", "– 2 uien", "• 4 teentjes knoflook"). 
        Always extract the amount and unit correctly even when prefixed with these characters. Ignore leading dashes, bullets, or hyphens when parsing amounts.
        
        Sections: dishIngredients, marinadeIngredients, seasoningIngredients, batterIngredients, sauceIngredients, baseIngredients, doughIngredients, toppingIngredients, instructions.
        Ingredients: amount (number/decimals), unit (tbsp/tsp/cup/g/kg/ml/l/oz/fl_oz/lb/piece/pinch/gr/gram/grams), name (Capitalized Words).
        Note: "Oz" unit usage - CRITICAL DISTINCTION:
        - Use "fl_oz" (liquid ounces) ONLY for liquids: water, milk, oil, broth, juice, wine, vinegar, etc.
        - Use "oz" (weight ounces) ONLY for weight/solids: meat, flour, cheese, vegetables, fruits, etc.
        - NEVER use "oz" for liquids - always use "fl_oz" for liquids
        - NEVER use "fl_oz" for weight/solids - always use "oz" for weight/solids
        - If you see "oz" in the recipe text and it's a liquid, convert it to "fl_oz"
        - If you see "oz" in the recipe text and it's a solid/weight, use "oz"
        - If uncertain about a liquid vs solid, check the ingredient name (liquids: water, milk, oil, etc. → use "fl_oz"; solids: meat, flour, etc. → use "oz")
        IMPORTANT: Read the ENTIRE amount including ALL fractions before converting. Convert all fractions and mixed numbers to decimals:
        - "1/2" → "0.5"
        - "1/4" → "0.25"
        - "1/8" → "0.125"
        - "1/12" → "0.083" (approximately 0.083333...)
        - "1/3" → "0.333" (approximately 0.333333...)
        - "2/3" → "0.667" (approximately 0.666666...)
        - "3/4" → "0.75"
        - "1 1/2" or "1½" → "1.5" (read BOTH the whole number AND the fraction)
        - "1 1/4" → "1.25"
        - "2 1/4" → "2.25"
        - "3 1/2" or "3½" → "3.5"
        CRITICAL: When you see "1 1/2", you must read it as "one AND one-half" = 1.5, NOT just "1". The fraction part MUST be included.
        CRITICAL: When you see "1/12", you must read it as "one-twelfth" = 0.083, NOT "0.5" or any other value.
        Mixed numbers (whole number + fraction) must be converted to a single decimal number that includes BOTH parts.
        LANGUAGE PRESERVATION: Keep the same language as the text. Only translate if absolutely necessary for JSON structure compatibility. Preserve original wording and phrasing.
        
        INGREDIENT AMOUNT AND UNIT VALIDATION (CRITICAL - ACCURACY CHECK):
        - DOUBLE-CHECK: Before extracting an ingredient, carefully verify the exact amount and unit shown in the text. Do not guess or assume amounts.
        - READ ENTIRE AMOUNT: Read the COMPLETE amount including any fractions. If you see "1 1/2", read it as "one and one-half" = 1.5, NOT just "1". If you see "1/12", read it as "one-twelfth" = 0.083, NOT "0.5".
        - FRACTION CONVERSION VERIFICATION: After converting fractions, verify the conversion is correct:
          * "1 1/2" must become "1.5" (NOT "1" or "2")
          * "1/12" must become "0.083" (NOT "0.5" or any other value)
          * "1/8" must become "0.125"
          * "1/4" must become "0.25"
          * "1/3" must become "0.333"
          * "1/2" must become "0.5"
          * "2/3" must become "0.667"
          * "3/4" must become "0.75"
        - MIXED NUMBER VERIFICATION: For mixed numbers like "1 1/2", verify you captured BOTH the whole number (1) AND the fraction (1/2 = 0.5), resulting in 1.5 total.
        - Re-check all fraction conversions before finalizing.
        - QUALITATIVE MEASUREMENTS: If the recipe says "to taste", "as needed", "optional", "a pinch", or similar qualitative terms, use these exact terms:
          * For "to taste" or "as needed": amount = "0", unit = "", name = "Salt (to taste)" or "Salt (as needed)"
          * For "a pinch": amount = "1", unit = "pinch", name = "Salt"
          * DO NOT convert qualitative measurements to specific amounts (e.g., "salt to taste" should NOT become "1.5 tsp salt")
        - MISSING INGREDIENTS CHECK: After extraction, review the text again to ensure ALL ingredients listed in the recipe are captured. Do not skip any ingredients.
        - AMOUNT VERIFICATION: Cross-reference extracted amounts with what is actually written in the text. If uncertain, extract exactly what is shown, do not estimate.
        - UNIT ACCURACY: Verify the unit matches what is written (tbsp vs tsp, cup vs cups, etc.). Pay attention to abbreviations and full words.
        - If an ingredient amount is unclear or not specified, use amount = "0" and include "(amount unclear)" in the name.
        
        INGREDIENT NAME ACCURACY (CRITICAL - EXACT WORD EXTRACTION):
        - EXTRACT EXACT WORDS: Extract ingredient names EXACTLY as written in the text. Do NOT substitute, assume, or change words.
        - NO WORD SUBSTITUTIONS: If the text says "sesame powder", extract "sesame powder" - NOT "sesame oil", "sesame seeds", or any other variation.
        - VERIFY EACH WORD: Read each word of the ingredient name carefully. "Powder" is NOT the same as "oil". "Fresh" is NOT the same as "dried". Extract exactly what is written.
        - DO NOT ASSUME: Do not assume similar ingredients. If you see "sesame powder", do not extract "sesame oil" thinking it's similar. They are different ingredients.
        - IF UNCERTAIN: If a word is unclear or partially visible, extract what you can see and mark uncertainty, but DO NOT substitute with a different word.
        - VERIFICATION STEP: After extracting each ingredient name, verify it matches exactly what is written in the text. If it doesn't match, correct it.
        - COMMON ERRORS TO AVOID: Do not confuse "powder" with "oil", "fresh" with "dried", "ground" with "whole", "chopped" with "whole", etc. Extract the exact word as written.
        
        INGREDIENT SECTION ASSIGNMENT RULES (CRITICAL - NO DUPLICATION):
        - READ TEXT CONTEXT CAREFULLY: Pay attention to how ingredients are described in the text. If the text explicitly mentions a section name (e.g., "sauce", "batter", "base", "dough", "topping", "marinade"), place those ingredients in the corresponding section.
        - marinadeIngredients: ONLY ingredients that are explicitly part of a marinade or pre-soaking mixture. If text says "marinade", "marinate", or lists ingredients "for marinade", place them ONLY in marinadeIngredients.
        - sauceIngredients: ONLY ingredients that are explicitly part of a sauce. If text says "sauce", "for sauce", "sauce ingredients", or lists ingredients under a "sauce" heading, place them ONLY in sauceIngredients.
        - batterIngredients: ONLY ingredients that are explicitly part of a batter. If text says "batter", "for batter", "batter ingredients", or lists ingredients under a "batter" heading, place them ONLY in batterIngredients.
        - baseIngredients: ONLY ingredients that are explicitly part of a base. If text says "base", "for base", "base ingredients", or lists ingredients under a "base" heading, place them ONLY in baseIngredients.
        - doughIngredients: ONLY ingredients that are explicitly part of a dough. If text says "dough", "for dough", "dough ingredients", or lists ingredients under a "dough" heading, place them ONLY in doughIngredients.
        - toppingIngredients: ONLY ingredients that are explicitly part of a topping. If text says "topping", "for topping", "topping ingredients", or lists ingredients under a "topping" heading, place them ONLY in toppingIngredients.
        - dishIngredients: ONLY ingredients that are used directly in the main cooking/preparation process, NOT ingredients that are already included in other sections (marinade, sauce, batter, base, dough, topping).
        - seasoningIngredients: ONLY spices, herbs, salt, pepper, and other seasonings used for flavoring during cooking, NOT ingredients that belong to other specific sections.
        - CHECK FOR DUPLICATION: Before placing an ingredient, verify it does not already exist in another section. Each ingredient should appear in ONLY ONE section based on the text context.
        - CONTEXT-BASED ASSIGNMENT: If the text clearly indicates a section (e.g., "Sauce: soy sauce, mirin, sugar" or "For the batter: flour, eggs, milk"), assign ingredients to that specific section.
        - Example: If text says "Sauce: soy sauce, mirin, sugar", place ALL three in sauceIngredients, NOT in dishIngredients or marinadeIngredients.
        - Example: If text says "Batter: flour, eggs, water", place ALL three in batterIngredients, NOT in dishIngredients.
        
        SERVINGS EXTRACTION:
        - Look for text indicating number of servings: "serves 4", "4 servings", "serves 4-6", "makes 4 servings", etc.
        - Extract the number as an integer. If a range is given (e.g., "4-6"), use the first number or average.
        - If no servings information is found, use 0 (will be set to default later).
        
        TIME EXTRACTION:
        - PREPARATION TIME: Look for "prep time", "preparation time", "prep", "marinate", "soak", "overnight", etc.
        - COOKING TIME: Look for "cook time", "cooking time", "cook for", "bake for", "simmer for", etc.
        - TIME UNITS: Extract time in minutes, but handle various formats:
          * "30 minutes" or "30 mins" → 30 minutes
          * "1 hour" or "1 hr" → 60 minutes
          * "1.5 hours" or "1 1/2 hours" → 90 minutes
          * "2 hours" → 120 minutes
          * "overnight" or "marinate overnight" → 1440 minutes (24 hours)
          * "1 day" → 1440 minutes
          * "2 days" → 2880 minutes
          * "30 seconds" → 0.5 minutes (round to 1 minute)
        - If time mentions "overnight" or "days", convert to minutes (1 day = 1440 minutes).
        - If no time information is found, use 0 for both prepTime and cookTime (will be extracted from instructions later if needed).
        
        INSTRUCTIONS EXTRACTION GUIDELINES:
        - CHECK TEXT BEFORE WRITING: Carefully read and analyze ALL text before extracting instructions. Look for references to other pages, recipes, or preparations (e.g., "see page 245", "refer to recipe on page X", "Nubo-style saikyo miso (see page 245)").
        - DETECT CROSS-PAGE REFERENCES: If an ingredient mentions another page or recipe (e.g., "miso (see page 245)", "marinade recipe on page 123"), this indicates a separate preparation that needs to be included.
        - SEQUENCE DETECTION AND ORDERING: Detect dependencies and order steps logically:
          * If a marinade, sauce, or preparation is referenced from another page, the preparation steps for that marinade/sauce MUST be the FIRST steps
          * After the marinade/sauce is prepared, then include steps to apply/use it
          * Follow the natural sequence: prepare dependencies → apply dependencies → main cooking → finish
        - USE ORIGINAL LANGUAGE: Keep the same language as the text. Preserve original terminology and key details.
        - FLOW AND CLARITY: You are allowed to rewrite and rephrase instructions for better flow and clarity while preserving the original meaning and key information.
        - STEP LIMIT: Keep instructions to a maximum of 10 steps (single digit preferred, ideally 5-8 steps). Combine related steps logically to achieve this.
        - RECIPE STRUCTURE AWARENESS: Pay attention to the logical order of the recipe:
          * Preparation steps (marinades, pre-soaking, pre-cooking preparations) should be in the FIRST steps
          * If a marinade is mentioned (either in the current text or referenced from another page), include its preparation as one of the first steps
          * Follow the natural cooking sequence: prep dependencies → apply dependencies → cook → finish
        - PRESERVE KEY DETAILS: Always preserve important details like temperatures, cooking times, techniques, and methods. Include these in your rewritten steps.
        - COMBINE LOGICALLY: Combine sequential actions that happen in the same phase (e.g., "Heat oil in pan, then add onions and cook until translucent").
        - REWRITE FOR CLARITY: You may rewrite steps to make them clearer and more actionable, but maintain the original meaning and all critical information.
        - GROUP RELATED STEPS: Group preparation steps together, cooking steps together, finishing steps together.
        
        TIPS EXTRACTION:
        - Look for sections labeled "Tips", "Notes", "Note", "Tip", "Helpful Tips", "Cooking Tips", "Chef's Tips", or similar headings
        - Extract any text that provides additional advice, variations, substitutions, storage tips, serving suggestions, or helpful information
        - Look for text in boxes, callouts, or special formatting that indicates tips or notes
        - Extract tips as an array of strings, with each tip as a separate item
        - If no tips are found, use an empty array []
        
        JSON format:
        {"title":"Recipe Title","description":"Description","servings":4,"prepTime":30,"cookTime":60,"dishIngredients":[{"amount":"12","unit":"","name":"Item"}],"marinadeIngredients":[],"seasoningIngredients":[],"batterIngredients":[],"sauceIngredients":[],"baseIngredients":[],"doughIngredients":[],"toppingIngredients":[],"instructions":["Step 1","Step 2"],"tips":["Tip 1","Tip 2"]}
        """
        
        let userPrompt = """
        Extract recipe from content. Check for cross-page references in ingredients (e.g., 'see page 245'). If a marinade/sauce is referenced from another page, include its preparation steps FIRST, then the steps to apply it. Also look for tips, notes, or helpful information sections and extract them into the tips array. PRESERVE the original language. Rewrite instructions for better flow and clarity, keeping to a maximum of 10 steps. Ensure marinades and preparations are in the first steps, followed by application steps. Return JSON only.
        
        Content:
        \(extractedText)
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo", // Cheaper text-only model
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": userPrompt
                ]
            ],
            "response_format": ["type": "json_object"],
            "max_tokens": 2000,
            "temperature": 0.1
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw OpenAIError.requestSerializationFailed
        }
        request.httpBody = httpBody
        
        // Make the request
        let (responseData, apiResponse) = try await URLSession.shared.data(for: request)
        
        guard let apiHTTPResponse = apiResponse as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard apiHTTPResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIError.apiError(message)
            }
            throw OpenAIError.httpError(apiHTTPResponse.statusCode)
        }
        
        // Parse the response
        guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        // Extract JSON from the response
        let jsonString = extractJSON(from: content)
        
        // Parse the recipe data
        guard let jsonData = jsonString.data(using: .utf8),
              let recipeDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw OpenAIError.jsonParsingFailed
        }
        
        return try parseRecipeResponse(from: recipeDict)
    }
    
    /// Extract recipe information from URL content (HTML/text) using OpenAI
    static func extractRecipe(fromURL urlString: String) async throws -> OpenAIRecipeResponse {
        guard !apiKey.isEmpty else {
            throw OpenAIError.apiKeyNotConfigured
        }
        
        // Fetch content from URL
        guard let url = URL(string: urlString) else {
            throw OpenAIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenAIError.invalidResponse
        }
        
        // Extract text from HTML, stripping HTML tags and limiting content size
        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw OpenAIError.invalidResponse
        }
        
        // Extract plain text from HTML and limit to reasonable size (max ~15000 characters ≈ 3750 tokens)
        // Reduced from 20000 to save on input tokens
        let extractedText = extractTextFromHTML(htmlString, maxLength: 15000)
        
        // Create the request
        guard let apiURL = URL(string: "\(baseURL)/chat/completions") else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create the prompt for recipe extraction from text (optimized for cost)
        let systemPrompt = """
        Extract recipe from text. PRESERVE THE ORIGINAL LANGUAGE from the text - do NOT translate to English unless the language is not supported. Return JSON only.
        
        IMPORTANT: Ingredients may be formatted with bullet points, dashes, or hyphens (e.g., "- 500gr bakkeljauw", "– 2 uien", "• 4 teentjes knoflook"). 
        Always extract the amount and unit correctly even when prefixed with these characters. Ignore leading dashes, bullets, or hyphens when parsing amounts.
        
        Sections: dishIngredients, marinadeIngredients, seasoningIngredients, batterIngredients, sauceIngredients, baseIngredients, doughIngredients, toppingIngredients, instructions.
        Ingredients: amount (number/decimals), unit (tbsp/tsp/cup/g/kg/ml/l/oz/fl_oz/lb/piece/pinch/gr/gram/grams), name (Capitalized Words).
        Note: "Oz" unit usage - CRITICAL DISTINCTION:
        - Use "fl_oz" (liquid ounces) ONLY for liquids: water, milk, oil, broth, juice, wine, vinegar, etc.
        - Use "oz" (weight ounces) ONLY for weight/solids: meat, flour, cheese, vegetables, fruits, etc.
        - NEVER use "oz" for liquids - always use "fl_oz" for liquids
        - NEVER use "fl_oz" for weight/solids - always use "oz" for weight/solids
        - If you see "oz" in the recipe text and it's a liquid, convert it to "fl_oz"
        - If you see "oz" in the recipe text and it's a solid/weight, use "oz"
        - If uncertain about a liquid vs solid, check the ingredient name (liquids: water, milk, oil, etc. → use "fl_oz"; solids: meat, flour, etc. → use "oz")
        IMPORTANT: Read the ENTIRE amount including ALL fractions before converting. Convert all fractions and mixed numbers to decimals:
        - "1/2" → "0.5"
        - "1/4" → "0.25"
        - "1/8" → "0.125"
        - "1/12" → "0.083" (approximately 0.083333...)
        - "1/3" → "0.333" (approximately 0.333333...)
        - "2/3" → "0.667" (approximately 0.666666...)
        - "3/4" → "0.75"
        - "1 1/2" or "1½" → "1.5" (read BOTH the whole number AND the fraction)
        - "1 1/4" → "1.25"
        - "2 1/4" → "2.25"
        - "3 1/2" or "3½" → "3.5"
        CRITICAL: When you see "1 1/2", you must read it as "one AND one-half" = 1.5, NOT just "1". The fraction part MUST be included.
        CRITICAL: When you see "1/12", you must read it as "one-twelfth" = 0.083, NOT "0.5" or any other value.
        Mixed numbers (whole number + fraction) must be converted to a single decimal number that includes BOTH parts.
        LANGUAGE PRESERVATION: Keep the same language as the text. Only translate if absolutely necessary for JSON structure compatibility. Preserve original wording and phrasing.
        
        INGREDIENT AMOUNT AND UNIT VALIDATION (CRITICAL - ACCURACY CHECK):
        - DOUBLE-CHECK: Before extracting an ingredient, carefully verify the exact amount and unit shown in the text. Do not guess or assume amounts.
        - READ ENTIRE AMOUNT: Read the COMPLETE amount including any fractions. If you see "1 1/2", read it as "one and one-half" = 1.5, NOT just "1". If you see "1/12", read it as "one-twelfth" = 0.083, NOT "0.5".
        - FRACTION CONVERSION VERIFICATION: After converting fractions, verify the conversion is correct:
          * "1 1/2" must become "1.5" (NOT "1" or "2")
          * "1/12" must become "0.083" (NOT "0.5" or any other value)
          * "1/8" must become "0.125"
          * "1/4" must become "0.25"
          * "1/3" must become "0.333"
          * "1/2" must become "0.5"
          * "2/3" must become "0.667"
          * "3/4" must become "0.75"
        - MIXED NUMBER VERIFICATION: For mixed numbers like "1 1/2", verify you captured BOTH the whole number (1) AND the fraction (1/2 = 0.5), resulting in 1.5 total.
        - Re-check all fraction conversions before finalizing.
        - QUALITATIVE MEASUREMENTS: If the recipe says "to taste", "as needed", "optional", "a pinch", or similar qualitative terms, use these exact terms:
          * For "to taste" or "as needed": amount = "0", unit = "", name = "Salt (to taste)" or "Salt (as needed)"
          * For "a pinch": amount = "1", unit = "pinch", name = "Salt"
          * DO NOT convert qualitative measurements to specific amounts (e.g., "salt to taste" should NOT become "1.5 tsp salt")
        - MISSING INGREDIENTS CHECK: After extraction, review the text again to ensure ALL ingredients listed in the recipe are captured. Do not skip any ingredients.
        - AMOUNT VERIFICATION: Cross-reference extracted amounts with what is actually written in the text. If uncertain, extract exactly what is shown, do not estimate.
        - UNIT ACCURACY: Verify the unit matches what is written (tbsp vs tsp, cup vs cups, etc.). Pay attention to abbreviations and full words.
        - If an ingredient amount is unclear or not specified, use amount = "0" and include "(amount unclear)" in the name.
        
        INGREDIENT NAME ACCURACY (CRITICAL - EXACT WORD EXTRACTION):
        - EXTRACT EXACT WORDS: Extract ingredient names EXACTLY as written in the text. Do NOT substitute, assume, or change words.
        - NO WORD SUBSTITUTIONS: If the text says "sesame powder", extract "sesame powder" - NOT "sesame oil", "sesame seeds", or any other variation.
        - VERIFY EACH WORD: Read each word of the ingredient name carefully. "Powder" is NOT the same as "oil". "Fresh" is NOT the same as "dried". Extract exactly what is written.
        - DO NOT ASSUME: Do not assume similar ingredients. If you see "sesame powder", do not extract "sesame oil" thinking it's similar. They are different ingredients.
        - IF UNCERTAIN: If a word is unclear or partially visible, extract what you can see and mark uncertainty, but DO NOT substitute with a different word.
        - VERIFICATION STEP: After extracting each ingredient name, verify it matches exactly what is written in the text. If it doesn't match, correct it.
        - COMMON ERRORS TO AVOID: Do not confuse "powder" with "oil", "fresh" with "dried", "ground" with "whole", "chopped" with "whole", etc. Extract the exact word as written.
        
        INGREDIENT SECTION ASSIGNMENT RULES (CRITICAL - NO DUPLICATION):
        - READ TEXT CONTEXT CAREFULLY: Pay attention to how ingredients are described in the text. If the text explicitly mentions a section name (e.g., "sauce", "batter", "base", "dough", "topping", "marinade"), place those ingredients in the corresponding section.
        - marinadeIngredients: ONLY ingredients that are explicitly part of a marinade or pre-soaking mixture. If text says "marinade", "marinate", or lists ingredients "for marinade", place them ONLY in marinadeIngredients.
        - sauceIngredients: ONLY ingredients that are explicitly part of a sauce. If text says "sauce", "for sauce", "sauce ingredients", or lists ingredients under a "sauce" heading, place them ONLY in sauceIngredients.
        - batterIngredients: ONLY ingredients that are explicitly part of a batter. If text says "batter", "for batter", "batter ingredients", or lists ingredients under a "batter" heading, place them ONLY in batterIngredients.
        - baseIngredients: ONLY ingredients that are explicitly part of a base. If text says "base", "for base", "base ingredients", or lists ingredients under a "base" heading, place them ONLY in baseIngredients.
        - doughIngredients: ONLY ingredients that are explicitly part of a dough. If text says "dough", "for dough", "dough ingredients", or lists ingredients under a "dough" heading, place them ONLY in doughIngredients.
        - toppingIngredients: ONLY ingredients that are explicitly part of a topping. If text says "topping", "for topping", "topping ingredients", or lists ingredients under a "topping" heading, place them ONLY in toppingIngredients.
        - dishIngredients: ONLY ingredients that are used directly in the main cooking/preparation process, NOT ingredients that are already included in other sections (marinade, sauce, batter, base, dough, topping).
        - seasoningIngredients: ONLY spices, herbs, salt, pepper, and other seasonings used for flavoring during cooking, NOT ingredients that belong to other specific sections.
        - CHECK FOR DUPLICATION: Before placing an ingredient, verify it does not already exist in another section. Each ingredient should appear in ONLY ONE section based on the text context.
        - CONTEXT-BASED ASSIGNMENT: If the text clearly indicates a section (e.g., "Sauce: soy sauce, mirin, sugar" or "For the batter: flour, eggs, milk"), assign ingredients to that specific section.
        - Example: If text says "Sauce: soy sauce, mirin, sugar", place ALL three in sauceIngredients, NOT in dishIngredients or marinadeIngredients.
        - Example: If text says "Batter: flour, eggs, water", place ALL three in batterIngredients, NOT in dishIngredients.
        
        SERVINGS EXTRACTION:
        - Look for text indicating number of servings: "serves 4", "4 servings", "serves 4-6", "makes 4 servings", etc.
        - Extract the number as an integer. If a range is given (e.g., "4-6"), use the first number or average.
        - If no servings information is found, use 0 (will be set to default later).
        
        TIME EXTRACTION:
        - PREPARATION TIME: Look for "prep time", "preparation time", "prep", "marinate", "soak", "overnight", etc.
        - COOKING TIME: Look for "cook time", "cooking time", "cook for", "bake for", "simmer for", etc.
        - TIME UNITS: Extract time in minutes, but handle various formats:
          * "30 minutes" or "30 mins" → 30 minutes
          * "1 hour" or "1 hr" → 60 minutes
          * "1.5 hours" or "1 1/2 hours" → 90 minutes
          * "2 hours" → 120 minutes
          * "overnight" or "marinate overnight" → 1440 minutes (24 hours)
          * "1 day" → 1440 minutes
          * "2 days" → 2880 minutes
          * "30 seconds" → 0.5 minutes (round to 1 minute)
        - If time mentions "overnight" or "days", convert to minutes (1 day = 1440 minutes).
        - If no time information is found, use 0 for both prepTime and cookTime (will be extracted from instructions later if needed).
        
        INSTRUCTIONS EXTRACTION GUIDELINES:
        - CHECK TEXT BEFORE WRITING: Carefully read and analyze ALL text before extracting instructions. Look for references to other pages, recipes, or preparations (e.g., "see page 245", "refer to recipe on page X", "Nubo-style saikyo miso (see page 245)").
        - DETECT CROSS-PAGE REFERENCES: If an ingredient mentions another page or recipe (e.g., "miso (see page 245)", "marinade recipe on page 123"), this indicates a separate preparation that needs to be included.
        - SEQUENCE DETECTION AND ORDERING: Detect dependencies and order steps logically:
          * If a marinade, sauce, or preparation is referenced from another page, the preparation steps for that marinade/sauce MUST be the FIRST steps
          * After the marinade/sauce is prepared, then include steps to apply/use it
          * Follow the natural sequence: prepare dependencies → apply dependencies → main cooking → finish
        - USE ORIGINAL LANGUAGE: Keep the same language as the text. Preserve original terminology and key details.
        - FLOW AND CLARITY: You are allowed to rewrite and rephrase instructions for better flow and clarity while preserving the original meaning and key information.
        - STEP LIMIT: Keep instructions to a maximum of 10 steps (single digit preferred, ideally 5-8 steps). Combine related steps logically to achieve this.
        - RECIPE STRUCTURE AWARENESS: Pay attention to the logical order of the recipe:
          * Preparation steps (marinades, pre-soaking, pre-cooking preparations) should be in the FIRST steps
          * If a marinade is mentioned (either in the current text or referenced from another page), include its preparation as one of the first steps
          * Follow the natural cooking sequence: prep dependencies → apply dependencies → cook → finish
        - PRESERVE KEY DETAILS: Always preserve important details like temperatures, cooking times, techniques, and methods. Include these in your rewritten steps.
        - COMBINE LOGICALLY: Combine sequential actions that happen in the same phase (e.g., "Heat oil in pan, then add onions and cook until translucent").
        - REWRITE FOR CLARITY: You may rewrite steps to make them clearer and more actionable, but maintain the original meaning and all critical information.
        - GROUP RELATED STEPS: Group preparation steps together, cooking steps together, finishing steps together.
        
        TIPS EXTRACTION:
        - Look for sections labeled "Tips", "Notes", "Note", "Tip", "Helpful Tips", "Cooking Tips", "Chef's Tips", or similar headings
        - Extract any text that provides additional advice, variations, substitutions, storage tips, serving suggestions, or helpful information
        - Look for text in boxes, callouts, or special formatting that indicates tips or notes
        - Extract tips as an array of strings, with each tip as a separate item
        - If no tips are found, use an empty array []
        
        JSON format:
        {"title":"Recipe Title","description":"Description","servings":4,"prepTime":30,"cookTime":60,"dishIngredients":[{"amount":"12","unit":"","name":"Item"}],"marinadeIngredients":[],"seasoningIngredients":[],"batterIngredients":[],"sauceIngredients":[],"baseIngredients":[],"doughIngredients":[],"toppingIngredients":[],"instructions":["Step 1","Step 2"],"tips":["Tip 1","Tip 2"]}
        """
        
        let userPrompt = """
        Extract recipe from content. Check for cross-page references in ingredients (e.g., 'see page 245'). If a marinade/sauce is referenced from another page, include its preparation steps FIRST, then the steps to apply it. Also look for tips, notes, or helpful information sections and extract them into the tips array. PRESERVE the original language. Rewrite instructions for better flow and clarity, keeping to a maximum of 10 steps. Ensure marinades and preparations are in the first steps, followed by application steps. Return JSON only.
        
        Content:
        \(extractedText)
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo", // Cheaper text-only model
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": userPrompt
                ]
            ],
            "response_format": ["type": "json_object"],
            "max_tokens": 2000,
            "temperature": 0.1
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw OpenAIError.requestSerializationFailed
        }
        request.httpBody = httpBody
        
        // Make the request
        let (responseData, apiResponse) = try await URLSession.shared.data(for: request)
        
        guard let apiHTTPResponse = apiResponse as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard apiHTTPResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIError.apiError(message)
            }
            throw OpenAIError.httpError(apiHTTPResponse.statusCode)
        }
        
        // Parse the response
        guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        // Extract JSON from the response
        let jsonString = extractJSON(from: content)
        
        // Parse the recipe data
        guard let jsonData = jsonString.data(using: .utf8),
              let recipeDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw OpenAIError.jsonParsingFailed
        }
        
        return try parseRecipeResponse(from: recipeDict)
    }
    
    /// Extract plain text from HTML content, removing tags and limiting length
    private static func extractTextFromHTML(_ html: String, maxLength: Int) -> String {
        // Use NSAttributedString to parse HTML and extract plain text
        guard let htmlData = html.data(using: .utf8),
              let attributedString = try? NSAttributedString(
                data: htmlData,
                options: [.documentType: NSAttributedString.DocumentType.html,
                         .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil
              ) else {
            // Fallback: Simple regex to remove HTML tags if parsing fails
            let plainText = html
                .replacingOccurrences(of: "<script[^>]*>.*?</script>", with: "", options: [.regularExpression, .caseInsensitive])
                .replacingOccurrences(of: "<style[^>]*>.*?</style>", with: "", options: [.regularExpression, .caseInsensitive])
                .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            return String(plainText.prefix(maxLength))
        }
        
        // Extract plain text and clean up whitespace
        var plainText = attributedString.string
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\n\\s*\\n", with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Limit length to avoid exceeding token limits
        if plainText.count > maxLength {
            plainText = String(plainText.prefix(maxLength)) + "..."
        }
        
        return plainText
    }
    
    /// Extract JSON string from response (handles markdown code blocks)
    /// Note: When using response_format: json_object, OpenAI returns JSON directly, but we keep this for safety
    private static func extractJSON(from content: String) -> String {
        var jsonString = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code blocks if present (shouldn't happen with json_object format, but keep for safety)
        if jsonString.hasPrefix("```json") {
            jsonString = String(jsonString.dropFirst(7))
        } else if jsonString.hasPrefix("```") {
            jsonString = String(jsonString.dropFirst(3))
        }
        
        if jsonString.hasSuffix("```") {
            jsonString = String(jsonString.dropLast(3))
        }
        
        return jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Parse recipe response from dictionary
    private static func parseRecipeResponse(from dict: [String: Any]) throws -> OpenAIRecipeResponse {
        let title = dict["title"] as? String ?? ""
        let description = dict["description"] as? String ?? ""
        
        // Parse servings (default to 0 if not found)
        let servings = (dict["servings"] as? Int) ?? (dict["servings"] as? String).flatMap { Int($0) } ?? 0
        
        // Parse prepTime and cookTime (in minutes, default to 0 if not found)
        let prepTime = (dict["prepTime"] as? Int) ?? (dict["prepTime"] as? String).flatMap { Int($0) } ?? 0
        let cookTime = (dict["cookTime"] as? Int) ?? (dict["cookTime"] as? String).flatMap { Int($0) } ?? 0
        
        // Parse ingredients
        let dishIngredients = parseIngredients(from: dict["dishIngredients"] as? [[String: Any]] ?? [])
        let marinadeIngredients = parseIngredients(from: dict["marinadeIngredients"] as? [[String: Any]] ?? [])
        let seasoningIngredients = parseIngredients(from: dict["seasoningIngredients"] as? [[String: Any]] ?? [])
        let batterIngredients = parseIngredients(from: dict["batterIngredients"] as? [[String: Any]] ?? [])
        let sauceIngredients = parseIngredients(from: dict["sauceIngredients"] as? [[String: Any]] ?? [])
        let baseIngredients = parseIngredients(from: dict["baseIngredients"] as? [[String: Any]] ?? [])
        let doughIngredients = parseIngredients(from: dict["doughIngredients"] as? [[String: Any]] ?? [])
        let toppingIngredients = parseIngredients(from: dict["toppingIngredients"] as? [[String: Any]] ?? [])
        
        // Parse instructions
        let instructions = (dict["instructions"] as? [String]) ?? []
        
        // Parse tips
        let tips = (dict["tips"] as? [String]) ?? []
        
        // Check if no recipe was detected (empty title and no ingredients/instructions)
        let allIngredients = dishIngredients + marinadeIngredients + seasoningIngredients + batterIngredients + sauceIngredients + baseIngredients + doughIngredients + toppingIngredients
        let hasValidInstructions = !instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.isEmpty
        
        if title.trimmingCharacters(in: .whitespaces).isEmpty && allIngredients.isEmpty && !hasValidInstructions {
            throw OpenAIError.noRecipeDetected
        }
        
        return OpenAIRecipeResponse(
            title: title,
            description: description,
            servings: servings,
            prepTime: prepTime,
            cookTime: cookTime,
            dishIngredients: dishIngredients,
            marinadeIngredients: marinadeIngredients,
            seasoningIngredients: seasoningIngredients,
            batterIngredients: batterIngredients,
            sauceIngredients: sauceIngredients,
            baseIngredients: baseIngredients,
            doughIngredients: doughIngredients,
            toppingIngredients: toppingIngredients,
            instructions: instructions,
            tips: tips
        )
    }
    
    /// Parse ingredient array
    private static func parseIngredients(from array: [[String: Any]]) -> [RecipeTextParser.IngredientItem] {
        return array.compactMap { dict in
            guard let name = dict["name"] as? String else { return nil }
            let amount = dict["amount"] as? String ?? ""
            let unit = dict["unit"] as? String ?? ""
            return RecipeTextParser.IngredientItem(amount: amount, unit: unit, name: name)
        }
    }
    
    // MARK: - Recipe Description and Cuisine Detection
    
    /// Generate a recipe description using OpenAI based on recipe information
    static func generateRecipeDescription(
        title: String,
        ingredients: [String],
        instructions: [String] = []
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            throw OpenAIError.apiKeyNotConfigured
        }
        
        guard !title.isEmpty else {
            return ""
        }
        
        // Create the request
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build the prompt
        let ingredientsText = ingredients.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: ", ")
        let instructionsText = instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: " ")
        
        // Get user's selected language
        let selectedLanguage = LocalizationManager.shared.currentLanguage
        let targetLanguageCode: String
        let languageName: String
        
        switch selectedLanguage {
        case .english:
            targetLanguageCode = "en"
            languageName = "English"
        case .system:
            if let preferredLanguage = Locale.preferredLanguages.first {
                // Normalize Chinese regional variants to zh-Hans or zh-Hant
                targetLanguageCode = normalizeChineseLanguageCode(preferredLanguage)
            } else {
                targetLanguageCode = "en"
            }
            languageName = getLanguageName(for: targetLanguageCode)
        default:
            targetLanguageCode = selectedLanguage.rawValue
            languageName = getLanguageName(for: targetLanguageCode)
        }
        
        let systemPrompt = """
        You are a culinary expert. Generate a brief, appetizing description (2-3 sentences) for a recipe in \(languageName).
        The description should be engaging, highlight key ingredients or cooking methods, and make the dish sound appealing.
        Keep it concise and professional. Write the description entirely in \(languageName).
        """
        
        var userPrompt = "Generate a description for this recipe in \(languageName):\nTitle: \(title)"
        if !ingredientsText.isEmpty {
            userPrompt += "\nIngredients: \(ingredientsText)"
        }
        if !instructionsText.isEmpty {
            // Use first few instructions to understand cooking method
            let firstInstructions = instructions.prefix(3).joined(separator: " ")
            userPrompt += "\nCooking method: \(firstInstructions)"
        }
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo", // Cheaper text-only model
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": userPrompt
                ]
            ],
            "max_tokens": 150,
            "temperature": 0.7
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw OpenAIError.requestSerializationFailed
        }
        request.httpBody = httpBody
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIError.apiError(message)
            }
            throw OpenAIError.httpError(httpResponse.statusCode)
        }
        
        // Parse the response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Detect the most suitable cuisine type for a recipe using OpenAI
    static func detectCuisine(
        title: String,
        ingredients: [String],
        instructions: [String] = []
    ) async throws -> String? {
        guard !apiKey.isEmpty else {
            throw OpenAIError.apiKeyNotConfigured
        }
        
        guard !title.isEmpty else {
            return nil
        }
        
        // Create the request
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build the prompt with available cuisines
        let availableCuisines = CuisineTypes.allCuisines.joined(separator: ", ")
        
        let ingredientsText = ingredients.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: ", ")
        
        let systemPrompt = """
        You are a culinary expert. Analyze the recipe and determine the most suitable cuisine type.
        Return ONLY the cuisine name from this list: \(availableCuisines)
        If the cuisine is not clearly identifiable, return "Other".
        Return only the cuisine name, nothing else.
        """
        
        var userPrompt = "Determine the cuisine type for this recipe:\nTitle: \(title)"
        if !ingredientsText.isEmpty {
            userPrompt += "\nIngredients: \(ingredientsText)"
        }
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo", // Cheaper text-only model
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": userPrompt
                ]
            ],
            "max_tokens": 50,
            "temperature": 0.3
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw OpenAIError.requestSerializationFailed
        }
        request.httpBody = httpBody
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIError.apiError(message)
            }
            throw OpenAIError.httpError(httpResponse.statusCode)
        }
        
        // Parse the response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        let detectedCuisine = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate that the detected cuisine is in our list
        if CuisineTypes.allCuisines.contains(detectedCuisine) {
            return detectedCuisine
        } else {
            // Try to find a match (case-insensitive)
            if let match = CuisineTypes.allCuisines.first(where: { $0.lowercased() == detectedCuisine.lowercased() }) {
                return match
            }
            return "Other"
        }
    }
    
    /// Extract preparation and cooking time from instructions
    static func extractTimeFromInstructions(
        title: String,
        instructions: [String]
    ) async throws -> (prepTime: Int, cookTime: Int) {
        guard !apiKey.isEmpty else {
            throw OpenAIError.apiKeyNotConfigured
        }
        
        guard !instructions.isEmpty else {
            return (15, 30) // Default values
        }
        
        // Create the request
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let instructionsText = instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: " ")
        
        let systemPrompt = """
        You are a culinary expert. Analyze the recipe instructions and extract preparation time and cooking time in minutes.
        Return ONLY a JSON object with "prepTime" and "cookTime" as integers (in minutes).
        If time cannot be determined, use reasonable defaults: prepTime: 15, cookTime: 30.
        
        TIME UNIT CONVERSION:
        - "30 minutes" or "30 mins" → 30 minutes
        - "1 hour" or "1 hr" → 60 minutes
        - "1.5 hours" or "1 1/2 hours" → 90 minutes
        - "2 hours" → 120 minutes
        - "overnight" or "marinate overnight" → 1440 minutes (24 hours)
        - "1 day" → 1440 minutes
        - "2 days" → 2880 minutes
        - "30 seconds" → 1 minute (round up)
        
        Look for time indicators like:
        - PREPARATION: "prep time", "preparation time", "prep", "marinate for X", "soak for X", "overnight", "refrigerate for X", etc.
        - COOKING: "cook time", "cooking time", "cook for X", "bake for X", "simmer for X", "fry for X", etc.
        """
        
        let userPrompt = """
        Extract preparation and cooking time from this recipe:
        Title: \(title)
        Instructions: \(instructionsText)
        
        Return JSON only: {"prepTime": 15, "cookTime": 30}
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo", // Cheaper text-only model
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": userPrompt
                ]
            ],
            "response_format": ["type": "json_object"],
            "max_tokens": 100,
            "temperature": 0.1
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw OpenAIError.requestSerializationFailed
        }
        request.httpBody = httpBody
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIError.apiError(message)
            }
            throw OpenAIError.httpError(httpResponse.statusCode)
        }
        
        // Parse the response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        // Extract JSON from the response
        let jsonString = extractJSON(from: content)
        
        guard let jsonData = jsonString.data(using: .utf8),
              let timeDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return (15, 30) // Default on parse failure
        }
        
        let prepTime = (timeDict["prepTime"] as? Int) ?? 15
        let cookTime = (timeDict["cookTime"] as? Int) ?? 30
        
        return (prepTime, cookTime)
    }
    
    /// Detect difficulty level (C, B, A, S, SS) using AI
    static func detectDifficulty(
        title: String,
        ingredients: [String],
        instructions: [String] = []
    ) async throws -> Recipe.Difficulty {
        guard !apiKey.isEmpty else {
            throw OpenAIError.apiKeyNotConfigured
        }
        
        guard !title.isEmpty else {
            return .c // Default
        }
        
        // Create the request
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let ingredientsText = ingredients.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: ", ")
        let instructionsText = instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: " ")
        
        let systemPrompt = """
        You are a culinary expert. Analyze the recipe and determine the difficulty level.
        Difficulty levels: C (easiest), B, A, S, SS (hardest).
        Consider: number of ingredients, complexity of techniques, cooking time, skill level required.
        Return ONLY one letter: C, B, A, S, or SS.
        """
        
        var userPrompt = "Determine the difficulty level for this recipe:\nTitle: \(title)"
        if !ingredientsText.isEmpty {
            userPrompt += "\nIngredients: \(ingredientsText)"
        }
        if !instructionsText.isEmpty {
            userPrompt += "\nInstructions: \(instructionsText)"
        }
        userPrompt += "\n\nReturn only one letter: C, B, A, S, or SS"
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo", // Cheaper text-only model
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": userPrompt
                ]
            ],
            "max_tokens": 10,
            "temperature": 0.3
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw OpenAIError.requestSerializationFailed
        }
        request.httpBody = httpBody
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIError.apiError(message)
            }
            throw OpenAIError.httpError(httpResponse.statusCode)
        }
        
        // Parse the response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        let difficultyString = content.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Map to Difficulty enum
        switch difficultyString {
        case "C":
            return .c
        case "B":
            return .b
        case "A":
            return .a
        case "S":
            return .s
        case "SS":
            return .ss
        default:
            return .c // Default to C if unrecognized
        }
    }
    
    /// Translate text to English using OpenAI API
    /// - Parameters:
    ///   - text: Text to translate
    ///   - sourceLanguage: Source language (optional, for better translation quality)
    /// - Returns: Translated text in English
    static func translateToEnglish(_ text: String, from sourceLanguage: NLLanguage? = nil) async throws -> String {
        guard !apiKey.isEmpty else {
            throw OpenAIError.apiKeyNotConfigured
        }
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return text
        }
        
        // Create the request
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build the prompt with language context if available
        let languageContext = sourceLanguage != nil ? " The text is in \(sourceLanguage!.rawValue)." : ""
        let systemPrompt = """
        You are a professional translator. Translate the following text to English. 
        Preserve the original meaning, tone, and formatting. For recipe content, maintain technical cooking terms accurately.
        \(languageContext)
        Return only the translated text, nothing else.
        """
        
        let userPrompt = """
        Translate this text to English:
        
        \(text)
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo", // Use cheaper model for translation
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": userPrompt
                ]
            ],
            "max_tokens": 2000,
            "temperature": 0.3 // Lower temperature for more consistent translation
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw OpenAIError.requestSerializationFailed
        }
        request.httpBody = httpBody
        
        // Make the request
        let (responseData, apiResponse) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = apiResponse as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            throw OpenAIError.httpError(httpResponse.statusCode)
        }
        
        // Parse the response
        guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.jsonParsingFailed
        }
        
        let translatedText = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return translatedText.isEmpty ? text : translatedText
    }
    
    /// Translate text from English to target language using OpenAI API
    /// - Parameters:
    ///   - text: Text to translate (should be in English)
    ///   - targetLanguage: Target language code (e.g., "nl" for Dutch, "es" for Spanish)
    /// - Returns: Translated text in target language
    static func translateFromEnglish(_ text: String, to targetLanguage: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw OpenAIError.apiKeyNotConfigured
        }
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return text
        }
        
        // Don't translate if target is English
        if targetLanguage.lowercased() == "en" || targetLanguage.lowercased().hasPrefix("en-") {
            return text
        }
        
        // Create the request
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Get language name for better translation
        let languageName = getLanguageName(for: targetLanguage)
        
        let systemPrompt = """
        You are a professional translator. Translate the following text from English to \(languageName).
        Preserve the original meaning, tone, and formatting. For recipe content, maintain technical cooking terms accurately and use appropriate culinary terminology in \(languageName).
        Return only the translated text, nothing else.
        """
        
        let userPrompt = """
        Translate this text from English to \(languageName):
        
        \(text)
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": userPrompt
                ]
            ],
            "max_tokens": 2000,
            "temperature": 0.3
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw OpenAIError.requestSerializationFailed
        }
        request.httpBody = httpBody
        
        // Make the request
        let (responseData, apiResponse) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = apiResponse as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OpenAIError.httpError(httpResponse.statusCode)
        }
        
        // Parse the response
        guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.jsonParsingFailed
        }
        
        let translatedText = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return translatedText.isEmpty ? text : translatedText
    }
    
    /// Get language name from language code
    private static func getLanguageName(for code: String) -> String {
        let languageMap: [String: String] = [
            "nl": "Dutch",
            "es": "Spanish",
            "fr": "French",
            "de": "German",
            "it": "Italian",
            "pt": "Portuguese",
            "ru": "Russian",
            "ja": "Japanese",
            "ko": "Korean",
            "zh": "Chinese",
            "zh-Hans": "Simplified Chinese",
            "zh-Hant": "Traditional Chinese",
            "th": "Thai",
            "vi": "Vietnamese",
            "id": "Indonesian",
            "ms": "Malay",
            "fil": "Filipino",
            "hi": "Hindi"
        ]
        
        // Check for exact match first
        if let name = languageMap[code] {
            return name
        }
        
        // Check for prefix match (e.g., "zh-Hans" -> "Simplified Chinese")
        for (key, value) in languageMap {
            if code.hasPrefix(key) {
                return value
            }
        }
        
        // Fallback: return the code itself
        return code
    }
    
    /// Normalize Chinese language codes to zh-Hans or zh-Hant
    /// - Parameter code: Language code from system (e.g., "zh-HK", "zh-TW", "zh-CN", "zh-Hans", "zh-Hant")
    /// - Returns: Normalized code (zh-Hans or zh-Hant)
    private static func normalizeChineseLanguageCode(_ code: String) -> String {
        let lowercased = code.lowercased()
        
        // Traditional Chinese regions: Hong Kong, Taiwan, Macau
        if lowercased.hasPrefix("zh-hk") || lowercased.hasPrefix("zh-tw") || lowercased.hasPrefix("zh-mo") || lowercased == "zh-hant" {
            return "zh-Hant"
        }
        
        // Simplified Chinese regions: China, Singapore
        if lowercased.hasPrefix("zh-cn") || lowercased.hasPrefix("zh-sg") || lowercased == "zh-hans" {
            return "zh-Hans"
        }
        
        // If it's just "zh" without variant, default to Simplified (most common)
        if lowercased == "zh" {
            return "zh-Hans"
        }
        
        // For all other cases, return as-is
        return code
    }
}

// MARK: - Response Models

struct OpenAIRecipeResponse {
    let title: String
    let description: String
    let servings: Int
    let prepTime: Int // in minutes
    let cookTime: Int // in minutes
    let dishIngredients: [RecipeTextParser.IngredientItem]
    let marinadeIngredients: [RecipeTextParser.IngredientItem]
    let seasoningIngredients: [RecipeTextParser.IngredientItem]
    let batterIngredients: [RecipeTextParser.IngredientItem]
    let sauceIngredients: [RecipeTextParser.IngredientItem]
    let baseIngredients: [RecipeTextParser.IngredientItem]
    let doughIngredients: [RecipeTextParser.IngredientItem]
    let toppingIngredients: [RecipeTextParser.IngredientItem]
    let instructions: [String]
    let tips: [String]
}

// MARK: - Errors

enum OpenAIError: LocalizedError {
    case apiKeyNotConfigured
    case imageConversionFailed
    case invalidURL
    case requestSerializationFailed
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case jsonParsingFailed
    case noRecipeDetected
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "OpenAI API key is not configured. Please set your API key in OpenAIService.swift"
        case .imageConversionFailed:
            return "Failed to convert image to base64 format"
        case .invalidURL:
            return "Invalid API URL"
        case .requestSerializationFailed:
            return "Failed to serialize request"
        case .invalidResponse:
            return "Invalid response from OpenAI API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "OpenAI API error: \(message)"
        case .jsonParsingFailed:
            return "Failed to parse JSON response from OpenAI"
        case .noRecipeDetected:
            return LocalizedString("No recipe is detected, please try again.", comment: "No recipe detected error message")
        }
    }
}

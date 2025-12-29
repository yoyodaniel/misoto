//
//  OpenAIService.swift
//  Misoto
//
//  Service for OpenAI API integration for recipe extraction
//

import Foundation
import UIKit

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
        guard !apiKey.isEmpty else {
            throw OpenAIError.apiKeyNotConfigured
        }
        
        // Optimize image before sending to API (resize and compress to reduce payload size)
        let optimizedImage = await ImageOptimizer.resizeForProcessing(image)
        
        // Convert image to base64 with compression (reduced quality slightly to save on tokens)
        guard let imageData = ImageOptimizer.compressImage(optimizedImage, quality: 0.75, maxFileSizeKB: 800) else {
            throw OpenAIError.imageConversionFailed
        }
        let base64Image = imageData.base64EncodedString()
        
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
        Extract recipe from image. Detect language, translate to English, return JSON only.
        
        Sections: dishIngredients, marinadeIngredients, seasoningIngredients, instructions.
        Ingredients: amount (number/decimals), unit (tbsp/tsp/cup/g/kg/ml/l/oz/lb/piece/pinch), name (Capitalized Words).
        IMPORTANT: Convert all fractions and mixed numbers to decimals:
        - "1/2" → "0.5"
        - "1 1/2" or "1½" → "1.5"
        - "3 1/2" or "3½" → "3.5"
        - "2 1/4" → "2.25"
        - "1/4" → "0.25"
        - "3/4" → "0.75"
        Mixed numbers (whole number + fraction) must be converted to a single decimal number.
        All output in English.
        
        JSON format:
        {"title":"Recipe Title","description":"Description","dishIngredients":[{"amount":"12","unit":"","name":"Item"}],"marinadeIngredients":[],"seasoningIngredients":[],"instructions":["Step 1","Step 2"]}
        """
        
        let userPrompt = "Extract recipe from image. Return JSON only."
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": userPrompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "response_format": ["type": "json_object"],
            "max_tokens": 1000,
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
        Extract recipe from text. Detect language, translate to English, return JSON only.
        
        Sections: dishIngredients, marinadeIngredients, seasoningIngredients, instructions.
        Ingredients: amount (number/decimals), unit (tbsp/tsp/cup/g/kg/ml/l/oz/lb/piece/pinch), name (Capitalized Words).
        IMPORTANT: Convert all fractions and mixed numbers to decimals:
        - "1/2" → "0.5"
        - "1 1/2" or "1½" → "1.5"
        - "3 1/2" or "3½" → "3.5"
        - "2 1/4" → "2.25"
        - "1/4" → "0.25"
        - "3/4" → "0.75"
        Mixed numbers (whole number + fraction) must be converted to a single decimal number.
        All output in English.
        
        JSON format:
        {"title":"Recipe Title","description":"Description","dishIngredients":[{"amount":"12","unit":"","name":"Item"}],"marinadeIngredients":[],"seasoningIngredients":[],"instructions":["Step 1","Step 2"]}
        """
        
        let userPrompt = """
        Extract recipe from content. Return JSON only.
        
        Content:
        \(extractedText)
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
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
            "max_tokens": 1000,
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
        
        // Parse ingredients
        let dishIngredients = parseIngredients(from: dict["dishIngredients"] as? [[String: Any]] ?? [])
        let marinadeIngredients = parseIngredients(from: dict["marinadeIngredients"] as? [[String: Any]] ?? [])
        let seasoningIngredients = parseIngredients(from: dict["seasoningIngredients"] as? [[String: Any]] ?? [])
        
        // Parse instructions
        let instructions = (dict["instructions"] as? [String]) ?? []
        
        // Check if no recipe was detected (empty title and no ingredients/instructions)
        let allIngredients = dishIngredients + marinadeIngredients + seasoningIngredients
        let hasValidInstructions = !instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.isEmpty
        
        if title.trimmingCharacters(in: .whitespaces).isEmpty && allIngredients.isEmpty && !hasValidInstructions {
            throw OpenAIError.noRecipeDetected
        }
        
        return OpenAIRecipeResponse(
            title: title,
            description: description,
            dishIngredients: dishIngredients,
            marinadeIngredients: marinadeIngredients,
            seasoningIngredients: seasoningIngredients,
            instructions: instructions
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
        
        let systemPrompt = """
        You are a culinary expert. Generate a brief, appetizing description (2-3 sentences) for a recipe.
        The description should be engaging, highlight key ingredients or cooking methods, and make the dish sound appealing.
        Keep it concise and professional.
        """
        
        var userPrompt = "Generate a description for this recipe:\nTitle: \(title)"
        if !ingredientsText.isEmpty {
            userPrompt += "\nIngredients: \(ingredientsText)"
        }
        if !instructionsText.isEmpty {
            // Use first few instructions to understand cooking method
            let firstInstructions = instructions.prefix(3).joined(separator: " ")
            userPrompt += "\nCooking method: \(firstInstructions)"
        }
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
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
            "model": "gpt-4o",
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
        Look for time indicators like "minutes", "mins", "hours", "hrs", "marinate for X", "cook for X", etc.
        """
        
        let userPrompt = """
        Extract preparation and cooking time from this recipe:
        Title: \(title)
        Instructions: \(instructionsText)
        
        Return JSON only: {"prepTime": 15, "cookTime": 30}
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o",
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
            "model": "gpt-4o",
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
}

// MARK: - Response Models

struct OpenAIRecipeResponse {
    let title: String
    let description: String
    let dishIngredients: [RecipeTextParser.IngredientItem]
    let marinadeIngredients: [RecipeTextParser.IngredientItem]
    let seasoningIngredients: [RecipeTextParser.IngredientItem]
    let instructions: [String]
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
            return NSLocalizedString("No recipe is detected, please try again.", comment: "No recipe detected error message")
        }
    }
}

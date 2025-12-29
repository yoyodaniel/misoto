//
//  TranslationAPIService.swift
//  Misoto
//
//  Translation API service for automatic translation using system/cloud services
//

import Foundation
import NaturalLanguage

@MainActor
class TranslationAPIService {
    
    // MARK: - Configuration
    // Configure your translation API here
    // Options: Google Cloud Translation, Microsoft Azure Translator, DeepL, etc.
    
    private static let useSystemTranslation = true // Set to false to use API service
    
    /// Translate text from source language to English using system or API translation
    static func translate(_ text: String, from sourceLanguage: NLLanguage) async -> String {
        // For automatic translation, we use a translation API service
        // Apple's Translation framework requires user interaction for privacy, so it's not suitable for automatic translation
        
        // Get source language code
        let sourceLangCode = sourceLanguage.rawValue
        
        // Try using LibreTranslate (free, open-source translation API)
        // This is a free alternative that doesn't require API keys
        if let translated = await translateWithLibreTranslate(text, from: sourceLangCode, to: "en") {
            return translated
        }
        
        // If LibreTranslate fails, you can integrate other services:
        // - Google Cloud Translation API (requires API key)
        // - Microsoft Azure Translator (requires API key)
        // - DeepL API (requires API key)
        
        print("Translation API not available, returning original text")
        return text
    }
    
    /// Translate using LibreTranslate (free, open-source translation service)
    /// Note: This uses a public instance - for production, consider hosting your own or using a paid service
    private static func translateWithLibreTranslate(_ text: String, from sourceLang: String, to targetLang: String) async -> String? {
        // Try multiple LibreTranslate public instances
        let apiURLs = [
            "https://libretranslate.de/translate",
            "https://translate.argosopentech.com/translate"
        ]
        
        // Map NLLanguage codes to LibreTranslate language codes
        let sourceLangMapped = mapLanguageCode(sourceLang)
        
        print("🌐 Attempting translation from \(sourceLangMapped) to \(targetLang) using LibreTranslate...")
        print("Text length: \(text.count) characters")
        print("Text preview: \(text.prefix(150))")
        
        // First try with detected language
        if let translated = await tryTranslateWithEndpoint(text: text, sourceLang: sourceLangMapped, targetLang: targetLang, apiURLs: apiURLs) {
            return translated
        }
        
        // If that fails, try with auto-detection
        print("⚠️ Translation with detected language failed, trying with auto-detection...")
        if let translated = await tryTranslateWithEndpoint(text: text, sourceLang: "auto", targetLang: targetLang, apiURLs: apiURLs) {
            return translated
        }
        
        print("❌ All LibreTranslate endpoints failed - translation unavailable")
        return nil
    }
    
    /// Helper function to try translation with a specific source language
    private static func tryTranslateWithEndpoint(text: String, sourceLang: String, targetLang: String, apiURLs: [String]) async -> String? {
        for apiURL in apiURLs {
            print("📡 Trying endpoint: \(apiURL) with source: \(sourceLang)")
            
            guard let url = URL(string: apiURL) else {
                print("❌ Invalid URL: \(apiURL)")
                continue
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 15.0 // 15 second timeout
            
            // LibreTranslate API format
            let body: [String: Any] = [
                "q": text,
                "source": sourceLang,
                "target": targetLang,
                "format": "text"
            ]
            
            guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
                print("❌ Failed to create request body for \(apiURL)")
                continue
            }
            request.httpBody = httpBody
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response from \(apiURL)")
                    continue
                }
                
                print("📥 Response status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    // Try to parse the response
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("📄 Response JSON keys: \(json.keys.joined(separator: ", "))")
                        
                        // Check for translatedText key
                        if let translatedText = json["translatedText"] as? String {
                            print("✅ Successfully translated using \(apiURL)")
                            print("Translated text length: \(translatedText.count)")
                            print("Translated text preview: \(translatedText.prefix(200))")
                            return translatedText
                        } else {
                            print("❌ Response does not contain 'translatedText' key")
                            print("Available keys: \(json.keys.joined(separator: ", "))")
                            if let responseString = String(data: data, encoding: .utf8) {
                                print("Full response: \(responseString.prefix(500))")
                            }
                        }
                    } else {
                        print("❌ Failed to parse JSON response from \(apiURL)")
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("Raw response: \(responseString.prefix(500))")
                        }
                    }
                } else {
                    print("❌ Translation API returned status code \(httpResponse.statusCode) from \(apiURL)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Error response: \(responseString.prefix(500))")
                    }
                }
            } catch {
                print("❌ Translation API error from \(apiURL): \(error.localizedDescription)")
                if let urlError = error as? URLError {
                    print("URL Error code: \(urlError.code.rawValue), description: \(urlError.localizedDescription)")
                }
            }
        }
        
        return nil
    }
    
    /// Map NLLanguage codes to LibreTranslate language codes
    private static func mapLanguageCode(_ code: String) -> String {
        // Map common language codes
        // LibreTranslate uses ISO 639-1 language codes
        let mapping: [String: String] = [
            "zh-Hans": "zh", // Simplified Chinese
            "zh-Hant": "zh", // Traditional Chinese
            "zh": "zh",      // Chinese (generic)
            "de": "de",      // German
            "ja": "ja",      // Japanese
            "fr": "fr",      // French
            "es": "es",      // Spanish
            "it": "it",      // Italian
            "pt": "pt",      // Portuguese
            "ko": "ko",      // Korean
            "ru": "ru",      // Russian
            "ar": "ar",      // Arabic
            "hi": "hi",      // Hindi
            "nl": "nl",      // Dutch
            "pl": "pl",      // Polish
            "tr": "tr",      // Turkish
            "vi": "vi",      // Vietnamese
            "th": "th",      // Thai
        ]
        
        // Check for exact match first
        if let mapped = mapping[code] {
            print("Language code mapping: \(code) -> \(mapped)")
            return mapped
        }
        
        // Check for prefix match (e.g., "zh-Hans" -> "zh")
        for (key, value) in mapping {
            if code.hasPrefix(key) {
                print("Language code prefix mapping: \(code) -> \(value) (matched prefix: \(key))")
                return value
            }
        }
        
        // If no mapping found, try to extract base language code
        // Some NLLanguage codes have format like "de-AT" (German-Austria)
        let baseCode = code.components(separatedBy: "-").first ?? code
        if let mapped = mapping[baseCode] {
            print("Language code base mapping: \(code) -> \(mapped) (extracted base: \(baseCode))")
            return mapped
        }
        
        print("⚠️ No language code mapping found for \(code), using original code")
        return code
    }
    
    // MARK: - Google Cloud Translation API Integration Example
    
    /// Example: Translate using Google Cloud Translation API
    /// Requires: Google Cloud Translation API key
    private static func translateWithGoogleAPI(_ text: String, from sourceLanguage: NLLanguage) async -> String {
        // Implementation example:
        /*
        let apiKey = "YOUR_GOOGLE_CLOUD_API_KEY"
        let sourceLangCode = sourceLanguage.rawValue
        let urlString = "https://translation.googleapis.com/language/translate/v2?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else { return text }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "q": text,
            "source": sourceLangCode,
            "target": "en",
            "format": "text"
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataDict = json["data"] as? [String: Any],
               let translations = dataDict["translations"] as? [[String: Any]],
               let firstTranslation = translations.first,
               let translatedText = firstTranslation["translatedText"] as? String {
                return translatedText
            }
        } catch {
            print("Google Translation API error: \(error.localizedDescription)")
        }
        */
        
        return text
    }
    
    // MARK: - Microsoft Azure Translator Integration Example
    
    /// Example: Translate using Microsoft Azure Translator
    /// Requires: Azure Translator API key and endpoint
    private static func translateWithAzureAPI(_ text: String, from sourceLanguage: NLLanguage) async -> String {
        // Implementation example:
        /*
        let apiKey = "YOUR_AZURE_API_KEY"
        let endpoint = "YOUR_AZURE_ENDPOINT"
        let sourceLangCode = sourceLanguage.rawValue
        let urlString = "\(endpoint)/translate?api-version=3.0&from=\(sourceLangCode)&to=en"
        
        guard let url = URL(string: urlString) else { return text }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        
        let body: [[String: String]] = [["Text": text]]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let translations = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let firstTranslation = translations.first,
               let translationsArray = firstTranslation["translations"] as? [[String: Any]],
               let translatedText = translationsArray.first?["text"] as? String {
                return translatedText
            }
        } catch {
            print("Azure Translation API error: \(error.localizedDescription)")
        }
        */
        
        return text
    }
}


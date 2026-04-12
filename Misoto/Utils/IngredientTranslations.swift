//
//  IngredientTranslations.swift
//  Misoto
//
//  Hardcoded ingredient translation dictionary loaded from a bundled JSON file.
//  Provides fast lookup to translate ingredient names between all 20 supported languages
//  without needing AI calls.
//

import Foundation

// MARK: - IngredientTranslations

class IngredientTranslations {
    
    /// Shared singleton instance
    static let shared = IngredientTranslations()
    
    // MARK: - Data Structures
    
    /// Forward lookup: English key -> [languageCode: translatedName]
    private var forwardIndex: [String: [String: String]] = [:]
    
    /// Reverse lookup: normalized(translatedName) -> English key, for every language
    /// This lets us find the canonical English key from any language input.
    private var reverseIndex: [String: String] = [:]
    
    /// All known English ingredient keys (lowercased)
    private(set) var allEnglishKeys: [String] = []
    
    /// Supported language codes (must match the JSON data)
    static let supportedLanguages = [
        "en", "ar", "de", "es", "fil", "fr", "he", "hi",
        "id", "it", "ja", "ko", "ms", "nl", "pt", "ru",
        "th", "vi", "zh-Hans", "zh-Hant"
    ]
    
    // MARK: - Initialization
    
    private init() {
        loadDictionary()
    }
    
    /// Load the ingredient dictionary from the bundled JSON file
    private func loadDictionary() {
        guard let url = Bundle.main.url(forResource: "IngredientDictionary", withExtension: "json") else {
            print("⚠️ IngredientTranslations: IngredientDictionary.json not found in bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: [String: String]] else {
                print("⚠️ IngredientTranslations: Invalid JSON structure")
                return
            }
            
            forwardIndex = json
            allEnglishKeys = Array(json.keys).sorted()
            
            // Build the reverse index for every language
            for (englishKey, translations) in json {
                let normalizedKey = Self.normalize(englishKey)
                // Map the English key itself
                reverseIndex[normalizedKey] = englishKey
                
                // Map every translation back to the English key
                for (_, translatedName) in translations {
                    let normalizedTranslation = Self.normalize(translatedName)
                    if !normalizedTranslation.isEmpty {
                        reverseIndex[normalizedTranslation] = englishKey
                    }
                }
            }
            
            print("✅ IngredientTranslations: Loaded \(forwardIndex.count) ingredients with reverse index of \(reverseIndex.count) entries")
            
        } catch {
            print("⚠️ IngredientTranslations: Failed to load dictionary: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public API
    
    /// Translate an ingredient name from any language to the target language.
    /// Returns `nil` if the ingredient is not found in the dictionary.
    ///
    /// - Parameters:
    ///   - ingredientName: The ingredient name in any supported language
    ///   - targetLanguage: The target language code (e.g., "ja", "zh-Hans", "fr")
    /// - Returns: The translated ingredient name, or `nil` if not found
    func translate(_ ingredientName: String, to targetLanguage: String) -> String? {
        // Step 1: Find the canonical English key
        guard let englishKey = findEnglishKey(for: ingredientName) else {
            return nil
        }
        
        // Step 2: Look up the translation in the target language
        guard let translations = forwardIndex[englishKey] else {
            return nil
        }
        
        return translations[targetLanguage]
    }
    
    /// Find the canonical English key for an ingredient name in any language.
    /// Uses normalized (lowercased, trimmed) matching.
    ///
    /// - Parameter ingredientName: The ingredient name in any language
    /// - Returns: The English key, or `nil` if not found
    func findEnglishKey(for ingredientName: String) -> String? {
        let normalized = Self.normalize(ingredientName)
        return reverseIndex[normalized]
    }
    
    /// Get all translations for an ingredient (by its English key).
    ///
    /// - Parameter englishKey: The English ingredient key (e.g., "chicken")
    /// - Returns: Dictionary of [languageCode: translatedName], or `nil` if not found
    func allTranslations(for englishKey: String) -> [String: String]? {
        let normalized = Self.normalize(englishKey)
        // Try direct lookup first
        if let translations = forwardIndex[normalized] {
            return translations
        }
        // Try via reverse index
        if let key = reverseIndex[normalized], let translations = forwardIndex[key] {
            return translations
        }
        return nil
    }
    
    /// Check if an ingredient name (in any language) exists in the dictionary.
    ///
    /// - Parameter ingredientName: The ingredient name to check
    /// - Returns: `true` if the ingredient is found
    func contains(_ ingredientName: String) -> Bool {
        let normalized = Self.normalize(ingredientName)
        return reverseIndex[normalized] != nil
    }
    
    /// Translate an ingredient name to the user's current app language.
    /// Falls back to the original name if no translation is found.
    ///
    /// - Parameter ingredientName: The ingredient name in any language
    /// - Returns: The translated name, or the original if not found
    func translateToCurrentLanguage(_ ingredientName: String) -> String {
        let currentLang = getCurrentLanguageCode()
        return translate(ingredientName, to: currentLang) ?? ingredientName
    }
    
    /// Suggest matching ingredient names for autocomplete.
    /// Searches across all languages for partial prefix matches.
    ///
    /// - Parameters:
    ///   - prefix: The text prefix to search for
    ///   - language: The language to return results in
    ///   - limit: Maximum number of suggestions (default 10)
    /// - Returns: Array of translated ingredient names matching the prefix
    func suggestions(for prefix: String, in language: String, limit: Int = 10) -> [String] {
        let normalizedPrefix = Self.normalize(prefix)
        guard !normalizedPrefix.isEmpty else { return [] }
        
        var results: [String] = []
        
        for (englishKey, translations) in forwardIndex {
            // Check if any translation starts with the prefix
            let matchesPrefix: Bool = {
                // Check English key
                if Self.normalize(englishKey).hasPrefix(normalizedPrefix) { return true }
                // Check all translations
                for (_, name) in translations {
                    if Self.normalize(name).hasPrefix(normalizedPrefix) { return true }
                }
                return false
            }()
            
            if matchesPrefix {
                if let translated = translations[language] {
                    results.append(translated)
                } else if let enName = translations["en"] {
                    results.append(enName)
                }
            }
            
            if results.count >= limit { break }
        }
        
        return results.sorted()
    }
    
    // MARK: - Helpers
    
    /// Normalize a string for matching: lowercase, trim whitespace, remove diacritics for Latin scripts
    static func normalize(_ string: String) -> String {
        return string
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: .diacriticInsensitive, locale: .current)
    }
    
    /// Get current app language code for translation
    private func getCurrentLanguageCode() -> String {
        let language = LocalizationManager.shared.currentLanguage
        switch language {
        case .chineseSimplified: return "zh-Hans"
        case .chineseTraditional: return "zh-Hant"
        default: return language.rawValue
        }
    }
}

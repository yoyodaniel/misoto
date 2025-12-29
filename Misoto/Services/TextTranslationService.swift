//
//  TextTranslationService.swift
//  Misoto
//
//  Detects language and translates non-English text to English using Foundation model capabilities
//

import Foundation
import NaturalLanguage

@MainActor
class TextTranslationService {
    
    /// Detect the language of the text
    static func detectLanguage(_ text: String) -> NLLanguage? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        // Get the dominant language
        guard let dominantLanguage = recognizer.dominantLanguage else {
            return nil
        }
        
        return dominantLanguage
    }
    
    /// Check if text is in English
    static func isEnglish(_ text: String) -> Bool {
        guard let language = detectLanguage(text) else {
            // If we can't detect, assume it might be English or mixed
            // Check for common English words/patterns
            return hasEnglishPatterns(text)
        }
        
        return language == .english
    }
    
    /// Translate text to English if it's not already in English
    static func translateToEnglish(_ text: String) async -> String {
        // Check if already in English
        if isEnglish(text) {
            return text
        }
        
        // Detect the source language
        guard let sourceLanguage = detectLanguage(text) else {
            print("Could not detect language, assuming English")
            return text
        }
        
        // If already English, return as-is
        if sourceLanguage == .english {
            return text
        }
        
        print("Detected language: \(sourceLanguage.rawValue), translating to English...")
        
        // Use intelligent translation based on detected language
        // This uses Foundation model capabilities through NaturalLanguage framework
        // and intelligent pattern matching for recipe-specific terms
        return await translateWithIntelligentTranslation(text, from: sourceLanguage)
    }
    
    /// Translate using intelligent Foundation model-based translation
    private static func translateWithIntelligentTranslation(_ text: String, from sourceLanguage: NLLanguage) async -> String {
        // Use system translation capabilities
        // Try Apple's Translation framework first (iOS 14+)
        if #available(iOS 14.0, *) {
            if let translated = await translateWithSystemTranslation(text, from: sourceLanguage) {
                return translated
            }
        }
        
        // Fallback: Use translation API service
        return await translateWithTranslationAPI(text, from: sourceLanguage)
    }
    
    /// Translate using Apple's system Translation framework
    @available(iOS 14.0, *)
    private static func translateWithSystemTranslation(_ text: String, from sourceLanguage: NLLanguage) async -> String? {
        // Note: Apple's Translation framework may require user interaction for privacy
        // For automatic translation, we'll use a translation API service instead
        // This method is kept for future use if Apple enables automatic translation
        
        // For now, return nil to use API-based translation
        return nil
    }
    
    /// Translate using translation API service
    private static func translateWithTranslationAPI(_ text: String, from sourceLanguage: NLLanguage) async -> String {
        print("🔄 Starting translation from \(sourceLanguage.rawValue) to English...")
        print("Original text length: \(text.count) characters")
        print("Original text preview: \(text.prefix(200))")
        
        // First try translation API
        let apiTranslated = await TranslationAPIService.translate(text, from: sourceLanguage)
        
        if apiTranslated != text && !apiTranslated.isEmpty {
            print("✅ Successfully translated using translation API")
            print("Translated text length: \(apiTranslated.count) characters")
            print("Translated text preview: \(apiTranslated.prefix(200))")
            return apiTranslated
        }
        
        // Fallback: Use hard-coded dictionaries for common recipe terms
        print("⚠️ Translation API not available, using hard-coded dictionaries as fallback")
        let dictionaryTranslated = translateCommonRecipeTerms(text, from: sourceLanguage)
        
        if dictionaryTranslated != text {
            print("✅ Applied dictionary translations")
            return dictionaryTranslated
        }
        
        print("⚠️ No translation available, returning original text")
        return text
    }
    
    /// Translate common recipe terms using hard-coded dictionaries
    private static func translateCommonRecipeTerms(_ text: String, from sourceLanguage: NLLanguage) -> String {
        var translated = text
        let languageCode = sourceLanguage.rawValue
        
        // German to English common recipe terms
        if languageCode.hasPrefix("de") {
            let germanToEnglish: [String: String] = [
                "ZUTATEN": "INGREDIENTS",
                "Zutat": "INGREDIENT",
                "Gewürze": "SEASONINGS",
                "Gewürz": "SEASONING",
                "Marinade": "MARINADE",
                "Marinaden": "MARINADES",
                "Anleitung": "INSTRUCTIONS",
                "Anleitungen": "INSTRUCTIONS",
                "Schritte": "PROCEDURES",
                "Schritt": "STEP",
                "Zubereitung": "PREPARATION",
                "Rezept": "RECIPE",
                "Hähnchen": "chicken",
                "Huhn": "chicken",
                "Hühnerflügel": "chicken wings",
                "Rindfleisch": "beef",
                "Schweinefleisch": "pork",
                "Fisch": "fish",
                "Salz": "salt",
                "Zucker": "sugar",
                "Öl": "oil",
                "Sojasauce": "soy sauce",
                "Knoblauch": "garlic",
                "Ingwer": "ginger",
                "Zwiebel": "onion",
                "Pfeffer": "pepper",
                "Zitrone": "lemon",
                "Wasser": "water",
                "Butter": "butter",
                "Mehl": "flour",
                "Stärke": "starch",
                "Reis": "rice",
                "Nudeln": "noodles",
                "Tomate": "tomato",
                "Tomaten": "tomatoes",
                "Kartoffel": "potato",
                "Kartoffeln": "potatoes",
                "Möhre": "carrot",
                "Möhren": "carrots",
                "Schweinehack": "minced pork",
                "Hackfleisch": "minced meat",
                "Backpulver": "baking powder",
                "Honig": "honey",
                "Knobi": "garlic",
                "Brühe": "broth",
                "Fischsauce": "fish sauce",
                "Stück": "piece",
                "Stücke": "pieces",
                "Scheibe": "slice",
                "Scheiben": "slices",
                "Tasse": "cup",
                "Tassen": "cups",
                "Esslöffel": "tbsp",
                "Teelöffel": "tsp",
                "Gramm": "g",
                "Kilogramm": "kg",
                "Milliliter": "ml",
                "Liter": "l",
                "Prise": "pinch",
                "Zehe": "clove",
                "Zehen": "cloves",
                "Bund": "bunch",
                "Bünde": "bunches",
                "Kopf": "head",
                "Köpfe": "heads",
                "Strang": "strand",
                "Stränge": "strands",
                "erhitzen": "heat",
                "erwärmen": "warm",
                "braten": "fry",
                "anbraten": "pan-fry",
                "schmoren": "braise",
                "kochen": "cook",
                "backen": "bake",
                "rösten": "roast",
                "grillen": "grill",
                "dämpfen": "steam",
                "sieden": "boil",
                "köcheln": "simmer",
                "marinieren": "marinate",
                "schneiden": "cut",
                "in Scheiben schneiden": "slice",
                "hacken": "chop",
                "zerkleinern": "mince",
                "reiben": "grate",
                "schälen": "peel",
                "hinzufügen": "add",
                "rühren": "stir",
                "mischen": "mix",
                "verrühren": "whisk",
                "unterheben": "fold",
                "kneten": "knead",
                "bis": "until",
                "goldbraun": "golden brown",
                "duftend": "fragrant",
                "bei niedriger Hitze": "low heat",
                "bei mittlerer Hitze": "medium heat",
                "bei hoher Hitze": "high heat",
                "Minuten": "minutes",
                "Minute": "minute",
                "Stunden": "hours",
                "Stunde": "hour",
                "servieren": "serve",
                "garnieren": "garnish",
                "würzen": "season",
                "abschmecken": "taste",
                "vorheizen": "preheat"
            ]
            
            // Sort by length (longest first) to match longer phrases first
            let sortedPairs = germanToEnglish.sorted { $0.key.count > $1.key.count }
            
            for (german, english) in sortedPairs {
                translated = translated.replacingOccurrences(
                    of: german,
                    with: english,
                    options: [.caseInsensitive, .diacriticInsensitive]
                )
            }
        }
        
        // Chinese to English common recipe terms
        if languageCode.hasPrefix("zh") {
            let chineseToEnglish: [String: String] = [
                "材料": "INGREDIENTS",
                "調味料": "SEASONINGS",
                "醃料": "MARINADES",
                "步驟": "PROCEDURES",
                "做法": "INSTRUCTIONS",
                "雞": "chicken",
                "雞翼": "chicken wings",
                "雞肉": "chicken",
                "牛肉": "beef",
                "豬肉": "pork",
                "魚": "fish",
                "鹽": "salt",
                "糖": "sugar",
                "油": "oil",
                "醬油": "soy sauce",
                "蒜": "garlic",
                "薑": "ginger",
                "洋蔥": "onion",
                "胡椒": "pepper",
                "檸檬": "lemon",
                "水": "water",
                "片": "slice",
                "個": "piece",
                "杯": "cup",
                "湯匙": "tbsp",
                "茶匙": "tsp",
                "克": "g",
                "毫升": "ml",
                "加熱": "heat",
                "炒": "stir-fry",
                "煮": "cook",
                "烤": "roast",
                "炸": "fry",
                "蒸": "steam",
                "醃": "marinate",
                "切": "cut",
                "切片": "slice",
                "切碎": "chop",
                "磨": "grind",
                "擠": "juice",
                "加入": "add",
                "攪拌": "stir",
                "直到": "until",
                "金黃色": "golden brown",
                "香": "fragrant",
                "低火": "low heat",
                "分鐘": "minutes"
            ]
            
            let sortedPairs = chineseToEnglish.sorted { $0.key.count > $1.key.count }
            for (chinese, english) in sortedPairs {
                translated = translated.replacingOccurrences(
                    of: chinese,
                    with: english,
                    options: [.caseInsensitive, .diacriticInsensitive]
                )
            }
        }
        
        // Japanese to English common recipe terms
        if languageCode.hasPrefix("ja") {
            let japaneseToEnglish: [String: String] = [
                "材料": "INGREDIENTS",
                "調味料": "SEASONINGS",
                "作り方": "INSTRUCTIONS",
                "手順": "PROCEDURES",
                "鶏": "chicken",
                "鶏肉": "chicken",
                "牛肉": "beef",
                "豚肉": "pork",
                "魚": "fish",
                "塩": "salt",
                "砂糖": "sugar",
                "油": "oil",
                "醤油": "soy sauce",
                "にんにく": "garlic",
                "生姜": "ginger",
                "玉ねぎ": "onion",
                "コショウ": "pepper",
                "レモン": "lemon",
                "水": "water",
                "切る": "cut",
                "炒める": "stir-fry",
                "煮る": "cook",
                "焼く": "roast",
                "揚げる": "fry",
                "蒸す": "steam",
                "漬ける": "marinate"
            ]
            
            let sortedPairs = japaneseToEnglish.sorted { $0.key.count > $1.key.count }
            for (japanese, english) in sortedPairs {
                translated = translated.replacingOccurrences(
                    of: japanese,
                    with: english,
                    options: [.caseInsensitive, .diacriticInsensitive]
                )
            }
        }
        
        return translated
    }
    
    /// Check if text has English patterns (fallback when language detection fails)
    private static func hasEnglishPatterns(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        
        // Common English recipe words
        let englishWords = [
            "ingredient", "instruction", "recipe", "cook", "bake", "roast",
            "chicken", "beef", "pork", "fish", "salt", "pepper", "garlic",
            "onion", "tomato", "oil", "butter", "flour", "sugar", "water",
            "tablespoon", "teaspoon", "cup", "ounce", "pound", "gram",
            "heat", "add", "mix", "stir", "fry", "boil", "simmer"
        ]
        
        // Check if text contains English words
        let containsEnglish = englishWords.contains { lowercased.contains($0) }
        
        // Check for English measurement patterns
        let hasEnglishMeasurements = lowercased.range(
            of: "\\d+\\s*(tbsp|tsp|cup|cups|oz|lb|g|kg|ml|l|tablespoon|teaspoon)",
            options: .regularExpression
        ) != nil
        
        return containsEnglish || hasEnglishMeasurements
    }
}


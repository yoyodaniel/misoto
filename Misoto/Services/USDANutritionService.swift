//
//  USDANutritionService.swift
//  Misoto
//
//  Created by Daniel Chan on 14.02.2026.
//
//  Integrates with the USDA FoodData Central API to look up
//  accurate nutritional data per 100g for ingredients.
//  API docs: https://fdc.nal.usda.gov/api-guide/
//

import Foundation

// MARK: - USDA API Response Models

struct USDASearchResponse: Codable {
    let foods: [USDAFood]
    let totalHits: Int
}

struct USDAFood: Codable {
    let fdcId: Int
    let description: String
    let dataType: String?
    let foodNutrients: [USDAFoodNutrient]
    let foodMeasures: [USDAFoodMeasure]?
    
    enum CodingKeys: String, CodingKey {
        case fdcId, description, dataType, foodNutrients, foodMeasures
    }
}

struct USDAFoodNutrient: Codable {
    let nutrientId: Int?
    let nutrientName: String?
    let nutrientNumber: String?
    let value: Double?
    let unitName: String?
}

struct USDAFoodMeasure: Codable {
    let disseminationText: String?  // e.g. "1 cup", "1 tbsp"
    let gramWeight: Double?
    let measureUnitName: String?    // e.g. "cup", "tbsp"
    let measureUnitAbbreviation: String?
    let rank: Int?
}

// MARK: - Nutrient Values (per 100g)

struct NutrientsPer100g {
    let calories: Double    // kcal
    let protein: Double     // g
    let carbohydrates: Double // g
    let fat: Double         // g
    let saturatedFat: Double // g
    let fiber: Double       // g
    let sugar: Double       // g
    let sodium: Double      // mg
    let foodMeasures: [USDAFoodMeasure] // portion info for unit conversion
    let foodName: String    // matched food name for debugging
}

// MARK: - USDA Nutrition Service

class USDANutritionService {
    static let shared = USDANutritionService()
    
    // In-memory cache: ingredient name → nutrients per 100g
    private var cache: [String: NutrientsPer100g] = [:]
    
    private init() {}
    
    // MARK: - Public API
    
    /// Look up nutrition per 100g for an ingredient name.
    /// Returns nil if no suitable match is found.
    func lookupNutrition(for ingredientName: String) async -> NutrientsPer100g? {
        let cacheKey = ingredientName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check cache first
        if let cached = cache[cacheKey] {
            return cached
        }
        
        // Search USDA
        guard let food = await searchFood(query: ingredientName) else {
            print("⚠️ USDA: No match found for '\(ingredientName)'")
            return nil
        }
        
        let nutrients = extractNutrients(from: food)
        cache[cacheKey] = nutrients
        
        print("✅ USDA: '\(ingredientName)' → '\(food.description)' | \(Int(nutrients.calories)) kcal/100g")
        return nutrients
    }
    
    /// Clear the lookup cache
    func clearCache() {
        cache.removeAll()
    }
    
    // MARK: - Private: API Calls
    
    private func searchFood(query: String) async -> USDAFood? {
        // Clean the query: remove quantities, preparation words
        let cleanedQuery = cleanIngredientName(query)
        guard !cleanedQuery.isEmpty else { return nil }
        
        // Build search queries: translated/simplified FIRST, then original
        let searchQueries = buildSearchQueries(cleanedQuery)
        
        // Strategy 1: Try curated databases (SR Legacy, Foundation) — highest quality
        for searchQuery in searchQueries {
            if let food = await performSearch(
                query: searchQuery,
                dataTypes: "SR%20Legacy,Foundation",
                requireQuality: true
            ) {
                return food
            }
        }
        
        // Strategy 2: Try Survey (FNDDS) — generic prepared foods
        for searchQuery in searchQueries {
            if let food = await performSearch(
                query: searchQuery,
                dataTypes: "Survey%20(FNDDS)",
                requireQuality: true
            ) {
                return food
            }
        }
        
        // Strategy 3: Last resort — Branded, but with strict quality gate
        for searchQuery in searchQueries {
            if let food = await performSearch(
                query: searchQuery,
                dataTypes: "Branded",
                requireQuality: true
            ) {
                return food
            }
        }
        
        print("⚠️ USDA: No match found after all strategies for '\(cleanedQuery)'")
        return nil
    }
    
    /// Perform a single USDA API search against specific data types
    private func performSearch(query: String, dataTypes: String?, requireQuality: Bool) async -> USDAFood? {
        let decodedDataTypes = dataTypes.flatMap { $0.removingPercentEncoding }
        let dtLabel = dataTypes ?? "All"
        print("🔍 USDA: Searching '\(query)' in [\(dtLabel)]")

        do {
            let data = try await BackendAPIProxy.usdaFoodsSearch(
                query: query,
                dataTypes: decodedDataTypes,
                pageSize: 10
            )

            let searchResponse = try JSONDecoder().decode(USDASearchResponse.self, from: data)
            
            if searchResponse.totalHits == 0 {
                print("🔍 USDA: 0 results for '\(query)' in [\(dtLabel)]")
                return nil
            }
            
            print("🔍 USDA: \(searchResponse.totalHits) results for '\(query)' in [\(dtLabel)]")
            
            // Pick best match with quality check
            if let match = pickBestMatch(from: searchResponse.foods, for: query) {
                if requireQuality {
                    // Verify the match is actually relevant — at least one query word in description
                    let queryWords = Set(query.lowercased().split(separator: " ").map(String.init).filter { $0.count > 2 })
                    let descWords = Set(match.description.lowercased().split(separator: " ").map(String.init).filter { $0.count > 2 })
                    let overlap = queryWords.intersection(descWords)
                    
                    if overlap.isEmpty && queryWords.count > 0 {
                        print("⚠️ USDA: Rejected '\(match.description)' — no word overlap with '\(query)'")
                        return nil
                    }
                }
                return match
            }
            
            return nil
        } catch {
            print("⚠️ USDA search failed for '\(query)': \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Build search queries: translated/simplified FIRST (higher quality), then original
    private func buildSearchQueries(_ query: String) -> [String] {
        var queries: [String] = []
        
        // 1. Try translated English name FIRST (best chance of hitting SR Legacy)
        if let translated = translateToEnglish(query), translated.lowercased() != query.lowercased() {
            queries.append(translated)
        }
        
        // 2. Try simplified/generic version (e.g., "skyr natur" → "yogurt plain nonfat")
        if let simplified = simplifyIngredient(query), !queries.contains(simplified) {
            queries.append(simplified)
        }
        
        // 3. Try the original query last
        if !queries.contains(query) {
            queries.append(query)
        }
        
        return queries
    }
    
    /// Translate common non-English ingredient names to English for USDA search
    private func translateToEnglish(_ name: String) -> String? {
        let lower = name.lowercased()
        
        // German → English
        let germanToEnglish: [String: String] = [
            "weizenmehl": "wheat flour white all-purpose",
            "mehl": "wheat flour",
            "vollkornmehl": "wheat flour whole-grain",
            "roggenmehl": "rye flour",
            "dinkelmehl": "spelt flour",
            "zucker": "sugar",
            "brauner zucker": "brown sugar",
            "puderzucker": "powdered sugar",
            "butter": "butter",
            "milch": "milk whole",
            "sahne": "cream heavy",
            "schlagsahne": "cream whipping",
            "schmand": "sour cream",
            "quark": "quark cheese",
            "skyr": "yogurt plain low fat",
            "joghurt": "yogurt plain",
            "ei": "egg whole raw",
            "eier": "eggs whole raw",
            "hähnchenbrust": "chicken breast raw",
            "hähnchenkeule": "chicken thigh raw",
            "hackfleisch": "ground beef raw",
            "rindfleisch": "beef raw",
            "schweinefleisch": "pork raw",
            "lachs": "salmon raw",
            "reis": "rice white long-grain",
            "nudeln": "pasta dry",
            "kartoffel": "potato raw",
            "kartoffeln": "potatoes raw",
            "zwiebel": "onion raw",
            "knoblauch": "garlic raw",
            "tomate": "tomato raw",
            "tomaten": "tomatoes raw",
            "karotte": "carrot raw",
            "möhre": "carrot raw",
            "paprika": "bell pepper raw",
            "gurke": "cucumber raw",
            "salz": "salt table",
            "pfeffer": "pepper black",
            "olivenöl": "olive oil",
            "sonnenblumenöl": "sunflower oil",
            "rapsöl": "canola oil",
            "sojasauce": "soy sauce",
            "honig": "honey",
            "senf": "mustard",
            "essig": "vinegar",
            "zitrone": "lemon raw",
            "limette": "lime raw",
            "ingwer": "ginger root raw",
            "zimt": "cinnamon ground",
            "backpulver": "baking powder",
            "natron": "baking soda",
            "hefe": "yeast",
            "haferflocken": "oats rolled",
            "mandeln": "almonds",
            "walnüsse": "walnuts",
            "kokosmilch": "coconut milk canned",
            "spinat": "spinach raw",
            "brokkoli": "broccoli raw",
            "blumenkohl": "cauliflower raw",
            "aubergine": "eggplant raw",
            "zucchini": "zucchini raw",
            "kürbis": "pumpkin raw",
            "pilze": "mushrooms raw",
            "champignons": "mushrooms white raw",
            "lauch": "leek raw",
            "sellerie": "celery raw",
            "petersilie": "parsley raw",
            "basilikum": "basil raw",
            "koriander": "coriander leaves raw",
            "thymian": "thyme",
            "rosmarin": "rosemary",
            "käse": "cheese cheddar",
            "parmesan": "parmesan cheese",
            "mozzarella": "mozzarella cheese",
            "frischkäse": "cream cheese",
        ]
        
        // Check for exact match first
        if let translation = germanToEnglish[lower] {
            return translation
        }
        
        // Check if any key is contained in the name
        for (german, english) in germanToEnglish.sorted(by: { $0.key.count > $1.key.count }) {
            if lower.contains(german) {
                return english
            }
        }
        
        // French → English (common ingredients)
        let frenchToEnglish: [String: String] = [
            "farine": "wheat flour", "beurre": "butter", "lait": "milk",
            "oeuf": "egg", "oeufs": "eggs", "poulet": "chicken",
            "boeuf": "beef", "porc": "pork", "riz": "rice",
            "sel": "salt", "poivre": "pepper", "huile d'olive": "olive oil",
            "sucre": "sugar", "crème": "cream", "fromage": "cheese",
            "oignon": "onion", "ail": "garlic", "tomate": "tomato",
            "pomme de terre": "potato", "carotte": "carrot",
        ]
        
        for (french, english) in frenchToEnglish.sorted(by: { $0.key.count > $1.key.count }) {
            if lower.contains(french) { return english }
        }
        
        // Spanish → English
        let spanishToEnglish: [String: String] = [
            "harina": "wheat flour", "mantequilla": "butter", "leche": "milk",
            "huevo": "egg", "pollo": "chicken", "arroz": "rice",
            "azúcar": "sugar", "aceite de oliva": "olive oil", "sal": "salt",
            "cebolla": "onion", "ajo": "garlic", "tomate": "tomato",
        ]
        
        for (spanish, english) in spanishToEnglish.sorted(by: { $0.key.count > $1.key.count }) {
            if lower.contains(spanish) { return english }
        }
        
        // Japanese → English (common recipe ingredients)
        let japaneseToEnglish: [String: String] = [
            "醤油": "soy sauce", "しょうゆ": "soy sauce", "しょう油": "soy sauce",
            "味噌": "miso", "みそ": "miso",
            "味醂": "mirin", "みりん": "mirin",
            "酒": "sake rice wine", "料理酒": "cooking sake",
            "砂糖": "sugar", "塩": "salt",
            "酢": "vinegar rice", "米酢": "rice vinegar",
            "ごま油": "sesame oil", "胡麻油": "sesame oil",
            "サラダ油": "vegetable oil",
            "鶏肉": "chicken", "鶏もも肉": "chicken thigh", "鶏むね肉": "chicken breast",
            "豚肉": "pork", "豚バラ": "pork belly", "豚ロース": "pork loin",
            "牛肉": "beef",
            "魚": "fish", "鮭": "salmon", "マグロ": "tuna", "エビ": "shrimp",
            "豆腐": "tofu", "油揚げ": "fried tofu",
            "卵": "egg", "たまご": "egg",
            "米": "rice white", "ご飯": "rice cooked",
            "小麦粉": "wheat flour", "片栗粉": "potato starch",
            "パン粉": "panko breadcrumbs",
            "にんにく": "garlic", "生姜": "ginger", "しょうが": "ginger",
            "玉ねぎ": "onion", "長ネギ": "green onion", "ねぎ": "green onion",
            "にんじん": "carrot", "大根": "daikon radish",
            "きゅうり": "cucumber", "なす": "eggplant",
            "キャベツ": "cabbage", "白菜": "napa cabbage",
            "ほうれん草": "spinach", "もやし": "bean sprouts",
            "バター": "butter", "牛乳": "milk",
            "だし": "dashi fish stock", "かつお節": "bonito flakes",
            "昆布": "kelp kombu", "わかめ": "wakame seaweed",
            "海苔": "nori seaweed",
        ]
        
        for (japanese, english) in japaneseToEnglish.sorted(by: { $0.key.count > $1.key.count }) {
            if lower.contains(japanese) { return english }
        }
        
        // Chinese → English
        let chineseToEnglish: [String: String] = [
            "酱油": "soy sauce", "醬油": "soy sauce",
            "老抽": "dark soy sauce", "生抽": "light soy sauce",
            "蚝油": "oyster sauce", "蠔油": "oyster sauce",
            "料酒": "cooking wine",
            "米醋": "rice vinegar", "醋": "vinegar",
            "芝麻油": "sesame oil", "麻油": "sesame oil",
            "花生油": "peanut oil", "菜籽油": "canola oil",
            "糖": "sugar", "盐": "salt", "鹽": "salt",
            "鸡肉": "chicken", "雞肉": "chicken",
            "猪肉": "pork", "豬肉": "pork", "五花肉": "pork belly",
            "牛肉": "beef",
            "虾": "shrimp", "蝦": "shrimp",
            "鱼": "fish", "魚": "fish", "三文鱼": "salmon",
            "豆腐": "tofu", "鸡蛋": "egg", "雞蛋": "egg",
            "米": "rice", "面粉": "wheat flour", "麵粉": "wheat flour",
            "淀粉": "corn starch", "澱粉": "corn starch",
            "大蒜": "garlic", "姜": "ginger", "薑": "ginger",
            "葱": "green onion", "蔥": "green onion", "洋葱": "onion", "洋蔥": "onion",
            "胡萝卜": "carrot", "胡蘿蔔": "carrot",
            "土豆": "potato", "马铃薯": "potato",
            "番茄": "tomato", "西红柿": "tomato",
            "黄瓜": "cucumber", "茄子": "eggplant",
            "白菜": "napa cabbage", "菠菜": "spinach",
            "豆芽": "bean sprouts", "香菇": "shiitake mushroom",
            "牛奶": "milk", "黄油": "butter", "奶油": "cream",
        ]
        
        for (chinese, english) in chineseToEnglish.sorted(by: { $0.key.count > $1.key.count }) {
            if lower.contains(chinese) { return english }
        }
        
        // Korean → English
        let koreanToEnglish: [String: String] = [
            "간장": "soy sauce", "된장": "doenjang soybean paste",
            "고추장": "gochujang red pepper paste",
            "고춧가루": "red pepper flakes", "참기름": "sesame oil",
            "식용유": "vegetable oil", "설탕": "sugar", "소금": "salt",
            "식초": "vinegar", "맛술": "mirin",
            "닭고기": "chicken", "돼지고기": "pork", "소고기": "beef",
            "새우": "shrimp", "생선": "fish", "두부": "tofu",
            "계란": "egg", "달걀": "egg",
            "쌀": "rice", "밀가루": "wheat flour",
            "마늘": "garlic", "생강": "ginger",
            "양파": "onion", "파": "green onion", "대파": "green onion",
            "당근": "carrot", "감자": "potato",
            "배추": "napa cabbage", "시금치": "spinach",
            "콩나물": "bean sprouts", "버섯": "mushroom",
            "우유": "milk", "버터": "butter",
            "김": "nori seaweed", "미역": "wakame seaweed",
        ]
        
        for (korean, english) in koreanToEnglish.sorted(by: { $0.key.count > $1.key.count }) {
            if lower.contains(korean) { return english }
        }
        
        // Malay/Indonesian → English
        let malayToEnglish: [String: String] = [
            "kecap manis": "sweet soy sauce", "kecap asin": "soy sauce",
            "minyak goreng": "cooking oil", "minyak kelapa": "coconut oil",
            "garam": "salt", "gula": "sugar",
            "bawang putih": "garlic", "bawang merah": "shallot",
            "jahe": "ginger", "halia": "ginger",
            "ayam": "chicken", "daging sapi": "beef", "daging babi": "pork",
            "udang": "shrimp", "ikan": "fish", "tahu": "tofu", "tempe": "tempeh",
            "telur": "egg", "nasi": "rice cooked", "beras": "rice",
            "tepung terigu": "wheat flour", "santan": "coconut milk",
            "susu": "milk", "mentega": "butter",
            "bawang bombay": "onion", "wortel": "carrot",
            "kentang": "potato", "tomat": "tomato",
        ]
        
        for (malay, english) in malayToEnglish.sorted(by: { $0.key.count > $1.key.count }) {
            if lower.contains(malay) { return english }
        }
        
        return nil
    }
    
    /// Simplify ingredient to a more generic USDA-friendly term
    private func simplifyIngredient(_ name: String) -> String? {
        let lower = name.lowercased()
        
        // Remove brand-specific or type-specific suffixes
        // e.g., "Weizenmehl Type 405" → "wheat flour white"
        // e.g., "Skyr Natur" → "yogurt plain"
        
        if lower.contains("skyr") { return "yogurt plain nonfat" }
        if lower.contains("type 405") || lower.contains("type405") { return "wheat flour white all-purpose" }
        if lower.contains("type 550") { return "wheat flour white bread" }
        if lower.contains("type 1050") { return "wheat flour whole-grain" }
        
        return nil
    }
    
    // MARK: - Private: Matching & Extraction
    
    /// Pick the best USDA food match from search results
    private func pickBestMatch(from foods: [USDAFood], for query: String) -> USDAFood? {
        guard !foods.isEmpty else { return nil }
        
        let queryLower = query.lowercased()
        let queryWords = Set(queryLower.split(separator: " ").map(String.init).filter { $0.count > 1 })
        
        // Score each result
        var scored: [(food: USDAFood, score: Int)] = foods.map { food in
            let desc = food.description.lowercased()
            let descWords = Set(desc.split(separator: " ").map(String.init).filter { $0.count > 1 })
            var score = 0
            
            // Prefer Foundation > SR Legacy > Survey > Branded
            if food.dataType == "Foundation" { score += 6 }
            else if food.dataType == "SR Legacy" { score += 5 }
            else if food.dataType == "Survey (FNDDS)" { score += 3 }
            else if food.dataType == "Branded" { score += 0 }
            
            // Prefer shorter, more generic descriptions
            if desc.count < 40 { score += 4 }
            else if desc.count < 60 { score += 2 }
            else if desc.count > 100 { score -= 2 } // penalize very long branded names
            
            // Prefer "raw" over cooked/processed for base calculations
            if desc.contains("raw") { score += 3 }
            
            // Penalize very specific preparations
            if desc.contains("canned") || desc.contains("frozen") { score -= 2 }
            if desc.contains("with salt") || desc.contains("with added") { score -= 1 }
            if desc.contains("flavored") || desc.contains("strawberry") || desc.contains("chocolate") { score -= 4 }
            
            // Word overlap bonus (strong signal)
            let overlap = queryWords.intersection(descWords)
            score += overlap.count * 4
            
            // Exact containment bonus
            if desc.contains(queryLower) { score += 6 }
            if desc.hasPrefix(queryLower) { score += 4 }
            
            // First word match bonus (primary ingredient)
            if let firstQueryWord = queryLower.split(separator: " ").first,
               desc.hasPrefix(String(firstQueryWord)) {
                score += 3
            }
            
            return (food, score)
        }
        
        scored.sort { $0.score > $1.score }
        
        if let best = scored.first {
            print("🔍 USDA: Best match for '\(query)' → '\(best.food.description)' (\(best.food.dataType ?? "?")) score=\(best.score)")
        }
        
        return scored.first?.food
    }
    
    /// Extract nutrient values per 100g from a USDA food item
    private func extractNutrients(from food: USDAFood) -> NutrientsPer100g {
        var calories: Double = 0
        var protein: Double = 0
        var carbs: Double = 0
        var fat: Double = 0
        var satFat: Double = 0
        var fiber: Double = 0
        var sugar: Double = 0
        var sodium: Double = 0
        
        for nutrient in food.foodNutrients {
            guard let value = nutrient.value else { continue }
            
            // Match by nutrient number (more reliable) or nutrient ID
            let number = nutrient.nutrientNumber ?? ""
            let id = nutrient.nutrientId ?? 0
            
            switch number {
            case "208":                      // Energy (kcal) — SR Legacy
                calories = value
            case "957":                      // Energy (Atwater General) — Foundation
                if calories == 0 { calories = value }
            case "958":                      // Energy (Atwater Specific) — Foundation
                if calories == 0 { calories = value }
            case "203": protein = value      // Protein
            case "204": fat = value          // Total lipid (fat)
            case "205": carbs = value        // Carbohydrate
            case "269",                      // Sugars, total (SR Legacy)
                 "269.3":                    // Sugars, total (Foundation variant)
                if sugar == 0 { sugar = value }
            case "291": fiber = value        // Fiber, total dietary
            case "606": satFat = value       // Fatty acids, total saturated
            case "307": sodium = value       // Sodium
            default:
                // Fallback: match by nutrient ID
                switch id {
                case 1008, 2047, 2048:       // Energy variants
                    if calories == 0 { calories = value }
                case 1003: protein = value
                case 1004: fat = value
                case 1005: carbs = value
                case 2000: if sugar == 0 { sugar = value }
                case 1079: fiber = value
                case 1258: satFat = value
                case 1093: sodium = value
                default: break
                }
            }
        }
        
        // If calories are still 0 but we have macros, compute from 4/4/9 rule
        if calories == 0 && (protein > 0 || carbs > 0 || fat > 0) {
            calories = protein * 4 + carbs * 4 + fat * 9
            print("ℹ️ USDA: Computed calories from macros: \(Int(calories)) kcal (P:\(protein) C:\(carbs) F:\(fat))")
        }
        
        return NutrientsPer100g(
            calories: calories,
            protein: protein,
            carbohydrates: carbs,
            fat: fat,
            saturatedFat: satFat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            foodMeasures: food.foodMeasures ?? [],
            foodName: food.description
        )
    }
    
    /// Clean an ingredient name for USDA search (remove amounts, prep words)
    private func cleanIngredientName(_ name: String) -> String {
        var cleaned = name.lowercased()
        
        // Remove common preparation/state words that confuse USDA search
        let removeWords = [
            "fresh", "dried", "chopped", "minced", "diced", "sliced", "grated",
            "crushed", "ground", "whole", "peeled", "deseeded", "boneless",
            "skinless", "organic", "large", "medium", "small", "finely",
            "roughly", "thinly", "coarsely", "to taste", "optional",
            "for garnish", "for serving", "as needed"
        ]
        
        for word in removeWords {
            cleaned = cleaned.replacingOccurrences(of: word, with: "")
        }
        
        // Remove extra whitespace
        cleaned = cleaned.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
}

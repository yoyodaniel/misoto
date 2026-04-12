//
//  IngredientDatabase.swift
//  Misoto
//
//  On-device ingredient matching engine.
//  Loads canonical ingredients, aliases, and allergen data from bundled JSON files.
//  Provides fast lookup to match free-text ingredient names to canonical IDs.
//
//  Created by Daniel Chan on 08.02.2026.
//

import Foundation

// MARK: - IngredientDatabase

class IngredientDatabase {
    
    /// Shared singleton instance
    static let shared = IngredientDatabase()
    
    // MARK: - Data Structures
    
    struct CanonicalEntry {
        let id: String
        let name: String
        let category: Ingredient.FoodCategory
        let defaultUnitHint: String?
    }
    
    struct AllergenEntry {
        let allergens: [Ingredient.Allergen]
        let dietaryFlags: [Ingredient.DietaryFlag]
    }
    
    struct MatchResult {
        let canonicalId: String
        let canonicalName: String
        let foodCategory: Ingredient.FoodCategory
        let defaultUnitHint: String?
        let confidence: Double  // 0.0 – 1.0
    }
    
    // MARK: - Internal Storage
    
    /// Canonical ingredient lookup: canonicalId → entry
    private var canonicalMap: [String: CanonicalEntry] = [:]
    
    /// Alias lookup: normalized alias string → canonicalId (O(1) exact match)
    private var aliasMap: [String: String] = [:]
    
    /// Allergen lookup: canonicalId → allergen entry
    private var allergenMap: [String: AllergenEntry] = [:]
    
    /// All canonical names for substring matching (sorted by length descending for greedy matching)
    private var allNames: [(normalized: String, id: String)] = []
    
    /// Is data loaded?
    private(set) var isLoaded = false
    
    // MARK: - Initialization
    
    private init() {
        loadData()
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        loadCanonical()
        loadAliases()
        loadAllergens()
        
        // Build sorted name list for substring matching
        allNames = canonicalMap.values.map { (normalize($0.name), $0.id) }
            .sorted { $0.normalized.count > $1.normalized.count }
        
        isLoaded = true
        print("🧪 IngredientDatabase loaded: \(canonicalMap.count) canonical, \(aliasMap.count) aliases, \(allergenMap.count) allergen entries")
    }
    
    private func loadCanonical() {
        guard let url = Bundle.main.url(forResource: "CanonicalIngredients", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("⚠️ IngredientDatabase: CanonicalIngredients.json not found in bundle")
            return
        }
        
        struct RawCanonical: Decodable {
            let id: String
            let name: String
            let category: String
            let defaultUnitHint: String?
        }
        
        guard let items = try? JSONDecoder().decode([RawCanonical].self, from: data) else {
            print("⚠️ IngredientDatabase: Failed to decode CanonicalIngredients.json")
            return
        }
        
        for item in items {
            guard let category = Ingredient.FoodCategory(rawValue: item.category) else { continue }
            canonicalMap[item.id] = CanonicalEntry(
                id: item.id,
                name: item.name,
                category: category,
                defaultUnitHint: item.defaultUnitHint
            )
        }
    }
    
    private func loadAliases() {
        guard let url = Bundle.main.url(forResource: "IngredientAliases", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("⚠️ IngredientDatabase: IngredientAliases.json not found in bundle")
            return
        }
        
        guard let lookup = try? JSONDecoder().decode([String: String].self, from: data) else {
            print("⚠️ IngredientDatabase: Failed to decode IngredientAliases.json")
            return
        }
        
        aliasMap = lookup
    }
    
    private func loadAllergens() {
        guard let url = Bundle.main.url(forResource: "IngredientAllergens", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("⚠️ IngredientDatabase: IngredientAllergens.json not found in bundle")
            return
        }
        
        struct RawAllergen: Decodable {
            let id: String
            let allergens: [String]
            let dietaryFlags: [String]
        }
        
        guard let items = try? JSONDecoder().decode([RawAllergen].self, from: data) else {
            print("⚠️ IngredientDatabase: Failed to decode IngredientAllergens.json")
            return
        }
        
        for item in items {
            let allergens = item.allergens.compactMap { Ingredient.Allergen(rawValue: $0) }
            let flags = item.dietaryFlags.compactMap { Ingredient.DietaryFlag(rawValue: $0) }
            allergenMap[item.id] = AllergenEntry(allergens: allergens, dietaryFlags: flags)
        }
    }
    
    // MARK: - Text Normalization
    
    /// Normalize text for matching: lowercase, trim, strip common modifiers
    private func normalize(_ text: String) -> String {
        var s = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common preparation words that shouldn't affect matching
        let stripPrefixes = [
            "fresh ", "dried ", "frozen ", "canned ", "organic ",
            "large ", "small ", "medium ", "whole ",
            "finely ", "coarsely ", "roughly ",
            "thinly ", "thickly ",
        ]
        for prefix in stripPrefixes {
            if s.hasPrefix(prefix) {
                s = String(s.dropFirst(prefix.count))
            }
        }
        
        // Remove trailing preparation instructions (after comma)
        if let commaIndex = s.firstIndex(of: ",") {
            s = String(s[s.startIndex..<commaIndex]).trimmingCharacters(in: .whitespaces)
        }
        
        // Remove parenthetical content
        s = s.replacingOccurrences(of: "\\s*\\(.*?\\)", with: "", options: .regularExpression)
        
        // Remove common trailing modifiers
        let stripSuffixes = [
            ", chopped", ", diced", ", minced", ", sliced", ", grated",
            ", julienned", ", crushed", ", peeled", ", deveined",
            ", to taste", ", optional", ", divided",
        ]
        for suffix in stripSuffixes {
            if s.hasSuffix(suffix) {
                s = String(s.dropLast(suffix.count))
            }
        }
        
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Matching
    
    /// Match an ingredient name to a canonical ingredient.
    /// Returns the best match, or nil if no match is found.
    func match(_ name: String) -> MatchResult? {
        let normalized = normalize(name)
        guard !normalized.isEmpty else { return nil }
        
        // 1. Exact alias match (highest confidence)
        if let canonicalId = aliasMap[normalized],
           let entry = canonicalMap[canonicalId] {
            return MatchResult(
                canonicalId: entry.id,
                canonicalName: entry.name,
                foodCategory: entry.category,
                defaultUnitHint: entry.defaultUnitHint,
                confidence: 1.0
            )
        }
        
        // 2. Try stripping common adjectives one-by-one for partial match
        let modifiers = [
            "boneless ", "skinless ", "boneless skinless ",
            "extra-virgin ", "extra virgin ",
            "unsalted ", "salted ",
            "low-sodium ", "reduced-fat ",
            "smoked ", "roasted ", "toasted ", "grilled ",
            "ground ", "shredded ", "grated ", "chopped ", "diced ", "minced ", "sliced ",
        ]
        
        for modifier in modifiers {
            if normalized.hasPrefix(modifier) {
                let stripped = String(normalized.dropFirst(modifier.count))
                if let canonicalId = aliasMap[stripped],
                   let entry = canonicalMap[canonicalId] {
                    return MatchResult(
                        canonicalId: entry.id,
                        canonicalName: entry.name,
                        foodCategory: entry.category,
                        defaultUnitHint: entry.defaultUnitHint,
                        confidence: 0.9
                    )
                }
            }
        }
        
        // 3. Try plural/singular variations
        let variations = generateVariations(normalized)
        for variation in variations {
            if let canonicalId = aliasMap[variation],
               let entry = canonicalMap[canonicalId] {
                return MatchResult(
                    canonicalId: entry.id,
                    canonicalName: entry.name,
                    foodCategory: entry.category,
                    defaultUnitHint: entry.defaultUnitHint,
                    confidence: 0.85
                )
            }
        }
        
        // 4. Substring matching — check if normalized text contains a canonical name
        for (canonicalName, canonicalId) in allNames {
            if normalized.contains(canonicalName),
               let entry = canonicalMap[canonicalId] {
                // Score based on how much of the input the canonical name covers
                let coverage = Double(canonicalName.count) / Double(normalized.count)
                let confidence = min(0.8, 0.5 + coverage * 0.3)
                return MatchResult(
                    canonicalId: entry.id,
                    canonicalName: entry.name,
                    foodCategory: entry.category,
                    defaultUnitHint: entry.defaultUnitHint,
                    confidence: confidence
                )
            }
        }
        
        // 5. Token-based matching — split into words and try matching subsets
        let tokens = normalized.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if tokens.count >= 2 {
            // Try last N tokens (ingredient name is often at the end: "boneless chicken thigh" → "chicken thigh")
            for startIdx in 1..<min(tokens.count, 4) {
                let subset = tokens[startIdx...].joined(separator: " ")
                if let canonicalId = aliasMap[subset],
                   let entry = canonicalMap[canonicalId] {
                    return MatchResult(
                        canonicalId: entry.id,
                        canonicalName: entry.name,
                        foodCategory: entry.category,
                        defaultUnitHint: entry.defaultUnitHint,
                        confidence: 0.7
                    )
                }
            }
            
            // Try first N tokens (sometimes it's "chicken thigh boneless")
            for endIdx in stride(from: tokens.count - 1, through: 1, by: -1) {
                let subset = tokens[..<endIdx].joined(separator: " ")
                if let canonicalId = aliasMap[subset],
                   let entry = canonicalMap[canonicalId] {
                    return MatchResult(
                        canonicalId: entry.id,
                        canonicalName: entry.name,
                        foodCategory: entry.category,
                        defaultUnitHint: entry.defaultUnitHint,
                        confidence: 0.7
                    )
                }
            }
        }
        
        return nil
    }
    
    /// Generate singular/plural variations of a text
    private func generateVariations(_ text: String) -> [String] {
        var variations: [String] = []
        
        // Simple plural → singular
        if text.hasSuffix("ies") {
            variations.append(String(text.dropLast(3)) + "y")       // berries → berry
        } else if text.hasSuffix("ves") {
            variations.append(String(text.dropLast(3)) + "f")       // halves → half
        } else if text.hasSuffix("es") {
            variations.append(String(text.dropLast(2)))              // tomatoes → tomato
            variations.append(String(text.dropLast(1)))              // purses → purs (rarely correct but safe)
        } else if text.hasSuffix("s") && !text.hasSuffix("ss") {
            variations.append(String(text.dropLast(1)))              // carrots → carrot
        }
        
        // Simple singular → plural
        if text.hasSuffix("y") {
            variations.append(String(text.dropLast(1)) + "ies")     // berry → berries
        } else if text.hasSuffix("f") {
            variations.append(String(text.dropLast(1)) + "ves")     // half → halves
        } else if text.hasSuffix("o") || text.hasSuffix("sh") || text.hasSuffix("ch") || text.hasSuffix("x") || text.hasSuffix("s") {
            variations.append(text + "es")                           // tomato → tomatoes
        } else {
            variations.append(text + "s")                            // carrot → carrots
        }
        
        return variations
    }
    
    // MARK: - Enrichment (attach canonical data to an Ingredient)
    
    /// Enrich an Ingredient with canonical data (canonicalId + foodCategory).
    /// Returns a new Ingredient with the fields populated.
    func enrich(_ ingredient: Ingredient) -> Ingredient {
        // Skip if already enriched
        if ingredient.canonicalId != nil { return ingredient }
        
        guard let match = match(ingredient.name) else { return ingredient }
        
        var enriched = ingredient
        enriched.canonicalId = match.canonicalId
        enriched.foodCategory = match.foodCategory
        return enriched
    }
    
    /// Enrich an array of Ingredients with canonical data.
    func enrich(_ ingredients: [Ingredient]) -> [Ingredient] {
        return ingredients.map { enrich($0) }
    }
    
    // MARK: - Allergen & Dietary Lookups
    
    /// Get allergens for a canonical ingredient ID.
    func allergens(for canonicalId: String) -> [Ingredient.Allergen] {
        return allergenMap[canonicalId]?.allergens ?? []
    }
    
    /// Get dietary flags for a canonical ingredient ID.
    func dietaryFlags(for canonicalId: String) -> [Ingredient.DietaryFlag] {
        return allergenMap[canonicalId]?.dietaryFlags ?? []
    }
    
    /// Get all unique allergens present in a list of ingredients.
    func allAllergens(in ingredients: [Ingredient]) -> Set<Ingredient.Allergen> {
        var result = Set<Ingredient.Allergen>()
        for ingredient in ingredients {
            if let id = ingredient.canonicalId {
                result.formUnion(allergens(for: id))
            }
        }
        return result
    }
    
    /// Check if a recipe's ingredients are compatible with a dietary flag.
    /// Returns true only if ALL ingredients with canonical IDs have the flag.
    func isCompatible(ingredients: [Ingredient], with flag: Ingredient.DietaryFlag) -> Bool {
        let enrichedIngredients = ingredients.filter { $0.canonicalId != nil }
        guard !enrichedIngredients.isEmpty else { return false }
        
        return enrichedIngredients.allSatisfy { ingredient in
            guard let id = ingredient.canonicalId else { return true }
            return dietaryFlags(for: id).contains(flag)
        }
    }
    
    /// Get the food category for a canonical ID.
    func foodCategory(for canonicalId: String) -> Ingredient.FoodCategory? {
        return canonicalMap[canonicalId]?.category
    }
    
    /// Get the canonical name for a canonical ID.
    func canonicalName(for canonicalId: String) -> String? {
        return canonicalMap[canonicalId]?.name
    }
    
    // MARK: - Autocomplete Suggestions
    
    struct Suggestion: Identifiable {
        let id: String          // canonical ID
        let name: String        // display name (e.g. "Chicken Thigh")
        let category: Ingredient.FoodCategory
        let matchedAlias: String?  // the alias that matched, if different from name
        
        var displayName: String {
            if let alias = matchedAlias, alias.lowercased() != name.lowercased() {
                return name
            }
            return name
        }
    }
    
    /// Get autocomplete suggestions for a partial query string.
    /// Returns up to `limit` suggestions sorted by relevance.
    func suggestions(for query: String, limit: Int = 8) -> [Suggestion] {
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 2 else { return [] }  // Need at least 2 chars
        
        var seen = Set<String>()  // Deduplicate by canonical ID
        var results: [(suggestion: Suggestion, score: Int)] = []
        
        // 1. Search aliases for prefix matches (highest priority)
        for (alias, canonicalId) in aliasMap {
            guard !seen.contains(canonicalId) else { continue }
            
            if alias.hasPrefix(q) {
                guard let entry = canonicalMap[canonicalId] else { continue }
                seen.insert(canonicalId)
                // Score: exact match = 100, prefix match = 90 - length difference
                let score = alias == q ? 100 : max(80, 90 - (alias.count - q.count))
                results.append((
                    Suggestion(id: canonicalId, name: entry.name, category: entry.category, matchedAlias: alias),
                    score
                ))
            }
        }
        
        // 2. Search aliases for contains matches (lower priority)
        if results.count < limit {
            for (alias, canonicalId) in aliasMap {
                guard !seen.contains(canonicalId) else { continue }
                
                if alias.contains(q) {
                    guard let entry = canonicalMap[canonicalId] else { continue }
                    seen.insert(canonicalId)
                    let score = 60
                    results.append((
                        Suggestion(id: canonicalId, name: entry.name, category: entry.category, matchedAlias: alias),
                        score
                    ))
                }
                
                if results.count >= limit * 2 { break }  // Cap for performance
            }
        }
        
        // 3. Also search canonical names directly
        for entry in canonicalMap.values {
            guard !seen.contains(entry.id) else { continue }
            let lowName = entry.name.lowercased()
            
            if lowName.hasPrefix(q) {
                seen.insert(entry.id)
                let score = lowName == q ? 100 : max(80, 90 - (lowName.count - q.count))
                results.append((
                    Suggestion(id: entry.id, name: entry.name, category: entry.category, matchedAlias: nil),
                    score
                ))
            } else if lowName.contains(q) {
                seen.insert(entry.id)
                results.append((
                    Suggestion(id: entry.id, name: entry.name, category: entry.category, matchedAlias: nil),
                    60
                ))
            }
        }
        
        // Sort by score descending, then alphabetically
        results.sort { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            return lhs.suggestion.name < rhs.suggestion.name
        }
        
        return Array(results.prefix(limit).map(\.suggestion))
    }
    
    // MARK: - Browse All Ingredients
    
    /// Get all canonical ingredients, optionally filtered by search query,
    /// grouped by food category and sorted alphabetically.
    func allIngredients(matching query: String? = nil) -> [(category: Ingredient.FoodCategory, ingredients: [Suggestion])] {
        let q = query?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Group by category
        var grouped: [Ingredient.FoodCategory: [Suggestion]] = [:]
        
        for entry in canonicalMap.values {
            // If there's a query, filter by name or alias match
            if let q = q, !q.isEmpty {
                let nameMatch = entry.name.lowercased().contains(q)
                let aliasMatch = aliasMap.contains { alias, id in
                    id == entry.id && alias.contains(q)
                }
                guard nameMatch || aliasMatch else { continue }
            }
            
            let suggestion = Suggestion(
                id: entry.id,
                name: entry.name,
                category: entry.category,
                matchedAlias: nil
            )
            grouped[entry.category, default: []].append(suggestion)
        }
        
        // Sort ingredients within each category alphabetically
        for key in grouped.keys {
            grouped[key]?.sort { $0.name < $1.name }
        }
        
        // Sort categories in a logical order
        let categoryOrder: [Ingredient.FoodCategory] = [
            .produce, .meat, .poultry, .seafood, .dairy, .grain,
            .legume, .spice, .herb, .oil, .vinegar, .sauce,
            .condiment, .baking, .nut, .beverage, .misc
        ]
        
        return categoryOrder.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category: category, ingredients: items)
        }
    }
    
    // MARK: - Statistics
    
    var canonicalCount: Int { canonicalMap.count }
    var aliasCount: Int { aliasMap.count }
    var allergenEntryCount: Int { allergenMap.count }
}

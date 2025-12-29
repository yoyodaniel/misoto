//
//  RecipeTextParser.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation

struct RecipeTextParser {
    
    struct IngredientItem: Equatable {
        var amount: String
        var unit: String
        var name: String
        
        enum IngredientCategory: String, Codable {
            case marinade = "marinade"
            case dish = "dish"
        }
    }
    
    struct ParsedRecipe {
        var title: String
        var description: String
        var ingredients: [String]  // Keep for backward compatibility (combined)
        var marinadeIngredients: [IngredientItem]  // Marinade ingredients
        var seasoningIngredients: [IngredientItem]  // Seasoning ingredients
        var dishIngredients: [IngredientItem]  // Dish ingredients (main recipe)
        var ingredientItems: [IngredientItem] {  // Combined for backward compatibility
            return marinadeIngredients + seasoningIngredients + dishIngredients
        }
        var instructions: [String]
    }
    
    static func parse(_ text: String) -> ParsedRecipe {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .filter { isValidRecipeLine($0) }
        
        var title = ""
        var description = ""
        var ingredients: [(String, IngredientCategory)] = []  // Store ingredient with category
        var instructions: [String] = []
        
        var currentSection: Section = .unknown
        var descriptionLines: [String] = []
        var currentIngredientCategory: IngredientCategory = .dish
        
        enum IngredientCategory {
            case marinade
            case seasoning
            case dish
        }
        
        enum Section {
            case unknown
            case title
            case description
            case ingredients
            case instructions
        }
        
        for (index, line) in lines.enumerated() {
            let lowercased = line.lowercased()
            
            // Filter out category/section headers and unwanted words
            if lowercased == "procedures" || lowercased == "procedure" {
                currentSection = .instructions
                continue
            }
            
            if lowercased == "marinades" || lowercased == "marinade" {
                // This is a category header, switch to marinade category
                if currentSection == .ingredients {
                    currentIngredientCategory = .marinade
                }
                continue
            }
            
            if lowercased == "seasonings" || lowercased == "seasoning" || lowercased.contains("調味料") {
                // This is a category header, switch to seasoning category
                if currentSection == .ingredients {
                    currentIngredientCategory = .seasoning
                }
                continue
            }
            
            // Filter out "Done" from instructions
            if lowercased.trimmingCharacters(in: .whitespaces) == "done" {
                continue
            }
            
            // Detect section headers
            if lowercased.contains("ingredient") || lowercased.contains("ingredients") || lowercased.contains("材料") {
                currentSection = .ingredients
                currentIngredientCategory = .dish  // Reset to dish when starting ingredients section
                continue
            } else if lowercased.contains("instruction") || lowercased.contains("step") || lowercased.contains("method") || lowercased.contains("directions") {
                currentSection = .instructions
                continue
            } else if lowercased.contains("recipe") || lowercased.contains("dish") || lowercased.contains("menu") {
                if title.isEmpty {
                    currentSection = .title
                }
            }
            
            // Parse based on current section
            switch currentSection {
            case .title:
                if title.isEmpty {
                    title = line
                } else {
                    descriptionLines.append(line)
                    currentSection = .description
                }
                
            case .description:
                if isIngredientLine(line) {
                    currentSection = .ingredients
                    ingredients.append((parseIngredientLine(line), currentIngredientCategory))
                } else if isInstructionLine(line) {
                    currentSection = .instructions
                    instructions.append(parseInstructionLine(line))
                } else {
                    // Only add meaningful description text
                    if line.count > 5 && line.contains(where: { $0.isLetter }) {
                        descriptionLines.append(line)
                    }
                }
                
            case .ingredients:
                // Skip category headers like "MARINADES" or "SEASONINGS" (already handled above)
                let lowercased = line.lowercased().trimmingCharacters(in: .whitespaces)
                if lowercased == "marinades" || lowercased == "marinade" {
                    currentIngredientCategory = .marinade
                    continue
                }
                if lowercased == "seasonings" || lowercased == "seasoning" || lowercased.contains("調味料") {
                    currentIngredientCategory = .seasoning
                    continue
                }
                
                if isInstructionLine(line) {
                    currentSection = .instructions
                    instructions.append(parseInstructionLine(line))
                } else if !isIngredientLine(line) && !line.isEmpty {
                    // Might be a description line that got mixed in
                    if descriptionLines.isEmpty && description.isEmpty {
                        descriptionLines.append(line)
                    } else {
                        ingredients.append((parseIngredientLine(line), currentIngredientCategory))
                    }
                } else {
                    ingredients.append((parseIngredientLine(line), currentIngredientCategory))
                }
                
            case .instructions:
                // Skip "Done" and "PROCEDURES"
                let lowercased = line.lowercased().trimmingCharacters(in: .whitespaces)
                if lowercased == "done" || lowercased == "procedures" || lowercased == "procedure" {
                    continue
                }
                
                let cleanedLine = parseInstructionLine(line)
                if cleanedLine.isEmpty {
                    continue
                }
                
                // Merge consecutive instruction lines (handle line breaks in OCR)
                if !instructions.isEmpty {
                    let lastInstruction = instructions.last!
                    let cleanedLower = cleanedLine.lowercased().trimmingCharacters(in: .whitespaces)
                    
                    // Check if this is a continuation or a new instruction
                    // If previous instruction ends with punctuation, likely new instruction
                    // If current line starts with action verb (capitalized), likely new instruction
                    // If current line is short and lowercase, likely continuation
                    let endsWithPunctuation = lastInstruction.hasSuffix(".") || 
                                            lastInstruction.hasSuffix("!") || 
                                            lastInstruction.hasSuffix("?")
                    
                    // Check if current line starts with an action verb (likely new instruction)
                    let actionVerbs = ["heat", "add", "mix", "stir", "cook", "bake", "roast", "grill", "fry",
                                      "saute", "steam", "boil", "simmer", "braise", "combine", "whisk", "beat",
                                      "fold", "knead", "roll", "cut", "slice", "dice", "chop", "mince", "grate",
                                      "peel", "core", "seed", "trim", "marinate", "season", "taste", "preheat",
                                      "warm", "cool", "chill", "freeze", "thaw", "defrost", "rest", "serve",
                                      "garnish", "decorate", "plate", "present", "drizzle", "pour", "sprinkle",
                                      "dust", "coat", "place", "put", "set", "bring", "remove", "take", "get",
                                      "use", "prepare", "make", "create", "arrange", "layer", "spread"]
                    
                    let startsWithActionVerb = actionVerbs.contains { cleanedLower.hasPrefix($0) || cleanedLower.hasPrefix("\($0) ") }
                    
                    let isLikelyNew = endsWithPunctuation || 
                                     isNewInstructionStart(cleanedLine) ||
                                     (startsWithActionVerb && cleanedLine.count > 5) ||
                                     (cleanedLine.first?.isUppercase == true && cleanedLine.count > 10)
                    
                    if isLikelyNew {
                        // New instruction
                        instructions.append(cleanedLine)
                    } else {
                        // Continuation of previous instruction - merge them
                        let merged = lastInstruction + " " + cleanedLine
                        instructions[instructions.count - 1] = merged
                    }
                } else {
                    instructions.append(cleanedLine)
                }
                
            case .unknown:
                if index == 0 {
                    // First line is likely the title, especially if it's all caps or short
                    if line.count < 100 && (line == line.uppercased() || line.count > 3) {
                        title = line
                        currentSection = .title
                    } else {
                        // If first line looks like description, treat as title anyway
                        title = line
                        currentSection = .description
                    }
                } else if isIngredientLine(line) {
                    currentSection = .ingredients
                    ingredients.append((parseIngredientLine(line), currentIngredientCategory))
                } else if isInstructionLine(line) {
                    currentSection = .instructions
                    instructions.append(parseInstructionLine(line))
                } else {
                    // Only add to description if it's meaningful text
                    if line.count > 5 && line.contains(where: { $0.isLetter }) {
                        descriptionLines.append(line)
                    }
                }
            }
        }
        
        description = descriptionLines.joined(separator: " ")
        
        // Clean up and validate
        if title.isEmpty && !lines.isEmpty {
            // Find first valid line as title
            if let firstValidLine = lines.first(where: { isValidRecipeLine($0) && $0.count > 3 }) {
                title = firstValidLine
            }
        }
        
        // Clean title
        title = title
            .replacingOccurrences(of: "^[#*]+\\s*", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s*[#*]+$", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        
        // Remove empty items and filter out garbage, then separate by category
        let filteredIngredients = ingredients
            .filter { !$0.0.trimmingCharacters(in: .whitespaces).isEmpty }
            .filter { isValidRecipeLine($0.0) }
            .filter { line, _ in
                let lowercased = line.lowercased().trimmingCharacters(in: .whitespaces)
                // Filter out category headers
                return lowercased != "marinades" && lowercased != "marinade" && 
                       lowercased != "seasonings" && lowercased != "seasoning" &&
                       !lowercased.contains("調味料")
            }
        
        // Separate and parse ingredients into marinade, seasoning, and dish lists
        // Also merge parenthetical notes with previous ingredients
        var marinadeItems: [IngredientItem] = []
        var seasoningItems: [IngredientItem] = []
        var dishItems: [IngredientItem] = []
        
        var previousItem: (item: IngredientItem, category: IngredientCategory)?
        
        for (line, category) in filteredIngredients {
            // Check if this line is a parenthetical note that should be merged with previous ingredient
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Check for parenthetical note with parentheses
            let isParentheticalNote = trimmedLine.hasPrefix("(") && trimmedLine.hasSuffix(")") && 
                                     !trimmedLine.lowercased().contains("tsp") && 
                                     !trimmedLine.lowercased().contains("tbsp") &&
                                     !trimmedLine.lowercased().contains("cup") &&
                                     trimmedLine.range(of: "^\\d+", options: .regularExpression) == nil
            
            // Check if this is a description line that should be merged (e.g., "Grind Lemon Rind" after "1 Lemon")
            // It should:
            // 1. Not have an amount/unit at the start
            // 2. Not be a valid standalone ingredient (no measurements)
            // 3. Contain action words that suggest it's a description (slice, juice, grind, cut, etc.)
            // 4. Be related to the previous ingredient
            let lowercased = trimmedLine.lowercased()
            let hasNoAmount = trimmedLine.range(of: "^\\d+", options: .regularExpression) == nil
            let hasNoUnit = !lowercased.contains("tsp") && !lowercased.contains("tbsp") && 
                           !lowercased.contains("cup") && !lowercased.contains("oz") &&
                           !lowercased.contains("lb") && !lowercased.contains("g") &&
                           !lowercased.contains("kg") && !lowercased.contains("ml") &&
                           !lowercased.contains("l") && !lowercased.contains("piece") &&
                           !lowercased.contains("slice") && !lowercased.contains("clove")
            let hasActionWords = lowercased.contains("slice") || lowercased.contains("juice") ||
                                lowercased.contains("grind") || lowercased.contains("cut") ||
                                lowercased.contains("dice") || lowercased.contains("chop") ||
                                lowercased.contains("mince") || lowercased.contains("grate") ||
                                lowercased.contains("peel") || lowercased.contains("trim")
            let isDescriptionLine = hasNoAmount && hasNoUnit && hasActionWords
            
            if (isParentheticalNote || isDescriptionLine), let prev = previousItem {
                // Merge with previous ingredient
                let note: String
                if isParentheticalNote {
                    note = String(trimmedLine.dropFirst().dropLast()) // Remove parentheses
                } else {
                    note = trimmedLine // Use the line as-is for description lines
                }
                
                var mergedItem = prev.item
                mergedItem.name = "\(mergedItem.name) (\(note))"
                
                // Update the previous item in the appropriate list
                switch prev.category {
                case .marinade:
                    if !marinadeItems.isEmpty {
                        marinadeItems[marinadeItems.count - 1] = mergedItem
                    }
                case .seasoning:
                    if !seasoningItems.isEmpty {
                        seasoningItems[seasoningItems.count - 1] = mergedItem
                    }
                case .dish:
                    if !dishItems.isEmpty {
                        dishItems[dishItems.count - 1] = mergedItem
                    }
                }
                // Update previousItem to reflect the merged name
                previousItem = (mergedItem, prev.category)
                continue
            }
            
            var item = parseIngredientItem(line)
            // Additional validation: ensure ingredient name makes sense for food
            if !item.name.trimmingCharacters(in: .whitespaces).isEmpty {
                // Validate that the ingredient name is food-related
                // Check both the parsed ingredient name and the original line
                let ingredientName = item.name.lowercased()
                let originalLine = line.lowercased()
                
                // More lenient validation: if it has measurements or looks like an ingredient, allow it
                let hasMeasurement = originalLine.range(of: "\\d+\\s*(tbsp|tsp|cup|cups|oz|lb|g|kg|ml|l|tablespoon|teaspoon|piece|pieces|slice|slices|clove|cloves|bunch|bunches|head|heads|strand|strands|pinch|pinches|dash|dashes)", options: .regularExpression) != nil
                
                // Check if it's food-related OR has measurements (likely an ingredient)
                if hasMeasurement || isValidFoodRelatedText(ingredientName) || isValidFoodRelatedText(originalLine) {
                    previousItem = (item, category)
                    switch category {
                    case .marinade:
                        marinadeItems.append(item)
                    case .seasoning:
                        seasoningItems.append(item)
                    case .dish:
                        dishItems.append(item)
                    }
                } else {
                    // If ingredient doesn't make sense, skip it
                    previousItem = nil
                }
            } else {
                // If parsing failed, clear previousItem so we don't merge with invalid data
                previousItem = nil
            }
        }
        
        // Create combined formatted string version for backward compatibility (for Recipe model)
        let allItems = marinadeItems + seasoningItems + dishItems
        let formattedIngredients = allItems.map { item in
            if item.unit.isEmpty {
                return item.amount.isEmpty ? item.name : "\(item.amount) \(item.name)"
            } else {
                return "\(item.amount) \(item.unit) \(item.name)"
            }
        }
        
        // Number instructions and filter out "Done"
        instructions = instructions
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .filter { isValidRecipeLine($0) }
            .map { cleanInstruction($0) }
            .filter { line in
                let lowercased = line.lowercased().trimmingCharacters(in: .whitespaces)
                return lowercased != "done"
            }
            .enumerated()
            .map { index, instruction in
                // Number instructions starting from 1
                return "\(index + 1). \(instruction)"
            }
        
        // Clean description
        description = descriptionLines
            .filter { isValidRecipeLine($0) }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
        
        return ParsedRecipe(
            title: title,
            description: description,
            ingredients: formattedIngredients,
            marinadeIngredients: marinadeItems,
            seasoningIngredients: seasoningItems,
            dishIngredients: dishItems,
            instructions: instructions
        )
    }
    
    private static func isIngredientLine(_ line: String) -> Bool {
        let lowercased = line.lowercased()
        
        // Common patterns for ingredients
        let patterns = [
            "\\d+\\s*(tbsp|tsp|cup|cups|oz|lb|g|kg|ml|l)",
            "\\d+\\s*(tablespoon|teaspoon)",
            "^\\d+",
            "^[•\\-\\*]",
            "\\d+\\s*x\\s*",
        ]
        
        for pattern in patterns {
            if line.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        
        // Check for common ingredient keywords
        let ingredientKeywords = ["cup", "tbsp", "tsp", "oz", "lb", "gram", "kg", "ml", "liter"]
        return ingredientKeywords.contains { lowercased.contains($0) }
    }
    
    private static func isInstructionLine(_ line: String) -> Bool {
        let lowercased = line.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Common patterns for instructions
        let patterns = [
            "^\\d+[.)]",
            "^step\\s+\\d+",
            "^\\d+\\.",
            "^[•\\-\\*]",
        ]
        
        for pattern in patterns {
            if line.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        
        // Check for common instruction keywords
        let instructionKeywords = ["step", "method", "direction", "first", "next", "then", "finally"]
        if instructionKeywords.contains(where: { lowercased.hasPrefix($0) }) {
            return true
        }
        
        // Check for action verbs that typically start instructions
        // These are cooking/preparation actions that indicate an instruction
        let actionVerbs = ["heat", "add", "mix", "stir", "cook", "bake", "roast", "grill", "fry",
                          "saute", "steam", "boil", "simmer", "braise", "combine", "whisk", "beat",
                          "fold", "knead", "roll", "cut", "slice", "dice", "chop", "mince", "grate",
                          "peel", "core", "seed", "trim", "marinate", "season", "taste", "preheat",
                          "warm", "cool", "chill", "freeze", "thaw", "defrost", "rest", "serve",
                          "garnish", "decorate", "plate", "present", "drizzle", "pour", "sprinkle",
                          "dust", "coat", "place", "put", "set", "bring", "remove", "take", "get",
                          "use", "prepare", "make", "create", "arrange", "layer", "spread"]
        
        // Check if line starts with an action verb (case-insensitive)
        for verb in actionVerbs {
            if lowercased.hasPrefix(verb) || lowercased.hasPrefix("\(verb) ") {
                // Make sure it's not an ingredient line (ingredients usually have amounts/units)
                let hasAmount = line.range(of: "^\\d+", options: .regularExpression) != nil
                let hasUnit = lowercased.contains("tsp") || lowercased.contains("tbsp") ||
                             lowercased.contains("cup") || lowercased.contains("oz") ||
                             lowercased.contains("lb") || lowercased.contains("g") ||
                             lowercased.contains("kg") || lowercased.contains("ml") ||
                             lowercased.contains("l") || lowercased.contains("piece") ||
                             lowercased.contains("slice") || lowercased.contains("clove")
                
                // If it starts with an action verb and doesn't have amount/unit, it's likely an instruction
                if !hasAmount || !hasUnit {
                    return true
                }
            }
        }
        
        return false
    }
    
    private static func parseIngredientLine(_ line: String) -> String {
        // Remove bullet points and numbering
        var cleaned = line
            .replacingOccurrences(of: "^[•\\-\\*]\\s*", with: "", options: .regularExpression)
            .replacingOccurrences(of: "^\\d+[.)]\\s*", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        
        return cleaned
    }
    
    private static func cleanIngredient(_ ingredient: String) -> String {
        var cleaned = ingredient
            // Remove leading/trailing symbols (including degree symbol)
            .replacingOccurrences(of: "^[#*°]+\\s*", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s*[#*°]+$", with: "", options: .regularExpression)
            // Remove standalone codes at the start
            .replacingOccurrences(of: "^[A-Z]{1,3}\\d+[/]?\\d*[#*°]*\\s+", with: "", options: .regularExpression)
            // Remove single letter + symbols patterns (e.g., "T#", "T°")
            .replacingOccurrences(of: "^[A-Z][#*°]+\\s+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+[A-Z][#*°]+$", with: "", options: .regularExpression)
            // Remove embedded artifacts (space + letter + symbol)
            .replacingOccurrences(of: "\\s+[A-Za-z][#*°]+\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        
        return cleaned
    }
    
    private static func parseIngredientWithAmount(_ ingredient: String) -> String {
        let item = parseIngredientItem(ingredient)
        if item.unit.isEmpty {
            return item.amount.isEmpty ? item.name : "\(item.amount) \(item.name)"
        } else {
            return "\(item.amount) \(item.unit) \(item.name)"
        }
    }
    
    private static func parseIngredientItem(_ ingredient: String) -> IngredientItem {
        var cleaned = cleanIngredient(ingredient)
        
        // Common units (needed for concatenation detection)
        let units = ["tsp", "tbsp", "tablespoon", "teaspoon", "cup", "cups", "oz", "ounce", "ounces", "lb", "pound", "pounds", "g", "gram", "grams", "kg", "kilogram", "kilograms", "ml", "milliliter", "milliliters", "l", "liter", "liters", "pinch", "pinches", "dash", "dashes", "piece", "pieces", "pcs", "pc", "slice", "slices", "clove", "cloves", "bunch", "bunches", "head", "heads", "strand", "strands"]
        
        // First, handle cases where amount and unit are concatenated (e.g., "30ml" -> "30 ml")
        // Pattern: number (with optional decimal) followed directly by unit abbreviation (no space)
        let unitAbbreviations = ["ml", "kg", "g", "l", "tsp", "tbsp", "oz", "lb"]
        for unitAbbr in unitAbbreviations {
            // Pattern: digit(s) followed directly by unit abbreviation (case insensitive)
            // Use a regex to find and replace: "30ml" -> "30 ml"
            let pattern = "(\\d+(?:\\.\\d+)?)(\(NSRegularExpression.escapedPattern(for: unitAbbr)))"
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let mutableString = NSMutableString(string: cleaned)
                regex.replaceMatches(in: mutableString, options: [], range: NSRange(location: 0, length: mutableString.length), withTemplate: "$1 $2")
                cleaned = String(mutableString)
            }
        }
        
        // Pattern: amount (with optional fraction, including simple fractions like "1/3") + optional unit + ingredient name
        // Try pattern: "1 1/2 tsp ingredient" or "1/3 tsp ingredient" or "12 pieces ingredient" or "12 ingredient"
        let fullPattern = "^(\\d+/\\d+|\\d+(?:\\s+\\d+/\\d+)?)\\s+(\(units.joined(separator: "|")))\\s+(.+)$"
        if let regex = try? NSRegularExpression(pattern: fullPattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count)),
           match.numberOfRanges >= 4 {
            
            let amountRange = Range(match.range(at: 1), in: cleaned)!
            let unitRange = Range(match.range(at: 2), in: cleaned)!
            let nameRange = Range(match.range(at: 3), in: cleaned)!
            
            let amountString = String(cleaned[amountRange]).trimmingCharacters(in: .whitespaces)
            let amount = convertFractionToDecimal(amountString)
            let unit = String(cleaned[unitRange]).trimmingCharacters(in: .whitespaces).lowercased()
            var name = String(cleaned[nameRange]).trimmingCharacters(in: .whitespaces)
            
            name = capitalizeEachWord(name)
            
            return IngredientItem(amount: amount, unit: unit, name: name)
        }
        
        // Try pattern: just amount (including simple fractions like "1/3") + ingredient name (no unit)
        let amountPattern = "^(\\d+/\\d+|\\d+(?:\\s+\\d+/\\d+)?)\\s+(.+)$"
        if let regex = try? NSRegularExpression(pattern: amountPattern, options: []),
           let match = regex.firstMatch(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count)),
           match.numberOfRanges >= 3 {
            
            let amountRange = Range(match.range(at: 1), in: cleaned)!
            let nameRange = Range(match.range(at: 2), in: cleaned)!
            
            let amountString = String(cleaned[amountRange]).trimmingCharacters(in: .whitespaces)
            let amount = convertFractionToDecimal(amountString)
            var name = String(cleaned[nameRange]).trimmingCharacters(in: .whitespaces)
            
            // Check if the name starts with a unit
            let words = name.components(separatedBy: .whitespaces)
            if let firstWord = words.first?.lowercased(), units.contains(firstWord) {
                let unit = firstWord
                name = words.dropFirst().joined(separator: " ")
                name = capitalizeEachWord(name)
                return IngredientItem(amount: amount, unit: unit, name: name)
            }
            
            name = capitalizeEachWord(name)
            return IngredientItem(amount: amount, unit: "", name: name)
        }
        
        // Check for unit-only patterns like "pinch of salt" or "some honey"
        // These should be treated as amount "1" + unit
        let unitOnlyPattern = "^((\(units.joined(separator: "|")))(?:\\s+of)?)\\s+(.+)$"
        if let regex = try? NSRegularExpression(pattern: unitOnlyPattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: cleaned, options: [], range: NSRange(location: 0, length: cleaned.utf16.count)),
           match.numberOfRanges >= 3 {
            
            let unitRange = Range(match.range(at: 2), in: cleaned)!
            let nameRange = Range(match.range(at: 3), in: cleaned)!
            
            let unit = String(cleaned[unitRange]).trimmingCharacters(in: .whitespaces).lowercased()
            var name = String(cleaned[nameRange]).trimmingCharacters(in: .whitespaces)
            
            name = capitalizeEachWord(name)
            // Treat unit-only patterns as amount "1" + unit
            return IngredientItem(amount: "1", unit: unit, name: name)
        }
        
        // No amount or unit, just the ingredient name
        let capitalizedName = capitalizeEachWord(cleaned)
        return IngredientItem(amount: "", unit: "", name: capitalizedName)
    }
    
    private static func capitalizeEachWord(_ text: String) -> String {
        return text.components(separatedBy: .whitespaces)
            .map { word in
                // Don't capitalize common measurement words
                let lowercased = word.lowercased()
                if ["tsp", "tbsp", "cup", "cups", "oz", "lb", "g", "kg", "ml", "l", "of", "a", "an", "the", "with", "and", "or"].contains(lowercased) {
                    return lowercased
                }
                // Capitalize first letter, keep rest as is
                return word.prefix(1).uppercased() + word.dropFirst().lowercased()
            }
            .joined(separator: " ")
    }
    
    // Convert fractions to decimal strings (e.g., "1/2" -> "0.5", "1 1/2" -> "1.5")
    private static func convertFractionToDecimal(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        
        // Pattern: mixed number "1 1/2"
        let mixedPattern = "^\\s*(\\d+)\\s+(\\d+)/(\\d+)\\s*$"
        if let regex = try? NSRegularExpression(pattern: mixedPattern, options: []),
           let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count)),
           match.numberOfRanges >= 4,
           let wholeRange = Range(match.range(at: 1), in: trimmed),
           let numeratorRange = Range(match.range(at: 2), in: trimmed),
           let denominatorRange = Range(match.range(at: 3), in: trimmed),
           let whole = Double(String(trimmed[wholeRange])),
           let numerator = Double(String(trimmed[numeratorRange])),
           let denominator = Double(String(trimmed[denominatorRange])),
           denominator != 0 {
            let decimal = whole + (numerator / denominator)
            return formatDecimal(decimal)
        }
        
        // Pattern: simple fraction "1/2"
        let fractionPattern = "^\\s*(\\d+)/(\\d+)\\s*$"
        if let regex = try? NSRegularExpression(pattern: fractionPattern, options: []),
           let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(location: 0, length: trimmed.utf16.count)),
           match.numberOfRanges >= 3,
           let numeratorRange = Range(match.range(at: 1), in: trimmed),
           let denominatorRange = Range(match.range(at: 2), in: trimmed),
           let numerator = Double(String(trimmed[numeratorRange])),
           let denominator = Double(String(trimmed[denominatorRange])),
           denominator != 0 {
            let decimal = numerator / denominator
            return formatDecimal(decimal)
        }
        
        // No fraction found, return original
        return trimmed
    }
    
    // Format decimal to remove unnecessary trailing zeros
    private static func formatDecimal(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        }
        
        // Format with up to 2 decimal places, then remove trailing zeros
        var formatted = String(format: "%.2f", value)
        while formatted.hasSuffix("0") && formatted.contains(".") {
            formatted = String(formatted.dropLast())
        }
        if formatted.hasSuffix(".") {
            formatted = String(formatted.dropLast())
        }
        return formatted
    }
    
    private static func isNewInstructionStart(_ line: String) -> Bool {
        let lowercased = line.lowercased()
        
        // Check if line starts with instruction keywords (likely new instruction)
        let instructionStarters = ["preheat", "mix", "add", "remove", "bake", "cook", "fry", "stir", "combine", "season", "heat", "place", "put", "set", "bring", "boil", "simmer", "grill", "roast"]
        
        for starter in instructionStarters {
            if lowercased.hasPrefix(starter) {
                return true
            }
        }
        
        // Check if previous instruction ends with punctuation (likely complete)
        // This is handled by checking if the line looks like a continuation
        return false
    }
    
    private static func cleanInstruction(_ instruction: String) -> String {
        var cleaned = instruction
            // Remove leading/trailing symbols (including degree symbol)
            .replacingOccurrences(of: "^[#*°]+\\s*", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s*[#*°]+$", with: "", options: .regularExpression)
            // Remove standalone codes
            .replacingOccurrences(of: "^[A-Z]{1,3}\\d+[/]?\\d*[#*°]*\\s+", with: "", options: .regularExpression)
            // Remove single letter + symbols patterns (e.g., "T#", "T°")
            .replacingOccurrences(of: "^[A-Z][#*°]+\\s+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+[A-Z][#*°]+$", with: "", options: .regularExpression)
            // Remove embedded artifacts (space + letter + symbol)
            .replacingOccurrences(of: "\\s+[A-Za-z][#*°]+\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        
        // Filter out "Done"
        let lowercased = cleaned.lowercased().trimmingCharacters(in: .whitespaces)
        if lowercased == "done" {
            return ""
        }
        
        return cleaned
    }
    
    private static func parseInstructionLine(_ line: String) -> String {
        // Remove step numbering
        var cleaned = line
            .replacingOccurrences(of: "^\\d+[.)]\\s*", with: "", options: .regularExpression)
            .replacingOccurrences(of: "^step\\s+\\d+[.:]?\\s*", with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "^[•\\-\\*]\\s*", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        
        return cleaned
    }
    
    private static func isValidRecipeLine(_ line: String) -> Bool {
        // Filter out garbage text patterns
        let garbagePatterns = [
            "^[#*°]{2,}",  // Multiple symbols only (including degree symbol)
            "^\\d+[#*°]+$",  // Numbers with symbols
            "^[A-Z]{1,3}\\d+[/]?\\d*[#*°]*$",  // Codes like "XE1311/24" or "H1/242"
            "^[#*°]+\\d+",  // Symbols with numbers
            "^\\d+[/]\\d+[#*°]+",  // Fractions with symbols
            "^[#*°]{1,2}$",  // Just one or two symbols
            "^[A-Z][#*°]+$",  // Single uppercase letter followed by symbols (e.g., "T#", "T°")
            "^[A-Z][#*°]+\\s*$",  // Single uppercase letter + symbols with trailing spaces
            "^[a-z][#*°]+$",  // Single lowercase letter + symbols
            "^[A-Z][#*°]+\\s",  // Single letter + symbols followed by space (likely OCR artifact)
            "\\b\\d+ban\\b",  // Patterns like "2ban" (OCR garbage)
            "^[A-Z][a-z]+,\\s*[A-Z][a-z]+\\s+[A-Z][a-z]+",  // Nonsensical patterns like "Ban There, Threra"
        ]
        
        for pattern in garbagePatterns {
            if line.range(of: pattern, options: .regularExpression) != nil {
                return false
            }
        }
        
        // Check for nonsensical text patterns (repeated words, gibberish)
        let words = line.components(separatedBy: CharacterSet(charactersIn: " ,")).filter { !$0.isEmpty && !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        if words.count >= 2 {
            // Check for patterns like "2ban, Ban There, Threra" - repeated similar words or gibberish
            let uniqueWords = Set(words.map { $0.lowercased().trimmingCharacters(in: .punctuationCharacters) })
            if words.count >= 3 && Double(uniqueWords.count) / Double(words.count) < 0.5 {
                // Too many repeated words, likely garbage
                return false
            }
            
            // Check for patterns like "2ban" or "ban there" - nonsensical word combinations
            let hasNonsensicalPattern = words.contains { word in
                let lowercased = word.lowercased()
                // Check for patterns like "2ban", "ban there", etc.
                return lowercased.range(of: "\\d+[a-z]{2,}", options: .regularExpression) != nil ||
                       (lowercased.count <= 3 && lowercased.range(of: "^[a-z]+$", options: .regularExpression) != nil && words.count > 1)
            }
            
            // If we have multiple short words that don't form a meaningful phrase, likely garbage
            if words.count >= 3 && hasNonsensicalPattern {
                let meaningfulWords = words.filter { word in
                    let w = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
                    return w.count > 3 && w.range(of: "^[a-z]+$", options: .regularExpression) != nil
                }
                if meaningfulWords.count < words.count / 2 {
                    return false
                }
            }
        }
        
        // Must have at least one letter (for meaningful text)
        guard line.contains(where: { $0.isLetter }) else {
            // Exception: allow lines that are clearly measurements (e.g., "1 1/2 tsp")
            let measurementPattern = "\\d+\\s*(tbsp|tsp|cup|cups|oz|lb|g|kg|ml|l|tablespoon|teaspoon)"
            return line.range(of: measurementPattern, options: [.regularExpression, .caseInsensitive]) != nil
        }
        
        // Filter out lines that are mostly symbols
        let letterCount = line.filter { $0.isLetter }.count
        let nonWhitespaceCount = line.filter { !$0.isWhitespace }.count
        
        if nonWhitespaceCount > 0 {
            let letterRatio = Double(letterCount) / Double(nonWhitespaceCount)
            // Must have at least 20% letters
            if letterRatio < 0.2 {
                return false
            }
        }
        
        // Validate that the text makes sense for food/recipes
        return isValidFoodRelatedText(line)
    }
    
    // Validate that text is food/recipe related
    private static func isValidFoodRelatedText(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        
        // Common food-related keywords (ingredients, cooking terms, etc.)
        let foodKeywords = [
            // Common ingredients
            "chicken", "beef", "pork", "fish", "seafood", "shrimp", "salmon", "tuna", "lamb", "turkey",
            "rice", "noodle", "pasta", "bread", "flour", "sugar", "salt", "pepper", "garlic", "onion",
            "tomato", "potato", "carrot", "celery", "pepper", "chili", "ginger", "herb", "spice",
            "oil", "butter", "milk", "cream", "cheese", "egg", "yogurt", "sauce", "soy", "vinegar",
            "lemon", "lime", "orange", "apple", "banana", "berry", "fruit", "vegetable", "lettuce",
            "cucumber", "zucchini", "eggplant", "mushroom", "spinach", "broccoli", "cauliflower",
            "bean", "lentil", "chickpea", "tofu", "tempeh", "nut", "almond", "walnut", "peanut",
            "sesame", "sesame oil", "coconut", "coconut oil", "avocado", "olive", "olive oil", "basil", "oregano", "thyme", "rosemary", "parsley",
            "cilantro", "mint", "dill", "sage", "bay", "cumin", "coriander", "turmeric", "paprika",
            "cinnamon", "nutmeg", "clove", "cardamom", "star anise", "fennel", "mustard", "honey",
            "maple", "molasses", "syrup", "jam", "jelly", "marmalade", "chocolate", "cocoa", "vanilla",
            
            // Cooking methods and terms
            "cook", "bake", "roast", "grill", "fry", "saute", "steam", "boil", "simmer", "braise",
            "stir", "mix", "blend", "whisk", "beat", "fold", "knead", "roll", "cut", "slice", "dice",
            "chop", "mince", "grate", "peel", "core", "seed", "trim", "marinate", "season", "taste",
            "preheat", "heat", "warm", "cool", "chill", "freeze", "thaw", "defrost", "rest", "serve",
            "garnish", "decorate", "plate", "present", "drizzle", "pour", "sprinkle", "dust", "coat",
            
            // Recipe structure terms
            "ingredient", "instruction", "step", "method", "preparation", "cooking time", "serving",
            "portion", "serves", "yield", "recipe", "dish", "meal", "course", "appetizer", "entree",
            "main", "dessert", "snack", "breakfast", "lunch", "dinner", "brunch", "supper",
            
            // Units and measurements (already covered but good to have)
            "cup", "tablespoon", "teaspoon", "ounce", "pound", "gram", "kilogram", "milliliter", "liter",
            "piece", "slice", "clove", "bunch", "head", "strand", "pinch", "dash", "drop",
            
            // Common recipe descriptors
            "fresh", "dried", "frozen", "canned", "organic", "raw", "cooked", "roasted", "grilled",
            "fried", "steamed", "boiled", "baked", "crispy", "tender", "juicy", "flavorful", "aromatic",
            "spicy", "sweet", "sour", "bitter", "salty", "umami", "savory", "rich", "light", "heavy",
            
            // Chinese/Asian cooking terms (since the example recipe is Chinese)
            "wok", "stir-fry", "dim sum", "dumpling", "noodle", "rice", "soy", "oyster", "hoisin",
            "szechuan", "sichuan", "cantonese", "spring onion", "scallion", "bok choy", "napa",
        ]
        
        // Non-food words that should be filtered out
        let nonFoodKeywords = [
            "computer", "phone", "laptop", "software", "hardware", "internet", "website", "email",
            "document", "file", "folder", "application", "program", "code", "programming", "developer",
            "business", "meeting", "office", "work", "job", "career", "company", "corporation",
            "vehicle", "car", "truck", "bike", "motorcycle", "airplane", "train", "bus", "taxi",
            "building", "house", "apartment", "room", "furniture", "chair", "table", "desk", "bed",
            "clothing", "shirt", "pants", "shoes", "jacket", "dress", "suit", "uniform",
            "animal", "dog", "cat", "bird", "pet", "wildlife", "zoo",
            "sport", "game", "player", "team", "coach", "stadium", "ball", "racket",
            "music", "song", "album", "artist", "concert", "instrument", "guitar", "piano",
            "movie", "film", "actor", "actress", "director", "cinema", "theater",
            "book", "novel", "author", "writer", "publisher", "library",
            "school", "university", "college", "student", "teacher", "professor", "class",
            "medicine", "doctor", "hospital", "patient", "treatment", "surgery", "disease",
            "machine", "engine", "motor", "battery", "wire", "cable", "plug", "socket",
        ]
        
        // Check if text contains non-food keywords (should be filtered out)
        for keyword in nonFoodKeywords {
            if lowercased.contains(keyword) {
                // Allow exceptions for food-related contexts (e.g., "chicken" is food, not animal)
                let foodContextExceptions = ["chicken", "turkey", "duck", "goose"] // These are food
                if !foodContextExceptions.contains(keyword) {
                    return false
                }
            }
        }
        
        // For ingredient lines, check if they contain food-related terms
        // Allow lines with measurements (they're likely ingredients)
        let hasMeasurement = lowercased.range(of: "\\d+\\s*(tbsp|tsp|cup|cups|oz|lb|g|kg|ml|l|tablespoon|teaspoon|piece|pieces|slice|slices|clove|cloves|bunch|bunches|head|heads|strand|strands|pinch|pinches|dash|dashes)", options: .regularExpression) != nil
        
        // Check if text contains food-related keywords
        // First check for compound keywords (like "sesame oil"), then single keywords
        let hasFoodKeyword = foodKeywords.contains { keyword in
            lowercased.contains(keyword)
        } || lowercased.contains("sesame oil") || lowercased.contains("olive oil") || lowercased.contains("coconut oil") || lowercased.contains("vegetable oil") || lowercased.contains("cooking oil")
        
        // Check if text contains common ingredient patterns (numbers + words)
        let hasIngredientPattern = lowercased.range(of: "^\\d+\\s+[a-z]+", options: .regularExpression) != nil
        
        // Check if text contains cooking action words
        let hasCookingAction = lowercased.range(of: "\\b(cook|bake|roast|grill|fry|saute|steam|boil|simmer|stir|mix|blend|whisk|cut|slice|dice|chop|mince|grate|peel|marinate|season|heat|preheat|serve|garnish|drizzle|pour|sprinkle)\\b", options: .regularExpression) != nil
        
        // Allow if it has measurements, food keywords, ingredient patterns, or cooking actions
        // Also allow short lines that might be valid (like "Salt" or "Pepper")
        if hasMeasurement || hasFoodKeyword || hasIngredientPattern || hasCookingAction {
            return true
        }
        
        // For very short lines (1-2 words), be more lenient if they look like ingredient names
        let words = lowercased.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if words.count <= 2 && words.allSatisfy({ word in
            word.count >= 3 && word.range(of: "^[a-z]+$", options: .regularExpression) != nil
        }) {
            // Allow short ingredient-like words
            return true
        }
        
        // For instructions, allow if they contain action words or recipe structure
        let instructionKeywords = ["step", "first", "next", "then", "finally", "add", "remove", "place", "put", "take", "get", "use", "combine", "mix", "stir"]
        if instructionKeywords.contains(where: { lowercased.hasPrefix($0) || lowercased.contains(" \($0) ") }) {
            return true
        }
        
        // If none of the above, it's likely not food-related
        return false
    }
}


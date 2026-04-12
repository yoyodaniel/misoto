//
//  Ingredient.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation

struct Ingredient: Codable, Equatable {
    var amount: String
    var unit: String
    var name: String
    var category: Category?
    var canonicalId: String?         // e.g. "POULTRY_CHICKEN_THIGH"
    var foodCategory: FoodCategory?  // e.g. .poultry — for shopping list grouping
    
    // MARK: - Recipe Section Category (dish, marinade, sauce, etc.)
    
    enum Category: String, Codable {
        case dish = "dish"
        case marinade = "marinade"
        case seasoning = "seasoning"
        case batter = "batter"
        case sauce = "sauce"
        case base = "base"
        case dough = "dough"
        case topping = "topping"
        case filling = "filling"
        case garnish = "garnish"
    }
    
    // MARK: - Food Category (what the ingredient IS)
    
    enum FoodCategory: String, Codable, CaseIterable {
        case produce = "produce"
        case meat = "meat"
        case poultry = "poultry"
        case seafood = "seafood"
        case dairy = "dairy"
        case grain = "grain"
        case legume = "legume"
        case spice = "spice"
        case herb = "herb"
        case oil = "oil"
        case vinegar = "vinegar"
        case sauce = "sauce"
        case condiment = "condiment"
        case baking = "baking"
        case nut = "nut"
        case beverage = "beverage"
        case misc = "misc"
        
        /// Localized display name for grouping in shopping lists, etc.
        var displayName: String {
            switch self {
            case .produce:   return LocalizedString("Produce", comment: "Food category")
            case .meat:      return LocalizedString("Meat", comment: "Food category")
            case .poultry:   return LocalizedString("Poultry", comment: "Food category")
            case .seafood:   return LocalizedString("Seafood", comment: "Food category")
            case .dairy:     return LocalizedString("Dairy & Eggs", comment: "Food category")
            case .grain:     return LocalizedString("Grains & Pasta", comment: "Food category")
            case .legume:    return LocalizedString("Legumes", comment: "Food category")
            case .spice:     return LocalizedString("Spices", comment: "Food category")
            case .herb:      return LocalizedString("Herbs", comment: "Food category")
            case .oil:       return LocalizedString("Oils", comment: "Food category")
            case .vinegar:   return LocalizedString("Vinegars", comment: "Food category")
            case .sauce:     return LocalizedString("Sauces", comment: "Food category")
            case .condiment: return LocalizedString("Condiments", comment: "Food category")
            case .baking:    return LocalizedString("Baking", comment: "Food category")
            case .nut:       return LocalizedString("Nuts & Seeds", comment: "Food category")
            case .beverage:  return LocalizedString("Beverages", comment: "Food category")
            case .misc:      return LocalizedString("Other", comment: "Food category")
            }
        }
        
        /// SF Symbol icon for this food category
        var iconName: String {
            switch self {
            case .produce:   return "leaf.fill"
            case .meat:      return "fork.knife"
            case .poultry:   return "bird.fill"
            case .seafood:   return "fish.fill"
            case .dairy:     return "cup.and.saucer.fill"
            case .grain:     return "basket.fill"
            case .legume:    return "leaf.circle.fill"
            case .spice:     return "flame.fill"
            case .herb:      return "leaf.arrow.circlepath"
            case .oil:       return "drop.fill"
            case .vinegar:   return "drop.halffull"
            case .sauce:     return "waterbottle.fill"
            case .condiment: return "takeoutbag.and.cup.and.straw.fill"
            case .baking:    return "birthday.cake.fill"
            case .nut:       return "tree.fill"
            case .beverage:  return "mug.fill"
            case .misc:      return "bag.fill"
            }
        }
    }
    
    // MARK: - Allergen (FDA Big 9)
    
    enum Allergen: String, Codable, CaseIterable {
        case dairy = "dairy"
        case eggs = "eggs"
        case fish = "fish"
        case shellfish = "shellfish"
        case treeNuts = "tree_nuts"
        case peanuts = "peanuts"
        case gluten = "gluten"
        case soy = "soy"
        case sesame = "sesame"
        
        var displayName: String {
            switch self {
            case .dairy:     return "🥛 " + LocalizedString("Dairy", comment: "Allergen")
            case .eggs:      return "🥚 " + LocalizedString("Eggs", comment: "Allergen")
            case .fish:      return "🐟 " + LocalizedString("Fish", comment: "Allergen")
            case .shellfish: return "🦐 " + LocalizedString("Shellfish", comment: "Allergen")
            case .treeNuts:  return "🌰 " + LocalizedString("Tree Nuts", comment: "Allergen")
            case .peanuts:   return "🥜 " + LocalizedString("Peanuts", comment: "Allergen")
            case .gluten:    return "🌾 " + LocalizedString("Gluten", comment: "Allergen")
            case .soy:       return "🫘 " + LocalizedString("Soy", comment: "Allergen")
            case .sesame:    return "⚪ " + LocalizedString("Sesame", comment: "Allergen")
            }
        }
    }
    
    // MARK: - Dietary Flag
    
    enum DietaryFlag: String, Codable, CaseIterable {
        case vegan = "vegan"
        case vegetarian = "vegetarian"
        case glutenFree = "gluten_free"
        case dairyFree = "dairy_free"
        case nutFree = "nut_free"
        
        var displayName: String {
            switch self {
            case .vegan:      return "🌱 " + LocalizedString("Vegan", comment: "Dietary flag")
            case .vegetarian: return "🥬 " + LocalizedString("Vegetarian", comment: "Dietary flag")
            case .glutenFree: return "🌾 " + LocalizedString("Gluten-Free", comment: "Dietary flag")
            case .dairyFree:  return "🥛 " + LocalizedString("Dairy-Free", comment: "Dietary flag")
            case .nutFree:    return "🥜 " + LocalizedString("Nut-Free", comment: "Dietary flag")
            }
        }
    }
    
    // MARK: - Init
    
    init(
        amount: String,
        unit: String,
        name: String,
        category: Category? = nil,
        canonicalId: String? = nil,
        foodCategory: FoodCategory? = nil
    ) {
        self.amount = amount
        self.unit = unit
        self.name = name
        self.category = category
        self.canonicalId = canonicalId
        self.foodCategory = foodCategory
    }
    
    // Helper to convert to display string (for backward compatibility)
    var displayString: String {
        if unit.isEmpty {
            return amount.isEmpty ? name : "\(amount) \(name)"
        } else {
            // Use UnitTranslations to get the translated and pluralized unit abbreviation
            let translatedUnit = UnitTranslations.abbreviation(for: unit, amount: amount)
            return "\(amount) \(translatedUnit) \(name)"
        }
    }
}

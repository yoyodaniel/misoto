//
//  Ingredient.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation

struct Ingredient: Identifiable, Codable, Equatable {
    var id: String
    var amount: String
    var unit: String
    var name: String
    var category: Category?
    
    enum Category: String, Codable {
        case dish = "dish"
        case marinade = "marinade"
        case seasoning = "seasoning"
        case batter = "batter"
        case sauce = "sauce"
        case base = "base"
        case dough = "dough"
        case topping = "topping"
    }
    
    init(
        id: String = UUID().uuidString,
        amount: String,
        unit: String,
        name: String,
        category: Category? = nil
    ) {
        self.id = id
        self.amount = amount
        self.unit = unit
        self.name = name
        self.category = category
    }
    
    // Helper to convert to display string (for backward compatibility)
    var displayString: String {
        if unit.isEmpty {
            return amount.isEmpty ? name : "\(amount) \(name)"
        } else {
            return "\(amount) \(unit) \(name)"
        }
    }
}



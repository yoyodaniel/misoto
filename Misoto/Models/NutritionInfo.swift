//
//  NutritionInfo.swift
//  Misoto
//
//  Created by Daniel Chan on 08.02.2026.
//

import Foundation

/// Nutritional information for a recipe (per serving, AI-estimated)
struct NutritionInfo: Codable, Equatable {
    let calories: Int        // kcal
    let protein: Double      // grams
    let carbohydrates: Double // grams
    let fat: Double          // grams
    let saturatedFat: Double // grams
    let fiber: Double        // grams
    let sugar: Double        // grams
    let sodium: Int          // milligrams
    
    // MARK: - Daily Reference Values (based on 2,000 kcal diet)
    
    /// FDA / EFSA daily reference values
    private static let dailyCalories: Double = 2000
    private static let dailyProtein: Double = 50      // grams
    private static let dailyCarbs: Double = 275        // grams
    private static let dailyFat: Double = 78           // grams
    private static let dailySaturatedFat: Double = 20  // grams
    private static let dailyFiber: Double = 28         // grams
    private static let dailySugar: Double = 50         // grams
    private static let dailySodium: Double = 2300      // milligrams
    
    // MARK: - % Daily Value Computed Properties
    
    /// Calories as a fraction of daily reference (0.0 – 1.0+)
    var caloriesDV: Double {
        Double(calories) / Self.dailyCalories
    }
    
    /// Protein as a fraction of daily reference (0.0 – 1.0+)
    var proteinDV: Double {
        protein / Self.dailyProtein
    }
    
    /// Carbohydrates as a fraction of daily reference (0.0 – 1.0+)
    var carbsDV: Double {
        carbohydrates / Self.dailyCarbs
    }
    
    /// Fat as a fraction of daily reference (0.0 – 1.0+)
    var fatDV: Double {
        fat / Self.dailyFat
    }
    
    /// Saturated fat as a fraction of daily reference (0.0 – 1.0+)
    var saturatedFatDV: Double {
        saturatedFat / Self.dailySaturatedFat
    }
    
    /// Fiber as a fraction of daily reference (0.0 – 1.0+)
    var fiberDV: Double {
        fiber / Self.dailyFiber
    }
    
    /// Sugar as a fraction of daily reference (0.0 – 1.0+)
    var sugarDV: Double {
        sugar / Self.dailySugar
    }
    
    /// Sodium as a fraction of daily reference (0.0 – 1.0+)
    var sodiumDV: Double {
        Double(sodium) / Self.dailySodium
    }
}

//
//  RecipeImageStylePreset.swift
//  Misoto
//
//  Style presets for AI dish-photo enhancement (v1.5).
//

import Foundation

enum RecipeImageStylePreset: String, CaseIterable, Identifiable, Sendable {
    case recipeApp
    case modernPatisserie
    case rusticComfort
    case minimalist
    case celebration
    case premiumDessert
    case familyCookbook
    case foodBlog

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .recipeApp:
            return LocalizedString("Clean recipe app", comment: "Dish photo style preset")
        case .modernPatisserie:
            return LocalizedString("Modern patisserie", comment: "Dish photo style preset")
        case .rusticComfort:
            return LocalizedString("Rustic comfort", comment: "Dish photo style preset")
        case .minimalist:
            return LocalizedString("Minimalist", comment: "Dish photo style preset")
        case .celebration:
            return LocalizedString("Celebration", comment: "Dish photo style preset")
        case .premiumDessert:
            return LocalizedString("Premium dessert", comment: "Dish photo style preset")
        case .familyCookbook:
            return LocalizedString("Family cookbook", comment: "Dish photo style preset")
        case .foodBlog:
            return LocalizedString("Modern food blog", comment: "Dish photo style preset")
        }
    }

    var shortDescription: String {
        switch self {
        case .recipeApp:
            return LocalizedString("Bright, neutral, app-thumbnail ready.", comment: "Dish photo style preset description")
        case .modernPatisserie:
            return LocalizedString("Refined bakery finish and elegant plating.", comment: "Dish photo style preset description")
        case .rusticComfort:
            return LocalizedString("Warm homestyle cookbook feel.", comment: "Dish photo style preset description")
        case .minimalist:
            return LocalizedString("Calm, uncluttered Scandinavian look.", comment: "Dish photo style preset description")
        case .celebration:
            return LocalizedString("Festive but tidy and photo-ready.", comment: "Dish photo style preset description")
        case .premiumDessert:
            return LocalizedString("High-end dessert photography polish.", comment: "Dish photo style preset description")
        case .familyCookbook:
            return LocalizedString("Approachable, authentic home-baked warmth.", comment: "Dish photo style preset description")
        case .foodBlog:
            return LocalizedString("Editorial color pop, still realistic.", comment: "Dish photo style preset description")
        }
    }
}

//
//  FreeTierLimits.swift
//  Misoto
//
//  Free tier usage limits
//

import Foundation

struct FreeTierLimits {
    static let maxRecipesPerMonth = 15
    static let maxAIDescriptionsPerMonth = 3
    static let maxAIImageExtractionsPerMonth = 5
    /// AI dish-photo enhancements (separate from recipe extraction; higher API cost).
    static let maxAIImageEditsPerMonth = 3
}


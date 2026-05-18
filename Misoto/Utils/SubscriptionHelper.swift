//
//  SubscriptionHelper.swift
//  Misoto
//
//  Helper functions for subscription checks and upgrade prompts
//

import Foundation
import SwiftUI

@MainActor
struct SubscriptionHelper {
    static func checkRecipeCreationLimit() async throws -> Bool {
        let subscriptionService = SubscriptionService.shared
        await subscriptionService.loadSubscriptionStatus()
        
        // Premium users can create unlimited recipes
        if subscriptionService.hasPremium {
            return true
        }
        
        // Check free tier limit
        let usageService = UsageTrackingService.shared
        let count = try await usageService.getRecipeCountThisMonth()
        return count < FreeTierLimits.maxRecipesPerMonth
    }
    
    static func checkAIDescriptionLimit() async throws -> Bool {
        let subscriptionService = SubscriptionService.shared
        await subscriptionService.loadSubscriptionStatus()
        
        // Premium users can generate unlimited descriptions
        if subscriptionService.hasPremium {
            return true
        }
        
        // Check free tier limit
        let usageService = UsageTrackingService.shared
        let count = try await usageService.getAIDescriptionCountThisMonth()
        return count < FreeTierLimits.maxAIDescriptionsPerMonth
    }
    
    static func checkAIImageExtractionLimit() async throws -> Bool {
        let subscriptionService = SubscriptionService.shared
        await subscriptionService.loadSubscriptionStatus()
        
        // Premium users can extract unlimited images
        if subscriptionService.hasPremium {
            return true
        }
        
        // Check free tier limit
        let usageService = UsageTrackingService.shared
        let count = try await usageService.getAIImageExtractionCountThisMonth()
        return count < FreeTierLimits.maxAIImageExtractionsPerMonth
    }
    
    static func trackRecipeCreation() async throws {
        let subscriptionService = SubscriptionService.shared
        await subscriptionService.loadSubscriptionStatus()
        
        // Only track for free tier users
        if !subscriptionService.hasPremium {
            try await UsageTrackingService.shared.trackRecipeCreation()
        }
    }
    
    static func trackAIDescriptionGeneration() async throws {
        let subscriptionService = SubscriptionService.shared
        await subscriptionService.loadSubscriptionStatus()
        
        // Only track for free tier users
        if !subscriptionService.hasPremium {
            try await UsageTrackingService.shared.trackAIDescriptionGeneration()
        }
    }
    
    static func trackAIImageExtraction() async throws {
        let subscriptionService = SubscriptionService.shared
        await subscriptionService.loadSubscriptionStatus()
        
        print("🔍 SubscriptionHelper.trackAIImageExtraction() called")
        print("🔍 User hasPremium: \(subscriptionService.hasPremium)")
        
        // Only track for free tier users
        if !subscriptionService.hasPremium {
            print("✅ User is free tier, tracking AI extraction...")
            try await UsageTrackingService.shared.trackAIImageExtraction()
        } else {
            print("ℹ️ User is premium, skipping tracking")
        }
    }

    static func checkAIImageEditLimit() async throws -> Bool {
        let subscriptionService = SubscriptionService.shared
        await subscriptionService.loadSubscriptionStatus()
        if subscriptionService.hasPremium {
            return true
        }
        let count = try await UsageTrackingService.shared.getAIImageEditCountThisMonth()
        return count < FreeTierLimits.maxAIImageEditsPerMonth
    }

    static func trackAIImageEdit() async throws {
        let subscriptionService = SubscriptionService.shared
        await subscriptionService.loadSubscriptionStatus()
        if !subscriptionService.hasPremium {
            try await UsageTrackingService.shared.trackAIImageEdit()
        }
    }
}

enum SubscriptionLimitError: LocalizedError {
    case recipeLimitReached
    case aiDescriptionLimitReached
    case aiImageExtractionLimitReached
    case aiImageEditLimitReached
    
    var errorDescription: String? {
        switch self {
        case .recipeLimitReached:
            return NSLocalizedString("You have reached the free tier limit", comment: "Recipe limit error")
        case .aiDescriptionLimitReached:
            return NSLocalizedString("You have reached your free tier limit for AI descriptions", comment: "AI description limit error")
        case .aiImageExtractionLimitReached:
            return NSLocalizedString("You have reached your free tier limit for AI image extractions", comment: "AI image extraction limit error")
        case .aiImageEditLimitReached:
            return NSLocalizedString("You have reached your free tier limit for AI photo enhancements", comment: "AI image edit limit error")
        }
    }
}


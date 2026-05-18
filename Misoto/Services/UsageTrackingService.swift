//
//  UsageTrackingService.swift
//  Misoto
//
//  Service for tracking free tier usage limits
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class UsageTrackingService {
    static let shared = UsageTrackingService()
    
    private let firestore = FirebaseManager.shared.firestore
    private let usageCollection = "usage"
    
    private init() {}
    
    // MARK: - Track Recipe Creation
    
    func trackRecipeCreation() async throws {
        // No-op: recipeCount is already incremented by RecipeService.createRecipe()
        // This method exists only for API compatibility with SubscriptionHelper.
        // Do NOT add a FieldValue.increment here — it would cause double-counting.
    }
    
    func getRecipeCountThisMonth() async throws -> Int {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw UsageTrackingError.unauthorized
        }
        
        // Get recipe count from user document (as specified by user)
        let userRef = firestore.collection("users").document(userID)
        let userDocument = try await userRef.getDocument()
        
        if let userData = userDocument.data() {
            // Try Int first
            if let recipeCount = userData["recipeCount"] as? Int {
                return recipeCount
            }
            // Try NSNumber (Firestore can return numbers as NSNumber)
            if let recipeCount = userData["recipeCount"] as? NSNumber {
                return recipeCount.intValue
            }
        }
        
        // Fallback: Try to get from usage collection (monthly tracking)
        let monthKey = getCurrentMonthKey()
        let usageRef = firestore.collection(usageCollection).document(userID)
        
        let usageDocument = try await usageRef.getDocument()
        if let usageData = usageDocument.data(),
           let recipeCountDict = usageData["recipeCount"] as? [String: Any] {
            if let monthData = recipeCountDict[monthKey] {
                if let intValue = monthData as? Int {
                    return intValue
                } else if let numberValue = monthData as? NSNumber {
                    return numberValue.intValue
                }
            }
        }
        
        return 0
    }
    
    // MARK: - Track AI Description Generation
    
    func trackAIDescriptionGeneration() async throws {
        // Enforced server-side when calling openaiChatCompletions (usageType: description).
    }
    
    func getAIDescriptionCountThisMonth() async throws -> Int {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw UsageTrackingError.unauthorized
        }
        
        let monthKey = getCurrentMonthKey()
        // Structure: users/{userId}/usage/aiDescriptionCount/{monthKey}
        let userRef = firestore.collection("users").document(userID)
        
        let document = try await userRef.getDocument()
        guard let data = document.data() else {
            return 0
        }
        
        // Navigate: data -> usage -> aiDescriptionCount -> {monthKey}
        if let usage = data["usage"] as? [String: Any],
           let aiDescriptionCount = usage["aiDescriptionCount"] as? [String: Any] {
            if let monthData = aiDescriptionCount[monthKey] {
                if let intValue = monthData as? Int {
                    return intValue
                } else if let numberValue = monthData as? NSNumber {
                    return numberValue.intValue
                }
            }
        }
        
        return 0
    }
    
    // MARK: - Track AI Image Extraction
    
    func trackAIImageExtraction() async throws {
        // Enforced server-side when calling openaiChatCompletions (usageType: imageExtraction).
    }
    
    func getAIImageExtractionCountThisMonth() async throws -> Int {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw UsageTrackingError.unauthorized
        }
        
        let monthKey = getCurrentMonthKey()
        // Structure: users/{userId}/usage/aiImageExtractionCount/{monthKey}
        // Example: users/{userId}/usage/aiImageExtractionCount/2026-01 = 4
        let userRef = firestore.collection("users").document(userID)
        
        let document = try await userRef.getDocument()
        guard let data = document.data() else {
            return 0
        }
        
        // Navigate: data -> usage -> aiImageExtractionCount -> {monthKey}
        if let usage = data["usage"] as? [String: Any],
           let aiImageExtractionCount = usage["aiImageExtractionCount"] as? [String: Any] {
            // Check if the value is an Int or NSNumber (Firestore can return either)
            if let monthData = aiImageExtractionCount[monthKey] {
                if let intValue = monthData as? Int {
                    return intValue
                } else if let numberValue = monthData as? NSNumber {
                    return numberValue.intValue
                } else if let stringValue = monthData as? String,
                          let intValue = Int(stringValue) {
                    return intValue
                }
            }
        }
        
        return 0
    }

    // MARK: - Track AI dish-photo edit

    func trackAIImageEdit() async throws {
        // Enforced server-side when calling openaiImageEdit.
    }

    func getAIImageEditCountThisMonth() async throws -> Int {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw UsageTrackingError.unauthorized
        }

        let monthKey = getCurrentMonthKey()
        let userRef = firestore.collection("users").document(userID)
        let document = try await userRef.getDocument()
        guard let data = document.data(),
              let usage = data["usage"] as? [String: Any],
              let aiImageEditCount = usage["aiImageEditCount"] as? [String: Any],
              let monthData = aiImageEditCount[monthKey] else {
            return 0
        }
        if let intValue = monthData as? Int { return intValue }
        if let numberValue = monthData as? NSNumber { return numberValue.intValue }
        if let stringValue = monthData as? String, let intValue = Int(stringValue) { return intValue }
        return 0
    }
    
    // MARK: - Helpers
    
    private func getCurrentMonthKey() -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        return "\(components.year ?? 0)-\(String(format: "%02d", components.month ?? 0))"
    }
}

enum UsageTrackingError: LocalizedError {
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return NSLocalizedString("You must be signed in to track usage", comment: "Usage tracking error")
        }
    }
}


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
        guard let userID = Auth.auth().currentUser?.uid else {
            throw UsageTrackingError.unauthorized
        }
        
        let monthKey = getCurrentMonthKey()
        let usageRef = firestore.collection(usageCollection).document(userID)
        
        try await usageRef.setData([
            "recipeCount.\(monthKey)": FieldValue.increment(Int64(1)),
            "updatedAt": Timestamp(date: Date())
        ], merge: true)
    }
    
    func getRecipeCountThisMonth() async throws -> Int {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw UsageTrackingError.unauthorized
        }
        
        let monthKey = getCurrentMonthKey()
        let usageRef = firestore.collection(usageCollection).document(userID)
        
        let document = try await usageRef.getDocument()
        if let data = document.data(),
           let recipeCount = data["recipeCount"] as? [String: Int],
           let count = recipeCount[monthKey] {
            return count
        }
        
        return 0
    }
    
    // MARK: - Track AI Description Generation
    
    func trackAIDescriptionGeneration() async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw UsageTrackingError.unauthorized
        }
        
        let monthKey = getCurrentMonthKey()
        let usageRef = firestore.collection(usageCollection).document(userID)
        
        try await usageRef.setData([
            "aiDescriptionCount.\(monthKey)": FieldValue.increment(Int64(1)),
            "updatedAt": Timestamp(date: Date())
        ], merge: true)
    }
    
    func getAIDescriptionCountThisMonth() async throws -> Int {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw UsageTrackingError.unauthorized
        }
        
        let monthKey = getCurrentMonthKey()
        let usageRef = firestore.collection(usageCollection).document(userID)
        
        let document = try await usageRef.getDocument()
        if let data = document.data(),
           let count = data["aiDescriptionCount"] as? [String: Int],
           let aiCount = count[monthKey] {
            return aiCount
        }
        
        return 0
    }
    
    // MARK: - Track AI Image Extraction
    
    func trackAIImageExtraction() async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw UsageTrackingError.unauthorized
        }
        
        let monthKey = getCurrentMonthKey()
        let usageRef = firestore.collection(usageCollection).document(userID)
        
        try await usageRef.setData([
            "aiImageExtractionCount.\(monthKey)": FieldValue.increment(Int64(1)),
            "updatedAt": Timestamp(date: Date())
        ], merge: true)
    }
    
    func getAIImageExtractionCountThisMonth() async throws -> Int {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw UsageTrackingError.unauthorized
        }
        
        let monthKey = getCurrentMonthKey()
        let usageRef = firestore.collection(usageCollection).document(userID)
        
        let document = try await usageRef.getDocument()
        if let data = document.data(),
           let count = data["aiImageExtractionCount"] as? [String: Int],
           let extractionCount = count[monthKey] {
            return extractionCount
        }
        
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


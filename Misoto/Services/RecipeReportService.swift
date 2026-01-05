//
//  RecipeReportService.swift
//  Misoto
//
//  Created by Daniel Chan on 4.1.2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class RecipeReportService {
    private let firestore = FirebaseManager.shared.firestore
    private let recipesCollection = "recipes"
    private let reportsCollection = "recipeReports"
    
    // Threshold for auto-hiding posts
    private let autoHideThreshold = 10
    
    // MARK: - Report Recipe
    
    /// Report a recipe/post. Increments reportCount and auto-hides if threshold is reached.
    func reportRecipe(recipeID: String, reason: String? = nil) async throws {
        guard let reporterID = Auth.auth().currentUser?.uid else {
            throw RecipeReportError.unauthorized
        }
        
        // Get recipe to check author
        let recipeDoc = try await firestore.collection(recipesCollection).document(recipeID).getDocument()
        guard recipeDoc.exists else {
            throw RecipeReportError.recipeNotFound
        }
        
        guard let recipeData = try? recipeDoc.data(as: Recipe.self) else {
            throw RecipeReportError.recipeNotFound
        }
        
        // Don't allow users to report their own recipes
        guard recipeData.authorID != reporterID else {
            throw RecipeReportError.cannotReportOwnRecipe
        }
        
        // Check if user has already reported this recipe (prevent duplicate reports)
        let existingReport = try await firestore.collection(reportsCollection)
            .whereField("recipeID", isEqualTo: recipeID)
            .whereField("reporterID", isEqualTo: reporterID)
            .limit(to: 1)
            .getDocuments()
        
        if !existingReport.documents.isEmpty {
            throw RecipeReportError.alreadyReported
        }
        
        // Create report document
        let reportID = UUID().uuidString
        let reportData: [String: Any] = [
            "id": reportID,
            "recipeID": recipeID,
            "reporterID": reporterID,
            "reason": reason ?? "",
            "createdAt": Timestamp(date: Date())
        ]
        
        try await firestore.collection(reportsCollection).document(reportID).setData(reportData)
        
        // Get current report count and increment it
        let currentReportCount = (recipeDoc.data()?["reportCount"] as? Int) ?? 0
        let newReportCount = currentReportCount + 1
        
        // Update report count using FieldValue.increment for atomic operation
        var updateData: [String: Any] = [
            "reportCount": FieldValue.increment(Int64(1)),
            "updatedAt": Timestamp(date: Date())
        ]
        
        // Auto-hide if threshold reached (check after increment)
        if newReportCount >= autoHideThreshold {
            updateData["isHidden"] = true
            print("⚠️ Recipe \(recipeID) auto-hidden due to \(newReportCount) reports")
        }
        
        try await firestore.collection(recipesCollection).document(recipeID).updateData(updateData)
        print("✅ Recipe \(recipeID) reported. Report count updated to: \(newReportCount)")
    }
    
    // MARK: - Check if Recipe is Hidden
    
    func isRecipeHidden(recipeID: String) async throws -> Bool {
        let recipeDoc = try await firestore.collection(recipesCollection).document(recipeID).getDocument()
        
        guard recipeDoc.exists, let recipeData = recipeDoc.data() else {
            return false
        }
        
        return (recipeData["isHidden"] as? Bool) ?? false
    }
}

enum RecipeReportError: LocalizedError {
    case unauthorized
    case cannotReportOwnRecipe
    case alreadyReported
    case recipeNotFound
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return LocalizedString("You must be logged in to report a recipe", comment: "Not logged in error")
        case .cannotReportOwnRecipe:
            return LocalizedString("You cannot report your own recipe", comment: "Cannot report own recipe error")
        case .alreadyReported:
            return LocalizedString("You have already reported this recipe", comment: "Already reported error")
        case .recipeNotFound:
            return LocalizedString("Recipe not found", comment: "Recipe not found error")
        }
    }
}


//
//  FeedbackService.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class FeedbackService {
    private let firestore = FirebaseManager.shared.firestore
    
    // MARK: - Submit Feedback
    
    func submitFeedback(type: FeedbackType, name: String, subtitle: String, email: String?) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw FeedbackError.userNotAuthenticated
        }
        
        guard !subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FeedbackError.emptySubtitle
        }
        
        // Validate email format if provided (email is optional)
        var validatedEmail: String? = nil
        if let email = email, !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            guard emailPredicate.evaluate(with: trimmedEmail) else {
                throw FeedbackError.invalidEmail
            }
            validatedEmail = trimmedEmail
        }
        
        var feedbackData: [String: Any] = [
            "userID": userID,
            "type": type.rawValue,
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "subtitle": subtitle.trimmingCharacters(in: .whitespacesAndNewlines),
            "timestamp": FieldValue.serverTimestamp(),
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? LocalizedString("Unknown", comment: "Unknown version")
        ]
        
        // Add email only if provided
        if let email = validatedEmail {
            feedbackData["email"] = email
        }
        
        do {
            try await firestore.collection("feedback").addDocument(data: feedbackData)
            print("✅ \(type.displayName) submitted successfully")
        } catch {
            print("❌ Error submitting \(type.displayName): \(error.localizedDescription)")
            throw FeedbackError.submissionFailed(error.localizedDescription)
        }
    }
}

// MARK: - Feedback Type

enum FeedbackType: String {
    case featureRequest = "feature_request"
    case generalFeedback = "general_feedback"
    case translationSuggestion = "translation_suggestion"
    
    var displayName: String {
        switch self {
        case .featureRequest:
            return LocalizedString("Feature Request", comment: "Feature request type")
        case .generalFeedback:
            return LocalizedString("General Feedback", comment: "General feedback type")
        case .translationSuggestion:
            return LocalizedString("Translation Suggestion", comment: "Translation suggestion type")
        }
    }
}

// MARK: - Feedback Errors

enum FeedbackError: LocalizedError {
    case userNotAuthenticated
    case emptySubtitle
    case invalidEmail
    case submissionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return LocalizedString("You must be signed in to submit feedback", comment: "Feedback error - not authenticated")
        case .emptySubtitle:
            return LocalizedString("Please provide your feedback or feature request", comment: "Feedback error - empty subtitle")
        case .invalidEmail:
            return LocalizedString("Please provide a valid email address or leave it empty", comment: "Feedback error - invalid email")
        case .submissionFailed(let message):
            return LocalizedString("Failed to submit: \(message)", comment: "Feedback error - submission failed")
        }
    }
}


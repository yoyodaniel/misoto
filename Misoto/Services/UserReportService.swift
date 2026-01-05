//
//  UserReportService.swift
//  Misoto
//
//  Created by Daniel Chan on 30.12.2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class UserReportService {
    private let firestore = FirebaseManager.shared.firestore
    private let usersCollection = "users"
    private let reportsCollection = "userReports"
    
    // Threshold for auto-ban
    private let autoBanThreshold = 10
    
    // MARK: - Report User
    
    /// Report a user. Increments reportCount and auto-bans if threshold is reached.
    func reportUser(userID: String, reason: String? = nil) async throws {
        guard let reporterID = Auth.auth().currentUser?.uid else {
            throw ReportError.unauthorized
        }
        
        // Don't allow users to report themselves
        guard userID != reporterID else {
            throw ReportError.cannotReportSelf
        }
        
        // Check if user has already reported this user (prevent duplicate reports)
        let existingReport = try await firestore.collection(reportsCollection)
            .whereField("reportedUserID", isEqualTo: userID)
            .whereField("reporterID", isEqualTo: reporterID)
            .limit(to: 1)
            .getDocuments()
        
        if !existingReport.documents.isEmpty {
            throw ReportError.alreadyReported
        }
        
        // Create report document
        let reportID = UUID().uuidString
        let reportData: [String: Any] = [
            "id": reportID,
            "reportedUserID": userID,
            "reporterID": reporterID,
            "reason": reason ?? "",
            "createdAt": Timestamp(date: Date())
        ]
        
        try await firestore.collection(reportsCollection).document(reportID).setData(reportData)
        
        // Increment report count for the reported user
        let userRef = firestore.collection(usersCollection).document(userID)
        let userDoc = try await userRef.getDocument()
        
        guard userDoc.exists else {
            throw ReportError.userNotFound
        }
        
        let currentReportCount = (userDoc.data()?["reportCount"] as? Int) ?? 0
        let newReportCount = currentReportCount + 1
        
        // Update report count using FieldValue.increment for atomic operation
        var updateData: [String: Any] = [
            "reportCount": FieldValue.increment(Int64(1)),
            "updatedAt": Timestamp(date: Date())
        ]
        
        // Auto-ban if threshold reached (check after increment)
        if newReportCount >= autoBanThreshold {
            updateData["isBanned"] = true
            print("⚠️ User \(userID) auto-banned due to \(newReportCount) reports")
        }
        
        try await userRef.updateData(updateData)
        print("✅ User \(userID) report count updated. New count: \(newReportCount)")
        
        print("✅ User \(userID) reported. Report count: \(newReportCount)")
    }
    
    // MARK: - Check if User is Banned
    
    func isUserBanned(userID: String) async throws -> Bool {
        let userDoc = try await firestore.collection(usersCollection).document(userID).getDocument()
        
        guard userDoc.exists, let userData = userDoc.data() else {
            return false
        }
        
        return (userData["isBanned"] as? Bool) ?? false
    }
    
    // MARK: - Filter Banned Users
    
    /// Filters out banned users from an array of user IDs
    func filterBannedUserIDs(userIDs: [String]) async -> [String] {
        var nonBannedIDs: [String] = []
        
        await withTaskGroup(of: String?.self) { group in
            for userID in userIDs {
                group.addTask {
                    do {
                        let isBanned = try await self.isUserBanned(userID: userID)
                        return isBanned ? nil : userID
                    } catch {
                        print("⚠️ Error checking ban status for user \(userID): \(error.localizedDescription)")
                        return nil // Err on the side of caution - exclude if we can't verify
                    }
                }
            }
            
            for await userID in group {
                if let id = userID {
                    nonBannedIDs.append(id)
                }
            }
        }
        
        return nonBannedIDs
    }
}

enum ReportError: LocalizedError {
    case unauthorized
    case cannotReportSelf
    case alreadyReported
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "You must be logged in to report a user"
        case .cannotReportSelf:
            return "You cannot report yourself"
        case .alreadyReported:
            return "You have already reported this user"
        case .userNotFound:
            return "User not found"
        }
    }
}


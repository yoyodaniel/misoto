//
//  XPService.swift
//  Misoto
//
//  Centralized XP award and level progression service.
//

import Foundation
import FirebaseFirestore

@MainActor
final class XPService {
    static let shared = XPService()

    private let firestore = FirebaseManager.shared.firestore
    private let progressCollection = "userProgress"
    private let eventsCollection = "xpEvents"
    private let systemActorID = "system"
    /// Backend Cloud Functions is the source of truth for XP.
    private let clientAwardingEnabled = false

    private init() {}

    // MARK: - Public API

    func getXPValueForAction(_ actionType: XPActionType) -> Int {
        XPLevelCalculator.xpValue(for: actionType)
    }

    func getLevelTitle(_ level: Int) -> String {
        XPLevelCalculator.getLevelTitle(level: level)
    }

    func getLevelProgress(totalXP: Int) -> XPLevelProgress {
        XPLevelCalculator.getLevelProgress(totalXP: totalXP)
    }

    func getUserProgress(userId: String) async throws -> UserProgress {
        let ref = firestore.collection(progressCollection).document(userId)
        let snapshot = try await ref.getDocument()
        if let progress = try? snapshot.data(as: UserProgress.self) {
            return progress
        }

        let initial = UserProgress(userId: userId)
        try ref.setData(from: initial, merge: true)
        return initial
    }

    func recalculateUserLevel(userId: String) async throws -> UserProgress {
        let current = try await getUserProgress(userId: userId)
        let level = XPLevelCalculator.levelFromXP(current.totalXP)
        let title = XPLevelCalculator.getLevelTitle(level: level)
        let updated = UserProgress(
            userId: current.userId,
            totalXP: current.totalXP,
            currentLevel: level,
            currentTitle: title,
            createdAt: current.createdAt,
            updatedAt: Date()
        )
        try firestore.collection(progressCollection).document(userId).setData(from: updated, merge: true)
        return updated
    }

    func createXPEventIfNotExists(eventId: String, eventData: XPEvent) async throws -> Bool {
        guard clientAwardingEnabled else { return false }
        let eventRef = firestore.collection(eventsCollection).document(eventId)
        return try await withCheckedThrowingContinuation { continuation in
            firestore.runTransaction { transaction, errorPointer in
                let existing: DocumentSnapshot
                do {
                    existing = try transaction.getDocument(eventRef)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return false
                }
                if existing.exists {
                    return false
                }

                do {
                    let encoded = try Firestore.Encoder().encode(eventData)
                    transaction.setData(encoded, forDocument: eventRef)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return false
                }
                return true
            } completion: { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (result as? Bool) ?? false)
            }
        }
    }

    func awardXP(
        receiverUserId: String,
        actorUserId: String,
        eventType: XPActionType,
        targetId: String,
        xpAmount: Int,
        metadata: [String: String]? = nil,
        explicitEventId: String? = nil
    ) async throws -> XPAwardResult? {
        guard clientAwardingEnabled else { return nil }
        guard !receiverUserId.isEmpty, !actorUserId.isEmpty, !targetId.isEmpty else { return nil }
        guard xpAmount > 0 else { return nil }
        if receiverUserId == actorUserId && actorUserId != systemActorID && isSelfAwardBlocked(eventType) {
            return nil
        }

        let eventId = explicitEventId ?? defaultEventID(
            actionType: eventType,
            receiverUserId: receiverUserId,
            actorUserId: actorUserId,
            targetId: targetId
        )

        let event = XPEvent(
            eventId: eventId,
            receiverUserId: receiverUserId,
            actorUserId: actorUserId,
            eventType: eventType.rawValue,
            targetId: targetId,
            xpAmount: xpAmount,
            createdAt: Date(),
            metadata: metadata
        )

        let created = try await createXPEventIfNotExists(eventId: eventId, eventData: event)
        guard created else { return nil }

        let previous = try await getUserProgress(userId: receiverUserId)
        let nextTotalXP = previous.totalXP + xpAmount
        let currentLevel = XPLevelCalculator.levelFromXP(nextTotalXP)
        let previousLevel = previous.currentLevel
        let currentTitle = XPLevelCalculator.getLevelTitle(level: currentLevel)
        let updated = UserProgress(
            userId: receiverUserId,
            totalXP: nextTotalXP,
            currentLevel: currentLevel,
            currentTitle: currentTitle,
            createdAt: previous.createdAt,
            updatedAt: Date()
        )
        try firestore.collection(progressCollection).document(receiverUserId).setData(from: updated, merge: true)

        let progress = XPLevelCalculator.getLevelProgress(totalXP: nextTotalXP)
        return XPAwardResult(
            awardedXP: xpAmount,
            totalXP: nextTotalXP,
            previousLevel: previousLevel,
            currentLevel: currentLevel,
            levelUp: currentLevel > previousLevel,
            currentTitle: currentTitle,
            xpNeededForNextLevel: progress.xpNeededForNextLevel
        )
    }

    func awardXPForAction(
        receiverUserId: String,
        actorUserId: String,
        actionType: XPActionType,
        targetId: String,
        metadata: [String: String]? = nil
    ) async throws -> XPAwardResult? {
        guard clientAwardingEnabled else { return nil }
        var baseXP = getXPValueForAction(actionType)
        guard baseXP > 0 else { return nil }

        if isActorDailyCappedAction(actionType) {
            baseXP = try await applyDailyCaps(
                actionType: actionType,
                receiverUserId: receiverUserId,
                actorUserId: actorUserId,
                proposedXP: baseXP
            )
            guard baseXP > 0 else { return nil }
        }

        if actionType == .recipePublished {
            baseXP = try await applyRecipePublishDailyAdjustment(
                receiverUserId: receiverUserId,
                actorUserId: actorUserId,
                proposedXP: baseXP
            )
            guard baseXP > 0 else { return nil }
        }

        let eventId = defaultEventID(
            actionType: actionType,
            receiverUserId: receiverUserId,
            actorUserId: actorUserId,
            targetId: targetId
        )

        let result = try await awardXP(
            receiverUserId: receiverUserId,
            actorUserId: actorUserId,
            eventType: actionType,
            targetId: targetId,
            xpAmount: baseXP,
            metadata: metadata,
            explicitEventId: eventId
        )

        if result != nil {
            try await maybeAwardMilestones(for: actionType, receiverUserId: receiverUserId)
        }
        return result
    }

    func revokeXPForAction(
        receiverUserId: String,
        actorUserId: String,
        actionType: XPActionType,
        targetId: String
    ) async throws -> XPAwardResult? {
        guard clientAwardingEnabled else { return nil }
        let eventId = defaultEventID(
            actionType: actionType,
            receiverUserId: receiverUserId,
            actorUserId: actorUserId,
            targetId: targetId
        )

        let eventRef = firestore.collection(eventsCollection).document(eventId)
        let eventSnapshot = try await eventRef.getDocument()
        guard eventSnapshot.exists else { return nil }

        let currentProgress = try await getUserProgress(userId: receiverUserId)
        let xpToRevoke = getXPValueForAction(actionType)
        let nextTotalXP = max(0, currentProgress.totalXP - xpToRevoke)
        let nextLevel = XPLevelCalculator.levelFromXP(nextTotalXP)
        let nextTitle = XPLevelCalculator.getLevelTitle(level: nextLevel)

        let updated = UserProgress(
            userId: receiverUserId,
            totalXP: nextTotalXP,
            currentLevel: nextLevel,
            currentTitle: nextTitle,
            createdAt: currentProgress.createdAt,
            updatedAt: Date()
        )

        try await eventRef.delete()
        try firestore.collection(progressCollection).document(receiverUserId).setData(from: updated, merge: true)

        let progress = XPLevelCalculator.getLevelProgress(totalXP: nextTotalXP)
        return XPAwardResult(
            awardedXP: -xpToRevoke,
            totalXP: nextTotalXP,
            previousLevel: currentProgress.currentLevel,
            currentLevel: nextLevel,
            levelUp: false,
            currentTitle: nextTitle,
            xpNeededForNextLevel: progress.xpNeededForNextLevel
        )
    }

    // MARK: - Event ID / Caps

    func defaultEventID(
        actionType: XPActionType,
        receiverUserId: String,
        actorUserId: String,
        targetId: String
    ) -> String {
        switch actionType {
        case .likeReceived:
            return "LIKE_RECEIVED:\(actorUserId):\(targetId)"
        case .saveReceived:
            return "SAVE_RECEIVED:\(actorUserId):\(targetId)"
        case .recipeSaved:
            return "RECIPE_SAVED:\(actorUserId):\(targetId)"
        case .followerGained:
            return "FOLLOWER_GAINED:\(actorUserId):\(receiverUserId)"
        case .userFollowed:
            return "USER_FOLLOWED:\(actorUserId):\(targetId)"
        case .commentWritten:
            return "COMMENT_WRITTEN:\(actorUserId):\(targetId)"
        case .commentReceived:
            return "COMMENT_RECEIVED:\(actorUserId):\(targetId)"
        default:
            return "\(actionType.rawValue):\(actorUserId):\(targetId)"
        }
    }

    private func isActorDailyCappedAction(_ action: XPActionType) -> Bool {
        switch action {
        case .recipeSaved, .commentWritten, .userFollowed, .dailyQualifyingVisit:
            return true
        default:
            return false
        }
    }

    private func isSelfAwardBlocked(_ action: XPActionType) -> Bool {
        switch action {
        case .likeReceived, .saveReceived, .commentReceived, .followerGained:
            return true
        default:
            return false
        }
    }

    private func dailyCap(for action: XPActionType) -> Int {
        switch action {
        case .recipeSaved:
            return 20
        case .commentWritten:
            return 30
        case .userFollowed:
            return 10
        case .dailyQualifyingVisit:
            return 30
        default:
            return .max
        }
    }

    private func applyDailyCaps(
        actionType: XPActionType,
        receiverUserId: String,
        actorUserId: String,
        proposedXP: Int
    ) async throws -> Int {
        let cap = dailyCap(for: actionType)
        guard cap < .max else { return proposedXP }

        let (start, end) = dayBounds(for: Date())
        let snapshot = try await firestore.collection(eventsCollection)
            .whereField("actorUserId", isEqualTo: actorUserId)
            .getDocuments()

        let used = snapshot.documents.reduce(0) { partial, doc in
            let data = doc.data()
            guard (data["receiverUserId"] as? String) == receiverUserId else { return partial }
            guard (data["eventType"] as? String) == actionType.rawValue else { return partial }
            let createdAtDate: Date
            if let timestamp = data["createdAt"] as? Timestamp {
                createdAtDate = timestamp.dateValue()
            } else {
                return partial
            }
            guard createdAtDate >= start && createdAtDate < end else { return partial }
            return partial + (data["xpAmount"] as? Int ?? 0)
        }
        return max(0, min(proposedXP, cap - used))
    }

    private func applyRecipePublishDailyAdjustment(
        receiverUserId: String,
        actorUserId: String,
        proposedXP: Int
    ) async throws -> Int {
        let (start, end) = dayBounds(for: Date())
        let snapshot = try await firestore.collection(eventsCollection)
            .whereField("actorUserId", isEqualTo: actorUserId)
            .getDocuments()

        let publishedCountToday = snapshot.documents.filter { doc in
            let data = doc.data()
            guard (data["receiverUserId"] as? String) == receiverUserId else { return false }
            guard (data["eventType"] as? String) == XPActionType.recipePublished.rawValue else { return false }
            guard let timestamp = data["createdAt"] as? Timestamp else { return false }
            let createdAt = timestamp.dateValue()
            return createdAt >= start && createdAt < end
        }.count
        if publishedCountToday < 3 {
            return proposedXP
        }
        return Int((Double(proposedXP) * 0.25).rounded())
    }

    private func dayBounds(for date: Date) -> (Date, Date) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
        return (start, end)
    }

    // MARK: - Milestones

    private func maybeAwardMilestones(for actionType: XPActionType, receiverUserId: String) async throws {
        switch actionType {
        case .recipePublished:
            let recipeCount = try await fetchUserCounter(userId: receiverUserId, key: "recipeCount")
            if recipeCount >= 1 {
                _ = try await awardMilestone(.firstRecipePublished, receiverUserId: receiverUserId, suffix: "1")
            }
            if recipeCount >= 5 {
                _ = try await awardMilestone(.fiveRecipesPublished, receiverUserId: receiverUserId, suffix: "5")
            }
            if recipeCount >= 10 {
                _ = try await awardMilestone(.tenRecipesPublished, receiverUserId: receiverUserId, suffix: "10")
            }
        case .likeReceived:
            let likesCount = try await fetchUserCounter(userId: receiverUserId, key: "likesCount")
            if likesCount >= 1 {
                _ = try await awardMilestone(.firstLikeReceived, receiverUserId: receiverUserId, suffix: "1")
            }
            if likesCount >= 10 {
                _ = try await awardMilestone(.tenLikesReceived, receiverUserId: receiverUserId, suffix: "10")
            }
            if likesCount >= 50 {
                _ = try await awardMilestone(.fiftyLikesReceived, receiverUserId: receiverUserId, suffix: "50")
            }
            if likesCount >= 100 {
                _ = try await awardMilestone(.oneHundredLikesReceived, receiverUserId: receiverUserId, suffix: "100")
            }
        case .commentReceived:
            let commentCount = try await countReceivedEvents(
                receiverUserId: receiverUserId,
                eventType: .commentReceived
            )
            if commentCount >= 1 {
                _ = try await awardMilestone(.firstCommentReceived, receiverUserId: receiverUserId, suffix: "1")
            }
        case .followerGained:
            let followerCount = try await fetchUserCounter(userId: receiverUserId, key: "followerCount")
            if followerCount >= 1 {
                _ = try await awardMilestone(.firstFollowerGained, receiverUserId: receiverUserId, suffix: "1")
            }
            if followerCount >= 10 {
                _ = try await awardMilestone(.tenFollowersGained, receiverUserId: receiverUserId, suffix: "10")
            }
            if followerCount >= 100 {
                _ = try await awardMilestone(.oneHundredFollowersGained, receiverUserId: receiverUserId, suffix: "100")
            }
        default:
            break
        }
    }

    private func awardMilestone(
        _ milestone: XPActionType,
        receiverUserId: String,
        suffix: String
    ) async throws -> XPAwardResult? {
        let eventId = "MILESTONE:\(milestone.rawValue):\(receiverUserId):\(suffix)"
        return try await awardXP(
            receiverUserId: receiverUserId,
            actorUserId: systemActorID,
            eventType: milestone,
            targetId: receiverUserId,
            xpAmount: getXPValueForAction(milestone),
            metadata: nil,
            explicitEventId: eventId
        )
    }

    private func fetchUserCounter(userId: String, key: String) async throws -> Int {
        let doc = try await firestore.collection("users").document(userId).getDocument()
        return doc.data()?[key] as? Int ?? 0
    }

    private func countReceivedEvents(receiverUserId: String, eventType: XPActionType) async throws -> Int {
        let snapshot = try await firestore.collection(eventsCollection)
            .whereField("receiverUserId", isEqualTo: receiverUserId)
            .whereField("eventType", isEqualTo: eventType.rawValue)
            .getDocuments()
        return snapshot.documents.count
    }
}


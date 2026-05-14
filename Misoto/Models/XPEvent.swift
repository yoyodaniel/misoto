//
//  XPEvent.swift
//  Misoto
//

import Foundation
import FirebaseFirestore

struct XPEvent: Identifiable, Codable {
    var id: String { eventId }
    var eventId: String
    var receiverUserId: String
    var actorUserId: String
    var eventType: String
    var targetId: String
    var xpAmount: Int
    var createdAt: Date
    var metadata: [String: String]?

    init(
        eventId: String,
        receiverUserId: String,
        actorUserId: String,
        eventType: String,
        targetId: String,
        xpAmount: Int,
        createdAt: Date = Date(),
        metadata: [String: String]? = nil
    ) {
        self.eventId = eventId
        self.receiverUserId = receiverUserId
        self.actorUserId = actorUserId
        self.eventType = eventType
        self.targetId = targetId
        self.xpAmount = xpAmount
        self.createdAt = createdAt
        self.metadata = metadata
    }
}

struct XPAwardResult: Equatable {
    let awardedXP: Int
    let totalXP: Int
    let previousLevel: Int
    let currentLevel: Int
    let levelUp: Bool
    let currentTitle: String
    let xpNeededForNextLevel: Int
}


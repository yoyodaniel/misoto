//
//  UserProgress.swift
//  Misoto
//

import Foundation
import FirebaseFirestore

struct UserProgress: Identifiable, Codable {
    var id: String { userId }
    var userId: String
    var totalXP: Int
    var currentLevel: Int
    var currentTitle: String
    var createdAt: Date
    var updatedAt: Date

    init(
        userId: String,
        totalXP: Int = 0,
        currentLevel: Int = 1,
        currentTitle: String = XPLevelCalculator.getLevelTitle(level: 1),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.userId = userId
        self.totalXP = max(0, totalXP)
        self.currentLevel = max(1, currentLevel)
        self.currentTitle = currentTitle
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case userId
        case totalXP
        case currentLevel
        case currentTitle
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = try container.decode(String.self, forKey: .userId)
        totalXP = try container.decodeIfPresent(Int.self, forKey: .totalXP) ?? 0
        currentLevel = try container.decodeIfPresent(Int.self, forKey: .currentLevel) ?? 1
        currentTitle = try container.decodeIfPresent(String.self, forKey: .currentTitle) ?? XPLevelCalculator.getLevelTitle(level: currentLevel)
        createdAt = Self.decodeDate(container: container, key: .createdAt) ?? Date()
        updatedAt = Self.decodeDate(container: container, key: .updatedAt) ?? createdAt
    }

    private static func decodeDate(container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> Date? {
        if let timestamp = try? container.decodeIfPresent(Timestamp.self, forKey: key) {
            return timestamp.dateValue()
        }
        if let date = try? container.decodeIfPresent(Date.self, forKey: key) {
            return date
        }
        return nil
    }
}


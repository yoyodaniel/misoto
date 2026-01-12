//
//  Subscription.swift
//  Misoto
//
//  Subscription model for tracking user subscription status
//

import Foundation
import FirebaseFirestore

enum SubscriptionTier: String, Codable {
    case free = "free"
    case premium = "premium"
    
    var displayName: String {
        switch self {
        case .free:
            return LocalizedString("Free", comment: "Free tier")
        case .premium:
            return LocalizedString("Premium", comment: "Premium tier")
        }
    }
}

struct Subscription: Codable {
    var id: String // User ID
    var tier: SubscriptionTier
    var expiresAt: Date?
    var productID: String? // StoreKit product ID
    var transactionID: String? // Original transaction ID for restore
    var isActive: Bool
    var purchasedAt: Date?
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case tier
        case expiresAt
        case productID
        case transactionID
        case isActive
        case purchasedAt
        case updatedAt
    }
    
    init(
        id: String,
        tier: SubscriptionTier = .free,
        expiresAt: Date? = nil,
        productID: String? = nil,
        transactionID: String? = nil,
        isActive: Bool = true,
        purchasedAt: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.tier = tier
        self.expiresAt = expiresAt
        self.productID = productID
        self.transactionID = transactionID
        self.isActive = isActive
        self.purchasedAt = purchasedAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        tier = try container.decode(SubscriptionTier.self, forKey: .tier)
        
        // Handle Date/Timestamp conversion for Firestore
        if let timestamp = try? container.decodeIfPresent(Timestamp.self, forKey: .expiresAt) {
            expiresAt = timestamp.dateValue()
        } else {
            expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        }
        
        productID = try container.decodeIfPresent(String.self, forKey: .productID)
        transactionID = try container.decodeIfPresent(String.self, forKey: .transactionID)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        
        if let timestamp = try? container.decodeIfPresent(Timestamp.self, forKey: .purchasedAt) {
            purchasedAt = timestamp.dateValue()
        } else {
            purchasedAt = try container.decodeIfPresent(Date.self, forKey: .purchasedAt)
        }
        
        if let timestamp = try? container.decodeIfPresent(Timestamp.self, forKey: .updatedAt) {
            updatedAt = timestamp.dateValue()
        } else {
            updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(tier, forKey: .tier)
        try container.encodeIfPresent(productID, forKey: .productID)
        try container.encodeIfPresent(transactionID, forKey: .transactionID)
        try container.encode(isActive, forKey: .isActive)
        
        // Convert Dates to Timestamps for Firestore
        if let expiresAt = expiresAt {
            try container.encode(Timestamp(date: expiresAt), forKey: .expiresAt)
        }
        if let purchasedAt = purchasedAt {
            try container.encode(Timestamp(date: purchasedAt), forKey: .purchasedAt)
        }
        try container.encode(Timestamp(date: updatedAt), forKey: .updatedAt)
    }
    
    /// Check if subscription is currently valid (not expired)
    var isValid: Bool {
        guard isActive else { return false }
        guard tier != .free else { return true } // Free tier is always valid
        guard let expiresAt = expiresAt else { return false }
        return expiresAt > Date()
    }
    
    /// Check if user has premium access
    var hasPremium: Bool {
        return tier == .premium && isValid
    }
}


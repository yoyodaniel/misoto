//
//  SubscriptionBackendSync.swift
//  Misoto
//
//  Syncs subscription state via Cloud Functions (Firestore rules block client writes).
//

import FirebaseAuth
import FirebaseFunctions
import Foundation

enum SubscriptionBackendSync {
    private static let region = "us-central1"

    private static var functions: Functions {
        Functions.functions(region: region)
    }

    static func ensureSubscriptionRecord() async throws {
        guard Auth.auth().currentUser != nil else {
            throw SubscriptionError.unauthorized
        }
        _ = try await functions.httpsCallable("ensureSubscriptionRecord").call([:])
    }

    static func syncSubscription(_ subscription: Subscription) async throws {
        guard Auth.auth().currentUser != nil else {
            throw SubscriptionError.unauthorized
        }

        var payload: [String: Any] = [
            "tier": subscription.tier.rawValue,
        ]

        if subscription.tier == .premium {
            guard let productID = subscription.productID,
                  let transactionID = subscription.transactionID else {
                throw SubscriptionError.unverified
            }
            payload["productID"] = productID
            payload["transactionID"] = transactionID
        }

        _ = try await functions.httpsCallable("syncPremiumSubscription").call(payload)
    }
}

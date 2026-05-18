//
//  SubscriptionService.swift
//  Misoto
//
//  Service for managing subscriptions using StoreKit
//

import Foundation
import StoreKit
import FirebaseFirestore
import FirebaseAuth
import Combine
import OSLog

@MainActor
class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    private let firestore = FirebaseManager.shared.firestore
    private let subscriptionsCollection = "subscriptions"
    
    // StoreKit product IDs (will be set up in App Store Connect)
    static let premiumMonthlyProductID = "com.misoto.premium.monthly"
    static let premiumYearlyProductID = "com.misoto.premium.yearly"
    
    @Published var subscription: Subscription?
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Load subscription status
        Task {
            await loadSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let productIDs = [
                SubscriptionService.premiumMonthlyProductID,
                SubscriptionService.premiumYearlyProductID
            ]
            
            let storeProducts = try await Product.products(for: productIDs)
            products = storeProducts.sorted { $0.price < $1.price }
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            print("❌ Error loading products: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Purchase Subscription
    
    func purchase(_ product: Product) async throws {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw SubscriptionError.unauthorized
        }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            // Update subscription in Firestore
            if let expirationDate = transaction.expirationDate {
                await updateSubscription(
                    userID: userID,
                    productID: product.id,
                    transactionID: String(transaction.id),
                    expiresAt: expirationDate
                )
            }
            // Finish the transaction
            await transaction.finish()
        case .userCancelled:
            throw SubscriptionError.userCancelled
        case .pending:
            throw SubscriptionError.pending
        @unknown default:
            throw SubscriptionError.unknown
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async throws {
        guard Auth.auth().currentUser?.uid != nil else {
            throw SubscriptionError.unauthorized
        }
        
        try await AppStore.sync()
        await loadSubscriptionStatus()
    }
    
    // MARK: - Check Subscription Status
    
    func loadSubscriptionStatus() async {
        guard let userID = Auth.auth().currentUser?.uid else {
            subscription = nil
            return
        }
        
        do {
            let document = try await firestore.collection(subscriptionsCollection).document(userID).getDocument()
            
            if let sub = try? document.data(as: Subscription.self) {
                subscription = sub
            } else {
                try await SubscriptionBackendSync.ensureSubscriptionRecord()
                let refreshed = try await firestore.collection(subscriptionsCollection).document(userID).getDocument()
                if let sub = try? refreshed.data(as: Subscription.self) {
                    subscription = sub
                } else {
                    subscription = Subscription(id: userID, tier: .free)
                }
            }
            
            // Also verify with StoreKit
            await verifyStoreKitSubscription()
            
        } catch {
            print("⚠️ Error loading subscription: \(error.localizedDescription)")
            subscription = Subscription(id: userID, tier: .free)
        }
    }
    
    private func verifyStoreKitSubscription() async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        var latestTransaction: StoreKit.Transaction?
        var latestExpirationDate: Date?
        
        // Check all subscription statuses
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productID == SubscriptionService.premiumMonthlyProductID ||
                   transaction.productID == SubscriptionService.premiumYearlyProductID {
                    if let expiration = transaction.expirationDate {
                        if latestExpirationDate == nil || expiration > latestExpirationDate! {
                            latestExpirationDate = expiration
                            latestTransaction = transaction
                        }
                    }
                }
            } catch {
                print("⚠️ Error verifying transaction: \(error.localizedDescription)")
            }
        }
        
        // Update subscription if we found a valid transaction
        if let transaction = latestTransaction,
           let expiresAt = latestExpirationDate,
           expiresAt > Date() {
            await updateSubscription(
                userID: userID,
                productID: transaction.productID,
                transactionID: String(transaction.id),
                expiresAt: expiresAt
            )
        }
    }
    
    // MARK: - Check Premium Access
    
    var hasPremium: Bool {
        return subscription?.hasPremium ?? false
    }
    
    // MARK: - Private Helpers
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            let log = Logger(subsystem: "com.miniadd.Misoto", category: "SubscriptionTransactions")
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateSubscriptionFromTransaction(transaction)
                    await transaction.finish()
                } catch {
                    log.error("Transaction verification failed: \(error.localizedDescription, privacy: .public)")
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.unverified
        case .verified(let safe):
            return safe
        }
    }
    
    private func updateSubscriptionFromTransaction(_ transaction: StoreKit.Transaction) async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        if let expirationDate = transaction.expirationDate {
            await updateSubscription(
                userID: userID,
                productID: transaction.productID,
                transactionID: String(transaction.id),
                expiresAt: expirationDate
            )
        }
    }
    
    private func updateSubscription(
        userID: String,
        productID: String,
        transactionID: String,
        expiresAt: Date
    ) async {
        let sub = Subscription(
            id: userID,
            tier: .premium,
            expiresAt: expiresAt,
            productID: productID,
            transactionID: transactionID,
            isActive: true,
            purchasedAt: Date(),
            updatedAt: Date()
        )
        
        do {
            try await SubscriptionBackendSync.syncSubscription(sub)
            subscription = sub
            print("✅ Subscription updated: Premium until \(expiresAt)")
        } catch {
            print("❌ Error updating subscription: \(error.localizedDescription)")
        }
    }
}

// MARK: - Errors

enum SubscriptionError: LocalizedError {
    case unauthorized
    case userCancelled
    case pending
    case unverified
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return LocalizedString("You must be signed in to purchase a subscription", comment: "Subscription error")
        case .userCancelled:
            return LocalizedString("Purchase was cancelled", comment: "Subscription error")
        case .pending:
            return LocalizedString("Purchase is pending", comment: "Subscription error")
        case .unverified:
            return LocalizedString("Transaction could not be verified", comment: "Subscription error")
        case .unknown:
            return LocalizedString("An unknown error occurred", comment: "Subscription error")
        }
    }
}


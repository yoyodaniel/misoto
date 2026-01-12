//
//  SubscriptionViewModel.swift
//  Misoto
//
//  ViewModel for managing subscription UI state
//

import Foundation
import Combine
import StoreKit

@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var subscription: Subscription?
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var isLoadingProducts = false
    @Published var errorMessage: String?
    @Published var recipeCountThisMonth = 0
    @Published var aiDescriptionCountThisMonth = 0
    @Published var aiImageExtractionCountThisMonth = 0
    
    private let subscriptionService = SubscriptionService.shared
    private let usageService = UsageTrackingService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Observe subscription service state
        subscriptionService.$subscription
            .assign(to: \.subscription, on: self)
            .store(in: &cancellables)
        
        subscriptionService.$products
            .assign(to: \.products, on: self)
            .store(in: &cancellables)
        
        subscriptionService.$isLoading
            .assign(to: \.isLoadingProducts, on: self)
            .store(in: &cancellables)
    }
    
    var hasPremium: Bool {
        return subscription?.hasPremium ?? false
    }
    
    var subscriptionTier: SubscriptionTier {
        return subscription?.tier ?? .free
    }
    
    // MARK: - Load Data
    
    func loadData() async {
        await subscriptionService.loadSubscriptionStatus()
        await loadUsageCounts()
        await subscriptionService.loadProducts()
    }
    
    func loadUsageCounts() async {
        do {
            recipeCountThisMonth = try await usageService.getRecipeCountThisMonth()
            aiDescriptionCountThisMonth = try await usageService.getAIDescriptionCountThisMonth()
            aiImageExtractionCountThisMonth = try await usageService.getAIImageExtractionCountThisMonth()
        } catch {
            print("⚠️ Error loading usage counts: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await subscriptionService.purchase(product)
            await subscriptionService.loadSubscriptionStatus()
            await loadUsageCounts()
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Purchase error: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Restore
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await subscriptionService.restorePurchases()
            await loadUsageCounts()
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Restore error: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Usage Limits
    
    var canCreateRecipe: Bool {
        if hasPremium { return true }
        return recipeCountThisMonth < FreeTierLimits.maxRecipesPerMonth
    }
    
    var canGenerateAIDescription: Bool {
        if hasPremium { return true }
        return aiDescriptionCountThisMonth < FreeTierLimits.maxAIDescriptionsPerMonth
    }
    
    var canExtractAIImage: Bool {
        if hasPremium { return true }
        return aiImageExtractionCountThisMonth < FreeTierLimits.maxAIImageExtractionsPerMonth
    }
    
    var recipesRemaining: Int {
        if hasPremium { return -1 } // Unlimited
        return max(0, FreeTierLimits.maxRecipesPerMonth - recipeCountThisMonth)
    }
    
    var aiDescriptionsRemaining: Int {
        if hasPremium { return -1 } // Unlimited
        return max(0, FreeTierLimits.maxAIDescriptionsPerMonth - aiDescriptionCountThisMonth)
    }
    
    var aiImageExtractionsRemaining: Int {
        if hasPremium { return -1 } // Unlimited
        return max(0, FreeTierLimits.maxAIImageExtractionsPerMonth - aiImageExtractionCountThisMonth)
    }
}


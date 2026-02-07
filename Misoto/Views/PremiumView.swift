//
//  PremiumView.swift
//  Misoto
//
//  View for Premium subscription purchase
//

import SwiftUI
import StoreKit

struct PremiumView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProduct: Product?
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    
    // MARK: - Computed Properties
    
    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var horizontalPadding: CGFloat {
        isPad ? 60 : 20
    }
    
    private var contentHorizontalPadding: CGFloat {
        isPad ? 40 : 60
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundView
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 40)
                        
                        headerSection
                        subscriptionCardsSection
                        descriptionText
                        purchaseButtonSection
                        errorMessageSection
                        restoreButton
                        footerLinksSection
                    }
                }
            }
            .navigationTitle(LocalizedString("Premium Subscription", comment: "Premium Subscription navigation title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedString("Done", comment: "Done button")) {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadData()
                // Auto-select yearly if available (better value)
                if let yearly = viewModel.products.first(where: { $0.id.contains("yearly") }) {
                    selectedProduct = yearly
                } else if let first = viewModel.products.first {
                    selectedProduct = first
                }
            }
            .alert(LocalizedString("Restore Purchases", comment: "Restore alert title"), isPresented: $showRestoreAlert) {
                Button(LocalizedString("OK", comment: "OK button")) { }
            } message: {
                Text(restoreMessage)
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showTermsOfService) {
                TermsOfServiceView()
            }
        }
    }
    
    // MARK: - View Components
    
    private var backgroundView: some View {
        ZStack {
            // Background Image
            Image("misoto")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .offset(x: -15)
                .ignoresSafeArea()
            
            // Gradient Overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.6),
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.5),
                    Color.black.opacity(0.7)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text(LocalizedString("Discover more. Cook smarter.", comment: "Premium main title"))
                .font(.system(size: isPad ? 36 : 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, horizontalPadding)
            
            Text(LocalizedString("Unlimited access to all recipes and AI features", comment: "Premium subtitle"))
                .font(.system(size: isPad ? 20 : 18, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .padding(.horizontal, horizontalPadding)
        }
        .padding(.bottom, isPad ? 32 : 24)
        .padding(.horizontal, contentHorizontalPadding)
    }
    
    @ViewBuilder
    private var subscriptionCardsSection: some View {
        if !viewModel.products.isEmpty {
            if isPad {
                let columns = [
                    GridItem(.flexible(minimum: 200), spacing: 16),
                    GridItem(.flexible(minimum: 200), spacing: 16)
                ]
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(viewModel.products, id: \.id) { product in
                        SubscriptionCardView(
                            product: product,
                            isSelected: selectedProduct?.id == product.id,
                            onSelect: { selectedProduct = product }
                        )
                    }
                }
                .padding(.horizontal, contentHorizontalPadding)
                .padding(.bottom, 24)
            } else {
                HStack(spacing: 12) {
                    ForEach(viewModel.products, id: \.id) { product in
                        SubscriptionCardView(
                            product: product,
                            isSelected: selectedProduct?.id == product.id,
                            onSelect: { selectedProduct = product }
                        )
                    }
                }
                .padding(.horizontal, contentHorizontalPadding)
                .padding(.bottom, 24)
            }
        }
    }
    
    private var descriptionText: some View {
        Text(LocalizedString("Unlock unlimited recipes and AI-powered features to create, share, and discover amazing dishes.", comment: "Premium description"))
            .font(.system(size: 15))
            .foregroundColor(.white.opacity(0.9))
            .multilineTextAlignment(.center)
            .padding(.horizontal, contentHorizontalPadding)
            .padding(.bottom, 24)
    }
    
    @ViewBuilder
    private var purchaseButtonSection: some View {
        if let selectedProduct = selectedProduct {
            Button(action: {
                Task {
                    await viewModel.purchase(selectedProduct)
                    if viewModel.hasPremium {
                        dismiss()
                    }
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(LocalizedString("Subscribe", comment: "Subscribe button"))
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(14)
            }
            .disabled(viewModel.isLoading)
            .padding(.horizontal, contentHorizontalPadding)
            .padding(.bottom, 16)
        }
    }
    
    @ViewBuilder
    private var errorMessageSection: some View {
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .padding()
                .background(Color.red.opacity(0.8))
                .cornerRadius(8)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
    }
    
    private var restoreButton: some View {
        Button(action: {
            Task {
                await viewModel.restorePurchases()
                if viewModel.hasPremium {
                    restoreMessage = LocalizedString("Purchases restored successfully!", comment: "Restore success")
                    showRestoreAlert = true
                    dismiss()
                } else {
                    restoreMessage = LocalizedString("No purchases found to restore", comment: "Restore no purchases")
                    showRestoreAlert = true
                }
            }
        }) {
            Text(LocalizedString("Restore Purchases", comment: "Restore purchases button"))
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
        .padding(.bottom, 24)
    }
    
    private var footerLinksSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button(action: {
                    showPrivacyPolicy = true
                }) {
                    Text(LocalizedString("Privacy Policy", comment: "Privacy Policy link"))
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .underline()
                }
                
                Text("•")
                    .foregroundColor(.white.opacity(0.6))
                
                Button(action: {
                    showTermsOfService = true
                }) {
                    Text(LocalizedString("Terms of Use", comment: "Terms of Use link"))
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .underline()
                }
            }
            
            Text(LocalizedString("Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period.", comment: "Subscription terms"))
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text(LocalizedString("Manage subscriptions in Settings", comment: "Manage subscriptions"))
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                    .underline()
            }
        }
        .padding(.horizontal, contentHorizontalPadding)
        .padding(.bottom, 40)
    }
    
    // MARK: - Helper Methods
}

struct SubscriptionCardView: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var isYearly: Bool {
        product.id.contains("yearly")
    }
    
    private var subscriptionPeriod: String {
        guard let subscription = product.subscription else {
            return ""
        }
        return SubscriptionCardView.formatSubscriptionPeriod(subscription.subscriptionPeriod)
    }
    
    /// Format subscription period text for display
    static func formatSubscriptionPeriod(_ period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day:
            return period.value == 1 
                ? LocalizedString("1 day", comment: "1 day subscription")
                : String(format: LocalizedString("%d days", comment: "Multiple days subscription"), period.value)
        case .week:
            return period.value == 1
                ? LocalizedString("1 week", comment: "1 week subscription")
                : String(format: LocalizedString("%d weeks", comment: "Multiple weeks subscription"), period.value)
        case .month:
            return period.value == 1
                ? LocalizedString("1 month", comment: "1 month subscription")
                : String(format: LocalizedString("%d months", comment: "Multiple months subscription"), period.value)
        case .year:
            return period.value == 1
                ? LocalizedString("1 year", comment: "1 year subscription")
                : String(format: LocalizedString("%d years", comment: "Multiple years subscription"), period.value)
        @unknown default:
            return LocalizedString("Subscription", comment: "Unknown subscription period")
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Title - Allow full text to display without truncation
                Text(product.displayName)
                    .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 18 : 15, weight: .bold))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(nil) // Allow multiple lines
                    .fixedSize(horizontal: false, vertical: true) // Allow text to wrap
                    .multilineTextAlignment(.leading)
                
                // Subscription Duration
                if !subscriptionPeriod.isEmpty {
                    Text(subscriptionPeriod)
                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 15 : 13))
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                }
                
                // Subtitle
                Text(isYearly ? LocalizedString("Best Value", comment: "Yearly best value") : LocalizedString("Monthly", comment: "Monthly"))
                    .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 15 : 14))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                
                Spacer()
                
                // Price
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 28 : 24, weight: .bold))
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    if isYearly {
                        Text(LocalizedString("Save 17%", comment: "Yearly discount"))
                            .font(.system(size: UIDevice.current.userInterfaceIdiom == .pad ? 13 : 12, weight: .semibold))
                            .foregroundColor(isSelected ? .white.opacity(0.9) : .green)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: UIDevice.current.userInterfaceIdiom == .pad ? 240 : 180) // Use minHeight to allow content to expand
            .padding(UIDevice.current.userInterfaceIdiom == .pad ? 24 : 20)
            .background(
                isSelected
                    ? LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color(.systemBackground), Color(.systemGray6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 0 : 1)
            )
            .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.05), radius: isSelected ? 8 : 2, x: 0, y: isSelected ? 4 : 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PremiumView()
}


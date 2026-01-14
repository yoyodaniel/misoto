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
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Image
                Image("misoto")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .offset(x: -15) // Match login screen positioning
                    .ignoresSafeArea()
                
                // Gradient Overlay for Text Readability
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.6), // Darker at top for better text visibility
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.5),
                        Color.black.opacity(0.7) // Darker at bottom too
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 40) // Reduced from 80pt to move content up
                        
                        // Header Text
                        VStack(spacing: 12) {
                            // Main Title
                            Text(LocalizedString("Discover more. Cook smarter.", comment: "Premium main title"))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 60) // Same padding as cards
                            
                            // Subtitle
                            Text(LocalizedString("Unlimited access to all recipes and AI features", comment: "Premium subtitle"))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.95))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 60) // Same padding as cards
                        }
                        .padding(.bottom, 32)
                    
                    // Subscription Cards (Horizontal Layout)
                    if !viewModel.products.isEmpty {
                        HStack(spacing: 12) {
                            ForEach(viewModel.products, id: \.id) { product in
                                SubscriptionCardView(
                                    product: product,
                                    isSelected: selectedProduct?.id == product.id,
                                    onSelect: { selectedProduct = product }
                                )
                            }
                        }
                        .padding(.horizontal, 60)
                        .padding(.bottom, 24)
                    }
                    
                    // Description Text
                    Text(LocalizedString("Unlock unlimited recipes and AI-powered features to create, share, and discover amazing dishes.", comment: "Premium description"))
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 60)
                        .padding(.bottom, 32)
                    
                    // Purchase Button
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
                        .padding(.horizontal, 60)
                        .padding(.bottom, 16)
                    }
                    
                    // Error Message
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
                    
                    // Restore Purchases
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
                    
                    // Terms and Privacy
                    VStack(spacing: 8) {
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
                    .padding(.horizontal, 60)
                    .padding(.bottom, 40)
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
        }
    }
}

struct SubscriptionCardView: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var isYearly: Bool {
        product.id.contains("yearly")
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Title
                Text(product.displayName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                
                // Subtitle
                Text(isYearly ? LocalizedString("Best Value", comment: "Yearly best value") : LocalizedString("Monthly", comment: "Monthly"))
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                
                Spacer()
                
                // Price
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    if isYearly {
                        Text(LocalizedString("Save 17%", comment: "Yearly discount"))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(isSelected ? .white.opacity(0.9) : .green)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .padding(20)
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


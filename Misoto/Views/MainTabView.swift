//
//  MainTabView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import UIKit
import FirebaseAuth

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var subscriptionViewModel = SubscriptionViewModel()
    @State private var showUploadRecipe = false
    @State private var showExtractFromImage = false
    @State private var showExtractFromLink = false
    @State private var showExtractFromWebsite = false
    @State private var showAddMenuOptions = false
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var imageForExtraction: UIImage?
    @State private var pendingExtractionImage: UIImage? // Image waiting to be shown in extract view
    @State private var showLoginSheet = false
    @State private var selectedTab = 0
    @State private var showRecipeLimitAlert = false
    @State private var showAIExtractionLimitAlert = false
    @State private var showPremium = false
    
    private var nextResetDateString: String {
        let calendar = Calendar.current
        let today = Date()
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: today) ?? today
        var components = calendar.dateComponents([.year, .month], from: nextMonth)
        components.day = 1
        let nextMonthFirst = calendar.date(from: components) ?? today
        
        let dateFormatter = DateFormatter()
        
        // Get locale based on current language setting
        let currentLanguage = LocalizationManager.shared.currentLanguage
        let localeIdentifier: String
        
        switch currentLanguage {
        case .english:
            localeIdentifier = "en_US"
            dateFormatter.dateFormat = "dd MMM yyyy"
        case .system:
            localeIdentifier = Locale.current.identifier
            dateFormatter.dateFormat = "dd MMM yyyy"
        case .spanish:
            localeIdentifier = "es_ES"
            dateFormatter.dateFormat = "dd MMM yyyy"
        case .french:
            localeIdentifier = "fr_FR"
            dateFormatter.dateFormat = "dd MMM yyyy"
        case .german:
            localeIdentifier = "de_DE"
            dateFormatter.dateFormat = "dd MMM yyyy"
        case .italian:
            localeIdentifier = "it_IT"
            dateFormatter.dateFormat = "dd MMM yyyy"
        case .portuguese:
            localeIdentifier = "pt_PT"
            dateFormatter.dateFormat = "dd MMM yyyy"
        case .dutch:
            localeIdentifier = "nl_NL"
            dateFormatter.dateFormat = "dd MMM yyyy"
        case .russian:
            localeIdentifier = "ru_RU"
            dateFormatter.dateFormat = "dd MMM yyyy"
        case .japanese:
            localeIdentifier = "ja_JP"
            dateFormatter.dateFormat = "yyyy年M月d日"
        case .korean:
            localeIdentifier = "ko_KR"
            dateFormatter.dateFormat = "yyyy년 M월 d일"
        case .thai:
            localeIdentifier = "th_TH"
            dateFormatter.dateFormat = "d MMM yyyy"
        case .vietnamese:
            localeIdentifier = "vi_VN"
            dateFormatter.dateFormat = "dd MMM yyyy"
        case .indonesian:
            localeIdentifier = "id_ID"
            dateFormatter.dateFormat = "dd MMM yyyy"
        case .malay:
            localeIdentifier = "ms_MY"
            dateFormatter.dateFormat = "dd MMM yyyy"
        case .filipino:
            localeIdentifier = "fil_PH"
            dateFormatter.dateFormat = "dd MMM yyyy"
        case .hindi:
            localeIdentifier = "hi_IN"
            dateFormatter.dateFormat = "dd MMM yyyy"
        case .chineseSimplified:
            localeIdentifier = "zh_Hans_CN"
            dateFormatter.dateFormat = "yyyy年M月d日"
        case .chineseTraditional:
            localeIdentifier = "zh_Hant_TW"
            dateFormatter.dateFormat = "yyyy年M月d日"
        case .arabic:
            localeIdentifier = "ar_SA"
            dateFormatter.dateFormat = "dd MMM yyyy"
        case .hebrew:
            localeIdentifier = "he_IL"
            dateFormatter.dateFormat = "dd MMM yyyy"
        }
        
        dateFormatter.locale = Locale(identifier: localeIdentifier)
        return dateFormatter.string(from: nextMonthFirst)
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                ExploreView(showLoginSheet: $showLoginSheet)
                    .tabItem {
                        Label(LocalizedString("Explore", comment: "Explore tab"), systemImage: "menucard.fill")
                    }
                    .tag(0)
                
                AccountView(showLoginSheet: $showLoginSheet)
                    .tabItem {
                        Label(LocalizedString("Account", comment: "Account tab"), systemImage: "person.fill")
                    }
                    .tag(1)
            }
            .onChange(of: selectedTab) { _, newTab in
                // If user taps Account tab and is not authenticated, show login sheet
                if newTab == 1 && !authViewModel.isAuthenticated {
                    showLoginSheet = true
                    // Reset to Explore tab after showing login
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        selectedTab = 0
                    }
                }
            }
            
            // Floating Upload Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        HapticFeedback.buttonTap()
                        // Check authentication before showing add menu options
                        if Auth.auth().currentUser != nil {
                            showAddMenuOptions = true
                        } else {
                            showLoginSheet = true
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .offset(y: -40)
                    .padding(.trailing, 20)
                }
            }
        }
        .confirmationDialog(
            LocalizedString("Add Recipe", comment: "Add recipe dialog title"),
            isPresented: $showAddMenuOptions,
            titleVisibility: .visible
        ) {
            Button(LocalizedString("Manual Entry", comment: "Manual entry option")) {
                if Auth.auth().currentUser != nil {
                    Task {
                        await subscriptionViewModel.loadUsageCounts()
                        if !subscriptionViewModel.canCreateRecipe {
                            showRecipeLimitAlert = true
                        } else {
                            showUploadRecipe = true
                        }
                    }
                } else {
                    showLoginSheet = true
                }
            }
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(LocalizedString("Take Picture", comment: "Take picture option")) {
                    if Auth.auth().currentUser != nil {
                        Task {
                            await subscriptionViewModel.loadUsageCounts()
                            // Check AI extraction limit for extraction-based methods
                            if !subscriptionViewModel.canExtractAIImage {
                                showAIExtractionLimitAlert = true
                            } else if !subscriptionViewModel.canCreateRecipe {
                                showRecipeLimitAlert = true
                            } else {
                                showCamera = true
                            }
                        }
                    } else {
                        showLoginSheet = true
                    }
                }
            }
            
            Button(LocalizedString("Extract from Image", comment: "Extract from image option")) {
                if Auth.auth().currentUser != nil {
                    Task {
                        await subscriptionViewModel.loadUsageCounts()
                        // Check AI extraction limit for extraction-based methods
                        if !subscriptionViewModel.canExtractAIImage {
                            showAIExtractionLimitAlert = true
                        } else if !subscriptionViewModel.canCreateRecipe {
                            showRecipeLimitAlert = true
                        } else {
                            // Clear any pending image when manually selecting extract from image
                            pendingExtractionImage = nil
                            showExtractFromImage = true
                        }
                    }
                } else {
                    showLoginSheet = true
                }
            }
            
            Button(LocalizedString("Extract from Link", comment: "Extract from link option")) {
                if Auth.auth().currentUser != nil {
                    Task {
                        await subscriptionViewModel.loadUsageCounts()
                        // Check AI extraction limit for extraction-based methods
                        if !subscriptionViewModel.canExtractAIImage {
                            showAIExtractionLimitAlert = true
                        } else if !subscriptionViewModel.canCreateRecipe {
                            showRecipeLimitAlert = true
                        } else {
                            showExtractFromLink = true
                        }
                    }
                } else {
                    showLoginSheet = true
                }
            }
            
            Button(LocalizedString("Extract from Website", comment: "Extract from website option")) {
                if Auth.auth().currentUser != nil {
                    Task {
                        await subscriptionViewModel.loadUsageCounts()
                        // Check AI extraction limit for extraction-based methods
                        if !subscriptionViewModel.canExtractAIImage {
                            showAIExtractionLimitAlert = true
                        } else if !subscriptionViewModel.canCreateRecipe {
                            showRecipeLimitAlert = true
                        } else {
                            showExtractFromWebsite = true
                        }
                    }
                } else {
                    showLoginSheet = true
                }
            }
            
            Button(LocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {}
        }
        .alert(LocalizedString("Recipe Limit Reached", comment: "Recipe limit alert title"), isPresented: $showRecipeLimitAlert) {
            Button(LocalizedString("OK", comment: "OK button")) {
                showRecipeLimitAlert = false
            }
            Button(LocalizedString("Upgrade Now", comment: "Upgrade now button")) {
                showRecipeLimitAlert = false
                showPremium = true
            }
        } message: {
            Text(LocalizedString("You have reached the free tier limit", comment: "Recipe limit error"))
        }
        .alert(LocalizedString("AI Extraction Limit Reached", comment: "AI extraction limit alert title"), isPresented: $showAIExtractionLimitAlert) {
            Button(LocalizedString("OK", comment: "OK button")) {
                showAIExtractionLimitAlert = false
            }
            Button(LocalizedString("Upgrade Now", comment: "Upgrade now button")) {
                showAIExtractionLimitAlert = false
                showPremium = true
            }
        } message: {
            Text(LocalizedString("You have reached your free tier limit for AI image extractions", comment: "AI image extraction limit error") + "\n\n" + String(format: LocalizedString("Your free allowance will reset on %@", comment: "Reset date info"), nextResetDateString))
        }
        .sheet(isPresented: $showLoginSheet) {
            LoginView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showUploadRecipe) {
            UploadRecipeView()
        }
        .fullScreenCover(isPresented: $showExtractFromImage) {
            // Use pendingExtractionImage if available (from camera), otherwise use imageForExtraction (from manual selection)
            ExtractMenuFromImageView(initialImage: pendingExtractionImage ?? imageForExtraction)
                .onDisappear {
                    // Clear images when view is dismissed
                    capturedImage = nil
                    imageForExtraction = nil
                    pendingExtractionImage = nil
                }
        }
        .sheet(isPresented: $showExtractFromLink) {
            ExtractMenuFromLinkView()
        }
        .sheet(isPresented: $showExtractFromWebsite) {
            ExtractMenuFromWebsiteView()
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView { image in
                // Store the image in both variables
                // pendingExtractionImage is used specifically for the extract view
                // This ensures the image is available when the view is created
                imageForExtraction = image
                capturedImage = image
                pendingExtractionImage = image
                
                // Dismiss camera first
                showCamera = false
                
                // Use a small delay to ensure camera fully dismisses and state is updated
                // before showing extract view
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
                    // Verify image is still set before showing extract view
                    if pendingExtractionImage != nil {
                        showExtractFromImage = true
                    }
                }
            }
            .ignoresSafeArea(.all)
        }
        .sheet(isPresented: $showPremium) {
            PremiumView()
                .environmentObject(subscriptionViewModel)
        }
        .task {
            // Load subscription data when view appears
            await subscriptionViewModel.loadData()
        }
    }
}

#Preview {
    MainTabView()
}

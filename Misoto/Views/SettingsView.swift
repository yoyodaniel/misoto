//
//  SettingsView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showFeedbackSheet = false
    @State private var feedbackName = ""
    @State private var feedbackSubtitle = ""
    @State private var feedbackEmail = ""
    @State private var showShareSheet = false
    @State private var showSignOutConfirmation = false
    @State private var showEditProfile = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showReAuthenticate = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var showPremium = false
    @State private var deleteAccountError: String?
    @StateObject private var accountViewModel = AccountViewModel()
    @StateObject private var subscriptionViewModel = SubscriptionViewModel()
    private let authService = AuthService()
    
    // Section expansion states
    @State private var isAppearanceExpanded = true
    @State private var isLanguageExpanded = true
    @State private var isSubscriptionExpanded = true
    @State private var isShareExpanded = true
    @State private var isFeedbackExpanded = true
    @State private var isPrivacyTermsExpanded = true
    @State private var isAccountExpanded = false // Collapsed by default
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Appearance Section
                Section {
                    DisclosureGroup(isExpanded: $isAppearanceExpanded) {
                        Toggle(isOn: $appSettings.isDarkModeEnabled) {
                            HStack {
                                Image(systemName: "moon.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text(LocalizedString("Dark Mode", comment: "Dark mode setting"))
                            }
                        }
                        .onChange(of: appSettings.isDarkModeEnabled) {
                            HapticFeedback.buttonTap()
                        }
                        
                        Toggle(isOn: $appSettings.isHapticFeedbackEnabled) {
                            HStack {
                                Image(systemName: "hand.tap.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text(LocalizedString("Haptic Feedback", comment: "Haptic feedback setting"))
                            }
                        }
                        .onChange(of: appSettings.isHapticFeedbackEnabled) {
                            // Play haptic when toggling (if it was enabled)
                            if appSettings.isHapticFeedbackEnabled {
                                HapticFeedback.play(.medium)
                            }
                        }
                    } label: {
                        Text(LocalizedString("Appearance", comment: "Appearance section header"))
                            .font(.headline)
                    }
                }
                
                // MARK: - Language Section
                Section {
                    DisclosureGroup(isExpanded: $isLanguageExpanded) {
                        // Only show English and System Language for now
                        // Other languages are commented out but code is preserved
                        ForEach(AppLanguage.availableLanguages, id: \.self) { language in
                            Button(action: {
                                HapticFeedback.play(.selection)
                                Task {
                                    await viewModel.selectLanguage(language)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "globe")
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    HStack(spacing: 4) {
                                        Text(language.displayName)
                                        if language == .system {
                                            Text("(BETA)")
                                                .font(.caption)
                                                .italic()
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if viewModel.isChangingLanguage && viewModel.pendingLanguage == language {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else if !viewModel.isChangingLanguage && viewModel.selectedLanguage == language {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                            .disabled(viewModel.isChangingLanguage)
                        }
                    } label: {
                        Text(LocalizedString("Language", comment: "Language section header"))
                            .font(.headline)
                    }
                } footer: {
                    if isLanguageExpanded {
                        Text(LocalizedString("The language selected will be used as the default writing language for recipe extractions.", comment: "Language selection footnote"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Subscription Section
                Section {
                    DisclosureGroup(isExpanded: $isSubscriptionExpanded) {
                        // Account Type Row
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 16))
                                    Text(LocalizedString("Account Type", comment: "Account type label"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Text(subscriptionViewModel.hasPremium ? LocalizedString("Premium", comment: "Premium account type") : LocalizedString("Free", comment: "Free account type"))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Button(action: {
                                HapticFeedback.buttonTap()
                                showPremium = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(LocalizedString("Upgrade Now", comment: "Upgrade now button"))
                                        .font(.system(size: 13, weight: .semibold))
                                        .lineLimit(1)
                                        .fixedSize(horizontal: true, vertical: false)
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color(red: 1.0, green: 0.85, blue: 0.0)) // Bright yellow
                                .cornerRadius(10)
                                .shadow(color: Color.yellow.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        // Usage Statistics
                        HStack(spacing: 20) {
                            // AI Extractions
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.purple)
                                        .font(.system(size: 16))
                                    Text(LocalizedString("AI Extractions", comment: "AI extractions label"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Text("\(subscriptionViewModel.aiImageExtractionCountThisMonth) / \(FreeTierLimits.maxAIImageExtractionsPerMonth)")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            // Recipes
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "menucard")
                                        .foregroundColor(.green)
                                        .font(.system(size: 16))
                                    Text(LocalizedString("Recipes", comment: "Recipes label"))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                HStack {
                                    Text("\(subscriptionViewModel.recipeCountThisMonth) / \(FreeTierLimits.maxRecipesPerMonth)")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } label: {
                        Text(LocalizedString("Premium Subscription", comment: "Premium subscription section header"))
                            .font(.headline)
                    }
                } footer: {
                    if isSubscriptionExpanded {
                        Text(LocalizedString("AI extractions (from images, links, or websites) share a combined monthly limit.", comment: "AI extractions limit explanation"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Share Section
                Section {
                    DisclosureGroup(isExpanded: $isShareExpanded) {
                        Button(action: {
                            HapticFeedback.buttonTap()
                            showShareSheet = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text(LocalizedString("Share App", comment: "Share app button"))
                            }
                        }
                        .foregroundColor(.primary)
                    } label: {
                        Text(LocalizedString("Share", comment: "Share section header"))
                            .font(.headline)
                    }
                }
                
                // MARK: - Feedback Section
                Section {
                    DisclosureGroup(isExpanded: $isFeedbackExpanded) {
                        Button(action: {
                            HapticFeedback.buttonTap()
                            showFeedbackSheet = true
                        }) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text(LocalizedString("Submit Feedback", comment: "Submit feedback button"))
                            }
                        }
                        .foregroundColor(.primary)
                    } label: {
                        Text(LocalizedString("Feedback", comment: "Feedback section header"))
                            .font(.headline)
                    }
                } footer: {
                    if isFeedbackExpanded {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedString("We appreciate collaborating with our users to improve the app further and tailor it to your needs.", comment: "Feedback instructional text"))
                            Text(LocalizedString("Share your ideas, suggestions, feature requests, or general feedback. Your input helps us build a better experience for everyone.", comment: "Feedback how it works text"))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Privacy & Terms Section
                Section {
                    DisclosureGroup(isExpanded: $isPrivacyTermsExpanded) {
                        Button(action: {
                            HapticFeedback.buttonTap()
                            showPrivacyPolicy = true
                        }) {
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text(LocalizedString("Privacy Policy", comment: "Privacy policy button"))
                            }
                        }
                        .foregroundColor(.primary)
                        
                        Button(action: {
                            HapticFeedback.buttonTap()
                            showTermsOfService = true
                        }) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text(LocalizedString("Terms of Service", comment: "Terms of service button"))
                            }
                        }
                        .foregroundColor(.primary)
                    } label: {
                        Text(LocalizedString("Privacy & Terms", comment: "Privacy and terms section header"))
                            .font(.headline)
                    }
                }
                
                // MARK: - Account Section
                Section {
                    DisclosureGroup(isExpanded: $isAccountExpanded) {
                        Button(action: {
                            HapticFeedback.buttonTap()
                            showEditProfile = true
                        }) {
                            HStack {
                                Image(systemName: "person.circle")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text(LocalizedString("Update Profile", comment: "Update profile button"))
                            }
                        }
                        .foregroundColor(.primary)
                        
                        Picker(selection: Binding(
                            get: { PrivacyLevel.from(user: authViewModel.currentUser) },
                            set: { newLevel in
                                Task {
                                    await updatePrivacyLevel(newLevel)
                                }
                            }
                        )) {
                            ForEach(PrivacyLevel.allCases) { level in
                                HStack {
                                    Image(systemName: level == .public ? "globe" : level == .limited ? "lock.fill" : "eye.slash.fill")
                                        .foregroundColor(.blue)
                                        .frame(width: 20)
                                    Text(level.displayName)
                                }
                                .tag(level)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text(LocalizedString("Account Privacy", comment: "Account privacy picker label"))
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: PrivacyLevel.from(user: authViewModel.currentUser)) {
                            HapticFeedback.buttonTap()
                        }
                        
                    Button(role: .destructive, action: {
                        HapticFeedback.play(.warning)
                        showDeleteAccountConfirmation = true
                    }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.red)
                                    .frame(width: 24)
                                Text(LocalizedString("Delete Account", comment: "Delete account button"))
                            }
                        }
                        .foregroundColor(.red)
                    } label: {
                        Text(LocalizedString("Account", comment: "Account section header"))
                        .font(.headline)
                    }
                } footer: {
                    if isAccountExpanded {
                        let privacyLevel = PrivacyLevel.from(user: authViewModel.currentUser)
                        if privacyLevel != .public {
                            Text(privacyLevel.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // MARK: - Sign Out Section
                Section {
                    Button(role: .destructive, action: {
                        HapticFeedback.play(.warning)
                        showSignOutConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            Text(LocalizedString("Sign Out", comment: "Sign out button"))
                        }
                    }
                    .foregroundColor(.red)
                }
                
                // MARK: - Version
                Section {
                    HStack {
                        Spacer()
                        Text(String(format: LocalizedString("Version %@", comment: "Version number"), viewModel.appVersion))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle(LocalizedString("Settings", comment: "Settings view title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedString("Done", comment: "Done button")) {
                        HapticFeedback.buttonTap()
                        dismiss()
                    }
                }
            }
        .preferredColorScheme(appSettings.isDarkModeEnabled ? .dark : .light)
        .task {
            // Load subscription data and usage counts when view appears
            await subscriptionViewModel.loadData()
        }
        .onAppear {
            // Refresh usage counts when view appears (in case user created recipes/extractions)
            Task {
                await subscriptionViewModel.loadUsageCounts()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RecipeSaved"))) { _ in
            // Refresh usage counts when a recipe is saved (including extractions)
            Task {
                await subscriptionViewModel.loadUsageCounts()
            }
        }
            .sheet(isPresented: $showFeedbackSheet) {
                FeedbackSheet(
                    name: $feedbackName,
                    subtitle: $feedbackSubtitle,
                    email: $feedbackEmail,
                    viewModel: viewModel
                )
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [shareAppText()])
                    .presentationDetents([.medium])
            }
            .confirmationDialog(
                LocalizedString("Sign Out", comment: "Sign out confirmation title"),
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button(LocalizedString("Sign Out", comment: "Sign out button"), role: .destructive) {
                    HapticFeedback.play(.warning)
                    authViewModel.signOut()
                    dismiss()
                }
                Button(LocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {}
            } message: {
                Text(LocalizedString("Are you sure you want to sign out?", comment: "Sign out confirmation message"))
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(viewModel: accountViewModel, authViewModel: authViewModel)
            }
            .confirmationDialog(
                LocalizedString("Delete Account", comment: "Delete account confirmation title"),
                isPresented: $showDeleteAccountConfirmation,
                titleVisibility: .visible
            ) {
                Button(LocalizedString("Delete Account", comment: "Delete account button"), role: .destructive) {
                    HapticFeedback.play(.error)
                    // Show re-authentication screen first
                    showReAuthenticate = true
                }
                Button(LocalizedString("Cancel", comment: "Cancel button"), role: .cancel) {}
            } message: {
                Text(LocalizedString("Are you sure you want to delete your account? Your account will be deleted immediately and this action is not reversible.", comment: "Delete account confirmation message"))
            }
            .sheet(isPresented: $showReAuthenticate) {
                ReAuthenticateView(authService: authService) {
                    // After successful re-authentication, proceed with deletion
                    Task { @MainActor in
                        showReAuthenticate = false
                        await deleteAccount()
                    }
                }
                .presentationDetents([.fraction(0.4)])
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showTermsOfService) {
                TermsOfServiceView()
            }
            .sheet(isPresented: $showPremium) {
                PremiumView()
            }
            .onAppear {
                accountViewModel.authViewModel = authViewModel
                Task {
                    await subscriptionViewModel.loadData()
                }
            }
        }
    }
    
    // MARK: - Account Management
    
    private func updatePrivacyLevel(_ level: PrivacyLevel) async {
        do {
            try await accountViewModel.toggleProfileVisibility(hidden: level.isProfileHidden)
            try await accountViewModel.toggleCompletePrivacy(isPrivate: level.isCompletelyPrivate)
            await authViewModel.reloadUserData()
        } catch {
            print("⚠️ Error updating privacy level: \(error.localizedDescription)")
        }
    }
    
    private func deleteAccount() async {
        deleteAccountError = nil
        do {
            try await accountViewModel.deleteAccount()
            // Sign out after account deletion
            authViewModel.signOut()
            dismiss()
        } catch {
            deleteAccountError = error.localizedDescription
            print("⚠️ Error deleting account: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Share App
    
    private func shareAppText() -> String {
        let appName = LocalizedString("Misoto", comment: "App name")
        let appStoreURL = "https://apps.apple.com/app/misoto" // Update with actual App Store URL
        return String(format: LocalizedString("Check out %@! %@", comment: "Share app text"), appName, appStoreURL)
    }
}

// MARK: - Feedback Sheet

struct FeedbackSheet: View {
    @Binding var name: String
    @Binding var subtitle: String
    @Binding var email: String
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var emailValidationError: String?
    @State private var selectedType: FeedbackType = .featureRequest
    
    enum Field {
        case name, subtitle, email
    }
    
    private var isEmailValid: Bool {
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true // Email is optional
        }
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isEmailValid &&
        !viewModel.isSubmittingFeedback
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Feedback Type Selection
                Section {
                    Picker(selection: $selectedType, label: Text(LocalizedString("Type", comment: "Feedback type label"))) {
                        Text(FeedbackType.featureRequest.displayName).tag(FeedbackType.featureRequest)
                        Text(FeedbackType.generalFeedback.displayName).tag(FeedbackType.generalFeedback)
                        Text(FeedbackType.translationSuggestion.displayName).tag(FeedbackType.translationSuggestion)
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text(LocalizedString("Feedback Type", comment: "Feedback type section header"))
                }
                
                // Name field
                Section {
                    TextField(
                        LocalizedString("Your name", comment: "Name placeholder"),
                        text: $name
                    )
                    .focused($focusedField, equals: .name)
                } header: {
                    Text(LocalizedString("Name", comment: "Name input header"))
                }
                
                // Feedback description
                Section {
                    TextField(
                        selectedType == .featureRequest 
                            ? LocalizedString("Describe your feature request", comment: "Feature request placeholder")
                            : selectedType == .translationSuggestion
                            ? LocalizedString("Suggest a translation improvement", comment: "Translation suggestion placeholder")
                            : LocalizedString("Share your feedback", comment: "General feedback placeholder"),
                        text: $subtitle,
                        axis: .vertical
                    )
                    .lineLimit(5...10)
                    .focused($focusedField, equals: .subtitle)
                } header: {
                    Text(selectedType == .featureRequest 
                         ? LocalizedString("Feature Request", comment: "Feature request input header")
                         : selectedType == .translationSuggestion
                         ? LocalizedString("Translation Suggestion", comment: "Translation suggestion input header")
                         : LocalizedString("Feedback", comment: "General feedback input header"))
                } footer: {
                    Text(selectedType == .featureRequest
                         ? LocalizedString("Please describe the feature you'd like to see in the app.", comment: "Feature request footer")
                         : selectedType == .translationSuggestion
                         ? LocalizedString("Please suggest improvements to translations or report incorrect translations.", comment: "Translation suggestion footer")
                         : LocalizedString("Please share your thoughts, suggestions, or report any issues.", comment: "General feedback footer"))
                }
                
                // Email field (optional)
                Section {
                    TextField(
                        LocalizedString("Email address (optional)", comment: "Email placeholder"),
                        text: $email
                    )
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .onChange(of: email) {
                        validateEmail()
                    }
                } header: {
                    Text(LocalizedString("Contact Email", comment: "Email input header"))
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        if let validationError = emailValidationError {
                            Text(validationError)
                                .foregroundColor(.red)
                                .font(.caption)
                        } else {
                            Text(selectedType == .featureRequest
                                 ? LocalizedString("Optional: We'll use this to respond to your feature request if needed.", comment: "Email footer - feature request")
                                 : selectedType == .translationSuggestion
                                 ? LocalizedString("Optional: We'll use this to respond to your translation suggestion if needed.", comment: "Email footer - translation suggestion")
                                 : LocalizedString("Optional: We'll use this to respond to your feedback if needed.", comment: "Email footer - general feedback"))
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
                
                if let errorMessage = viewModel.feedbackErrorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if let successMessage = viewModel.feedbackSuccessMessage {
                    Section {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(LocalizedString("Submit Feedback", comment: "Feedback sheet title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedString("Cancel", comment: "Cancel button")) {
                        HapticFeedback.buttonTap()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        if viewModel.isSubmittingFeedback {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Button(LocalizedString("Submit", comment: "Submit button")) {
                            HapticFeedback.importantAction()
                            let emailToSubmit = email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines)
                            Task {
                                await viewModel.submitFeedback(type: selectedType, name: name, subtitle: subtitle, email: emailToSubmit)
                                if viewModel.feedbackSuccessMessage != nil {
                                    HapticFeedback.play(.success)
                                    // Clear fields and dismiss after successful submission
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        name = ""
                                        subtitle = ""
                                        email = ""
                                        emailValidationError = nil
                                        selectedType = .featureRequest
                                        dismiss()
                                    }
                                }
                            }
                        }
                        .disabled(!canSubmit || viewModel.isSubmittingFeedback)
                    }
                }
            }
            .onAppear {
                focusedField = .name
            }
        }
    }
    
    private func validateEmail() {
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            emailValidationError = nil
            return
        }
        
        if !isEmailValid {
            emailValidationError = LocalizedString("Please enter a valid email address", comment: "Email validation error")
        } else {
            emailValidationError = nil
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        
        // Configure for iPad
        if let popover = controller.popoverPresentationController {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    SettingsView()
}


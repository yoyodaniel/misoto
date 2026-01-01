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
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Appearance Section
                Section {
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
                } header: {
                    Text(LocalizedString("Appearance", comment: "Appearance section header"))
                }
                
                // MARK: - Language Section
                Section {
                    // Only show English and System Language for now
                    // Other languages are commented out but code is preserved
                    ForEach(AppLanguage.availableLanguages, id: \.self) { language in
                        Button(action: {
                            HapticFeedback.play(.selection)
                            viewModel.selectLanguage(language)
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
                                if viewModel.selectedLanguage == language {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                } header: {
                    Text(LocalizedString("Language", comment: "Language section header"))
                } footer: {
                    Text(LocalizedString("The language selected will be used as the default writing language for recipe extractions.", comment: "Language selection footnote"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // MARK: - Share Section
                Section {
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
                } header: {
                    Text(LocalizedString("Share", comment: "Share section header"))
                }
                
                // MARK: - Feedback Section
                Section {
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
                } header: {
                    Text(LocalizedString("Feedback", comment: "Feedback section header"))
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedString("We appreciate collaborating with our users to improve the app further and tailor it to your needs.", comment: "Feedback instructional text"))
                        Text(LocalizedString("Share your ideas, suggestions, feature requests, or general feedback. Your input helps us build a better experience for everyone.", comment: "Feedback how it works text"))
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                    .onChange(of: email) { _ in
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


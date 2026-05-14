//
//  SettingsViewModel.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var selectedLanguage: AppLanguage = .system
    @Published var isSubmittingFeedback = false
    @Published var feedbackErrorMessage: String?
    @Published var feedbackSuccessMessage: String?
    @Published var isChangingLanguage = false
    @Published var pendingLanguage: AppLanguage?
    @Published var notificationPreferences = NotificationPreferences.default
    
    private let feedbackService = FeedbackService()
    private let userDefaults = UserDefaults.standard
    private let appSettings = AppSettings.shared
    private let firestore = FirebaseManager.shared.firestore
    private var cancellables = Set<AnyCancellable>()
    
    // Computed property that syncs with AppSettings
    var isDarkModeEnabled: Bool {
        get {
            appSettings.isDarkModeEnabled
        }
        set {
            appSettings.isDarkModeEnabled = newValue
        }
    }
    
    // MARK: - Notification Preferences
    
    func loadNotificationPreferences() async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await firestore.collection("users").document(userID).getDocument()
            if let data = snapshot.data(),
               let raw = data["notificationPreferences"] as? [String: Any] {
                notificationPreferences = NotificationPreferences(from: raw)
            } else {
                notificationPreferences = .default
            }
        } catch {
            print("⚠️ Failed to load notification preferences: \(error.localizedDescription)")
        }
    }
    
    func updateMuteAll(_ isMuted: Bool) async {
        notificationPreferences.muteAll = isMuted
        await saveNotificationPreferences()
    }
    
    func updateNotificationPreference(_ key: NotificationPreferenceKey, enabled: Bool) async {
        switch key {
        case .recipeRecommendations:
            notificationPreferences.recipeRecommendations = enabled
        case .comments:
            notificationPreferences.comments = enabled
        case .follows:
            notificationPreferences.follows = enabled
        case .likes:
            notificationPreferences.likes = enabled
        }
        await saveNotificationPreferences()
    }
    
    private func saveNotificationPreferences() async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        do {
            try await firestore.collection("users").document(userID).setData([
                "notificationPreferences": notificationPreferences.toFirestoreMap(),
                "updatedAt": Timestamp(date: Date())
            ], merge: true)
        } catch {
            print("⚠️ Failed to save notification preferences: \(error.localizedDescription)")
        }
    }
    
    // MARK: - UserDefaults Keys
    
    private enum UserDefaultsKeys {
        static let selectedLanguage = "selectedLanguage"
    }
    
    init() {
        loadSettings()
        
        // Observe language changes from LocalizationManager using Combine
        NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                // Update selectedLanguage to reflect the current language in LocalizationManager
                self.selectedLanguage = LocalizationManager.shared.currentLanguage
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load Settings
    
    private func loadSettings() {
        // Sync with LocalizationManager's current language (which detects device language if no manual override)
        // This ensures Settings shows the detected device language, not a default English
        selectedLanguage = LocalizationManager.shared.currentLanguage
        
        // Only save to UserDefaults if it's a manual selection (with override flag)
        // If it's a detected language, don't save it so device changes are reflected
        let isManualOverride = userDefaults.bool(forKey: "languageIsManualOverride")
        if !isManualOverride {
            // Detected language - don't save, but show it in Settings
            // Remove any old saved preference that's not a manual override
            if userDefaults.string(forKey: UserDefaultsKeys.selectedLanguage) != nil {
                userDefaults.removeObject(forKey: UserDefaultsKeys.selectedLanguage)
            }
        }
    }
    
    // MARK: - Dark Mode
    
    func toggleDarkMode() {
        appSettings.isDarkModeEnabled.toggle()
    }
    
    // MARK: - Language Selection
    
    func selectLanguage(_ language: AppLanguage) async {
        // Don't do anything if already changing or selecting the same language
        guard !isChangingLanguage, language != selectedLanguage else { return }
        
        isChangingLanguage = true
        pendingLanguage = language
        
        // Wait 1 second to create loading illusion
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Update the language
        selectedLanguage = language
        userDefaults.set(language.rawValue, forKey: UserDefaultsKeys.selectedLanguage)
        // Update the localization manager
        LocalizationManager.shared.setLanguage(language)
        
        isChangingLanguage = false
        pendingLanguage = nil
    }
    
    // MARK: - Feedback Submission
    
    func submitFeedback(type: FeedbackType, name: String, subtitle: String, email: String?) async {
        guard !isSubmittingFeedback else { return }
        
        isSubmittingFeedback = true
        feedbackErrorMessage = nil
        feedbackSuccessMessage = nil
        
        do {
            try await feedbackService.submitFeedback(type: type, name: name, subtitle: subtitle, email: email)
            let successMessage: String
            switch type {
            case .featureRequest:
                successMessage = LocalizedString("Thank you for your feature request!", comment: "Feature request success message")
            case .translationSuggestion:
                successMessage = LocalizedString("Thank you for your translation suggestion!", comment: "Translation suggestion success message")
            case .generalFeedback:
                successMessage = LocalizedString("Thank you for your feedback!", comment: "General feedback success message")
            }
            feedbackSuccessMessage = successMessage
            
            // Clear success message after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    feedbackSuccessMessage = nil
                }
            }
        } catch {
            feedbackErrorMessage = error.localizedDescription
        }
        
        isSubmittingFeedback = false
    }
    
    // MARK: - App Version
    
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? LocalizedString("Unknown", comment: "Unknown version")
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? LocalizedString("Unknown", comment: "Unknown build")
        return "\(version) (\(build))"
    }
}

enum NotificationPreferenceKey {
    case recipeRecommendations
    case comments
    case follows
    case likes
}

struct NotificationPreferences: Codable {
    var muteAll: Bool
    var recipeRecommendations: Bool
    var comments: Bool
    var follows: Bool
    var likes: Bool
    /// Reserved for future per-thread or per-user mute controls.
    var mutedThreadIDs: [String]
    
    static let `default` = NotificationPreferences(
        muteAll: false,
        recipeRecommendations: true,
        comments: true,
        follows: true,
        likes: true,
        mutedThreadIDs: []
    )
    
    init(
        muteAll: Bool,
        recipeRecommendations: Bool,
        comments: Bool,
        follows: Bool,
        likes: Bool,
        mutedThreadIDs: [String]
    ) {
        self.muteAll = muteAll
        self.recipeRecommendations = recipeRecommendations
        self.comments = comments
        self.follows = follows
        self.likes = likes
        self.mutedThreadIDs = mutedThreadIDs
    }
    
    init(from map: [String: Any]) {
        self.muteAll = map["muteAll"] as? Bool ?? false
        self.recipeRecommendations = map["recipeRecommendations"] as? Bool ?? true
        self.comments = map["comments"] as? Bool ?? true
        self.follows = map["follows"] as? Bool ?? true
        self.likes = map["likes"] as? Bool ?? true
        self.mutedThreadIDs = map["mutedThreadIDs"] as? [String] ?? []
    }
    
    func toFirestoreMap() -> [String: Any] {
        [
            "muteAll": muteAll,
            "recipeRecommendations": recipeRecommendations,
            "comments": comments,
            "follows": follows,
            "likes": likes,
            "mutedThreadIDs": mutedThreadIDs
        ]
    }
}

// MARK: - App Language

enum AppLanguage: String, CaseIterable {
    case english = "en"
    // MARK: - Commented out languages (preserved for future use - code kept but not shown in UI)
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case dutch = "nl"
    case russian = "ru"
    case japanese = "ja"
    case korean = "ko"
    case thai = "th"
    case vietnamese = "vi"
    case indonesian = "id"
    case malay = "ms"
    case filipino = "fil"
    case hindi = "hi"
    case arabic = "ar"
    case hebrew = "he"
    case system = "system"
    
    /// Available languages for selection (currently only English and System Language)
    /// Other languages are preserved in the enum but not shown in the UI
    static var availableLanguages: [AppLanguage] {
        return [.english, .system]
    }
    
    var displayName: String {
        switch self {
        case .english:
            return LocalizedString("English", comment: "English language option")
        // MARK: - Language display names (preserved for future use - not shown in UI currently)
        case .chineseSimplified:
            return LocalizedString("Chinese, Simplified", comment: "Simplified Chinese language option")
        case .chineseTraditional:
            return LocalizedString("Chinese, Traditional", comment: "Traditional Chinese language option")
        case .spanish:
            return LocalizedString("Spanish", comment: "Spanish language option")
        case .french:
            return LocalizedString("French", comment: "French language option")
        case .german:
            return LocalizedString("German", comment: "German language option")
        case .italian:
            return LocalizedString("Italian", comment: "Italian language option")
        case .portuguese:
            return LocalizedString("Portuguese", comment: "Portuguese language option")
        case .dutch:
            return LocalizedString("Dutch", comment: "Dutch language option")
        case .russian:
            return LocalizedString("Russian", comment: "Russian language option")
        case .japanese:
            return LocalizedString("Japanese", comment: "Japanese language option")
        case .korean:
            return LocalizedString("Korean", comment: "Korean language option")
        case .thai:
            return LocalizedString("Thai", comment: "Thai language option")
        case .vietnamese:
            return LocalizedString("Vietnamese", comment: "Vietnamese language option")
        case .indonesian:
            return LocalizedString("Indonesian", comment: "Indonesian language option")
        case .malay:
            return LocalizedString("Malay", comment: "Malay language option")
        case .filipino:
            return LocalizedString("Filipino", comment: "Filipino language option")
        case .hindi:
            return LocalizedString("Hindi", comment: "Hindi language option")
        case .arabic:
            return LocalizedString("Arabic", comment: "Arabic language option")
        case .hebrew:
            return LocalizedString("Hebrew", comment: "Hebrew language option")
        case .system:
            let systemLanguageName = AppLanguage.getSystemLanguageName()
            return String(format: LocalizedString("System Language (%@)", comment: "System language option with language name"), systemLanguageName)
        }
    }
    
    static func getSystemLanguageName() -> String {
        // Get the preferred language from the system
        guard let preferredLanguage = Locale.preferredLanguages.first else {
            return LocalizedString("Unknown", comment: "Unknown language")
        }
        
        // Extract the language code (e.g., "en" from "en-US")
        let languageCode = preferredLanguage.components(separatedBy: "-").first ?? preferredLanguage
        
        // Create a locale for the language itself to get its native name
        let languageLocale = Locale(identifier: preferredLanguage)
        
        // Try to get the native language name first
        if let nativeName = languageLocale.localizedString(forLanguageCode: languageCode) {
            // If we got a name, capitalize it properly
            return nativeName.capitalized
        }
        
        // Fallback: use current locale to get localized name
        let currentLocale = Locale.current
        if let localizedName = currentLocale.localizedString(forLanguageCode: languageCode) {
            return localizedName.capitalized
        }
        
        // Final fallback: return the language code
        return languageCode.uppercased()
    }
}


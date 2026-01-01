//
//  LocalizationManager.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: AppLanguage = .english
    
    private var bundle: Bundle = Bundle.main
    
    private init() {
        loadLanguage()
    }
    
    // MARK: - Language Management
    
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: "selectedLanguage")
        updateBundle()
        
        // Force objectWillChange to trigger view updates
        objectWillChange.send()
        
        // Post notification to update UI
        NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
    }
    
    private func loadLanguage() {
        if let languageRawValue = UserDefaults.standard.string(forKey: "selectedLanguage"),
           let language = AppLanguage(rawValue: languageRawValue) {
            currentLanguage = language
        } else {
            // Default to English on first launch
            currentLanguage = .english
            // Save English as default to UserDefaults
            UserDefaults.standard.set(AppLanguage.english.rawValue, forKey: "selectedLanguage")
        }
        updateBundle()
    }
    
    private func updateBundle() {
        let languageCode: String
        switch currentLanguage {
        case .english:
            // Explicitly use English - always use en.lproj bundle
            languageCode = "en"
        case .system:
            // Use system's preferred language, fallback to English
            // Normalize Chinese regional variants to zh-Hans or zh-Hant for correct bundle loading
            if let preferredLanguage = Locale.preferredLanguages.first {
                languageCode = Self.normalizeChineseLanguageCode(preferredLanguage)
            } else {
                languageCode = "en"
            }
        default:
            // For all other languages, use the rawValue (language code)
            languageCode = currentLanguage.rawValue
        }
        
        print("🔍 updateBundle called - currentLanguage: \(currentLanguage.rawValue), languageCode: \(languageCode)")
        
        // Find the bundle for the selected language
        // For English, we MUST use the en.lproj bundle, not Bundle.main
        if currentLanguage == .english {
            // Explicitly load English bundle
            if let enPath = Bundle.main.path(forResource: "en", ofType: "lproj") {
                print("✅ Found en.lproj at path: \(enPath)")
                if let enBundle = Bundle(path: enPath) {
                    bundle = enBundle
                    print("✅ Loaded English bundle explicitly from: \(enPath)")
                    // Test that the bundle works
                    let testString = enBundle.localizedString(forKey: "Settings", value: nil, table: nil)
                    print("🧪 Test: bundle.localizedString('Settings') = '\(testString)'")
                } else {
                    bundle = Bundle.main
                    print("⚠️ Failed to create bundle from path: \(enPath)")
                }
            } else {
                bundle = Bundle.main
                print("⚠️ en.lproj not found in Bundle.main")
            }
        } else if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
                  let languageBundle = Bundle(path: path) {
            bundle = languageBundle
            print("✅ Loaded bundle for language: \(languageCode) from: \(path)")
        } else {
            // Fallback to English bundle
            if let enPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
               let enBundle = Bundle(path: enPath) {
                bundle = enBundle
                print("⚠️ Language bundle not found for \(languageCode), using English fallback")
            } else {
                bundle = Bundle.main
                print("⚠️ Using main bundle as fallback")
            }
        }
    }
    
    // MARK: - Localized String
    
    func localizedString(for key: String, comment: String = "") -> String {
        // If English is explicitly selected, always use English bundle, never system language
        if currentLanguage == .english {
            // Always use English bundle when English is selected
            if let enPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
               let enBundle = Bundle(path: enPath) {
                let enLocalized = enBundle.localizedString(forKey: key, value: nil, table: nil)
                // If found in English bundle, return it (even if it equals the key, that's the English value)
                return enLocalized
            } else {
                // If en.lproj doesn't exist, try main bundle but this shouldn't happen
                return Bundle.main.localizedString(forKey: key, value: nil, table: nil)
            }
        }
        
        // For system language or other languages, use the selected bundle
        var localized = bundle.localizedString(forKey: key, value: nil, table: nil)
        
        // If the key wasn't found in the custom bundle (localized == key means no translation found)
        if localized == key || localized.isEmpty {
            // Try English bundle as fallback
            if let enPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
               let enBundle = Bundle(path: enPath) {
                let enLocalized = enBundle.localizedString(forKey: key, value: nil, table: nil)
                if enLocalized != key && !enLocalized.isEmpty {
                    localized = enLocalized
                }
            }
            
            // If still not found, try main bundle as final fallback
            if localized == key || localized.isEmpty {
                let mainLocalized = Bundle.main.localizedString(forKey: key, value: nil, table: nil)
                if mainLocalized != key && !mainLocalized.isEmpty {
                    localized = mainLocalized
                }
            }
        }
        
        return localized
    }
    
    // Helper to get localized string with format arguments
    func localizedString(for key: String, arguments: CVarArg..., comment: String = "") -> String {
        let format = localizedString(for: key, comment: comment)
        return String(format: format, arguments: arguments)
    }
    
    /// Normalizes Chinese language codes to zh-Hans or zh-Hant for consistent bundle loading.
    /// - Parameter code: Language code from system (e.g., "zh-HK", "zh-TW", "zh-CN", "zh-Hans", "zh-Hant")
    /// - Returns: Normalized code (zh-Hans or zh-Hant)
    private static func normalizeChineseLanguageCode(_ code: String) -> String {
        let lowercased = code.lowercased()
        
        // Traditional Chinese regions: Hong Kong, Taiwan, Macau
        if lowercased.hasPrefix("zh-hk") || lowercased.hasPrefix("zh-tw") || lowercased.hasPrefix("zh-mo") || lowercased == "zh-hant" {
            return "zh-Hant"
        }
        
        // Simplified Chinese regions: China, Singapore
        if lowercased.hasPrefix("zh-cn") || lowercased.hasPrefix("zh-sg") || lowercased == "zh-hans" {
            return "zh-Hans"
        }
        
        // If it's just "zh" without variant, default to Simplified (most common)
        if lowercased == "zh" {
            return "zh-Hans"
        }
        
        // For all other cases, return as-is
        return code
    }
}

// MARK: - Helper Function for Easy Localization

/// Use this function instead of NSLocalizedString to support runtime language switching
func LocalizedString(_ key: String, comment: String = "") -> String {
    return LocalizationManager.shared.localizedString(for: key, comment: comment)
}

/// Use this for formatted strings with arguments
func LocalizedString(_ key: String, arguments: CVarArg..., comment: String = "") -> String {
    let format = LocalizationManager.shared.localizedString(for: key, comment: comment)
    return String(format: format, arguments: arguments)
}

// MARK: - Override NSLocalizedString for Runtime Language Switching

/// Override NSLocalizedString to use LocalizationManager for runtime language switching
/// This allows existing NSLocalizedString calls to work with runtime language changes
func NSLocalizedString(_ key: String, comment: String) -> String {
    return LocalizationManager.shared.localizedString(for: key, comment: comment)
}

// MARK: - View Modifier for Language Updates

struct LocalizedView: ViewModifier {
    @ObservedObject var localizationManager = LocalizationManager.shared
    
    func body(content: Content) -> some View {
        content
            // Observe language changes to trigger view updates
            // Use onChange to refresh content without changing the view identity
            // This prevents sheets from dismissing when language changes
            .onChange(of: localizationManager.currentLanguage) {
                // The @ObservedObject will automatically trigger view updates
                // No need to change the view ID which would cause sheets to dismiss
            }
    }
}

extension View {
    func localized() -> some View {
        modifier(LocalizedView())
    }
}


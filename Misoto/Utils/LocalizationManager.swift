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
        // Save manual selection to UserDefaults (this overrides device language detection)
        if language != .system {
            UserDefaults.standard.set(language.rawValue, forKey: "selectedLanguage")
            UserDefaults.standard.set(true, forKey: "languageIsManualOverride")
        } else {
            // If user selects "System Language", clear the saved preference to always detect device language
            UserDefaults.standard.removeObject(forKey: "selectedLanguage")
            UserDefaults.standard.removeObject(forKey: "languageIsManualOverride")
        }
        updateBundle()
        
        // Force objectWillChange to trigger view updates
        objectWillChange.send()
        
        // Post notification to update UI
        NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
    }
    
    private func loadLanguage() {
        // Always detect device language first
        let detectedLanguage = detectDeviceLanguage()
        print("🌍 Detected device language: \(detectedLanguage.rawValue)")
        
        // Check if user has manually selected a language (only honor if it's different from device)
        // But first check if this is a "manual override" flag (set when user explicitly selects in Settings)
        let isManualOverride = UserDefaults.standard.bool(forKey: "languageIsManualOverride")
        
        if let languageRawValue = UserDefaults.standard.string(forKey: "selectedLanguage"),
           let savedLanguage = AppLanguage(rawValue: languageRawValue),
           savedLanguage != .system,
           isManualOverride,
           savedLanguage != detectedLanguage {
            // User has explicitly manually selected a language different from device - honor it
            print("🌍 Using manually selected language: \(savedLanguage.rawValue) (device: \(detectedLanguage.rawValue))")
            currentLanguage = savedLanguage
        } else {
            // Use device language (no manual override, or saved matches device, or old saved preference)
            print("🌍 Using device language: \(detectedLanguage.rawValue)")
            currentLanguage = detectedLanguage
            // Clear old saved preferences that don't have manual override flag
            if !isManualOverride {
                UserDefaults.standard.removeObject(forKey: "selectedLanguage")
                print("🌍 Cleared old saved preference (not a manual override)")
            }
        }
        updateBundle()
    }
    
    /// Detects the device's preferred language and maps it to an AppLanguage case
    private func detectDeviceLanguage() -> AppLanguage {
        guard let preferredLanguage = Locale.preferredLanguages.first else {
            print("⚠️ No preferred language found, defaulting to English")
            return .english
        }
        
        print("🌍 Device preferred language: \(preferredLanguage)")
        
        // Normalize the language code (handle Chinese variants)
        let normalizedCode = Self.normalizeChineseLanguageCode(preferredLanguage)
        print("🌍 Normalized language code: \(normalizedCode)")
        
        // Extract base language code (e.g., "es-ES" -> "es", "ja-JP" -> "ja")
        let baseCode: String
        if let separatorIndex = normalizedCode.firstIndex(of: "-") {
            baseCode = String(normalizedCode[..<separatorIndex])
        } else {
            baseCode = normalizedCode
        }
        
        print("🌍 Base language code: \(baseCode)")
        
        // Map to AppLanguage cases
        switch baseCode.lowercased() {
        case "en":
            return .english
        case "zh":
            // Determine Simplified vs Traditional based on normalized code
            if normalizedCode.lowercased().hasPrefix("zh-hant") || 
               normalizedCode.lowercased().contains("hant") {
                print("🌍 Mapping to Chinese Traditional")
                return .chineseTraditional
            } else {
                print("🌍 Mapping to Chinese Simplified")
                return .chineseSimplified
            }
        case "es":
            return .spanish
        case "fr":
            return .french
        case "de":
            return .german
        case "it":
            return .italian
        case "pt":
            return .portuguese
        case "nl":
            return .dutch
        case "ru":
            return .russian
        case "ja":
            return .japanese
        case "ko":
            return .korean
        case "th":
            return .thai
        case "vi":
            return .vietnamese
        case "id":
            return .indonesian
        case "ms":
            return .malay
        case "fil", "tl":
            return .filipino
        case "hi":
            return .hindi
        case "ar":
            return .arabic
        case "he":
            return .hebrew
        default:
            // If language is not supported, default to English
            return .english
        }
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
    /// - Parameter code: Language code from system (e.g., "zh-HK", "zh-TW", "zh-CN", "zh-Hans", "zh-Hant", "zh-Hant-HK")
    /// - Returns: Normalized code (zh-Hans or zh-Hant)
    private static func normalizeChineseLanguageCode(_ code: String) -> String {
        let lowercased = code.lowercased()
        
        // Traditional Chinese regions: Hong Kong, Taiwan, Macau
        // Check for zh-HK, zh-Hant-HK, zh-Hant_HK, or any variant containing hk/tw/mo
        if lowercased.hasPrefix("zh-hk") || 
           lowercased.contains("-hk") || 
           lowercased.contains("_hk") ||
           lowercased.hasPrefix("zh-tw") || 
           lowercased.contains("-tw") || 
           lowercased.contains("_tw") ||
           lowercased.hasPrefix("zh-mo") || 
           lowercased.contains("-mo") || 
           lowercased.contains("_mo") ||
           lowercased == "zh-hant" ||
           lowercased.hasPrefix("zh-hant") {
            return "zh-Hant"
        }
        
        // Simplified Chinese regions: China, Singapore
        // Check for zh-CN, zh-Hans-CN, zh-Hans_CN, or any variant containing cn/sg
        if lowercased.hasPrefix("zh-cn") || 
           lowercased.contains("-cn") || 
           lowercased.contains("_cn") ||
           lowercased.hasPrefix("zh-sg") || 
           lowercased.contains("-sg") || 
           lowercased.contains("_sg") ||
           lowercased == "zh-hans" ||
           lowercased.hasPrefix("zh-hans") {
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

// MARK: - Time Formatting Helper

/// Format minutes into a human-readable duration string.
/// - < 60 min → "45 min"
/// - 60..1439 min → "2 h 30 min" or "2 h"
/// - >= 1440 min → "1 day" / "2 days 3 h"
func formatDuration(_ totalMinutes: Int) -> String {
    guard totalMinutes > 0 else {
        return "0 \(LocalizedString("min", comment: "Minutes abbreviation"))"
    }
    
    let days = totalMinutes / 1440
    let remainingAfterDays = totalMinutes % 1440
    let hours = remainingAfterDays / 60
    let minutes = remainingAfterDays % 60
    
    let dayStr = LocalizedString("d", comment: "Day abbreviation")
    let hourStr = LocalizedString("h", comment: "Hour abbreviation")
    let minStr = LocalizedString("min", comment: "Minutes abbreviation")
    
    if days > 0 {
        // 1 day, 2 days, 1 day 3 h, etc.
        var result = "\(days) \(dayStr)"
        if hours > 0 {
            result += " \(hours) \(hourStr)"
        }
        return result
    } else if hours > 0 {
        // 2 h, 2 h 30 min, etc.
        if minutes == 0 {
            return "\(hours) \(hourStr)"
        } else {
            return "\(hours) \(hourStr) \(minutes) \(minStr)"
        }
    } else {
        return "\(minutes) \(minStr)"
    }
}

/// Returns the appropriate SF Symbol for a given duration in minutes.
func durationIcon(for totalMinutes: Int) -> String {
    if totalMinutes >= 1440 {
        return "moon.stars.fill"
    } else {
        return "clock"
    }
}


//
//  AppSettings.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import Combine

@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    enum DefaultPostSharing: String, CaseIterable, Identifiable {
        case `public`
        case `private`

        var id: String { rawValue }

        var isPrivateRecipe: Bool {
            self == .private
        }
    }
    
    @Published var isDarkModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDarkModeEnabled, forKey: "darkModeEnabled")
        }
    }
    
    @Published var isHapticFeedbackEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isHapticFeedbackEnabled, forKey: "hapticFeedbackEnabled")
        }
    }

    @Published var defaultPostSharing: DefaultPostSharing {
        didSet {
            UserDefaults.standard.set(defaultPostSharing.rawValue, forKey: "defaultPostSharing")
        }
    }

    var defaultRecipeIsPrivate: Bool {
        defaultPostSharing.isPrivateRecipe
    }
    
    private init() {
        self.isDarkModeEnabled = UserDefaults.standard.bool(forKey: "darkModeEnabled")
        // Default haptic feedback to enabled
        if UserDefaults.standard.object(forKey: "hapticFeedbackEnabled") == nil {
            self.isHapticFeedbackEnabled = true
        } else {
            self.isHapticFeedbackEnabled = UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled")
        }

        if let stored = UserDefaults.standard.string(forKey: "defaultPostSharing"),
           let parsed = DefaultPostSharing(rawValue: stored) {
            self.defaultPostSharing = parsed
        } else {
            // New installs: posts are public (globally visible) by default
            self.defaultPostSharing = .public
        }
    }
}


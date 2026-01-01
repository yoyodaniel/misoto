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
    
    private init() {
        self.isDarkModeEnabled = UserDefaults.standard.bool(forKey: "darkModeEnabled")
        // Default haptic feedback to enabled
        if UserDefaults.standard.object(forKey: "hapticFeedbackEnabled") == nil {
            self.isHapticFeedbackEnabled = true
        } else {
            self.isHapticFeedbackEnabled = UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled")
        }
    }
}


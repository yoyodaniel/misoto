//
//  HapticFeedback.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import UIKit

enum HapticFeedback {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection
    
    static func play(_ type: HapticFeedback) {
        // Check if haptic feedback is enabled
        guard AppSettings.shared.isHapticFeedbackEnabled else { return }
        
        switch type {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
            
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
    
    // Convenience method for button taps
    static func buttonTap() {
        HapticFeedback.play(.light)
    }
    
    // Convenience method for important actions
    static func importantAction() {
        HapticFeedback.play(.medium)
    }
}


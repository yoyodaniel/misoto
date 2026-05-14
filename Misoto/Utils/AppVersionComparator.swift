//
//  AppVersionComparator.swift
//  Misoto
//

import Foundation

enum AppVersionComparator {
    /// Marketing version from Info.plist (e.g. "1.4.0").
    static func marketingVersion(from bundle: Bundle = .main) -> String {
        bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    /// `true` when `lhs` is a higher marketing version than `rhs` (after App Store update).
    static func isMarketingVersionNewer(_ lhs: String, than rhs: String) -> Bool {
        compareMarketingVersions(lhs, rhs) == .orderedDescending
    }

    static func compareMarketingVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let a = numericComponents(lhs)
        let b = numericComponents(rhs)
        let count = max(a.count, b.count)
        for i in 0 ..< count {
            let va = i < a.count ? a[i] : 0
            let vb = i < b.count ? b[i] : 0
            if va != vb {
                return va < vb ? .orderedAscending : .orderedDescending
            }
        }
        return .orderedSame
    }

    private static func numericComponents(_ version: String) -> [Int] {
        version.split(separator: ".").map { segment in
            let digits = segment.prefix(while: \.isNumber)
            return Int(digits) ?? 0
        }
    }
}

// MARK: - What's New prompt persistence

enum WhatsNewPromptStorage {
    static let acknowledgedMarketingVersionUserDefaultsKey = "whatsNewAcknowledgedMarketingVersion"

    /// Clears stored acknowledgment so the What's New sheet can appear again for the current marketing version (e.g. after Settings → Debug).
    static func clearAcknowledgedMarketingVersion() {
        UserDefaults.standard.removeObject(forKey: acknowledgedMarketingVersionUserDefaultsKey)
    }
}

extension NSNotification.Name {
    /// Posted after clearing acknowledgment so `MainTabView` can present the What's New sheet immediately.
    static let showWhatsNewAgain = NSNotification.Name("ShowWhatsNewAgain")
}

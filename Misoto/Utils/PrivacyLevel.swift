//
//  PrivacyLevel.swift
//  Misoto
//
//  Created by Daniel Chan on 30.12.2025.
//

import Foundation

enum PrivacyLevel: String, CaseIterable, Identifiable {
    case `public` = "public"
    case limited = "limited"
    case `private` = "private"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .public:
            return LocalizedString("Public", comment: "Public privacy level")
        case .limited:
            return LocalizedString("Limited", comment: "Limited privacy level")
        case .private:
            return LocalizedString("Private", comment: "Private privacy level")
        }
    }
    
    var description: String {
        switch self {
        case .public:
            return LocalizedString("Your profile is visible to everyone", comment: "Public privacy description")
        case .limited:
            return LocalizedString("Your profile is hidden from the explore view. Only your accepted followers can see your profile and recipes.", comment: "Limited privacy description")
        case .private:
            return LocalizedString("Your profile and recipes are hidden from all users, including followers.", comment: "Private privacy description")
        }
    }
    
    static func from(user: AppUser?) -> PrivacyLevel {
        guard let user = user else { return .public }
        
        if user.isCompletelyPrivate {
            return .private
        } else if user.isProfileHidden {
            return .limited
        } else {
            return .public
        }
    }
    
    var isProfileHidden: Bool {
        return self != .public
    }
    
    var isCompletelyPrivate: Bool {
        return self == .private
    }
}


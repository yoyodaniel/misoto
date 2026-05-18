//
//  StoragePaths.swift
//  Misoto
//
//  User-scoped Firebase Storage paths (must match storage.rules).
//

import Foundation

enum StoragePaths {
    static func recipeImage(userID: String) -> String {
        "users/\(userID)/recipes/\(UUID().uuidString).jpg"
    }

    static func recipeInstructionImage(userID: String) -> String {
        "users/\(userID)/recipe-instructions/\(UUID().uuidString).jpg"
    }

    static func recipeInstructionVideo(userID: String) -> String {
        "users/\(userID)/recipe-instructions/\(UUID().uuidString).mp4"
    }

    static func legacyInstructionImage(userID: String) -> String {
        "users/\(userID)/instructions/\(UUID().uuidString).jpg"
    }

    static func sourceImage(userID: String) -> String {
        "users/\(userID)/source-images/\(UUID().uuidString).jpg"
    }
}

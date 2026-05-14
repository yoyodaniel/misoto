//
//  Favorite.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation

struct Favorite: Identifiable, Codable {
    var id: String
    var userID: String
    var recipeID: String
    var recipeAuthorID: String?
    var createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        userID: String,
        recipeID: String,
        recipeAuthorID: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userID = userID
        self.recipeID = recipeID
        self.recipeAuthorID = recipeAuthorID
        self.createdAt = createdAt
    }
}


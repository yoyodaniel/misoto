//
//  RecipeBadge.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation

struct RecipeBadge: Codable, Equatable {
    var type: BadgeType
    var text: String
    
    enum BadgeType: String, Codable {
        case newbieTop = "newbie_top"
        case trending = "trending"
        case featured = "featured"
        case popular = "popular"
    }
    
    init(type: BadgeType, text: String) {
        self.type = type
        self.text = text
    }
}


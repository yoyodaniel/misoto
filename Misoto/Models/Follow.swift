//
//  Follow.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation

struct Follow: Identifiable, Codable {
    var id: String
    var followerID: String
    var followingID: String
    var createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        followerID: String,
        followingID: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.followerID = followerID
        self.followingID = followingID
        self.createdAt = createdAt
    }
}


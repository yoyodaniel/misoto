//
//  User.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation

struct AppUser: Identifiable, Codable {
    var id: String
    var email: String?
    var displayName: String
    var username: String?
    var profileImageURL: String?
    var bio: String?
    var followerCount: Int
    var followingCount: Int
    var recipeCount: Int
    var createdAt: Date
    
    init(
        id: String,
        email: String? = nil,
        displayName: String,
        username: String? = nil,
        profileImageURL: String? = nil,
        bio: String? = nil,
        followerCount: Int = 0,
        followingCount: Int = 0,
        recipeCount: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.username = username
        self.profileImageURL = profileImageURL
        self.bio = bio
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.recipeCount = recipeCount
        self.createdAt = createdAt
    }
}


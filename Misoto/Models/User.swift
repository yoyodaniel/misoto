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
    var likesCount: Int
    var reportCount: Int
    var isBanned: Bool
    var createdAt: Date
    var lastLogin: Date?
    var isProfileHidden: Bool
    var isCompletelyPrivate: Bool // Hide from all users including followers
    var premiumUser: Bool // Premium subscription status
    
    enum CodingKeys: String, CodingKey {
        case id, email, displayName, username, profileImageURL, bio
        case followerCount, followingCount, recipeCount, likesCount, reportCount
        case createdAt, lastLogin
        case isProfileHidden
        case isCompletelyPrivate
        case isBanned
        case premiumUser
    }
    
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
        likesCount: Int = 0,
        reportCount: Int = 0,
        isBanned: Bool = false,
        createdAt: Date = Date(),
        lastLogin: Date? = nil,
        isProfileHidden: Bool = false,
        isCompletelyPrivate: Bool = false,
        premiumUser: Bool = false
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
        self.likesCount = likesCount
        self.reportCount = reportCount
        self.isBanned = isBanned
        self.createdAt = createdAt
        self.lastLogin = lastLogin
        self.isProfileHidden = isProfileHidden
        self.isCompletelyPrivate = isCompletelyPrivate
        self.premiumUser = premiumUser
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        displayName = try container.decode(String.self, forKey: .displayName)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        followerCount = try container.decodeIfPresent(Int.self, forKey: .followerCount) ?? 0
        followingCount = try container.decodeIfPresent(Int.self, forKey: .followingCount) ?? 0
        recipeCount = try container.decodeIfPresent(Int.self, forKey: .recipeCount) ?? 0
        likesCount = try container.decodeIfPresent(Int.self, forKey: .likesCount) ?? 0
        reportCount = try container.decodeIfPresent(Int.self, forKey: .reportCount) ?? 0
        isBanned = try container.decodeIfPresent(Bool.self, forKey: .isBanned) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastLogin = try container.decodeIfPresent(Date.self, forKey: .lastLogin)
        isProfileHidden = try container.decodeIfPresent(Bool.self, forKey: .isProfileHidden) ?? false
        isCompletelyPrivate = try container.decodeIfPresent(Bool.self, forKey: .isCompletelyPrivate) ?? false
        premiumUser = try container.decodeIfPresent(Bool.self, forKey: .premiumUser) ?? false
    }
}


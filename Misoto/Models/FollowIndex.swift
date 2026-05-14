//
//  FollowIndex.swift
//  Misoto
//
//  Created by Codex on 08.05.2026.
//

import Foundation

struct FollowIndexUserSnapshot: Codable {
    let userID: String
    let displayName: String
    let displayNameLower: String
    let username: String
    let usernameLower: String
    let profileImageURL: String?
    let premiumUser: Bool
    let followedAt: Date

    init(user: AppUser, followedAt: Date = Date()) {
        self.userID = user.id
        self.displayName = user.displayName
        self.displayNameLower = user.displayName.lowercased()
        self.username = user.username ?? ""
        self.usernameLower = (user.username ?? "").lowercased()
        self.profileImageURL = user.profileImageURL
        self.premiumUser = user.premiumUser
        self.followedAt = followedAt
    }

    func toAppUser() -> AppUser {
        AppUser(
            id: userID,
            displayName: displayName,
            username: username.isEmpty ? nil : username,
            profileImageURL: profileImageURL,
            premiumUser: premiumUser
        )
    }
}

struct FollowPageCursor: Equatable {
    let followedAt: Date
    let userID: String
}

struct FollowPageResult {
    let users: [AppUser]
    let nextCursor: FollowPageCursor?
    let hasMore: Bool
}

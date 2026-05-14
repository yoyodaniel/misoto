//
//  XPLevelCalculator.swift
//  Misoto
//
//  Core XP math and level/title helpers.
//

import Foundation

// MARK: - XP Constants

enum XPActionType: String, Codable, CaseIterable {
    // CONTENT CREATION
    case recipePublished = "RECIPE_PUBLISHED"
    case mainPhotoAdded = "MAIN_PHOTO_ADDED"
    case stepPhotosAdded = "STEP_PHOTOS_ADDED"
    case videoAdded = "VIDEO_ADDED"
    case fullRecipeCompleted = "FULL_RECIPE_COMPLETED"
    case nutritionInfoAdded = "NUTRITION_INFO_ADDED"

    // RECEIVING ENGAGEMENT
    case likeReceived = "LIKE_RECEIVED"
    case commentReceived = "COMMENT_RECEIVED"
    case saveReceived = "SAVE_RECEIVED"
    case shareReceived = "SHARE_RECEIVED"
    case recipeCookedByOtherUser = "RECIPE_COOKED_BY_OTHER_USER"
    case ratingReceived = "RATING_RECEIVED"
    case followerGained = "FOLLOWER_GAINED"

    // ACTIVE USER ACTIONS
    case recipeSaved = "RECIPE_SAVED"
    case commentWritten = "COMMENT_WRITTEN"
    case userFollowed = "USER_FOLLOWED"
    case recipeCooked = "RECIPE_COOKED"
    case dailyQualifyingVisit = "DAILY_QUALIFYING_VISIT"

    // MILESTONE BONUSES
    case completeProfile = "COMPLETE_PROFILE"
    case firstRecipePublished = "FIRST_RECIPE_PUBLISHED"
    case firstLikeReceived = "FIRST_LIKE_RECEIVED"
    case firstCommentReceived = "FIRST_COMMENT_RECEIVED"
    case firstFollowerGained = "FIRST_FOLLOWER_GAINED"
    case tenLikesReceived = "TEN_LIKES_RECEIVED"
    case fiftyLikesReceived = "FIFTY_LIKES_RECEIVED"
    case oneHundredLikesReceived = "ONE_HUNDRED_LIKES_RECEIVED"
    case fiveRecipesPublished = "FIVE_RECIPES_PUBLISHED"
    case tenRecipesPublished = "TEN_RECIPES_PUBLISHED"
    case tenFollowersGained = "TEN_FOLLOWERS_GAINED"
    case oneHundredFollowersGained = "ONE_HUNDRED_FOLLOWERS_GAINED"
}

enum XPLevelCalculator {
    static func roundToNearestFive(_ value: Double) -> Int {
        Int((value / 5.0).rounded() * 5.0)
    }

    /// XP required to go from level L to L+1.
    static func xpToNextLevel(level: Int) -> Int {
        let L = max(1, level)
        return roundToNearestFive(25.0 + 10.0 * Double(L) + 5.0 * pow(Double(L), 1.5))
    }

    /// Total XP threshold where `level` starts.
    static func totalXPRequiredForLevel(_ level: Int) -> Int {
        guard level > 1 else { return 0 }
        return (1..<(level)).reduce(0) { partial, lvl in
            partial + xpToNextLevel(level: lvl)
        }
    }

    /// Derive current level from lifetime XP.
    static func levelFromXP(_ totalXP: Int) -> Int {
        let safeXP = max(0, totalXP)
        var level = 1
        while safeXP >= totalXPRequiredForLevel(level + 1) {
            level += 1
        }
        return level
    }

    static func getLevelTitle(level: Int) -> String {
        switch max(1, level) {
        case 1...5:
            return "Kitchen Newbie"
        case 6...10:
            return "Home Cook"
        case 11...15:
            return "Recipe Explorer"
        case 16...20:
            return "Skilled Cook"
        case 21...30:
            return "Rising Chef"
        case 31...40:
            return "Master Chef"
        case 41...50:
            return "Culinary Star"
        default:
            return "Legendary Chef"
        }
    }

    static func getLevelProgress(totalXP: Int) -> XPLevelProgress {
        let safeXP = max(0, totalXP)
        let currentLevel = levelFromXP(safeXP)
        let currentLevelXP = totalXPRequiredForLevel(currentLevel)
        let nextLevelXP = totalXPRequiredForLevel(currentLevel + 1)
        let xpIntoCurrentLevel = max(0, safeXP - currentLevelXP)
        let xpNeededForNextLevel = max(0, nextLevelXP - safeXP)
        let denominator = max(1, nextLevelXP - currentLevelXP)
        let progressPercent = min(100.0, max(0.0, (Double(xpIntoCurrentLevel) / Double(denominator)) * 100.0))

        return XPLevelProgress(
            currentLevel: currentLevel,
            totalXP: safeXP,
            currentLevelXP: currentLevelXP,
            nextLevelXP: nextLevelXP,
            xpIntoCurrentLevel: xpIntoCurrentLevel,
            xpNeededForNextLevel: xpNeededForNextLevel,
            progressPercent: progressPercent
        )
    }

    static func xpValue(for action: XPActionType) -> Int {
        switch action {
        case .recipePublished: return 20
        case .mainPhotoAdded: return 5
        case .stepPhotosAdded: return 0
        case .videoAdded: return 0
        case .fullRecipeCompleted: return 0
        case .nutritionInfoAdded: return 0
        case .likeReceived: return 1
        case .commentReceived: return 4
        case .saveReceived: return 3
        case .shareReceived: return 5
        case .recipeCookedByOtherUser: return 0
        case .ratingReceived: return 0
        case .followerGained: return 10
        case .recipeSaved: return 0
        case .commentWritten: return 2
        case .userFollowed: return 1
        case .recipeCooked: return 0
        case .dailyQualifyingVisit: return 0
        case .completeProfile: return 0
        case .firstRecipePublished: return 0
        case .firstLikeReceived: return 0
        case .firstCommentReceived: return 0
        case .firstFollowerGained: return 0
        case .tenLikesReceived: return 0
        case .fiftyLikesReceived: return 0
        case .oneHundredLikesReceived: return 0
        case .fiveRecipesPublished: return 0
        case .tenRecipesPublished: return 0
        case .tenFollowersGained: return 0
        case .oneHundredFollowersGained: return 0
        }
    }
}

// MARK: - Progress DTO

struct XPLevelProgress: Equatable {
    let currentLevel: Int
    let totalXP: Int
    let currentLevelXP: Int
    let nextLevelXP: Int
    let xpIntoCurrentLevel: Int
    let xpNeededForNextLevel: Int
    let progressPercent: Double
}

enum XPRuleEvaluator {
    static func shouldAward(
        actionType: XPActionType,
        receiverUserId: String,
        actorUserId: String,
        eventId: String,
        existingEventIDs: Set<String>
    ) -> Bool {
        if receiverUserId == actorUserId {
            switch actionType {
            case .likeReceived, .saveReceived, .commentReceived, .followerGained:
                return false
            default:
                break
            }
        }
        return !existingEventIDs.contains(eventId)
    }
}


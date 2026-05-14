//
//  MisotoTests.swift
//  MisotoTests
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Testing
@testable import Misoto

struct MisotoTests {

    @Test func recipeChangeProposalTargetKindRawValues() {
        #expect(RecipeChangeProposal.TargetKind.ingredient.rawValue == "ingredient")
        #expect(RecipeChangeProposal.TargetKind.instruction.rawValue == "instruction")
        #expect(RecipeChangeProposal.TargetKind.tip.rawValue == "tip")
        #expect(RecipeChangeProposal.TargetKind.description.rawValue == "description")
    }

    @Test func levelFromXPValidationPoints() {
        #expect(XPLevelCalculator.levelFromXP(0) == 1)
        #expect(XPLevelCalculator.levelFromXP(40) == 2)
        #expect(XPLevelCalculator.levelFromXP(100) == 3)
        #expect(XPLevelCalculator.levelFromXP(180) == 4)
    }

    @Test func levelTitleBands() {
        #expect(XPLevelCalculator.getLevelTitle(level: 1) == "Kitchen Newbie")
        #expect(XPLevelCalculator.getLevelTitle(level: 8) == "Home Cook")
        #expect(XPLevelCalculator.getLevelTitle(level: 18) == "Skilled Cook")
        #expect(XPLevelCalculator.getLevelTitle(level: 35) == "Master Chef")
        #expect(XPLevelCalculator.getLevelTitle(level: 51) == "Legendary Chef")
    }

    @Test func duplicateEventDoesNotAwardTwice() {
        let eventID = "LIKE_RECEIVED:actorA:recipe1"
        let first = XPRuleEvaluator.shouldAward(
            actionType: .likeReceived,
            receiverUserId: "ownerA",
            actorUserId: "actorA",
            eventId: eventID,
            existingEventIDs: []
        )
        let second = XPRuleEvaluator.shouldAward(
            actionType: .likeReceived,
            receiverUserId: "ownerA",
            actorUserId: "actorA",
            eventId: eventID,
            existingEventIDs: [eventID]
        )
        #expect(first)
        #expect(!second)
    }

    @Test func selfLikeDoesNotAwardXP() {
        let canAward = XPRuleEvaluator.shouldAward(
            actionType: .likeReceived,
            receiverUserId: "userA",
            actorUserId: "userA",
            eventId: "LIKE_RECEIVED:userA:recipeA",
            existingEventIDs: []
        )
        #expect(!canAward)
    }

    @Test func unlikeRelikeDoesNotAwardAgain() {
        let eventID = "LIKE_RECEIVED:actorA:recipeA"
        let initialAward = XPRuleEvaluator.shouldAward(
            actionType: .likeReceived,
            receiverUserId: "ownerA",
            actorUserId: "actorA",
            eventId: eventID,
            existingEventIDs: []
        )
        let reLikeAward = XPRuleEvaluator.shouldAward(
            actionType: .likeReceived,
            receiverUserId: "ownerA",
            actorUserId: "actorA",
            eventId: eventID,
            existingEventIDs: [eventID]
        )
        #expect(initialAward)
        #expect(!reLikeAward)
    }

    @Test func followIndexSnapshotLowercasingAndMapping() {
        let user = AppUser(
            id: "user-123",
            displayName: "Chef Daniel",
            username: "ChefDan",
            profileImageURL: "https://example.com/avatar.jpg",
            premiumUser: true
        )
        let snapshot = FollowIndexUserSnapshot(user: user)

        #expect(snapshot.userID == "user-123")
        #expect(snapshot.displayNameLower == "chef daniel")
        #expect(snapshot.usernameLower == "chefdan")
        #expect(snapshot.premiumUser)

        let mappedUser = snapshot.toAppUser()
        #expect(mappedUser.id == user.id)
        #expect(mappedUser.displayName == user.displayName)
        #expect(mappedUser.username == user.username)
        #expect(mappedUser.profileImageURL == user.profileImageURL)
        #expect(mappedUser.premiumUser == user.premiumUser)
    }

    @Test func marketingVersionOrdering() {
        #expect(AppVersionComparator.compareMarketingVersions("1.0.0", "1.0.0") == .orderedSame)
        #expect(AppVersionComparator.isMarketingVersionNewer("1.0.1", than: "1.0.0"))
        #expect(AppVersionComparator.isMarketingVersionNewer("2.0", than: "1.9"))
        #expect(AppVersionComparator.isMarketingVersionNewer("1.2.10", than: "1.2.3"))
        #expect(!AppVersionComparator.isMarketingVersionNewer("1.2.3", than: "1.2.10"))
    }

    @Test func followIndexSnapshotHandlesMissingUsername() {
        let user = AppUser(
            id: "user-456",
            displayName: "No Username User",
            username: nil
        )
        let snapshot = FollowIndexUserSnapshot(user: user)
        #expect(snapshot.username == "")
        #expect(snapshot.usernameLower == "")

        let mappedUser = snapshot.toAppUser()
        #expect(mappedUser.username == nil)
    }

}

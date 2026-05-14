//
//  AccountViewModel.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AccountViewModel: ObservableObject {
    @Published var userRecipes: [Recipe] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var incomingChangeProposals: [RecipeChangeProposal] = []
    @Published var unreadChangeProposalCount: Int = 0
    @Published var userProgress: UserProgress?
    
    private let recipeService = RecipeService.shared
    private let changeProposalService = RecipeChangeProposalService()
    private let authService = AuthService()
    private let localNotificationService = LocalNotificationService.shared
    private let firestore = FirebaseManager.shared.firestore
    private let xpService = XPService.shared
    private var userListener: ListenerRegistration?
    private var proposalListener: ListenerRegistration?
    private var progressListener: ListenerRegistration?
    private var tokenObserver: NSObjectProtocol?
    private var hasInitializedProposalSnapshot = false
    var authViewModel: AuthViewModel?
    private var currentObservedUserID: String?
    
    private var proposalSeenKey: String {
        let userID = Auth.auth().currentUser?.uid ?? "unknown"
        return "recipeChangeProposals.lastSeenAt.\(userID)"
    }
    
    private var notifiedProposalIDsKey: String {
        let userID = Auth.auth().currentUser?.uid ?? "unknown"
        return "recipeChangeProposals.notifiedIDs.\(userID)"
    }
    
    init() {
        tokenObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("APNsDeviceTokenUpdated"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            guard let token = notification.userInfo?["token"] as? String else { return }
            Task { @MainActor in
                await self.savePushTokenIfPossible(token)
            }
        }
    }
    
    deinit {
        userListener?.remove()
        proposalListener?.remove()
        progressListener?.remove()
        if let tokenObserver {
            NotificationCenter.default.removeObserver(tokenObserver)
        }
    }
    
    // MARK: - Real-time User Stats Listener
    
    private func setupUserListener(for userID: String) {
        userListener?.remove()
        
        let userRef = firestore.collection("users").document(userID)
        userListener = userRef.addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error listening to user updates: \(error.localizedDescription)")
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists else { return }
                
                // Reload user data in AuthService to update currentUser
                // This will trigger the Combine publisher and update AuthViewModel
                await self.authService.reloadUserData()
                print("✅ User data updated from real-time listener")
            }
        }
    }
    
    /// Clears account-scoped state and rebinds listeners when auth user changes.
    func handleAuthUserChanged(userID: String?) {
        guard currentObservedUserID != userID else { return }
        currentObservedUserID = userID
        
        // Always clear previous account data immediately to prevent cross-account leakage.
        userRecipes = []
        incomingChangeProposals = []
        unreadChangeProposalCount = 0
        userProgress = nil
        errorMessage = nil
        isLoading = false
        
        userListener?.remove()
        userListener = nil
        proposalListener?.remove()
        proposalListener = nil
        progressListener?.remove()
        progressListener = nil
        hasInitializedProposalSnapshot = false
        
        guard let userID else { return }
        setupUserListener(for: userID)
        setupIncomingProposalListener(for: userID)
        setupUserProgressListener(for: userID)
        Task {
            await loadUserProgress()
        }
        
        Task {
            await localNotificationService.requestAuthorizationIfNeeded()
        }
    }

    func loadUserProgress() async {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        if let progress = try? await xpService.getUserProgress(userId: userID) {
            let derivedLevel = XPLevelCalculator.levelFromXP(progress.totalXP)
            let derivedTitle = XPLevelCalculator.getLevelTitle(level: derivedLevel)
            userProgress = UserProgress(
                userId: progress.userId,
                totalXP: progress.totalXP,
                currentLevel: derivedLevel,
                currentTitle: derivedTitle,
                createdAt: progress.createdAt,
                updatedAt: progress.updatedAt
            )
        }
    }

    private func setupUserProgressListener(for userID: String) {
        progressListener?.remove()
        let ref = firestore.collection("userProgress").document(userID)
        progressListener = ref.addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error {
                    print("⚠️ User progress listener error: \(error.localizedDescription)")
                    return
                }
                guard let snapshot, snapshot.exists,
                      let progress = try? snapshot.data(as: UserProgress.self) else {
                    return
                }
                let previousProgress = self.userProgress
                let derivedLevel = XPLevelCalculator.levelFromXP(progress.totalXP)
                let derivedTitle = XPLevelCalculator.getLevelTitle(level: derivedLevel)
                self.userProgress = UserProgress(
                    userId: progress.userId,
                    totalXP: progress.totalXP,
                    currentLevel: derivedLevel,
                    currentTitle: derivedTitle,
                    createdAt: progress.createdAt,
                    updatedAt: progress.updatedAt
                )
                
                if let previousProgress {
                    let deltaXP = progress.totalXP - previousProgress.totalXP
                    if deltaXP != 0 {
                        let levelDelta = derivedLevel - previousProgress.currentLevel
                        let previousToNext = XPLevelCalculator.getLevelProgress(totalXP: previousProgress.totalXP).xpNeededForNextLevel
                        let currentToNext = XPLevelCalculator.getLevelProgress(totalXP: progress.totalXP).xpNeededForNextLevel
                        print("🧪 XP DEBUG | delta=\(deltaXP > 0 ? "+" : "")\(deltaXP) | total: \(previousProgress.totalXP) -> \(progress.totalXP) | level: \(previousProgress.currentLevel) -> \(derivedLevel) | toNext: \(previousToNext) -> \(currentToNext)")
                        if levelDelta > 0 {
                            print("🧪 XP DEBUG | LEVEL UP x\(levelDelta) | new title: \(derivedTitle)")
                        }
                    }
                } else {
                    print("🧪 XP DEBUG | initial progress snapshot totalXP=\(progress.totalXP), level=\(derivedLevel), title=\(derivedTitle)")
                }
            }
        }
    }

    private func savePushTokenIfPossible(_ token: String) async {
        guard let userID = Auth.auth().currentUser?.uid, !token.isEmpty else { return }
        let installationID = currentInstallationID()
        do {
            try await firestore.collection("users").document(userID).collection("devices").document(installationID).setData([
                "pushToken": token,
                "platform": "ios",
                "notificationsEnabled": true,
                "pushTokenUpdatedAt": Timestamp(date: Date())
            ], merge: true)
            print("✅ Saved APNs token for installation \(installationID)")
        } catch {
            print("⚠️ Failed to save APNs token: \(error.localizedDescription)")
        }
    }
    
    private func currentInstallationID() -> String {
        let key = "push.installationID"
        if let cached = UserDefaults.standard.string(forKey: key), !cached.isEmpty {
            return cached
        }
        let generated = UUID().uuidString
        UserDefaults.standard.set(generated, forKey: key)
        return generated
    }
    
    // MARK: - Recipe Management
    
    func loadUserRecipes() async {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("⚠️ No user ID found")
            return
        }
        
        print("🔍 Loading recipes for user: \(userID)")
        isLoading = true
        errorMessage = nil
        
        do {
            userRecipes = try await recipeService.fetchRecipes(byUserID: userID)
            print("✅ Loaded \(userRecipes.count) recipes")
        } catch {
            print("❌ Error loading recipes: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Change Proposal Notifications
    
    func loadIncomingChangeProposals() async {
        do {
            incomingChangeProposals = try await changeProposalService.fetchIncomingProposals(limit: 100)
            recalculateUnreadChangeProposalCount()
        } catch {
            print("⚠️ Error loading incoming change proposals: \(error.localizedDescription)")
        }
    }
    
    func markIncomingProposalsSeenNow() {
        let now = Date()
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: proposalSeenKey)
        recalculateUnreadChangeProposalCount()
    }
    
    private func recalculateUnreadChangeProposalCount() {
        let lastSeenTimestamp = UserDefaults.standard.double(forKey: proposalSeenKey)
        let lastSeenDate = lastSeenTimestamp > 0 ? Date(timeIntervalSince1970: lastSeenTimestamp) : .distantPast
        
        unreadChangeProposalCount = incomingChangeProposals.filter { proposal in
            proposal.createdAt > lastSeenDate
        }.count
    }
    
    private func setupIncomingProposalListener(for userID: String) {
        proposalListener?.remove()
        
        let query = firestore.collection("recipeChangeProposals")
            .whereField("recipeAuthorID", isEqualTo: userID)
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
        
        proposalListener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let error = error {
                    print("⚠️ Proposal listener failed (ordered query): \(error.localizedDescription)")
                    // Keep existing behavior by falling back to one-time fetch.
                    await self.loadIncomingChangeProposals()
                    return
                }
                
                guard let snapshot else { return }
                let proposals: [RecipeChangeProposal] = snapshot.documents.compactMap { document in
                    guard var proposal = try? document.data(as: RecipeChangeProposal.self) else { return nil }
                    proposal.id = document.documentID
                    return proposal
                }
                
                self.incomingChangeProposals = proposals
                self.recalculateUnreadChangeProposalCount()
                self.handleIncomingProposalNotification(proposals)
            }
        }
    }
    
    private func handleIncomingProposalNotification(_ proposals: [RecipeChangeProposal]) {
        let storedIDs = Set(UserDefaults.standard.stringArray(forKey: notifiedProposalIDsKey) ?? [])
        var nextStoredIDs = storedIDs
        
        // On first snapshot, establish baseline (don't notify for old items).
        if !hasInitializedProposalSnapshot {
            hasInitializedProposalSnapshot = true
            nextStoredIDs.formUnion(proposals.map(\.id))
            UserDefaults.standard.set(Array(nextStoredIDs), forKey: notifiedProposalIDsKey)
            return
        }
        
        // Notify only for fresh, unseen IDs.
        let newProposals = proposals.filter { !storedIDs.contains($0.id) }
        guard !newProposals.isEmpty else { return }
        
        // Remote APNs is now the source of truth for recommendation notifications.
        // Keep local bookkeeping for unread state/idempotency, but don't emit local duplicates.
        newProposals.forEach { proposal in
            nextStoredIDs.insert(proposal.id)
        }
        
        UserDefaults.standard.set(Array(nextStoredIDs), forKey: notifiedProposalIDsKey)
    }
    
    func toggleRecipePrivacy(recipe: Recipe, clearSharedWith: Bool = false) async {
        let recipeID = recipe.id
        let newPrivacyStatus = !recipe.isPrivate
        
        // Optimistic update: Update UI immediately
        if let index = userRecipes.firstIndex(where: { $0.id == recipeID }) {
            let currentSharedWith = userRecipes[index].sharedWith
            userRecipes[index].isPrivate = newPrivacyStatus
            
            // If making private and clearSharedWith is true: Save current sharedWith to preservedSharedWith, then clear sharedWith
            if newPrivacyStatus && clearSharedWith {
                // Save current sharedWith to preservedSharedWith before clearing (if it has users)
                if !currentSharedWith.isEmpty {
                    userRecipes[index].preservedSharedWith = currentSharedWith
                }
                // Always clear sharedWith when making "Private to All" (removes access)
                userRecipes[index].sharedWith = []
            }
            // When making public: Restore preservedSharedWith to sharedWith if it exists
            else if !newPrivacyStatus {
                // Restore preserved sharedWith list if it exists
                if let preserved = userRecipes[index].preservedSharedWith, !preserved.isEmpty {
                    userRecipes[index].sharedWith = preserved
                    userRecipes[index].preservedSharedWith = nil // Clear preserved list after restore
                }
                // If no preserved list, keep current sharedWith as-is
            }
            // When making private with clearSharedWith=false: Preserve sharedWith (for "Private Sharing" flow)
            //   No changes needed - sharedWith is already set correctly
            print("✅ Recipe privacy updated optimistically in UI, sharedWith: \(userRecipes[index].sharedWith.count) users, preserved: \(userRecipes[index].preservedSharedWith?.count ?? 0) users")
        }
        
        // Update backend
        do {
            try await recipeService.toggleRecipePrivacy(recipeID: recipeID, isPrivate: newPrivacyStatus, clearSharedWith: clearSharedWith)
            print("✅ Recipe privacy updated in backend")
        } catch {
            // Revert optimistic update on error
            if let index = userRecipes.firstIndex(where: { $0.id == recipeID }) {
                userRecipes[index].isPrivate = !newPrivacyStatus
                // Restore original sharedWith if reverting
                if newPrivacyStatus && clearSharedWith {
                    userRecipes[index].sharedWith = recipe.sharedWith
                }
            }
            print("❌ Error toggling recipe privacy: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    func updateRecipeSharing(recipe: Recipe, sharedWith: [String]) async {
        let recipeID = recipe.id
        
        // Optimistic update: Update UI immediately
        // Clear preservedSharedWith when user explicitly sets sharing
        if let index = userRecipes.firstIndex(where: { $0.id == recipeID }) {
            userRecipes[index].sharedWith = sharedWith
            // Ensure recipe is private when sharing
            userRecipes[index].isPrivate = true
            // Clear preservedSharedWith when user explicitly sets sharing (they're choosing new users)
            userRecipes[index].preservedSharedWith = nil
            print("✅ Recipe sharing updated optimistically in UI")
        }
        
        // Update backend
        do {
            try await recipeService.updateRecipeSharing(recipeID: recipeID, sharedWith: sharedWith)
            print("✅ Recipe sharing updated in backend")
        } catch {
            // Revert optimistic update on error
            if let index = userRecipes.firstIndex(where: { $0.id == recipeID }) {
                userRecipes[index].sharedWith = recipe.sharedWith
            }
            print("❌ Error updating recipe sharing: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteRecipe(_ recipe: Recipe) {
        // Optimistic update: Remove from UI immediately (synchronous, no async)
        let recipeID = recipe.id
        userRecipes.removeAll { $0.id == recipeID }
        print("✅ Recipe removed from UI instantly")
        
        // Optimistically update recipe count in user object
        if var currentUser = authService.currentUser {
            currentUser.recipeCount = max(0, currentUser.recipeCount - 1)
            authService.currentUser = currentUser
            print("✅ Recipe count updated optimistically: \(currentUser.recipeCount)")
        }
        
        // Delete from backend asynchronously in background (don't block UI)
        Task { @MainActor in
            do {
                // Delete recipe and update Firebase recipe count
                try await recipeService.deleteRecipe(recipeID: recipeID)
                print("✅ Recipe deleted from backend and Firebase recipeCount decremented")
                
                // Post notification to refresh feeds/views
                NotificationCenter.default.post(name: NSNotification.Name("RecipeDeleted"), object: nil, userInfo: ["recipeID": recipeID])
                
                // Explicitly reload user data to ensure UI reflects the updated count from Firebase
                await authService.reloadUserData()
                if let authVM = authViewModel {
                    await authVM.reloadUserData()
                }
                print("✅ User data reloaded - recipe count should now be: \(authService.currentUser?.recipeCount ?? 0)")
            } catch {
                // If deletion fails, log the error but don't disrupt UI
                print("❌ Error deleting recipe from backend: \(error.localizedDescription)")
                // Revert optimistic update if deletion failed
                if var currentUser = authService.currentUser {
                    currentUser.recipeCount += 1
                    authService.currentUser = currentUser
                }
            }
        }
    }
    
    // MARK: - Profile Updates
    
    func updateProfile(displayName: String?, username: String?, bio: String?) async throws {
        try await authService.updateProfile(displayName: displayName, username: username, bio: bio)
    }
    
    func uploadProfileImage(_ image: UIImage) async throws {
        _ = try await authService.uploadProfileImage(image)
    }
    
    func generateUsernameAlternatives(_ username: String) -> [String] {
        return authService.generateUsernameAlternatives(username)
    }
    
    func checkUsernameAvailability(_ username: String) async throws -> Bool {
        guard let userID = Auth.auth().currentUser?.uid else {
            return false
        }
        return try await authService.isUsernameAvailable(username, excludingUserID: userID)
    }
    
    // MARK: - Account Management
    
    func toggleProfileVisibility(hidden: Bool) async throws {
        try await authService.toggleProfileVisibility(hidden: hidden)
    }
    
    func toggleCompletePrivacy(isPrivate: Bool) async throws {
        try await authService.toggleCompletePrivacy(isPrivate: isPrivate)
    }
    
    func deleteAccount() async throws {
        try await authService.deleteAccount()
    }
}


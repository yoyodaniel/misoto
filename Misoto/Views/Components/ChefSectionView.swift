//
//  ChefSectionView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

struct ChefSectionView: View {
    let creatorID: String
    let creatorName: String
    let creatorUsername: String?
    let hasNotes: Bool
    var showLoginSheet: Binding<Bool>? = nil
    @StateObject private var viewModel: ChefSectionViewModel
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showUserProfile = false
    @State private var showLoginSheetLocal = false
    
    init(creatorID: String, creatorName: String, creatorUsername: String?, hasNotes: Bool = false, showLoginSheet: Binding<Bool>? = nil) {
        self.creatorID = creatorID
        self.creatorName = creatorName
        self.creatorUsername = creatorUsername
        self.hasNotes = hasNotes
        self.showLoginSheet = showLoginSheet
        _viewModel = StateObject(wrappedValue: ChefSectionViewModel(creatorID: creatorID))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Tappable Profile Section (opens profile sheet)
                Button(action: {
                    HapticFeedback.buttonTap()
                    showUserProfile = true
                }) {
                    HStack(spacing: 12) {
                        // Profile Picture
                        if let profileImageURL = viewModel.creator?.profileImageURL, let url = URL(string: profileImageURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                        }
                        
                        // Name and Username
                        VStack(alignment: .leading, spacing: 4) {
                            ZStack(alignment: .topTrailing) {
                                Text(viewModel.creator?.displayName ?? creatorName)
                                    .font(.headline)
                                
                                if let creator = viewModel.creator, creator.premiumUser {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.blue)
                                        .offset(x: 16, y: -1)
                                }
                            }
                            
                            if let username = viewModel.creator?.username ?? creatorUsername {
                                Text("@\(username)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Follow/Unfollow Button (separate from profile tap)
                if let currentUserID = Auth.auth().currentUser?.uid,
                   currentUserID != creatorID {
                    // Authenticated user - show Follow/Unfollow button
                    Button(action: {
                        Task {
                            await viewModel.toggleFollow()
                        }
                    }) {
                        HStack(spacing: 6) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: viewModel.isFollowing ? .primary : .white))
                                    .scaleEffect(0.8)
                            }
                            Text(viewModel.isFollowing ? LocalizedString("Unfollow", comment: "Unfollow button") : LocalizedString("Follow", comment: "Follow button"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .foregroundColor(viewModel.isFollowing ? .primary : .white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .frame(minWidth: 120)
                        .background(viewModel.isFollowing ? Color(.systemGray5) : Color.accentColor)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(viewModel.isFollowing ? Color(.systemGray3) : Color.clear, lineWidth: 1)
                        )
                    }
                    .disabled(viewModel.isLoading)
                } else if Auth.auth().currentUser == nil {
                    // Not authenticated - show Follow button that opens login sheet
                    Button(action: {
                        HapticFeedback.buttonTap()
                        if let showLoginSheet = showLoginSheet {
                            showLoginSheet.wrappedValue = true
                        } else {
                            showLoginSheetLocal = true
                        }
                    }) {
                        Text(LocalizedString("Follow", comment: "Follow button"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .frame(minWidth: 120)
                            .background(Color.accentColor)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.bottom, hasNotes ? 6 : 18)
        .sheet(isPresented: $showUserProfile) {
            UserProfileView(userID: creatorID)
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showLoginSheetLocal) {
            LoginView()
                .environmentObject(authViewModel)
        }
        .task {
            await viewModel.loadCreatorData()
            await viewModel.checkFollowStatus()
        }
    }
}

@MainActor
class ChefSectionViewModel: ObservableObject {
    @Published var creator: AppUser?
    @Published var isFollowing: Bool = false
    @Published var isLoading: Bool = false
    
    private let creatorID: String
    private let friendsService = FriendsService()
    private let authService = AuthService()
    private let firestore = FirebaseManager.shared.firestore
    private var followListener: ListenerRegistration?
    
    init(creatorID: String) {
        self.creatorID = creatorID
    }
    
    deinit {
        followListener?.remove()
    }
    
    func loadCreatorData() async {
        do {
            let document = try await firestore.collection("users").document(creatorID).getDocument()
            creator = try? document.data(as: AppUser.self)
        } catch {
            print("⚠️ Error loading creator data: \(error.localizedDescription)")
        }
    }
    
    func checkFollowStatus() async {
        guard let currentUserID = FirebaseAuth.Auth.auth().currentUser?.uid else {
            isFollowing = false
            return
        }
        
        do {
            isFollowing = try await friendsService.isFollowing(followerID: currentUserID, followingID: creatorID)
            // Set up real-time listener for follow status
            setupFollowListener(followerID: currentUserID, followingID: creatorID)
        } catch {
            print("⚠️ Error checking follow status: \(error.localizedDescription)")
            isFollowing = false
        }
    }
    
    private func setupFollowListener(followerID: String, followingID: String) {
        // Remove existing listener if any
        followListener?.remove()
        
        // Set up real-time listener for the follow document
        let query = firestore.collection("follows")
            .whereField("followerID", isEqualTo: followerID)
            .whereField("followingID", isEqualTo: followingID)
            .limit(to: 1)
        
        followListener = query.addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let error = error {
                    print("⚠️ Error listening to follow status: \(error.localizedDescription)")
                    return
                }
                
                // Update isFollowing based on whether documents exist
                self.isFollowing = !(snapshot?.documents.isEmpty ?? true)
                print("🔄 Follow status updated: \(self.isFollowing)")
            }
        }
    }
    
    func toggleFollow() async {
        guard let currentUserID = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        do {
            if isFollowing {
                try await friendsService.unfollowUser(followingID: creatorID)
                isFollowing = false
                // Update local follower count
                creator?.followerCount = max(0, (creator?.followerCount ?? 0) - 1)
            } else {
                try await friendsService.followUser(followingID: creatorID)
                isFollowing = true
                // Update local follower count
                creator?.followerCount = (creator?.followerCount ?? 0) + 1
            }
            
            // Reload current user data to update followingCount in profile
            // The real-time listener in AccountViewModel will also pick this up, but this ensures immediate update
            print("🔄 Reloading user data after follow/unfollow...")
            await authService.reloadUserData()
            print("✅ User data reloaded - followingCount should be: \(authService.currentUser?.followingCount ?? 0)")
            
            // Post notification to trigger UI refresh in AccountView
            NotificationCenter.default.post(name: NSNotification.Name("UserDataUpdated"), object: nil)
            
            // Also reload creator data if it's the current user viewing their own profile
            if creatorID == currentUserID {
                await loadCreatorData()
            }
        } catch {
            print("⚠️ Error toggling follow: \(error.localizedDescription)")
            // On error, re-check the follow status to ensure UI is in sync
            await checkFollowStatus()
        }
        
        isLoading = false
    }
}

#Preview {
    ChefSectionView(
        creatorID: "123",
        creatorName: "Chef John",
        creatorUsername: "chefjohn"
    )
    .padding()
}


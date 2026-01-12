//
//  UserProfileView.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

struct UserProfileView: View {
    let userID: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: UserProfileViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var showLoginSheet = false
    
    init(userID: String) {
        self.userID = userID
        _viewModel = StateObject(wrappedValue: UserProfileViewModel(userID: userID))
    }
    
    private var isOwnProfile: Bool {
        Auth.auth().currentUser?.uid == userID
    }
    
    private var isAuthenticated: Bool {
        Auth.auth().currentUser != nil
    }
    
    var body: some View {
        let _ = localizationManager.currentLanguage // Force view update when language changes
        return NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Profile Header
                        if let user = viewModel.user {
                            VStack(spacing: 16) {
                                // Profile Picture
                                if let imageURL = user.profileImageURL, let url = URL(string: imageURL) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        case .failure(_), .empty:
                                            Circle()
                                                .fill(Color(.secondarySystemBackground))
                                                .overlay {
                                                    Image(systemName: "person.fill")
                                                        .font(.system(size: 40))
                                                        .foregroundColor(.secondary)
                                                }
                                        @unknown default:
                                            Circle()
                                                .fill(Color(.secondarySystemBackground))
                                                .overlay {
                                                    Image(systemName: "person.fill")
                                                        .font(.system(size: 40))
                                                        .foregroundColor(.secondary)
                                                }
                                        }
                                    }
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color(.secondarySystemBackground))
                                        .frame(width: 100, height: 100)
                                        .overlay {
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.secondary)
                                        }
                                }
                                
                                // Name
                                Text(user.displayName)
                                    .font(.system(size: 22, weight: .bold))
                                
                                // Username
                                if let username = user.username, !username.isEmpty {
                                    Text("@\(username)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Bio
                                if let bio = user.bio, !bio.isEmpty {
                                    Text(bio)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                                
                                // Buttons - Different for own profile vs other users
                                HStack(spacing: 12) {
                                    if isOwnProfile {
                                        // Edit Profile button for own profile
                                        Button(action: {
                                            HapticFeedback.buttonTap()
                                            showEditProfile = true
                                        }) {
                                            Text(LocalizedString("Edit Profile", comment: "Edit profile button"))
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 24)
                                                .padding(.vertical, 8)
                                                .background(Color.accentColor)
                                                .cornerRadius(8)
                                        }
                                        
                                        // Settings button for own profile
                                        Button(action: {
                                            HapticFeedback.buttonTap()
                                            showSettings = true
                                        }) {
                                            Image(systemName: "gearshape.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(.primary)
                                                .frame(width: 36, height: 36)
                                                .background(Color(.secondarySystemBackground))
                                                .cornerRadius(8)
                                        }
                                    } else {
                                        // Follow/Unfollow button for other users (only shown if authenticated)
                                        if isAuthenticated {
                                            Button(action: {
                                                HapticFeedback.buttonTap()
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
                                                .padding(.vertical, 8)
                                                .frame(minWidth: 120)
                                                .background(viewModel.isFollowing ? Color(.systemGray5) : Color.accentColor)
                                                .cornerRadius(8)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(viewModel.isFollowing ? Color(.systemGray3) : Color.clear, lineWidth: 1)
                                                )
                                            }
                                            .disabled(viewModel.isLoading)
                                        } else {
                                            // Show "Follow" button that opens login sheet when not authenticated
                                            Button(action: {
                                                HapticFeedback.buttonTap()
                                                showLoginSheet = true
                                            }) {
                                                Text(LocalizedString("Follow", comment: "Follow button"))
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .lineLimit(1)
                                                    .fixedSize(horizontal: true, vertical: false)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 24)
                                                    .padding(.vertical, 8)
                                                    .frame(minWidth: 120)
                                                    .background(Color.accentColor)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 4)
                                
                                // Stats
                                HStack(spacing: 30) {
                                    StatItem(value: "\(user.recipeCount)", label: LocalizedString("Recipes", comment: "Recipes count"))
                                    StatItem(value: "\(user.followerCount)", label: LocalizedString("Followers", comment: "Followers count"))
                                    StatItem(value: "\(user.followingCount)", label: LocalizedString("Following", comment: "Following count"))
                                    StatItem(value: "\(user.likesCount)", label: LocalizedString("Likes", comment: "Likes count"))
                                }
                                .padding(.top, 8)
                            }
                            .padding(.top, 20)
                            .padding(.bottom, 24)
                        } else if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        }
                        
                        // Recipes Grid
                        if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        } else if !viewModel.userRecipes.isEmpty {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 1),
                                GridItem(.flexible(), spacing: 1),
                                GridItem(.flexible(), spacing: 1)
                            ], spacing: 1) {
                                ForEach(viewModel.userRecipes) { recipe in
                                    GeometryReader { geometry in
                                        if let imageURL = recipe.imageURL, let url = URL(string: imageURL) {
                                            AsyncImage(url: url) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                            }
                                            .frame(width: geometry.size.width, height: geometry.size.width)
                                            .clipped()
                                        } else {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: geometry.size.width, height: geometry.size.width)
                                        }
                                    }
                                    .aspectRatio(1, contentMode: .fit)
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedString("Close", comment: "Close button")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                if let accountViewModel = viewModel.accountViewModel {
                    EditProfileView(viewModel: accountViewModel, authViewModel: authViewModel)
                } else {
                    // Fallback - should not happen if isOwnProfile check is correct
                    Text("Error loading profile editor")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showLoginSheet) {
                LoginView()
                    .environmentObject(authViewModel)
            }
            .task {
                // Set authViewModel reference for AccountViewModel
                viewModel.accountViewModel?.authViewModel = authViewModel
                await viewModel.loadUserData()
                await viewModel.loadUserRecipes()
                await viewModel.checkFollowStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RecipeDeleted"))) { notification in
                // Refresh user recipes when a recipe is deleted
                Task {
                    let recipeID = notification.userInfo?["recipeID"] as? String
                    
                    // Remove deleted recipe optimistically from user recipes
                    if let recipeID = recipeID {
                        viewModel.userRecipes.removeAll { $0.id == recipeID }
                    }
                    
                    // Reload user recipes and data to ensure consistency
                    await viewModel.loadUserRecipes()
                    await viewModel.loadUserData()
                }
            }
        }
    }
}

@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var user: AppUser?
    @Published var userRecipes: [Recipe] = []
    @Published var isFollowing: Bool = false
    @Published var isLoading: Bool = false
    
    private let userID: String
    private let friendsService = FriendsService()
    private let recipeService = RecipeService.shared
    private let authService = AuthService()
    private let firestore = FirebaseManager.shared.firestore
    var accountViewModel: AccountViewModel?
    
    init(userID: String) {
        self.userID = userID
        // Only create AccountViewModel if viewing own profile
        if Auth.auth().currentUser?.uid == userID {
            accountViewModel = AccountViewModel()
        }
    }
    
    func loadUserData() async {
        isLoading = true
        do {
            let document = try await firestore.collection("users").document(userID).getDocument()
            user = try? document.data(as: AppUser.self)
        } catch {
            print("⚠️ Error loading user data: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func loadUserRecipes() async {
        do {
            userRecipes = try await recipeService.fetchRecipes(byUserID: userID)
        } catch {
            print("⚠️ Error loading user recipes: \(error.localizedDescription)")
        }
    }
    
    func checkFollowStatus() async {
        guard let currentUserID = FirebaseAuth.Auth.auth().currentUser?.uid,
              currentUserID != userID else {
            isFollowing = false
            return
        }
        
        do {
            isFollowing = try await friendsService.isFollowing(followerID: currentUserID, followingID: userID)
        } catch {
            print("⚠️ Error checking follow status: \(error.localizedDescription)")
            isFollowing = false
        }
    }
    
    func toggleFollow() async {
        guard FirebaseAuth.Auth.auth().currentUser != nil else { return }
        
        isLoading = true
        
        do {
            if isFollowing {
                try await friendsService.unfollowUser(followingID: userID)
                isFollowing = false
                user?.followerCount = max(0, (user?.followerCount ?? 0) - 1)
            } else {
                try await friendsService.followUser(followingID: userID)
                isFollowing = true
                user?.followerCount = (user?.followerCount ?? 0) + 1
            }
            
            await checkFollowStatus()
            await authService.reloadUserData()
            NotificationCenter.default.post(name: NSNotification.Name("UserDataUpdated"), object: nil)
        } catch {
            print("⚠️ Error toggling follow: \(error.localizedDescription)")
            await checkFollowStatus()
        }
        
        isLoading = false
    }
}

#Preview {
    UserProfileView(userID: "123")
        .environmentObject(AuthViewModel())
}


//
//  EditProfileView.swift
//  Misoto
//
//  Created by Daniel Chan on 30.12.2025.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AccountViewModel
    @ObservedObject var authViewModel: AuthViewModel
    
    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    @State private var errorMessage: String?
    @State private var usernameSuggestions: [String] = []
    @State private var showUsernameSuggestions = false
    @State private var isCheckingUsername = false
    @State private var usernameCheckTask: Task<Void, Never>?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    // Profile Picture
                    VStack(spacing: 20) {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay {
                                    Circle()
                                        .stroke(Color.accentColor, lineWidth: 3)
                                }
                        } else if let imageURL = authViewModel.currentUser?.profileImageURL,
                                  let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color(.secondarySystemBackground))
                                    .overlay {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.secondary)
                                    }
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: 3)
                            }
                        } else {
                            Circle()
                                .fill(Color(.secondarySystemBackground))
                                .frame(width: 120, height: 120)
                                .overlay {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                }
                        }
                        
                        PhotosPicker(
                            selection: $selectedPhoto,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Text(NSLocalizedString("Change Profile Picture", comment: "Change profile picture button"))
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                
                Section(header: Text(NSLocalizedString("Profile Information", comment: "Profile information section"))) {
                    TextField(NSLocalizedString("Name", comment: "Name field"), text: $displayName)
                        .textInputAutocapitalization(.words)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField(NSLocalizedString("Username", comment: "Username field"), text: $username)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        
                        // Username validation hint
                        if !username.isEmpty {
                            let cleanUsername = username.hasPrefix("@") ? String(username.dropFirst()) : username
                            if cleanUsername.count < 4 {
                                Text(NSLocalizedString("Username must be at least 4 characters", comment: "Username length hint"))
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else if cleanUsername.count > 15 {
                                Text(NSLocalizedString("Username must be no more than 15 characters", comment: "Username length hint"))
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else {
                                HStack {
                                    Text(NSLocalizedString("\(cleanUsername.count)/15 characters", comment: "Username character count"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if isCheckingUsername {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    }
                                }
                            }
                        }
                        
                        // Show username error and suggestions directly under username field
                        if let errorMessage = errorMessage, showUsernameSuggestions {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                
                                if !usernameSuggestions.isEmpty {
                                    Text(NSLocalizedString("Suggested usernames:", comment: "Suggested usernames label"))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 2)
                                    
                                    ForEach(usernameSuggestions, id: \.self) { suggestion in
                                        Button(action: {
                                            username = suggestion
                                            showUsernameSuggestions = false
                                            self.errorMessage = nil
                                        }) {
                                            HStack {
                                                Text("@\(suggestion)")
                                                    .font(.caption)
                                                    .foregroundColor(.accentColor)
                                                Spacer()
                                                Image(systemName: "arrow.right.circle.fill")
                                                    .font(.caption)
                                                    .foregroundColor(.accentColor)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.top, 2)
                        } else if let errorMessage = errorMessage, !showUsernameSuggestions {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    TextField(NSLocalizedString("Bio", comment: "Bio field"), text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Show non-username errors in a separate section
                if let errorMessage = errorMessage, !showUsernameSuggestions {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Edit Profile", comment: "Edit profile title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("Cancel", comment: "Cancel button")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Dismiss keyboard
                        dismissKeyboard()
                        
                        Task {
                            await saveProfile()
                        }
                    }) {
                        HStack {
                            if isUploading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(NSLocalizedString("Save", comment: "Save button"))
                        }
                    }
                    .disabled(isUploading || displayName.isEmpty || username.isEmpty || !isUsernameValid)
                }
            }
            .onAppear {
                if let user = authViewModel.currentUser {
                    displayName = user.displayName
                    username = user.username ?? ""
                    bio = user.bio ?? ""
                }
            }
            .onChange(of: selectedPhoto) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
            .onChange(of: username) { oldValue, newValue in
                // Cancel previous check task
                usernameCheckTask?.cancel()
                
                // Clear previous errors when user starts typing
                if showUsernameSuggestions {
                    errorMessage = nil
                    showUsernameSuggestions = false
                    usernameSuggestions = []
                }
                
                // Only check if username is valid length
                let cleanUsername = newValue.hasPrefix("@") ? String(newValue.dropFirst()) : newValue
                guard cleanUsername.count >= 4 && cleanUsername.count <= 15 else {
                    return
                }
                
                // Debounce: Wait 1 second after user stops typing
                usernameCheckTask = Task {
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    
                    // Check if task was cancelled
                    guard !Task.isCancelled else { return }
                    
                    // Only check if username changed (not cancelled)
                    guard username == newValue else { return }
                    
                    await checkUsernameAvailability(newValue)
                }
            }
        }
    }
    
    // Username validation computed property
    private var isUsernameValid: Bool {
        let cleanUsername = username.hasPrefix("@") ? String(username.dropFirst()) : username
        return cleanUsername.count >= 4 && cleanUsername.count <= 15
    }
    
    // Check username availability with debounce
    private func checkUsernameAvailability(_ usernameToCheck: String) async {
        // Don't check if it's the same as current username
        if let currentUsername = authViewModel.currentUser?.username,
           usernameToCheck.lowercased() == currentUsername.lowercased() {
            return
        }
        
        isCheckingUsername = true
        
        do {
            let cleanUsername = usernameToCheck.hasPrefix("@") ? String(usernameToCheck.dropFirst()) : usernameToCheck
            let isAvailable = try await viewModel.checkUsernameAvailability(cleanUsername)
            
            if !isAvailable {
                // Username is taken
                errorMessage = NSLocalizedString("This username is already taken", comment: "Username taken error")
                showUsernameSuggestions = true
                usernameSuggestions = viewModel.generateUsernameAlternatives(usernameToCheck)
            } else {
                // Username is available - clear any previous errors
                if showUsernameSuggestions {
                    errorMessage = nil
                    showUsernameSuggestions = false
                    usernameSuggestions = []
                }
            }
        } catch {
            // Silently handle errors during real-time check
            print("⚠️ Error checking username availability: \(error.localizedDescription)")
        }
        
        isCheckingUsername = false
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func saveProfile() async {
        isUploading = true
        errorMessage = nil
        
        do {
            // Upload profile image if changed
            if let image = selectedImage {
                try await viewModel.uploadProfileImage(image)
                print("✅ Profile image uploaded successfully")
            }
            
            // Update profile info
            try await viewModel.updateProfile(
                displayName: displayName,
                username: username.isEmpty ? nil : username,
                bio: bio.isEmpty ? nil : bio
            )
            print("✅ Profile updated successfully")
            
            // Force reload user data to ensure UI updates immediately
            await authViewModel.reloadUserData()
            
            // Small delay to ensure UI updates
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
            dismiss()
        } catch {
            // Check if it's an AuthError
            if let authError = error as? AuthError {
                errorMessage = authError.localizedDescription
                
                // If username is taken, generate suggestions
                if authError == .usernameTaken {
                    showUsernameSuggestions = true
                    usernameSuggestions = viewModel.generateUsernameAlternatives(username)
                } else {
                    showUsernameSuggestions = false
                    usernameSuggestions = []
                }
                
                print("❌ Error saving profile: \(authError.localizedDescription)")
            } else {
                errorMessage = error.localizedDescription
                showUsernameSuggestions = false
                usernameSuggestions = []
                print("❌ Error saving profile: \(error.localizedDescription)")
            }
        }
        
        isUploading = false
    }
}


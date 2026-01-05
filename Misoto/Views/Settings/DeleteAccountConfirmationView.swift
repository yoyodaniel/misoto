//
//  DeleteAccountConfirmationView.swift
//  Misoto
//
//  Created by Daniel Chan on 30.12.2025.
//

import SwiftUI

struct DeleteAccountConfirmationView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var accountViewModel = AccountViewModel()
    @State private var usernameInput: String = ""
    @State private var errorMessage: String?
    @State private var isDeleting = false
    @FocusState private var isUsernameFocused: Bool
    
    private var userUsername: String {
        authViewModel.currentUser?.username ?? ""
    }
    
    private var isUsernameValid: Bool {
        guard !userUsername.isEmpty else { return false }
        return usernameInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == userUsername.lowercased()
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text(LocalizedString("Are you sure you want to delete your account?", comment: "Delete account confirmation question"))
                        .font(.body)
                        .foregroundColor(.primary)
                } header: {
                    Text(LocalizedString("Delete Account", comment: "Delete account title"))
                }
                
                Section {
                    Text(LocalizedString("If yes, please enter your username and press delete to confirm the deletion.", comment: "Username entry instruction"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField(userUsername.isEmpty ? LocalizedString("Username", comment: "Username placeholder") : userUsername, text: $usernameInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isUsernameFocused)
                        .disabled(isDeleting)
                        .onChange(of: usernameInput) {
                            errorMessage = nil
                        }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                } header: {
                    Text(LocalizedString("Confirm Deletion", comment: "Confirm deletion section"))
                }
                
                Section {
                    Text(LocalizedString("Your account will be deleted in 30 days. To cancel the deletion, please log back in within 30 days.", comment: "30 day deletion notice"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(LocalizedString("Delete Account", comment: "Delete account title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizedString("Cancel", comment: "Cancel button")) {
                        HapticFeedback.buttonTap()
                        dismiss()
                    }
                    .disabled(isDeleting)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isDeleting {
                        ProgressView()
                    } else {
                        Button(LocalizedString("Delete Account", comment: "Delete account button"), role: .destructive) {
                            HapticFeedback.play(.error)
                            Task {
                                await deleteAccount()
                            }
                        }
                        .disabled(!isUsernameValid || usernameInput.isEmpty)
                    }
                }
            }
            .onAppear {
                accountViewModel.authViewModel = authViewModel
                isUsernameFocused = true
            }
        }
    }
    
    private func deleteAccount() async {
        guard isUsernameValid else {
            errorMessage = LocalizedString("Username does not match", comment: "Username mismatch error")
            HapticFeedback.play(.error)
            return
        }
        
        isDeleting = true
        
        do {
            try await accountViewModel.deleteAccount()
            // Sign out after account deletion
            authViewModel.signOut()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isDeleting = false
            print("⚠️ Error deleting account: \(error.localizedDescription)")
        }
    }
}

#Preview {
    DeleteAccountConfirmationView(authViewModel: AuthViewModel())
}


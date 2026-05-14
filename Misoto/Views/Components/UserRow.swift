//
//  UserRow.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI

struct UserRow: View {
    let user: AppUser
    var showFollow: Bool = false
    var followTitle: String = LocalizedString("Follow", comment: "Follow button")
    var showUnfollow: Bool = false
    var onRowTap: (() -> Void)?
    var action: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                profileImageView
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Text(user.displayName)
                            .font(.headline)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        if user.premiumUser {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                        }
                    }

                    if let username = user.username, !username.isEmpty {
                        Text("@\(username)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else if let bio = user.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text(" ")
                            .font(.caption)
                            .hidden()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onRowTap?()
            }
            
            Spacer()
            
            if showFollow {
                actionPill(
                    title: followTitle,
                    backgroundColor: Color.accentColor,
                    foregroundColor: .white
                )
            } else if showUnfollow {
                actionPill(
                    title: LocalizedString("Unfollow", comment: "Unfollow button"),
                    backgroundColor: Color.secondary.opacity(0.2),
                    foregroundColor: .primary
                )
            }
        }
        .frame(minHeight: 58)
        .padding(.vertical, 4)
    }

    private var profileImageView: some View {
        Group {
            if let imageURL = user.profileImageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                }
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
            }
        }
    }

    private func actionPill(title: String, backgroundColor: Color, foregroundColor: Color) -> some View {
        Text(title)
            .font(.caption)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minWidth: 88)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
            .contentShape(Rectangle())
            .highPriorityGesture(TapGesture().onEnded {
                action?()
            })
            .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    List {
        UserRow(user: AppUser(
            id: "1",
            displayName: "John Doe",
            bio: "Food enthusiast"
        ), showFollow: true)
    }
}


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
    var showUnfollow: Bool = false
    var action: (() -> Void)?
    
    var body: some View {
        HStack {
            if let imageURL = user.profileImageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.secondary)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                
                if let bio = user.bio {
                    Text(bio)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if showFollow {
                Button(action: {
                    action?()
                }) {
                    Text(LocalizedString("Follow", comment: "Follow button"))
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            } else if showUnfollow {
                Button(action: {
                    action?()
                }) {
                    Text(LocalizedString("Unfollow", comment: "Unfollow button"))
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.secondary.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
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


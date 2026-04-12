//
//  NewPostSharingSection.swift
//  Misoto
//
//  Lets authors choose public vs private when creating a new recipe, with gentle encouragement toward public sharing.
//

import SwiftUI

// MARK: - New post visibility (create flow)

struct NewPostSharingSection: View {
    @Binding var selection: AppSettings.DefaultPostSharing

    var body: some View {
        Section {
            visibilityRow(
                mode: .public,
                titleKey: "Post publicly",
                subtitleKey: "Share with the Misoto community and appear in Explore.",
                systemImage: "globe"
            )
            visibilityRow(
                mode: .private,
                titleKey: "Post privately",
                subtitleKey: "Only you see it on your profile; it will not appear in Explore.",
                systemImage: "eye.slash.fill"
            )
        } header: {
            Text(LocalizedString("Who can see this recipe?", comment: "Section header for visibility when creating a recipe"))
        } footer: {
            Group {
                if selection == .public {
                    Text(LocalizedString("Public posts inspire others and help great home cooking spread around the world.", comment: "Footer encouraging public sharing when public is selected"))
                } else {
                    Text(LocalizedString("You can switch to public anytime from your recipe.", comment: "Footer when private is selected for new post"))
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func visibilityRow(
        mode: AppSettings.DefaultPostSharing,
        titleKey: String,
        subtitleKey: String,
        systemImage: String
    ) -> some View {
        let isSelected = selection == mode
        Button {
            HapticFeedback.play(.selection)
            selection = mode
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 28, alignment: .center)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(LocalizedString(titleKey, comment: "Post visibility option title"))
                            .font(.body.weight(.semibold))
                            .foregroundColor(.primary)
                        if mode == .public {
                            Text(LocalizedString("Recommended", comment: "Badge for recommended public sharing option"))
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.accentColor.opacity(0.9)))
                        }
                    }
                    Text(LocalizedString(subtitleKey, comment: "Post visibility option subtitle"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .accentColor : Color(.systemGray3))
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#if DEBUG
#Preview("New post sharing") {
    Form {
        NewPostSharingSection(selection: .constant(.public))
    }
}
#endif

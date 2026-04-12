//
//  WhatsNewView.swift
//  Misoto
//
//  Shows release highlights after app updates.
//

import SwiftUI

struct WhatsNewView: View {
    let versionLabel: String
    let onDismiss: () -> Void
    let onDontShowAgain: () -> Void

    private let highlights: [String] = [
        LocalizedString("Posts are private by default", comment: "What's new bullet"),
        LocalizedString("Share posts globally with one tap", comment: "What's new bullet"),
        LocalizedString("Users can now leave reviews and ratings", comment: "What's new bullet"),
        LocalizedString("Nutrition Info (BETA)", comment: "What's new bullet"),
        LocalizedString("Standardized ingredients library added", comment: "What's new bullet"),
        LocalizedString("Cuisine cards added to sort by cuisine", comment: "What's new bullet"),
        LocalizedString("Generate instructions automatically with AI", comment: "What's new bullet")
    ]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(String(format: LocalizedString("Version %@", comment: "What's new version label"), versionLabel))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ForEach(highlights, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\u{2022}")
                            .font(.body.weight(.bold))
                        Text(item)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()

                VStack(spacing: 10) {
                    Button(LocalizedString("Dismiss", comment: "Dismiss what's new button")) {
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)

                    Button(LocalizedString("Don't show again", comment: "Don't show what's new again button")) {
                        onDontShowAgain()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
            .navigationTitle(LocalizedString("What's New", comment: "What's new title"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    WhatsNewView(versionLabel: "1.2.0", onDismiss: {}, onDontShowAgain: {})
}

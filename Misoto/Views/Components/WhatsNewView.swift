//
//  WhatsNewView.swift
//  Misoto
//
//  Shows release highlights after app updates.
//

import SwiftUI

struct WhatsNewView: View {
    let versionLabel: String
    /// Pass `true` when the user checked "Don't show again" so this marketing version is remembered.
    let onContinue: (_ doNotShowAgain: Bool) -> Void

    @State private var doNotShowAgain = false

    private let highlights: [String] = [
        LocalizedString("Search with natural language.", comment: "What's new release bullet"),
        LocalizedString("RPG-style XP and level-ups as you cook.", comment: "What's new release bullet"),
        LocalizedString("Post publicly—or keep recipes private.", comment: "What's new release bullet"),
        LocalizedString("AI helps polish recipe text while you write.", comment: "What's new release bullet")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
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

                    Button {
                        doNotShowAgain.toggle()
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: doNotShowAgain ? "checkmark.square.fill" : "square")
                                .font(.title3)
                                .foregroundStyle(doNotShowAgain ? Color.accentColor : Color.secondary)
                            Text(LocalizedString("Don't show again until the next app update", comment: "What's new do not show checkbox"))
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                    .accessibilityLabel(LocalizedString("Don't show again until the next app update", comment: "What's new do not show checkbox"))
                    .accessibilityAddTraits(doNotShowAgain ? .isSelected : [])

                    Button(LocalizedString("Continue", comment: "What's new continue button")) {
                        onContinue(doNotShowAgain)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(LocalizedString("What's New", comment: "What's new title"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#if DEBUG
#Preview {
    WhatsNewView(versionLabel: "1.2.0 (1)", onContinue: { _ in })
}
#endif

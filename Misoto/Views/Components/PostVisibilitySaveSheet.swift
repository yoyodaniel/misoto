//
//  PostVisibilitySaveSheet.swift
//  Misoto
//
//  Confirms public vs private visibility immediately before save or upload.
//

import SwiftUI

// MARK: - Save / upload visibility sheet

struct PostVisibilitySaveSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var postSharing: AppSettings.DefaultPostSharing
    let navigationTitle: String
    let primaryButtonTitle: String
    let readError: () -> String?
    let onCommit: () async -> Bool
    let onSuccess: () -> Void

    @State private var isSaving = false
    @State private var displayedError: String?

    var body: some View {
        NavigationStack {
            Form {
                NewPostSharingSection(selection: $postSharing)

                if let err = displayedError, !err.isEmpty {
                    Section {
                        Text(err)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedString("Cancel", comment: "Cancel button")) {
                        displayedError = nil
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(primaryButtonTitle) {
                        Task {
                            isSaving = true
                            displayedError = nil
                            let ok = await onCommit()
                            isSaving = false
                            if !ok {
                                displayedError = readError()
                                HapticFeedback.play(.error)
                                return
                            }
                            dismiss()
                            onSuccess()
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.12)
                            .ignoresSafeArea()
                        ProgressView()
                            .padding(20)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                    }
                    .allowsHitTesting(true)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
    }
}

#if DEBUG
#Preview("Post visibility save") {
    Text("Host")
        .sheet(isPresented: .constant(true)) {
            PostVisibilitySaveSheet(
                postSharing: .constant(.public),
                navigationTitle: "Before you save",
                primaryButtonTitle: "Save",
                readError: { nil },
                onCommit: { return true },
                onSuccess: {}
            )
        }
}
#endif

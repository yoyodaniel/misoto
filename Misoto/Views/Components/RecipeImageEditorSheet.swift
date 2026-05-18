//
//  RecipeImageEditorSheet.swift
//  Misoto
//
//  Sheet to enhance a dish photo with AI (v1.5).
//

import SwiftUI

struct RecipeImageEditorSheet: View {
    private enum Layout {
        static let previewHorizontalInset: CGFloat = 16
        static let previewCornerRadius: CGFloat = 16
        static let outerGlowInset: CGFloat = 14
        static let enhanceButtonMinHeight: CGFloat = 46
    }

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: RecipeImageEditorViewModel

    let onApply: (UIImage) -> Void

    init(sourceImage: UIImage, onApply: @escaping (UIImage) -> Void) {
        _viewModel = StateObject(wrappedValue: RecipeImageEditorViewModel(sourceImage: sourceImage))
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let squareSide = max(0, geometry.size.width - (Layout.previewHorizontalInset * 2))

                VStack(spacing: 0) {
                    imagePreview(side: squareSide)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, Layout.previewHorizontalInset)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                        .layoutPriority(1)

                    Divider()

                    ScrollView {
                        styleListContent
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    bottomActionBar
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(LocalizedString("AI Enhance", comment: "Photo editor sheet title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedString("Cancel", comment: "Cancel button")) {
                        HapticFeedback.buttonTap()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LocalizedString("Use photo", comment: "Apply enhanced photo")) {
                        HapticFeedback.importantAction()
                        onApply(viewModel.displayImage)
                        dismiss()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }

    // MARK: - Sections

    private func imagePreview(side: CGFloat) -> some View {
        ZStack {
            AIProcessingImageGlow(
                cornerRadius: Layout.previewCornerRadius,
                isActive: viewModel.isLoading
            )
            .frame(width: side, height: side)
            .allowsHitTesting(false)

            Image(uiImage: viewModel.displayImage)
                .resizable()
                .scaledToFill()
                .frame(width: side, height: side)
                .overlay {
                    RoundedRectangle(cornerRadius: Layout.previewCornerRadius, style: .continuous)
                        .strokeBorder(Color(.separator).opacity(0.25), lineWidth: 0.5)
                }
                .overlay {
                    ZStack {
                        RoundedRectangle(cornerRadius: Layout.previewCornerRadius, style: .continuous)
                            .fill(Color.black.opacity(0.1))
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.1)
                    }
                    .opacity(viewModel.isLoading ? 1 : 0)
                    .allowsHitTesting(viewModel.isLoading)
                    .animation(.easeInOut(duration: 0.5), value: viewModel.isLoading)
                }
                .clipShape(RoundedRectangle(cornerRadius: Layout.previewCornerRadius, style: .continuous))
        }
        .frame(width: side, height: side)
        .padding(Layout.outerGlowInset)
        .accessibilityLabel(LocalizedString("Dish photo preview", comment: "Preview image accessibility"))
        .accessibilityValue(
            viewModel.isLoading
                ? LocalizedString("Enhancing with AI", comment: "Photo preview accessibility while AI runs")
                : ""
        )
    }

    private var styleListContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedString("Style", comment: "Photo enhance style section"))
                .font(.headline)

            ForEach(RecipeImageStylePreset.allCases) { preset in
                stylePresetRow(preset)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func stylePresetRow(_ preset: RecipeImageStylePreset) -> some View {
        Button {
            if viewModel.selectedPreset != preset {
                HapticFeedback.play(.selection)
            }
            viewModel.selectedPreset = preset
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: viewModel.selectedPreset == preset ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(.accentColor)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text(preset.shortDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(viewModel.selectedPreset == preset
                          ? Color.accentColor.opacity(0.12)
                          : Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoading)
    }

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                HapticFeedback.importantAction()
                Task { await viewModel.enhancePhoto() }
            } label: {
                Label(
                    viewModel.hasEnhancedResult
                        ? LocalizedString("Enhance again", comment: "Re-run photo enhance")
                        : LocalizedString("Enhance photo", comment: "Run photo enhance"),
                    systemImage: "wand.and.stars"
                )
                .frame(maxWidth: .infinity, minHeight: Layout.enhanceButtonMinHeight)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isEnhanceActionEnabled)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(Color(.systemGroupedBackground))
    }
}

#if DEBUG
#Preview {
    RecipeImageEditorSheet(
        sourceImage: UIImage(systemName: "photo") ?? UIImage(),
        onApply: { _ in }
    )
}
#endif

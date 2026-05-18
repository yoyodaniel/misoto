//
//  RecipeImageEditorViewModel.swift
//  Misoto
//
//  MVVM for in-app AI dish-photo enhancement (v1.5).
//

import Combine
import FirebaseAuth
import Foundation
import UIKit

@MainActor
final class RecipeImageEditorViewModel: ObservableObject {
    let sourceImage: UIImage

    @Published var selectedPreset: RecipeImageStylePreset = .recipeApp
    @Published var enhancedImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Preset used for the last successful enhancement; re-enhance only when selection changes.
    private(set) var lastEnhancedPreset: RecipeImageStylePreset?

    init(sourceImage: UIImage) {
        self.sourceImage = sourceImage
    }

    var displayImage: UIImage {
        ImageOptimizer.squareCenterFilled(enhancedImage ?? sourceImage)
    }

    var hasEnhancedResult: Bool {
        enhancedImage != nil
    }

    var isEnhanceActionEnabled: Bool {
        guard !isLoading else { return false }
        guard let lastEnhancedPreset else { return true }
        return selectedPreset != lastEnhancedPreset
    }

    func enhancePhoto() async {
        guard Auth.auth().currentUser != nil else {
            errorMessage = LocalizedString("Please sign in to use AI features.", comment: "OpenAI proxy requires signed-in user")
            HapticFeedback.play(.error)
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        var didSucceed = false

        do {
            let canEdit = try await SubscriptionHelper.checkAIImageEditLimit()
            if !canEdit {
                errorMessage = LocalizedString(
                    "You have reached your free tier limit for AI photo enhancements",
                    comment: "AI image edit limit error"
                ) + "\n" + LocalizedString(
                    "Upgrade to Premium for unlimited AI photo enhancements",
                    comment: "Upgrade prompt for image edits"
                )
                HapticFeedback.play(.error)
                return
            }

            let result = try await RecipeImageStyleService.enhance(image: sourceImage, preset: selectedPreset)
            enhancedImage = result
            lastEnhancedPreset = selectedPreset
            didSucceed = true
        } catch let styleError as RecipeImageStyleError {
            errorMessage = styleError.localizedDescription
        } catch let openAIError as OpenAIError {
            errorMessage = openAIError.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        if didSucceed {
            HapticFeedback.play(.success)
        } else if errorMessage != nil {
            HapticFeedback.play(.error)
        }
    }
}

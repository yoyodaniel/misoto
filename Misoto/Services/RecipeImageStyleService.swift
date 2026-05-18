//
//  RecipeImageStyleService.swift
//  Misoto
//
//  AI dish-photo enhancement via Firebase → OpenAI Images API.
//

import Foundation
import UIKit

enum RecipeImageStyleError: LocalizedError {
    case imagePreparationFailed
    case invalidResponse
    case noImageInResponse

    var errorDescription: String? {
        switch self {
        case .imagePreparationFailed:
            return LocalizedString("Could not prepare the photo for enhancement.", comment: "Image edit prep error")
        case .invalidResponse:
            return LocalizedString("Invalid response from the photo enhancement service.", comment: "Image edit response error")
        case .noImageInResponse:
            return LocalizedString("No enhanced image was returned. Please try again.", comment: "Image edit empty result")
        }
    }
}

@MainActor
enum RecipeImageStyleService {
    static func enhance(image: UIImage, preset: RecipeImageStylePreset) async throws -> UIImage {
        guard let prepared = ImageOptimizer.jpegBase64ForImageEdit(image) else {
            throw RecipeImageStyleError.imagePreparationFailed
        }

        print("🖼️ RecipeImageStyleService: enhancing preset=\(preset.rawValue) base64Chars=\(prepared.base64.count)")
        let data = try await BackendAPIProxy.openAIImageEdit(
            imageBase64: prepared.base64,
            presetId: preset.rawValue,
            mimeType: prepared.mimeType
        )

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["data"] as? [[String: Any]],
              let first = items.first,
              let b64 = first["b64_json"] as? String,
              let imageData = Data(base64Encoded: b64),
              let result = UIImage(data: imageData) else {
            let snippet = String(data: data.prefix(400), encoding: .utf8) ?? ""
            print("❌ RecipeImageStyleService: parse failed. Snippet: \(snippet)")
            throw RecipeImageStyleError.noImageInResponse
        }

        let displayReady = ImageOptimizer.resizeForDisplay(
            ImageOptimizer.squareCenterFilled(result),
            maxDimension: 1200
        )
        print("✅ RecipeImageStyleService: enhanced image \(Int(displayReady.size.width))×\(Int(displayReady.size.height))")
        return displayReady
    }
}

//
//  RecipeImageStylePrompts.swift
//  Misoto
//
//  Preprogrammed prompts for OpenAI dish-photo enhancement.
//

import Foundation

enum RecipeImageStylePrompts {
    /// Matches the professional food-photography retoucher workflow used in ChatGPT before in-app enhancement.
    private static let basePrompt = """
    You are a professional food-photography retoucher. Return ONE polished version of this dish photo, ready for a cookbook, recipe app, or social-media grid. No text, borders, watermarks, or extra graphics—only the enhanced photograph.

    1. Framing
    • Center the main bowl/plate with even breathing room.
    • Zoom out slightly so the dish sits a little farther from the camera, with more space around the plate or bowl—avoid tight close-up framing.
    • Default output: square (1:1). Keep the whole dish visible; no awkward crop.
    • Unless instructed otherwise, use 1:1 for Misoto recipe cards.

    2. Lighting & Color
    • Brighten exposure and set a clean, neutral white balance (remove yellow/blue cast).
    • Boost contrast moderately so highlights pop and shadows deepen.
    • Gently enrich key food colors (greens, reds, yolks, sauces) while staying natural.

    3. Texture & Clarity
    • Sharpen the food itself—sauces glossy, grains distinct, herbs crisp.
    • Preserve soft depth-of-field so background props remain subtle.

    4. Background & Distractions
    • Remove or blur UI elements, on-screen text, harsh reflections, crumbs, or stains.
    • Keep backdrop minimal: light marble, warm wood, or neutral slate—whichever suits the dish best.

    5. Authenticity
    • Do not distort portion sizes or ingredient shapes.
    • Keep existing garnishes; add gentle steam only if it looks realistic.

    6. Deliverable
    • Output only the final enhanced food photograph—realistic photography, not illustration.
    """

    private static let presetAppends: [RecipeImageStylePreset: String] = [
        .recipeApp: "Style override: clean recipe-app grid look; neutral bright backdrop (light marble or soft white); minimal props.",
        .modernPatisserie: "Style override: modern patisserie; smooth bakery polish; refined plating; light marble or studio white background.",
        .rusticComfort: "Style override: rustic comfort cookbook; warm wood or homestyle surface; cozy natural light.",
        .minimalist: "Style override: minimalist Scandinavian; very clean white or pale marble; extremely uncluttered.",
        .celebration: "Style override: celebration-friendly; keep festive elements tidy and photo-ready.",
        .premiumDessert: "Style override: premium dessert book; glossy patisserie finish; elegant highlights.",
        .familyCookbook: "Style override: family cookbook warmth; authentic home-baked feel; approachable not overly styled.",
        .foodBlog: "Style override: modern food blog; slightly editorial color pop; appetizing and realistic.",
    ]

    static func fullPrompt(for preset: RecipeImageStylePreset) -> String {
        let style = presetAppends[preset] ?? presetAppends[.recipeApp] ?? ""
        return basePrompt + "\n\n" + style
    }

    static let allowedPresetIds: Set<String> = Set(RecipeImageStylePreset.allCases.map(\.rawValue))
}

//
//  RecipeImageStylePromptsTests.swift
//  MisotoTests
//

import XCTest
@testable import Misoto

final class RecipeImageStylePromptsTests: XCTestCase {
    func testFullPromptIncludesBaseAndStyle() {
        let prompt = RecipeImageStylePrompts.fullPrompt(for: .modernPatisserie)
        XCTAssertTrue(prompt.contains("professional food-photography retoucher"))
        XCTAssertTrue(prompt.contains("square (1:1)"))
        XCTAssertTrue(prompt.contains("Zoom out slightly"))
        XCTAssertTrue(prompt.contains("modern patisserie"))
    }

    func testAllowedPresetIdsMatchEnum() {
        XCTAssertEqual(RecipeImageStylePrompts.allowedPresetIds.count, RecipeImageStylePreset.allCases.count)
        for preset in RecipeImageStylePreset.allCases {
            XCTAssertTrue(RecipeImageStylePrompts.allowedPresetIds.contains(preset.rawValue))
        }
    }
}

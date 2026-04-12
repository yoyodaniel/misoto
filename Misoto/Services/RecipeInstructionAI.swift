//
//  RecipeInstructionAI.swift
//  Misoto
//
//  Shared entry points: on-device correction when available, OpenAI for generation and fallback editing.
//

import Foundation
import NaturalLanguage

// MARK: - Recipe instruction AI

enum RecipeInstructionAI {
    
    /// Improves spelling/grammar using Apple Foundation Models when available; otherwise OpenAI.
    static func improveInstructionStrings(_ instructions: [String]) async throws -> [String] {
        if let merged = await InstructionFoundationCorrection.correctedInstructionsMergingIntoOriginal(instructions) {
            return merged
        }
        return try await OpenAIService.editInstructions(instructions)
    }
    
    /// Generates new step text from title + ingredients (OpenAI).
    static func generateInstructionStrings(title: String, ingredients: [String]) async throws -> [String] {
        try await OpenAIService.generateInstructions(title: title, ingredients: ingredients)
    }
}

// MARK: - Foundation Models (iOS 26+)

#if canImport(FoundationModels)
import FoundationModels

enum InstructionFoundationCorrection {
    
    /// When Apple Intelligence / on-device model is ready, returns a full instruction array with the same count as `instructions`, with non-empty steps corrected. Otherwise `nil` (caller should use OpenAI).
    static func correctedInstructionsMergingIntoOriginal(_ instructions: [String]) async -> [String]? {
        guard #available(iOS 26.0, *) else { return nil }
        
        let model = SystemLanguageModel.default
        guard case .available = model.availability else { return nil }
        
        let validInstructions = instructions.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard !validInstructions.isEmpty else { return instructions }
        
        let combinedText = validInstructions.joined(separator: " ")
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(combinedText)
        let detectedCode = recognizer.dominantLanguage?.rawValue ?? "en"
        let languageName = OpenAIService.getLanguageName(for: detectedCode)
        
        let numberedInstructions = validInstructions.enumerated().map { index, text in
            "\(index + 1). \(text)"
        }.joined(separator: "\n")
        
        let systemInstructions = """
        You are a professional recipe editor. Review and correct the following recipe instructions for spelling and grammar only.
        Rules:
        - Fix spelling mistakes, grammar errors, and punctuation
        - Keep the same meaning, tone, and cooking terminology
        - Do NOT add, remove, or reorder steps
        - Do NOT change cooking times, temperatures, or quantities
        - Preserve the original language (\(languageName)) — do NOT translate
        - Return ONLY a JSON object with an "instructions" array of strings, same order and count as the numbered steps
        """
        
        let userPrompt = """
        Numbered steps (keep language \(languageName)):
        
        \(numberedInstructions)
        """
        
        do {
            let session = LanguageModelSession(instructions: systemInstructions)
            let response = try await session.respond(to: userPrompt)
            let rawContent = response.content
            guard let editedValid = Self.parseInstructionsJSON(from: rawContent),
                  editedValid.count == validInstructions.count else {
                return nil
            }
            
            var result = instructions
            var editedIndex = 0
            for i in 0..<result.count {
                if !result[i].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if editedIndex < editedValid.count {
                        result[i] = editedValid[editedIndex]
                        editedIndex += 1
                    }
                }
            }
            return result
        } catch {
            return nil
        }
    }
    
    private static func parseInstructionsJSON(from content: String) -> [String]? {
        var trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("```") {
            trimmed = trimmed.replacingOccurrences(of: "```json", with: "")
            trimmed = trimmed.replacingOccurrences(of: "```", with: "")
            trimmed = trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let data = trimmed.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let arr = json["instructions"] as? [String] else {
            return nil
        }
        return arr
    }
}

#else

enum InstructionFoundationCorrection {
    static func correctedInstructionsMergingIntoOriginal(_ instructions: [String]) async -> [String]? {
        nil
    }
}

#endif

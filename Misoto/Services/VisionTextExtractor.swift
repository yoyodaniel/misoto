//
//  VisionTextExtractor.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Vision
import UIKit

@MainActor
class VisionTextExtractor {
    
    /// Extract text from a single image
    func extractText(from image: UIImage) async throws -> String {
        // Optimize image before processing to reduce memory usage and improve performance
        let optimizedImage = ImageOptimizer.resizeForProcessing(image)
        guard let cgImage = optimizedImage.cgImage else {
            throw TextExtractionError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: TextExtractionError.noTextFound)
                    return
                }
                
                // Filter by confidence and meaningful content
                let recognizedStrings = observations.compactMap { observation -> String? in
                    guard let candidate = observation.topCandidates(1).first,
                          candidate.confidence > 0.3 else {
                        return nil
                    }
                    
                    let text = candidate.string.trimmingCharacters(in: .whitespaces)
                    
                    // Filter out garbage text (mostly symbols, numbers without context)
                    if self.isValidText(text) {
                        return text
                    }
                    return nil
                }
                
                let fullText = recognizedStrings.joined(separator: "\n")
                
                if fullText.isEmpty {
                    continuation.resume(throwing: TextExtractionError.noTextFound)
                } else {
                    continuation.resume(returning: fullText)
                }
            }
            
            // Use accurate recognition for better results
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func isValidText(_ text: String) -> Bool {
        // Must have at least 2 characters
        guard text.count >= 2 else { return false }
        
        // Filter out lines that are mostly symbols or numbers without letters
        let letterCount = text.filter { $0.isLetter }.count
        let totalChars = text.filter { !$0.isWhitespace }.count
        
        // Must have at least 30% letters (for meaningful text)
        guard totalChars > 0, Double(letterCount) / Double(totalChars) >= 0.3 else {
            return false
        }
        
        // Filter out common OCR garbage patterns
        let garbagePatterns = [
            "^[#*°]+$",  // Only symbols (including degree symbol)
            "^\\d+[#*°]+$",  // Numbers followed by symbols
            "^[A-Z]{1,2}\\d+",  // Short codes like "XE1311"
            "^\\d+[/]\\d+[#*°]+",  // Dates/codes with symbols
            "^[#*°]{2,}",  // Multiple symbols
            "^[A-Z][#*°]+$",  // Single letter followed by symbols (e.g., "T#", "T°")
            "^[A-Z][#*°]+\\s*$",  // Single letter + symbols with trailing spaces
            "^[a-z][#*°]+$",  // Single lowercase letter + symbols
        ]
        
        for pattern in garbagePatterns {
            if text.range(of: pattern, options: .regularExpression) != nil {
                return false
            }
        }
        
        // Must contain at least one letter
        return text.contains { $0.isLetter }
    }
    
    /// Extract text from multiple images and combine them
    func extractText(from images: [UIImage]) async throws -> String {
        guard !images.isEmpty else {
            throw TextExtractionError.invalidImage
        }
        
        var allTexts: [String] = []
        
        // Process each image
        for image in images {
            do {
                let text = try await extractText(from: image)
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    allTexts.append(text)
                }
            } catch {
                // Continue with other images if one fails
                print("Failed to extract text from one image: \(error.localizedDescription)")
            }
        }
        
        guard !allTexts.isEmpty else {
            throw TextExtractionError.noTextFound
        }
        
        // Combine texts with double newline separator to distinguish pages
        return allTexts.joined(separator: "\n\n")
    }
}

enum TextExtractionError: LocalizedError {
    case invalidImage
    case noTextFound
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return NSLocalizedString("Invalid image", comment: "Invalid image error")
        case .noTextFound:
            return NSLocalizedString("No text found in image", comment: "No text found error")
        case .processingFailed:
            return NSLocalizedString("Failed to process image", comment: "Processing failed error")
        }
    }
}


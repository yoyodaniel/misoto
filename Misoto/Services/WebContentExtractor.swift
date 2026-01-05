//
//  WebContentExtractor.swift
//  Misoto
//
//  Service for extracting text content from WKWebView
//

import Foundation
import WebKit
import UIKit
import Vision

@MainActor
class WebContentExtractor {
    
    /// Extract text content from a WKWebView
    /// Uses JavaScript to extract visible text without modifying the webpage DOM
    static func extractText(from webView: WKWebView) async throws -> String {
        // JavaScript to extract text content without modifying the DOM
        // Clones the content area and removes non-content elements from the clone
        let extractScript = """
        (function() {
            // Try to find main content area (common recipe website patterns)
            const contentSelectors = [
                'article', '.recipe-content', '.recipe', '.content', 
                'main', '.main-content', '[role="main"]', '.post-content',
                '.entry-content', '.recipe-details', '.recipe-body'
            ];
            
            let mainContent = null;
            for (const selector of contentSelectors) {
                const element = document.querySelector(selector);
                if (element) {
                    mainContent = element;
                    break;
                }
            }
            
            // If no main content found, use body
            const targetElement = mainContent || document.body;
            
            // Clone the element to avoid modifying the original DOM
            const clone = targetElement.cloneNode(true);
            
            // Remove script, style, nav, header, footer, aside, and other non-content elements from clone
            const nonContentSelectors = [
                'script', 'style', 'nav', 'header', 'footer', 'aside', 
                '.advertisement', '.ad', '.sidebar', '.menu', '.navigation',
                '.social', '.share', '.comments', '.related', '.footer-content'
            ];
            
            nonContentSelectors.forEach(selector => {
                const elements = clone.querySelectorAll(selector);
                elements.forEach(el => el.remove());
            });
            
            // Extract text from the clone, preserving line breaks
            const text = clone.innerText || clone.textContent || '';
            
            // Clean up excessive whitespace while preserving structure
            return text
                .replace(/\\s+/g, ' ')
                .replace(/\\n\\s*\\n\\s*\\n/g, '\\n\\n')
                .trim();
        })();
        """
        
        // Execute JavaScript and get result
        let result = try await webView.evaluateJavaScript(extractScript) as? String
        
        guard let extractedText = result, !extractedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WebContentExtractorError.noContentFound
        }
        
        return extractedText
    }
    
    /// Extract recipe images from a WKWebView
    /// Uses Vision framework to identify food images and returns multiple candidates
    /// Returns an array of image URLs (up to 5) that are likely food/recipe images
    static func extractRecipeImageURLs(from webView: WKWebView) async throws -> [String] {
        // JavaScript to extract all candidate images from the page
        let imageExtractScript = """
        (function() {
            // Common selectors for recipe images (in order of preference)
            const imageSelectors = [
                'img[itemprop="image"]',
                '.recipe-image img',
                '.featured-image img',
                '.hero-image img',
                '.recipe-hero img',
                '.post-image img',
                'article img',
                'main img',
                '.content img',
                '[role="main"] img',
                '.entry-content img',
                'img'
            ];
            
            const imageCandidates = [];
            const seenURLs = new Set();
            
            // Collect all candidate images
            for (const selector of imageSelectors) {
                const elements = document.querySelectorAll(selector);
                for (const img of elements) {
                    const width = img.naturalWidth || img.width || img.clientWidth || 0;
                    const height = img.naturalHeight || img.height || img.clientHeight || 0;
                    const size = width * height;
                    
                    // Only consider images that are at least 200x200 pixels
                    if (width >= 200 && height >= 200) {
                        // Get the image source URL - try multiple attributes for lazy-loaded images
                        let imageUrl = img.src || 
                                      img.getAttribute('data-src') || 
                                      img.getAttribute('data-lazy-src') ||
                                      img.getAttribute('data-original') ||
                                      (img.getAttribute('data-srcset')?.split(',')[0]?.trim().split(' ')[0]);
                        
                        if (imageUrl) {
                            // If it's a relative URL, make it absolute
                            if (!imageUrl.startsWith('http')) {
                                try {
                                    imageUrl = new URL(imageUrl, window.location.href).href;
                                } catch (e) {
                                    continue;
                                }
                            }
                            
                            // Avoid duplicates
                            if (!seenURLs.has(imageUrl)) {
                                seenURLs.add(imageUrl);
                                imageCandidates.push({
                                    url: imageUrl,
                                    width: width,
                                    height: height,
                                    size: size
                                });
                            }
                        }
                    }
                }
            }
            
            // Sort by size (largest first) and return top 10 URLs for Vision classification
            imageCandidates.sort((a, b) => b.size - a.size);
            return imageCandidates.slice(0, 10).map(img => img.url);
        })();
        """
        
        // Execute JavaScript and get candidate image URLs
        guard let imageURLStrings = try await webView.evaluateJavaScript(imageExtractScript) as? [String],
              !imageURLStrings.isEmpty else {
            print("⚠️ Could not extract image URLs from webpage")
            return []
        }
        
        print("🔍 Found \(imageURLStrings.count) candidate images, classifying with Vision...")
        
        // Use Vision framework to classify images and identify food images
        var foodImageURLs: [String] = []
        let maxImages = 5
        
        for imageURLString in imageURLStrings.prefix(10) { // Limit to 10 candidates for efficiency
            guard foodImageURLs.count < maxImages else {
                break
            }
            
            guard let imageURL = URL(string: imageURLString) else {
                continue
            }
            
            do {
                // Download image with timeout
                var request = URLRequest(url: imageURL)
                request.timeoutInterval = 5.0
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200,
                      let image = UIImage(data: data) else {
                    continue
                }
                
                // Use Vision framework to classify the image
                if await isFoodImage(image) {
                    foodImageURLs.append(imageURLString)
                    print("✅ Identified food image: \(imageURLString)")
                }
            } catch {
                print("⚠️ Error processing image \(imageURLString): \(error.localizedDescription)")
                continue
            }
        }
        
        print("✅ Extracted \(foodImageURLs.count) food images from webpage")
        return foodImageURLs
    }
    
    /// Use Vision framework to classify if an image is food-related
    /// Returns true if the image is likely food/recipe related
    private static func isFoodImage(_ image: UIImage) async -> Bool {
        guard let cgImage = image.cgImage else {
            return false
        }
        
        return await withCheckedContinuation { continuation in
            // Use Vision's image classification request
            let request = VNClassifyImageRequest { request, error in
                guard let observations = request.results as? [VNClassificationObservation],
                      error == nil else {
                    continuation.resume(returning: false)
                    return
                }
                
                // Check for food-related classifications
                // Food categories typically have high confidence for: food, dish, cuisine, meal, etc.
                for observation in observations.prefix(5) { // Check top 5 classifications
                    let identifier = observation.identifier.lowercased()
                    let confidence = observation.confidence
                    
                    // Food-related keywords (using Vision's standard classification identifiers)
                    let foodKeywords = ["food", "dish", "cuisine", "meal", "recipe", "cooking", "dining", "restaurant", "cuisine", "gastronomy"]
                    
                    if foodKeywords.contains(where: { identifier.contains($0) }) && confidence > 0.3 {
                        continuation.resume(returning: true)
                        return
                    }
                }
                
                continuation.resume(returning: false)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: false)
            }
        }
    }
}

enum WebContentExtractorError: LocalizedError {
    case noContentFound
    
    var errorDescription: String? {
        switch self {
        case .noContentFound:
            return LocalizedString("No content found on the webpage. Please navigate to a recipe page.", comment: "No content found error")
        }
    }
}


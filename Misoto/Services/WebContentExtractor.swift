//
//  WebContentExtractor.swift
//  Misoto
//
//  Service for extracting text content from WKWebView
//

import Foundation
import WebKit
import UIKit

@MainActor
class WebContentExtractor {
    
    /// Extract text content from a WKWebView
    /// Uses JavaScript to extract visible text, removing HTML tags and non-relevant code
    static func extractText(from webView: WKWebView) async throws -> String {
        // JavaScript to extract text content, focusing on main content areas
        let extractScript = """
        (function() {
            // Remove script, style, nav, header, footer, aside, and other non-content elements
            const nonContentSelectors = [
                'script', 'style', 'nav', 'header', 'footer', 'aside', 
                '.advertisement', '.ad', '.sidebar', '.menu', '.navigation',
                '.social', '.share', '.comments', '.related', '.footer-content'
            ];
            
            nonContentSelectors.forEach(selector => {
                const elements = document.querySelectorAll(selector);
                elements.forEach(el => el.remove());
            });
            
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
            
            // Extract text, preserving line breaks
            const text = targetElement.innerText || targetElement.textContent || '';
            
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
    
    /// Extract the main recipe image from a WKWebView
    /// Returns the first prominent image found, typically the hero/featured recipe image
    static func extractRecipeImage(from webView: WKWebView) async throws -> UIImage? {
        // JavaScript to find and extract the main recipe image
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
                'article img:first-of-type',
                'main img:first-of-type',
                '.content img:first-of-type',
                '[role="main"] img:first-of-type',
                '.entry-content img:first-of-type',
                'img:first-of-type'
            ];
            
            let imageElement = null;
            let largestImage = null;
            let largestSize = 0;
            
            // Try to find the main recipe image
            for (const selector of imageSelectors) {
                const elements = document.querySelectorAll(selector);
                if (elements.length > 0) {
                    // Filter out very small images (likely icons or decorative elements)
                    for (const img of elements) {
                        const width = img.naturalWidth || img.width || img.clientWidth || 0;
                        const height = img.naturalHeight || img.height || img.clientHeight || 0;
                        const size = width * height;
                        
                        // Prefer images that are at least 150x150 pixels (reduced from 200x200)
                        if (width >= 150 && height >= 150) {
                            // If we find a good candidate, use it
                            if (size > largestSize) {
                                largestImage = img;
                                largestSize = size;
                            }
                        }
                    }
                    // If we found a good image from a high-priority selector, use it
                    if (largestImage && largestSize > 22500) { // 150x150
                        imageElement = largestImage;
                        break;
                    }
                }
            }
            
            // If no image found with strict criteria, try with more lenient size requirements
            if (!imageElement) {
                for (const selector of imageSelectors) {
                    const elements = document.querySelectorAll(selector);
                    if (elements.length > 0) {
                        for (const img of elements) {
                            const width = img.naturalWidth || img.width || img.clientWidth || 0;
                            const height = img.naturalHeight || img.height || img.clientHeight || 0;
                            const size = width * height;
                            
                            // More lenient: at least 100x100 pixels
                            if (width >= 100 && height >= 100 && size > largestSize) {
                                largestImage = img;
                                largestSize = size;
                            }
                        }
                    }
                }
                imageElement = largestImage;
            }
            
            if (!imageElement) {
                return null;
            }
            
            // Get the image source URL - try multiple attributes for lazy-loaded images
            let imageUrl = imageElement.src || 
                          imageElement.getAttribute('data-src') || 
                          imageElement.getAttribute('data-lazy-src') ||
                          imageElement.getAttribute('data-original') ||
                          imageElement.getAttribute('data-srcset')?.split(',')[0]?.trim().split(' ')[0];
            
            // If it's a relative URL, make it absolute
            if (imageUrl && !imageUrl.startsWith('http')) {
                try {
                    imageUrl = new URL(imageUrl, window.location.href).href;
                } catch (e) {
                    return null;
                }
            }
            
            return imageUrl;
        })();
        """
        
        // Execute JavaScript and get image URL
        guard let imageURLString = try await webView.evaluateJavaScript(imageExtractScript) as? String,
              !imageURLString.isEmpty,
              imageURLString != "null",
              let imageURL = URL(string: imageURLString) else {
            print("⚠️ Could not extract image URL from webpage")
            return nil
        }
        
        // Download the image data with timeout
        do {
            var request = URLRequest(url: imageURL)
            request.timeoutInterval = 10.0
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("⚠️ Failed to download image: HTTP \(response)")
                return nil
            }
            
            guard let image = UIImage(data: data) else {
                print("⚠️ Could not create UIImage from downloaded data")
                return nil
            }
            
            print("✅ Successfully extracted recipe image: \(imageURLString)")
            return image
        } catch {
            print("⚠️ Error downloading image: \(error.localizedDescription)")
            return nil
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


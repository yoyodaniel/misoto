//
//  ImageCache.swift
//  Misoto
//
//  Created by Daniel Chan on 4.1.2026.
//

import Foundation
import UIKit

/// Global image cache configuration for URLSession
class ImageCache {
    static let shared = ImageCache()
    
    private init() {
        // Configure URLCache for better image caching
        // Memory capacity reduced to prevent memory issues and app termination
        let memoryCapacity = 20 * 1024 * 1024 // 20 MB (reduced from 50MB)
        // Disk capacity increased for recipe sharing app with multiple images per recipe
        // Calculation: 20 recipes/page × 5 images max × 500KB = ~50MB/page
        // 10 pages = ~500MB, plus Today's Special, What's New, search results, profiles
        // 1GB provides comfortable buffer for heavy browsing sessions
        let diskCapacity = 1024 * 1024 * 1024 // 1 GB
        
        // Create custom cache with larger capacity
        let urlCache = URLCache(
            memoryCapacity: memoryCapacity,
            diskCapacity: diskCapacity,
            diskPath: "misoto_image_cache"
        )
        
        URLCache.shared = urlCache
        
        // Configure URLSession.default to use cache aggressively
        // Note: AsyncImage uses URLSession.shared internally, which respects URLCache.shared
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = urlCache
        configuration.requestCachePolicy = .returnCacheDataElseLoad // Use cache if available, otherwise load
        
        print("✅ ImageCache configured: Memory \(memoryCapacity / 1024 / 1024)MB, Disk \(diskCapacity / 1024 / 1024)MB")
        print("✅ URLCache.shared is now configured for AsyncImage caching")
    }
    
    /// Clear the image cache (useful for debugging or when storage is needed)
    static func clearCache() {
        URLCache.shared.removeAllCachedResponses()
        print("🗑️ Image cache cleared")
    }
    
    /// Get current cache statistics
    static func getCacheStats() -> (memoryUsage: Int, diskUsage: Int) {
        let cache = URLCache.shared
        return (
            memoryUsage: cache.currentMemoryUsage,
            diskUsage: cache.currentDiskUsage
        )
    }
}


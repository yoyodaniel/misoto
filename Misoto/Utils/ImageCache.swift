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
        // Increased sizes for better caching when scrolling
        let memoryCapacity = 100 * 1024 * 1024 // 100 MB (increased from 50 MB)
        let diskCapacity = 500 * 1024 * 1024 // 500 MB (increased from 200 MB)
        
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


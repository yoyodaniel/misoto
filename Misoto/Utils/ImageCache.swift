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
        let memoryCapacity = 50 * 1024 * 1024 // 50 MB
        let diskCapacity = 200 * 1024 * 1024 // 200 MB
        URLCache.shared = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: "image_cache")
    }
}


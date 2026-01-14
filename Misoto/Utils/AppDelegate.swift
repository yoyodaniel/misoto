//
//  AppDelegate.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import UIKit
import FirebaseCore

@objc(AppDelegate)
class AppDelegate: NSObject, UIApplicationDelegate {
    
    private var memoryWarningObserver: NSObjectProtocol?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Firebase is already configured in MisotoApp.init()
        // This delegate is primarily to satisfy Firebase's AppDelegateSwizzler requirements
        
        // Listen for memory warnings to clear image cache when needed
        setupMemoryWarningObserver()
        
        return true
    }
    
    // Optional: Add these methods to satisfy Firebase's AppDelegateSwizzler more completely
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle URL schemes if needed
        return false
    }
    
    // MARK: - Memory Warning Handling
    
    private func setupMemoryWarningObserver() {
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }
    
    /// Clear image cache when memory is low to prevent memory issues
    private func handleMemoryWarning() {
        let cache = URLCache.shared
        let memoryUsage = cache.currentMemoryUsage
        let memoryCapacity = cache.memoryCapacity
        
        // If memory usage is above 80% of capacity, clear memory cache
        if memoryUsage > Int(Double(memoryCapacity) * 0.8) {
            cache.removeAllCachedResponses()
            print("⚠️ Memory warning: Cleared image cache (was using \(memoryUsage / 1024 / 1024)MB)")
        } else {
            // Log cache usage for monitoring
            print("⚠️ Memory warning: Image cache usage: \(memoryUsage / 1024 / 1024)MB / \(memoryCapacity / 1024 / 1024)MB")
        }
    }
    
    deinit {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}



//
//  AppDelegate.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import UIKit
import FirebaseCore
import UserNotifications

@objc(AppDelegate)
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    private var memoryWarningObserver: NSObjectProtocol?
    private var memoryMonitorTimer: Timer?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Firebase is already configured in MisotoApp.init()
        // This delegate is primarily to satisfy Firebase's AppDelegateSwizzler requirements
        
        // Listen for memory warnings to clear image cache when needed
        setupMemoryWarningObserver()
        
        // Start periodic memory monitoring to prevent memory buildup
        startMemoryMonitoring()
        
        // Show notification banners while app is in foreground.
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // Optional: Add these methods to satisfy Firebase's AppDelegateSwizzler more completely
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle URL schemes if needed
        return false
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("✅ APNs device token received: \(token)")
        NotificationCenter.default.post(
            name: NSNotification.Name("APNsDeviceTokenUpdated"),
            object: nil,
            userInfo: ["token": token]
        )
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("⚠️ Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
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
        
        // More aggressive: Clear memory cache if usage is above 50% of capacity
        // This prevents memory buildup that can cause app termination
        if memoryUsage > Int(Double(memoryCapacity) * 0.5) {
            cache.removeAllCachedResponses()
            print("⚠️ Memory warning: Cleared image cache (was using \(memoryUsage / 1024 / 1024)MB / \(memoryCapacity / 1024 / 1024)MB)")
        } else {
            // Log cache usage for monitoring
            print("⚠️ Memory warning: Image cache usage: \(memoryUsage / 1024 / 1024)MB / \(memoryCapacity / 1024 / 1024)MB")
        }
        
        // Also clear any other caches that might be holding memory
        // Force garbage collection of image data
        autoreleasepool {
            // This helps release any autoreleased image data
        }
    }
    
    // MARK: - Memory Monitoring
    
    /// Start periodic memory monitoring to prevent memory buildup
    private func startMemoryMonitoring() {
        // Check memory usage every 30 seconds
        memoryMonitorTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.checkMemoryUsage()
        }
    }
    
    /// Check current memory usage and clear cache if needed
    private func checkMemoryUsage() {
        let cache = URLCache.shared
        let memoryUsage = cache.currentMemoryUsage
        let memoryCapacity = cache.memoryCapacity
        
        // If memory usage is above 60% of capacity, proactively clear cache
        // This prevents memory buildup before the system sends a memory warning
        if memoryUsage > Int(Double(memoryCapacity) * 0.6) {
            cache.removeAllCachedResponses()
            print("🔍 Memory monitor: Proactively cleared image cache (was using \(memoryUsage / 1024 / 1024)MB / \(memoryCapacity / 1024 / 1024)MB)")
        }
    }
    
    deinit {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        memoryMonitorTimer?.invalidate()
    }
}



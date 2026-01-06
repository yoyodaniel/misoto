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
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Firebase is already configured in MisotoApp.init()
        // This delegate is primarily to satisfy Firebase's AppDelegateSwizzler requirements
        return true
    }
    
    // Optional: Add these methods to satisfy Firebase's AppDelegateSwizzler more completely
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle URL schemes if needed
        return false
    }
}



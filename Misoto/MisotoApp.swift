//
//  MisotoApp.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import FirebaseCore

@main
struct MisotoApp: App {
    // Configure Firebase first, before creating view models
    init() {
        FirebaseApp.configure()
    }
    
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var appSettings = AppSettings.shared
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isInitializing {
                    // Show loading screen while checking auth state
                    LoadingView()
                } else if authViewModel.isAuthenticated {
                    MainTabView()
                        .environmentObject(authViewModel)
                } else {
                    LoginView()
                        .environmentObject(authViewModel)
                }
            }
            .preferredColorScheme(appSettings.isDarkModeEnabled ? .dark : .light)
            .environmentObject(appSettings)
            .environmentObject(localizationManager)
            .localized() // Apply localization modifier to update views on language change
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                
                Text(LocalizedString("Loading...", comment: "Loading text"))
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

//
//  AppCheckConfigurator.swift
//  Misoto
//
//  Configures Firebase App Check before FirebaseApp.configure().
//

import FirebaseAppCheck
import FirebaseCore
import Foundation

// MARK: - Provider factory

private final class MisotoAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
  func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
    #if DEBUG
    return AppCheckDebugProvider(app: app)
    #else
    #if targetEnvironment(simulator)
    // App Attest is unavailable on the simulator; Device Check works for release testing.
    return DeviceCheckProvider(app: app)
    #else
    return AppAttestProvider(app: app)
    #endif
    #endif
  }
}

// MARK: - Configuration

enum AppCheckConfigurator {
  /// Call once before `FirebaseApp.configure()`.
  static func configureIfNeeded() {
    AppCheck.setAppCheckProviderFactory(MisotoAppCheckProviderFactory())
  }
}

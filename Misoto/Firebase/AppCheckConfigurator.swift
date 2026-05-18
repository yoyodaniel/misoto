//
//  AppCheckConfigurator.swift
//  Misoto
//
//  Configures Firebase App Check before FirebaseApp.configure().
//

import FirebaseAppCheck
import FirebaseCore
import Foundation

enum AppCheckConfigurator {
  /// Call once before `FirebaseApp.configure()`.
  static func configureIfNeeded() {
    #if DEBUG
    AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
    #else
    AppCheck.setAppCheckProviderFactory(AppAttestProviderFactory())
    #endif
  }
}

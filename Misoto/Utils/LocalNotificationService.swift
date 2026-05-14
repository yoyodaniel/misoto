//
//  LocalNotificationService.swift
//  Misoto
//
//  Handles app-local notifications for recipe update recommendations.
//

import Foundation
import UserNotifications
import UIKit

@MainActor
final class LocalNotificationService {
    static let shared = LocalNotificationService()
    
    private let center = UNUserNotificationCenter.current()
    private var didRequestAuthorization = false
    
    private init() {}
    
    func requestAuthorizationIfNeeded() async {
        guard !didRequestAuthorization else { return }
        didRequestAuthorization = true
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            print("🔔 Local notifications authorization granted: \(granted)")
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            print("⚠️ Local notification authorization failed: \(error.localizedDescription)")
        }
    }
    
    func sendRecipeSuggestionNotification(for proposal: RecipeChangeProposal) {
        Task {
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = LocalizedString("New recipe update recommendation", comment: "Notification title")
            content.body = notificationBody(for: proposal)
            content.sound = .default
            
            let request = UNNotificationRequest(
                identifier: "recipe-suggestion-\(proposal.id)",
                content: content,
                trigger: nil
            )
            
            do {
                try await center.add(request)
            } catch {
                print("⚠️ Failed to schedule recommendation notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func notificationBody(for proposal: RecipeChangeProposal) -> String {
        let sender = proposal.displayName.isEmpty ? LocalizedString("Someone", comment: "Fallback sender") : proposal.displayName
        let kindText: String
        switch proposal.targetKind {
        case .ingredient:
            kindText = LocalizedString("ingredient", comment: "Notification target ingredient")
        case .instruction:
            kindText = LocalizedString("step", comment: "Notification target step")
        case .tip:
            kindText = LocalizedString("tip", comment: "Notification target tip")
        case .description:
            kindText = LocalizedString("description", comment: "Notification target description")
        }
        
        return String(
            format: LocalizedString("%@ suggested a change to your recipe %@.", comment: "Notification recommendation body"),
            sender,
            kindText
        )
    }
}

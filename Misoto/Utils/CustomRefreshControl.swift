//
//  CustomRefreshControl.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import SwiftUI
import UIKit

struct CustomRefreshableModifier: ViewModifier {
    let action: () async -> Void
    let scale: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                RefreshControlReader(action: action, scale: scale)
            )
    }
}

struct RefreshControlReader: UIViewRepresentable {
    let action: () async -> Void
    let scale: CGFloat
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            guard let scrollView = uiView.findScrollView() else { return }
            
            // Remove existing refresh controls
            scrollView.subviews.forEach { subview in
                if subview is UIRefreshControl {
                    subview.removeFromSuperview()
                }
            }
            
            let refreshControl = UIRefreshControl()
            refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh(_:)), for: .valueChanged)
            
            // Scale down the refresh control
            refreshControl.transform = CGAffineTransform(scaleX: scale, y: scale)
            
            scrollView.refreshControl = refreshControl
            context.coordinator.refreshControl = refreshControl
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        var refreshControl: UIRefreshControl?
        let action: () async -> Void
        
        init(action: @escaping () async -> Void) {
            self.action = action
        }
        
        @objc func handleRefresh(_ sender: UIRefreshControl) {
            Task {
                await action()
                await MainActor.run {
                    sender.endRefreshing()
                }
            }
        }
    }
}

extension UIView {
    func findScrollView() -> UIScrollView? {
        if let scrollView = self as? UIScrollView {
            return scrollView
        }
        
        for subview in subviews {
            if let scrollView = subview.findScrollView() {
                return scrollView
            }
        }
        
        return nil
    }
}

extension View {
    func customRefreshable(scale: CGFloat = 0.75, action: @escaping () async -> Void) -> some View {
        modifier(CustomRefreshableModifier(action: action, scale: scale))
    }
}



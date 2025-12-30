//
//  CameraCaptureView.swift
//  Misoto
//
//  Camera capture view for taking pictures
//

import SwiftUI
import UIKit

struct CameraCaptureView: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.cameraCaptureMode = .photo
        // Make camera full screen with no safe area
        picker.modalPresentationStyle = .fullScreen
        picker.modalTransitionStyle = .coverVertical
        
        // Customize appearance for black background
        configureAppearance()
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // Ensure full screen presentation
        uiViewController.modalPresentationStyle = .fullScreen
        // Set black background
        uiViewController.view.backgroundColor = .black
        
        // Customize the bottom toolbar after view loads (multiple times to catch dynamic UI)
        DispatchQueue.main.async {
            self.customizeCameraInterface(uiViewController)
        }
        // Try again after delays to catch toolbar when it appears (especially after photo is taken)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.customizeCameraInterface(uiViewController)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.customizeCameraInterface(uiViewController)
        }
    }
    
    private func configureAppearance() {
        // Set toolbar appearance to black for camera picker
        let toolBarAppearance = UIToolbarAppearance()
        toolBarAppearance.configureWithOpaqueBackground()
        toolBarAppearance.backgroundColor = .black
        
        UIToolbar.appearance(whenContainedInInstancesOf: [UIImagePickerController.self]).standardAppearance = toolBarAppearance
        UIToolbar.appearance(whenContainedInInstancesOf: [UIImagePickerController.self]).compactAppearance = toolBarAppearance
        UIToolbar.appearance(whenContainedInInstancesOf: [UIImagePickerController.self]).scrollEdgeAppearance = toolBarAppearance
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func customizeCameraInterface(_ picker: UIImagePickerController) {
        // Find and customize the bottom toolbar
        func findToolbar(in view: UIView) -> UIToolbar? {
            for subview in view.subviews {
                if let toolbar = subview as? UIToolbar {
                    return toolbar
                }
                if let found = findToolbar(in: subview) {
                    return found
                }
            }
            return nil
        }
        
        // Customize toolbar appearance
        if let toolbar = findToolbar(in: picker.view) {
            toolbar.backgroundColor = .black
            toolbar.barTintColor = .black
            toolbar.isTranslucent = false
            toolbar.standardAppearance.backgroundColor = .black
            toolbar.compactAppearance?.backgroundColor = .black
            toolbar.scrollEdgeAppearance?.backgroundColor = .black
            
            // Also customize the toolbar's subviews (buttons container)
            for subview in toolbar.subviews {
                subview.backgroundColor = .black
            }
        }
        
        // Find and customize any container views with gray/dark gray background
        func customizeViews(in view: UIView) {
            // Check for gray backgrounds and change to black
            let grayColors: [UIColor] = [.systemGray, .systemGray2, .systemGray3, .systemGray4, .systemGray5, .systemGray6]
            if let bgColor = view.backgroundColor, grayColors.contains(where: { $0.isEqual(bgColor) }) {
                view.backgroundColor = .black
            }
            
            // Also check for dark gray backgrounds that should be black
            if let bgColor = view.backgroundColor,
               bgColor != .black && bgColor != .clear,
               bgColor.cgColor.alpha > 0.3 {
                // Check if it's a dark color (low brightness)
                var white: CGFloat = 0
                bgColor.getWhite(&white, alpha: nil)
                if white < 0.3 {
                    view.backgroundColor = .black
                }
            }
            
            for subview in view.subviews {
                customizeViews(in: subview)
            }
        }
        customizeViews(in: picker.view)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraCaptureView
        
        init(_ parent: CameraCaptureView) {
            self.parent = parent
        }
        
        func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
            // Customize toolbar when view appears (after photo is taken)
            if let picker = navigationController as? UIImagePickerController {
                DispatchQueue.main.async {
                    self.parent.customizeCameraInterface(picker)
                }
                // Also try again after a short delay to ensure UI is fully loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.parent.customizeCameraInterface(picker)
                }
            }
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                // Call the callback first to set the image (this happens synchronously)
                self.parent.onImageCaptured(image)
                // Dismiss immediately - the callback should have set the state
                self.parent.dismiss()
            } else {
                self.parent.dismiss()
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}



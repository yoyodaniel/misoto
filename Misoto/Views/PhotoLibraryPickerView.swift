//
//  PhotoLibraryPickerView.swift
//  Misoto
//
//  Photo library picker that can be programmatically presented
//

import SwiftUI
import UIKit
import PhotosUI

struct PhotoLibraryPickerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let maxSelectionCount: Int
    let onImagesSelected: ([UIImage]) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented && uiViewController.presentedViewController == nil {
            // Present PhotosPicker using PHPickerViewController
            var configuration = PHPickerConfiguration()
            configuration.filter = .images
            configuration.selectionLimit = maxSelectionCount
            
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = context.coordinator
            
            // Find the topmost view controller to present from
            DispatchQueue.main.async {
                guard uiViewController.presentedViewController == nil else { return }
                
                // Try to find the root view controller
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootViewController = window.rootViewController {
                    // Find the topmost presented view controller
                    var topViewController = rootViewController
                    while let presented = topViewController.presentedViewController {
                        topViewController = presented
                    }
                    
                    // Present from the topmost view controller
                    topViewController.present(picker, animated: true)
                } else {
                    // Fallback to presenting from the provided view controller
                    uiViewController.present(picker, animated: true)
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPickerView
        
        init(_ parent: PhotoLibraryPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            parent.isPresented = false
            
            // Load images from results
            var images: [UIImage] = []
            let group = DispatchGroup()
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    group.enter()
                    result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                        defer { group.leave() }
                        if let image = object as? UIImage {
                            images.append(image)
                        } else if let error = error {
                            print("Failed to load image: \(error.localizedDescription)")
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                self.parent.onImagesSelected(images)
            }
        }
    }
}


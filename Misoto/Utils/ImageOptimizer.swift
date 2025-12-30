//
//  ImageOptimizer.swift
//  Misoto
//
//  Utility for optimizing images before processing and upload
//

import UIKit

@MainActor
class ImageOptimizer {
    
    /// Resize image to maximum dimensions while maintaining aspect ratio
    /// This reduces memory usage and improves performance
    static func resizeImage(_ image: UIImage, maxDimension: CGFloat = 2048) -> UIImage {
        let size = image.size
        
        // If image is already smaller than max dimension, return original
        guard max(size.width, size.height) > maxDimension else {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: size.height * (maxDimension / size.width))
        } else {
            newSize = CGSize(width: size.width * (maxDimension / size.height), height: maxDimension)
        }
        
        // Resize image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage
    }
    
    /// Resize image for OCR/processing (smaller size for faster processing)
    static func resizeForProcessing(_ image: UIImage) -> UIImage {
        return resizeImage(image, maxDimension: 1600)
    }
    
    /// Resize image for upload (good balance between quality and file size)
    static func resizeForUpload(_ image: UIImage) -> UIImage {
        return resizeImage(image, maxDimension: 2048)
    }
    
    /// Resize image for display (smaller size for UI)
    static func resizeForDisplay(_ image: UIImage, maxDimension: CGFloat = 800) -> UIImage {
        return resizeImage(image, maxDimension: maxDimension)
    }
    
    /// Compress image data with quality optimization
    static func compressImage(_ image: UIImage, quality: CGFloat = 0.8, maxFileSizeKB: Int = 500) -> Data? {
        guard var imageData = image.jpegData(compressionQuality: quality) else {
            return nil
        }
        
        // If file size is acceptable, return
        let fileSizeKB = imageData.count / 1024
        if fileSizeKB <= maxFileSizeKB {
            return imageData
        }
        
        // Reduce quality progressively until file size is acceptable
        var currentQuality = quality
        while currentQuality > 0.1 && imageData.count / 1024 > maxFileSizeKB {
            currentQuality -= 0.1
            if let data = image.jpegData(compressionQuality: currentQuality) {
                imageData = data
            } else {
                break
            }
        }
        
        return imageData
    }
}



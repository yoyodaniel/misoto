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

    // MARK: - Display

    /// Renders EXIF orientation into pixels so SwiftUI `Image` does not appear stretched or rotated.
    static func normalizedForDisplay(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }

    // MARK: - AI dish-photo enhancement

    /// Center-crop to 1:1 by using the full shorter side and cropping the longer side (zoomed fill, no letterboxing).
    static func squareCenterFilled(_ image: UIImage) -> UIImage {
        let normalized = normalizedForDisplay(image)
        guard let cgImage = normalized.cgImage else { return normalized }
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let side = min(width, height)
        let originX = (width - side) / 2
        let originY = (height - side) / 2
        let cropRect = CGRect(x: originX, y: originY, width: side, height: side)
        guard let cropped = cgImage.cropping(to: cropRect) else { return normalized }
        return UIImage(cgImage: cropped, scale: normalized.scale, orientation: .up)
    }

    /// Center square crop for 1:1 recipe cards (`ModernRecipeCard`).
    static func squareCropForRecipeCard(_ image: UIImage) -> UIImage {
        squareCenterFilled(image)
    }

    /// JPEG base64 for OpenAI Images edit API — kept small for Firebase Callable payload limits (~10 MB).
    static func jpegBase64ForImageEdit(_ image: UIImage) -> (base64: String, mimeType: String)? {
        let square = squareCropForRecipeCard(image)
        // Callable carries base64 in JSON; PNG at 1024² often exceeds the 8 MB string cap.
        let maxBase64Characters = 4 * 1024 * 1024
        var maxDimension: CGFloat = 768
        var quality: CGFloat = 0.82

        while maxDimension >= 480 {
            var currentQuality = quality
            let sized = resizeImage(square, maxDimension: maxDimension)
            while currentQuality >= 0.45 {
                guard let jpegData = sized.jpegData(compressionQuality: currentQuality) else {
                    break
                }
                let encoded = jpegData.base64EncodedString()
                if encoded.count <= maxBase64Characters {
                    return (encoded, "image/jpeg")
                }
                currentQuality -= 0.08
            }
            maxDimension -= 128
        }
        return nil
    }
}











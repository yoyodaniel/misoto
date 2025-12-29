//
//  StorageService.swift
//  Misoto
//
//  Created by Daniel Chan on 24.12.2025.
//

import Foundation
import Combine
import FirebaseStorage
import UIKit
import UniformTypeIdentifiers

class StorageService: ObservableObject {
    private let storage = Storage.storage()
    
    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        // Optimize image before upload (resize and compress)
        let optimizedImage = await ImageOptimizer.resizeForUpload(image)
        guard let imageData = ImageOptimizer.compressImage(optimizedImage, quality: 0.8, maxFileSizeKB: 500) else {
            throw StorageError.invalidImage
        }
        
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        return try await withCheckedThrowingContinuation { continuation in
            storageRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                storageRef.downloadURL { url, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let url = url {
                        continuation.resume(returning: url.absoluteString)
                    } else {
                        continuation.resume(throwing: StorageError.uploadFailed)
                    }
                }
            }
        }
    }
    
    func uploadVideo(_ videoURL: URL, path: String) async throws -> String {
        // Note: Firebase Storage Swift SDK requires Data, so we must load video into memory
        // Consider limiting video file sizes in the UI to prevent memory issues
        let videoData = try Data(contentsOf: videoURL)
        
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"
        
        return try await withCheckedThrowingContinuation { continuation in
            storageRef.putData(videoData, metadata: metadata) { metadata, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                storageRef.downloadURL { url, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let url = url {
                        continuation.resume(returning: url.absoluteString)
                    } else {
                        continuation.resume(throwing: StorageError.uploadFailed)
                    }
                }
            }
        }
    }
    
    func deleteFile(at path: String) async throws {
        let storageRef = storage.reference().child(path)
        try await storageRef.delete()
    }
}

enum StorageError: LocalizedError {
    case invalidImage
    case uploadFailed
    case invalidPath
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return NSLocalizedString("Invalid image data", comment: "Invalid image error")
        case .uploadFailed:
            return NSLocalizedString("Failed to upload file", comment: "Upload failed error")
        case .invalidPath:
            return NSLocalizedString("Invalid storage path", comment: "Invalid path error")
        }
    }
}


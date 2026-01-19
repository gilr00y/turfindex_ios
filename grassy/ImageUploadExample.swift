//
//  ImageUploadExample.swift
//  grassy
//
//  Created by jason on 1/18/26.
//

import Foundation
import UIKit

/// Example usage of ImageUploadService
enum ImageUploadExample {
    
    // MARK: - Single Image Upload
    
    /// Upload a single image
    static func uploadSingleImage(userId: String, imageData: Data) async throws -> String {
        let filename = "\(UUID().uuidString).jpg"
        
        let recordId = try await ImageUploadService.shared.uploadImages(
            userId: userId,
            images: [
                (key: "1", data: imageData, filename: filename)
            ]
        )
        
        // Return the full photo URL path
        return "\(userId)/\(recordId)/\(filename)"
    }
    
    // MARK: - Multiple Images Upload
    
    /// Upload multiple images in a single batch
    static func uploadMultipleImages(
        userId: String,
        imageDatas: [Data]
    ) async throws -> (recordId: String, photoUrls: [String]) {
        // Create image entries with sequential keys
        let images: [(key: String, data: Data, filename: String)] = imageDatas.enumerated().map { index, data in
            let filename = "\(UUID().uuidString).jpg"
            return (key: "\(index + 1)", data: data, filename: filename)
        }
        
        // Upload all images
        let recordId = try await ImageUploadService.shared.uploadImages(
            userId: userId,
            images: images
        )
        
        // Construct photo URLs
        let photoUrls = images.map { "\(userId)/\(recordId)/\($0.filename)" }
        
        return (recordId: recordId, photoUrls: photoUrls)
    }
    
    // MARK: - Upload with Progress Tracking
    
    /// Upload images with progress tracking (for future enhancement)
    static func uploadWithProgress(
        userId: String,
        images: [(data: Data, filename: String)],
        onProgress: @escaping (Double) -> Void
    ) async throws -> String {
        let totalImages = images.count
        var completedImages = 0
        
        // For now, this is a placeholder for future progress tracking
        // The actual ImageUploadService would need to be enhanced to support progress callbacks
        
        let imageEntries = images.enumerated().map { index, image in
            (key: "\(index + 1)", data: image.data, filename: image.filename)
        }
        
        onProgress(0.0)
        
        let recordId = try await ImageUploadService.shared.uploadImages(
            userId: userId,
            images: imageEntries
        )
        
        onProgress(1.0)
        
        return recordId
    }
    
    // MARK: - Retry Logic
    
    /// Upload with retry on failure
    static func uploadWithRetry(
        userId: String,
        imageData: Data,
        maxRetries: Int = 3
    ) async throws -> String {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                return try await uploadSingleImage(userId: userId, imageData: imageData)
            } catch {
                lastError = error
                print("Upload attempt \(attempt) failed: \(error.localizedDescription)")
                
                if attempt < maxRetries {
                    // Wait before retrying (exponential backoff)
                    let delay = Double(attempt) * 1.0
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? ImageUploadError.serverError(statusCode: 0)
    }
}

// MARK: - Integration Example for CreatePostView

extension ImageUploadExample {
    
    /// Example of how to integrate into CreatePostView
    static func createPostWithUpload(
        userId: String,
        username: String,
        caption: String,
        location: String,
        tags: [String],
        imageData: Data
    ) async throws -> Post {
        // 1. Upload image
        let photoUrl = try await uploadSingleImage(userId: userId, imageData: imageData)
        
        // 2. Create post in database
        let post = try await PostService.shared.createPost(
            userId: userId,
            username: username,
            caption: caption,
            location: location,
            tags: tags,
            photoUrl: photoUrl
        )
        
        return post
    }
}

// MARK: - Testing Utilities

#if DEBUG
extension ImageUploadExample {
    
    /// Generate test image data
    static func generateTestImage(width: Int = 100, height: Int = 100) -> Data? {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Draw a gradient
            let colors = [UIColor.red.cgColor, UIColor.blue.cgColor]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(
                colorsSpace: colorSpace,
                colors: colors as CFArray,
                locations: [0, 1]
            )!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
        }
        
        return image.jpegData(compressionQuality: 0.8)
    }
    
    /// Test the upload flow
    static func testUploadFlow() async {
        guard let testData = generateTestImage() else {
            print("Failed to generate test image")
            return
        }
        
        do {
            let photoUrl = try await uploadSingleImage(
                userId: "test_user_123",
                imageData: testData
            )
            print("✅ Upload successful! Photo URL: \(photoUrl)")
        } catch {
            print("❌ Upload failed: \(error.localizedDescription)")
        }
    }
}
#endif

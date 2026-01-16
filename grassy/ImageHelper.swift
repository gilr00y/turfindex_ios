//
//  ImageHelper.swift
//  grassy
//
//  Created by jason on 1/14/26.
//

import UIKit

/// Helper utilities for image processing
enum ImageHelper {
    
    /// Compress and resize image for upload
    /// - Parameters:
    ///   - image: Original UIImage
    ///   - maxDimension: Maximum width or height (default 2048)
    ///   - compressionQuality: JPEG compression quality 0-1 (default 0.8)
    /// - Returns: Compressed image data
    static func prepareForUpload(
        _ image: UIImage,
        maxDimension: CGFloat = 2048,
        compressionQuality: CGFloat = 0.8
    ) -> Data? {
        let resizedImage = resize(image, maxDimension: maxDimension)
        return resizedImage.jpegData(compressionQuality: compressionQuality)
    }
    
    /// Resize image maintaining aspect ratio
    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let ratio = size.width / size.height
        
        var newSize: CGSize
        if size.width > size.height {
            // Landscape
            if size.width > maxDimension {
                newSize = CGSize(width: maxDimension, height: maxDimension / ratio)
            } else {
                newSize = size
            }
        } else {
            // Portrait or square
            if size.height > maxDimension {
                newSize = CGSize(width: maxDimension * ratio, height: maxDimension)
            } else {
                newSize = size
            }
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// Generate thumbnail
    static func generateThumbnail(_ image: UIImage, size: CGFloat = 200) -> UIImage {
        let thumbnailSize = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
        
        return renderer.image { context in
            let drawRect = AVMakeRect(
                aspectRatio: image.size,
                insideRect: CGRect(origin: .zero, size: thumbnailSize)
            )
            image.draw(in: drawRect)
        }
    }
    
    /// Calculate image file size
    static func fileSize(of data: Data) -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useKB, .useMB]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: Int64(data.count))
    }
}

import AVFoundation

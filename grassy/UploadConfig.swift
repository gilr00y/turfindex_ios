//
//  UploadConfig.swift
//  grassy
//
//  Created by jason on 1/18/26.
//

import Foundation

/// Configuration for image upload service
struct UploadConfig {
    /// Base URL for the upload API
    /// - Development: http://localhost:3000
    /// - Production: https://api.yourserver.com
    static let apiBaseURL: String = {
        return "http://138.197.102.182:3000"
    }()
    
    /// Timeout for API requests (in seconds)
    static let requestTimeout: TimeInterval = 30
    
    /// Timeout for image uploads (in seconds)
    static let uploadTimeout: TimeInterval = 120
    
    /// Maximum number of concurrent uploads
    static let maxConcurrentUploads = 3
    
    /// Default upload source identifier
    static let uploadSource = "mobile_app"
    
    /// Enable retry on network failures
    static let enableRetry = true
    
    /// Maximum retry attempts
    static let maxRetryAttempts = 3
    
    /// Retry delay (in seconds)
    static let retryDelay: TimeInterval = 2.0
}

// MARK: - Digital Ocean Spaces Configuration

extension UploadConfig {
    /// Digital Ocean Spaces bucket name
    static let spacesBaseBucket = "turf"
    
    /// Digital Ocean Spaces region
    static let spacesRegion = "nyc3"
    
    /// Construct full Digital Ocean Spaces URL
    static func spacesURL(for path: String) -> String {
        "https://\(spacesBaseBucket).\(spacesRegion).digitaloceanspaces.com/\(path)"
    }
}

// MARK: - Image Processing Configuration

extension UploadConfig {
    /// Maximum image dimension (width or height)
    static let maxImageDimension: CGFloat = 2048
    
    /// JPEG compression quality (0.0 - 1.0)
    static let compressionQuality: CGFloat = 0.8
    
    /// Supported image formats
    static let supportedFormats = ["jpg", "jpeg", "png", "heic", "heif", "webp"]
    
    /// Maximum file size (in bytes) - 10MB
    static let maxFileSize = 10 * 1024 * 1024
}

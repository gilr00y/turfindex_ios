//
//  ImageUploadModels.swift
//  grassy
//
//  Created by jason on 1/18/26.
//

import Foundation

// MARK: - Upload Request Models

/// Request to initiate image upload
struct ImageUploadRequest: Codable {
    let userId: String
    let metadata: UploadMetadata
    let images: [ImageInfo]
}

struct UploadMetadata: Codable {
    let uploadSource: String
    let sessionId: String
    let timestamp: String
    
    init(uploadSource: String = "mobile_app", sessionId: String = UUID().uuidString) {
        self.uploadSource = uploadSource
        self.sessionId = sessionId
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        self.timestamp = formatter.string(from: Date())
    }
}

struct ImageInfo: Codable {
    let key: String
    let filename: String
    let contentType: String
}

// MARK: - Upload Response Models

/// Response from upload initialization
struct ImageUploadResponse: Codable {
    let recordId: String
    let uploads: [PresignedUpload]
}

struct PresignedUpload: Codable {
    let filename: String
    let presignedUrl: String
}

// MARK: - Upload Confirmation

/// Request to confirm completed uploads
struct UploadConfirmRequest: Codable {
    // Empty for now, but can include checksums, sizes, etc.
}

/// Response from upload confirmation
struct UploadConfirmResponse: Codable {
    let success: Bool
    let recordId: String
    let message: String?
}

// MARK: - Leaderboard Models

/// Response from the top 100 leaderboard endpoint
struct LeaderboardResponse: Codable {
    let id: String
    let userId: String
    let status: String
    let metadata: UploadMetadata
    let images: [RatedImage]
    let createdAt: String
    let updatedAt: String
    let rating: ImageRating?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId
        case status
        case metadata
        case images
        case createdAt
        case updatedAt
        case rating
    }
}

struct RatedImage: Codable {
    let key: String
    let filename: String
    let contentType: String
    let rating: ImageRating?
    let url: String
}

struct ImageRating: Codable {
    let quality: Int
    let composition: Int
    let lighting: Int
    let overall: Int
    let feedback: String
}

// MARK: - Helper Extensions

extension ImageInfo {
    /// Create ImageInfo from image data
    init(key: String, data: Data, filename: String? = nil) {
        self.key = key
        self.filename = filename ?? "\(UUID().uuidString).jpg"
        
        // Detect content type from data
        if let contentType = data.mimeType {
            self.contentType = contentType
        } else {
            self.contentType = "image/jpeg"
        }
    }
}

extension Data {
    /// Detect MIME type from data
    /// This is a synchronous, thread-safe operation that only reads from immutable Data
    nonisolated var mimeType: String? {
        var bytes = [UInt8](repeating: 0, count: 1)
        copyBytes(to: &bytes, count: 1)
        
        switch bytes[0] {
        case 0xFF:
            return "image/jpeg"
        case 0x89:
            return "image/png"
        case 0x47:
            return "image/gif"
        case 0x49, 0x4D:
            return "image/tiff"
        case 0x52 where count > 12:
            // Check for WebP
            var testBytes = [UInt8](repeating: 0, count: 12)
            copyBytes(to: &testBytes, count: 12)
            let riff = String(data: Data(testBytes[0..<4]), encoding: .ascii)
            let webp = String(data: Data(testBytes[8..<12]), encoding: .ascii)
            if riff == "RIFF" && webp == "WEBP" {
                return "image/webp"
            }
            return nil
        default:
            return nil
        }
    }
}

//
//  ImageUploadService.swift
//  grassy
//
//  Created by jason on 1/18/26.
//

import Foundation

/// Service for handling multi-step image uploads via API
actor ImageUploadService {
    static let shared = ImageUploadService()
    
    private let baseURL: String
    
    init(baseURL: String = UploadConfig.apiBaseURL) {
        self.baseURL = baseURL
    }
    
    // MARK: - Public Upload API
    
    /// Upload images using the three-step process:
    /// 1. Request presigned URLs from API
    /// 2. Upload images to presigned URLs
    /// 3. Confirm uploads with API
    func uploadImages(
        userId: String,
        images: [(key: String, data: Data, filename: String)]
    ) async throws -> String {
        // Step 1: Request presigned URLs
        let recordId = try await requestPresignedURLs(userId: userId, images: images)
        
        // Step 2: Upload images to presigned URLs
        try await uploadToPresignedURLs(recordId: recordId, images: images)
        
        // Step 3: Confirm uploads
        try await confirmUploads(recordId: recordId)
        
        return recordId
    }
    
    // MARK: - Step 1: Request Presigned URLs
    
    private func requestPresignedURLs(
        userId: String,
        images: [(key: String, data: Data, filename: String)]
    ) async throws -> String {
        let imageInfos = images.map { ImageInfo(key: $0.key, data: $0.data, filename: $0.filename) }
        
        let request = ImageUploadRequest(
            userId: userId,
            metadata: UploadMetadata(),
            images: imageInfos
        )
        
        let url = URL(string: "\(baseURL)/images/upload")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageUploadError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ImageUploadError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let uploadResponse = try JSONDecoder().decode(ImageUploadResponse.self, from: data)
        
        // Store presigned URLs for later use
        await storePresignedURLs(recordId: uploadResponse.recordId, uploads: uploadResponse.uploads)
        
        return uploadResponse.recordId
    }
    
    // MARK: - Step 2: Upload to Presigned URLs
    
    private var presignedURLsCache: [String: [PresignedUpload]] = [:]
    
    private func storePresignedURLs(recordId: String, uploads: [PresignedUpload]) {
        presignedURLsCache[recordId] = uploads
    }
    
    private func uploadToPresignedURLs(
        recordId: String,
        images: [(key: String, data: Data, filename: String)]
    ) async throws {
        guard let presignedUploads = presignedURLsCache[recordId] else {
            throw ImageUploadError.missingPresignedURLs
        }
        
        // Create a mapping of filename to presigned URL
        let urlMap = Dictionary(
            uniqueKeysWithValues: presignedUploads.map { ($0.filename, $0.presignedUrl) }
        )
        
        // Upload each image in parallel
        try await withThrowingTaskGroup(of: Void.self) { group in
            for image in images {
                group.addTask {
                    guard let presignedURL = urlMap[image.filename] else {
                        throw ImageUploadError.missingPresignedURL(filename: image.filename)
                    }
                    
                    try await self.uploadSingleImage(data: image.data, to: presignedURL)
                }
            }
            
            // Wait for all uploads to complete
            try await group.waitForAll()
        }
        
        // Clean up cache
        presignedURLsCache.removeValue(forKey: recordId)
    }
    
    private func uploadSingleImage(data: Data, to presignedURL: String) async throws {
        guard let url = URL(string: presignedURL) else {
            throw ImageUploadError.invalidPresignedURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = data
        
        // Set content type based on data
        if let contentType = data.mimeType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageUploadError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ImageUploadError.uploadFailed(statusCode: httpResponse.statusCode)
        }
    }
    
    // MARK: - Step 3: Confirm Uploads
    
    private func confirmUploads(recordId: String) async throws {
        let url = URL(string: "\(baseURL)/images/\(recordId)/confirm")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let confirmRequest = UploadConfirmRequest()
        request.httpBody = try JSONEncoder().encode(confirmRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageUploadError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ImageUploadError.confirmationFailed(statusCode: httpResponse.statusCode)
        }
        
        let confirmResponse = try JSONDecoder().decode(UploadConfirmResponse.self, from: data)
        
        guard confirmResponse.success else {
            throw ImageUploadError.confirmationFailed(
                statusCode: httpResponse.statusCode,
                message: confirmResponse.message
            )
        }
    }
}

// MARK: - Errors

enum ImageUploadError: LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int)
    case missingPresignedURLs
    case missingPresignedURL(filename: String)
    case invalidPresignedURL
    case uploadFailed(statusCode: Int)
    case confirmationFailed(statusCode: Int, message: String? = nil)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let statusCode):
            return "Server error: \(statusCode)"
        case .missingPresignedURLs:
            return "Presigned URLs not found in cache"
        case .missingPresignedURL(let filename):
            return "No presigned URL for file: \(filename)"
        case .invalidPresignedURL:
            return "Invalid presigned URL format"
        case .uploadFailed(let statusCode):
            return "Upload failed with status: \(statusCode)"
        case .confirmationFailed(let statusCode, let message):
            if let message = message {
                return "Confirmation failed: \(message) (status: \(statusCode))"
            }
            return "Confirmation failed with status: \(statusCode)"
        }
    }
}

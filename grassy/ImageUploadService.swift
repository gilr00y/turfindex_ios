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
        print("\n╔═══════════════════════════════════════════╗")
        print("║   IMAGE UPLOAD SERVICE - 3-STEP PROCESS   ║")
        print("╚═══════════════════════════════════════════╝")
        print("👤 User ID: \(userId)")
        print("📦 Images to upload: \(images.count)")
        for (index, image) in images.enumerated() {
            print("   \(index + 1). Key: \(image.key), File: \(image.filename), Size: \(image.data.count) bytes")
        }
        
        // Step 1: Request presigned URLs
        print("\n┌─── STEP 1: Request Presigned URLs ───┐")
        let recordId = try await requestPresignedURLs(userId: userId, images: images)
        print("└─── STEP 1: Complete ✓ ───────────────┘")
        
        // Step 2: Upload images to presigned URLs
        print("\n┌─── STEP 2: Upload to Presigned URLs ─┐")
        try await uploadToPresignedURLs(recordId: recordId, images: images)
        print("└─── STEP 2: Complete ✓ ───────────────┘")
        
        // Step 3: Confirm uploads
        print("\n┌─── STEP 3: Confirm Uploads ──────────┐")
        try await confirmUploads(recordId: recordId)
        print("└─── STEP 3: Complete ✓ ───────────────┘")
        
        print("\n╔═══════════════════════════════════════════╗")
        print("║        UPLOAD SUCCESSFUL! ✓               ║")
        print("╚═══════════════════════════════════════════╝")
        print("📝 Record ID: \(recordId)\n")
        
        return recordId
    }
    
    // MARK: - Step 1: Request Presigned URLs
    
    private func requestPresignedURLs(
        userId: String,
        images: [(key: String, data: Data, filename: String)]
    ) async throws -> String {
        print("📤 Preparing upload request...")
        
        let imageInfos = images.map { ImageInfo(key: $0.key, data: $0.data, filename: $0.filename) }
        
        let request = ImageUploadRequest(
            userId: userId,
            metadata: UploadMetadata(),
            images: imageInfos
        )
        
        let url = URL(string: "\(baseURL)/images/upload")!
        print("🌐 POST \(url.absoluteString)")
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        print("📦 Request body size: \(urlRequest.httpBody?.count ?? 0) bytes")
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw ImageUploadError.invalidResponse
        }
        
        print("📥 Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Server returned error status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📋 Response body: \(responseString)")
            }
            throw ImageUploadError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let uploadResponse = try JSONDecoder().decode(ImageUploadResponse.self, from: data)
        
        print("✅ Record ID: \(uploadResponse.recordId)")
        print("✅ Presigned URLs received: \(uploadResponse.uploads.count)")
        
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
        print("📤 Starting parallel uploads...")
        
        guard let presignedUploads = presignedURLsCache[recordId] else {
            print("❌ Presigned URLs not found in cache!")
            throw ImageUploadError.missingPresignedURLs
        }
        
        print("✅ Found \(presignedUploads.count) presigned URLs")
        
        // Create a mapping of filename to presigned URL
        let urlMap = Dictionary(
            uniqueKeysWithValues: presignedUploads.map { ($0.filename, $0.presignedUrl) }
        )
        
        // Upload each image in parallel
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (index, image) in images.enumerated() {
                group.addTask {
                    guard let presignedURL = urlMap[image.filename] else {
                        print("❌ No presigned URL for: \(image.filename)")
                        throw ImageUploadError.missingPresignedURL(filename: image.filename)
                    }
                    
                    print("📤 [\(index + 1)/\(images.count)] Uploading \(image.filename)...")
                    try await self.uploadSingleImage(data: image.data, to: presignedURL)
                    print("✅ [\(index + 1)/\(images.count)] Uploaded \(image.filename)")
                }
            }
            
            // Wait for all uploads to complete
            try await group.waitForAll()
        }
        
        print("✅ All images uploaded successfully")
        
        // Clean up cache
        presignedURLsCache.removeValue(forKey: recordId)
        print("🧹 Cleaned up presigned URLs cache")
    }
    
    private func uploadSingleImage(data: Data, to presignedURL: String) async throws {
        guard let url = URL(string: presignedURL) else {
            print("❌ Invalid presigned URL format")
            throw ImageUploadError.invalidPresignedURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = data
        
        // Set content type based on data
        if let contentType = data.mimeType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            print("   Content-Type: \(contentType)")
        }
        
        request.setValue("public-read", forHTTPHeaderField: "x-amz-acl")
        print("   ACL: public-read" )
        
        print("   Size: \(data.count) bytes")
        print("   URL: \(url.host ?? "unknown")/...")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("   ❌ Invalid response type")
            throw ImageUploadError.invalidResponse
        }
        
        print("   Response: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("   ❌ Upload failed with status \(httpResponse.statusCode)")
            throw ImageUploadError.uploadFailed(statusCode: httpResponse.statusCode)
        }
    }
    
    // MARK: - Step 3: Confirm Uploads
    
    private func confirmUploads(recordId: String) async throws {
        print("📤 Sending confirmation...")
        
        let url = URL(string: "\(baseURL)/images/\(recordId)/confirm")!
        print("🌐 POST \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let confirmRequest = UploadConfirmRequest()
        request.httpBody = try JSONEncoder().encode(confirmRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw ImageUploadError.invalidResponse
        }
        
        print("📥 Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Confirmation failed with status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📋 Response body: \(responseString)")
            }
            throw ImageUploadError.confirmationFailed(statusCode: httpResponse.statusCode)
        }
        
        let confirmResponse = try JSONDecoder().decode(UploadConfirmResponse.self, from: data)
        
        print("✅ Success: \(confirmResponse.success)")
        if let message = confirmResponse.message {
            print("💬 Message: \(message)")
        }
        
        guard confirmResponse.success else {
            print("❌ Server reported failure")
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

//
//  StorageService.swift
//  grassy
//
//  Created by jason on 1/14/26.
//

import Foundation
import UIKit

/// Service for uploading photos to Digital Ocean Spaces using presigned URLs
actor StorageService {
    static let shared = StorageService()
    
    private init() {}
    
    /// Uploads a photo using a presigned URL from the backend
    func uploadPhoto(_ imageData: Data, userId: String) async throws -> String {
        // Step 1: Request presigned URL from your backend
        let presignedData = try await requestPresignedURL(userId: userId)
        
        // Step 2: Upload directly to Digital Ocean Spaces
        var request = URLRequest(url: presignedData.uploadURL)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw StorageError.uploadFailed
        }
        
        // Return the key (filename) for storing in your database
        return presignedData.key
    }
    
    /// Deletes a photo by notifying the backend
    func deletePhoto(key: String) async throws {
        // Call your backend to delete the photo
        guard let url = URL(string: "\(BackendConfig.baseURL)/api/photos/delete") else {
            throw StorageError.invalidRequest
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Include authentication token if needed
        let authToken = AuthService.shared.currentToken
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        
        let payload = ["key": key]
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw StorageError.deleteFailed
        }
    }
    
    /// Gets the public URL for a photo (no signing needed since photos are public-read)
    func getPhotoURL(key: String) -> URL {
        // Construct the public URL directly
        URL(string: "\(SpacesConfig.cdnEndpoint)/\(key)")!
    }
    
    // MARK: - Private Methods
    
    private func requestPresignedURL(userId: String) async throws -> PresignedURLResponse {
        guard let url = URL(string: "\(BackendConfig.baseURL)/api/photos/presigned-upload") else {
            throw StorageError.invalidRequest
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Include authentication token
        let authToken = AuthService.shared.currentToken
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        
        let payload = ["userId": userId]
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw StorageError.presignedURLFailed
        }
        
        return try JSONDecoder().decode(PresignedURLResponse.self, from: data)
    }
}

// MARK: - Models

struct PresignedURLResponse: Codable {
    let uploadURL: URL
    let key: String
    
    enum CodingKeys: String, CodingKey {
        case uploadURL = "upload_url"
        case key
    }
}

// MARK: - Configuration

struct BackendConfig {
    static let baseURL = "https://your-backend.com" // Replace with your actual backend URL
}

// MARK: - Errors

enum StorageError: LocalizedError {
    case uploadFailed
    case deleteFailed
    case invalidRequest
    case presignedURLFailed
    
    var errorDescription: String? {
        switch self {
        case .uploadFailed:
            return "Failed to upload photo"
        case .deleteFailed:
            return "Failed to delete photo"
        case .invalidRequest:
            return "Invalid request"
        case .presignedURLFailed:
            return "Failed to get upload URL"
        }
    }
}


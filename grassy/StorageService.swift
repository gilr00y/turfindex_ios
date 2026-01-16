//
//  StorageService.swift
//  grassy
//
//  Created by jason on 1/14/26.
//

import Foundation
import UIKit

/// Service for uploading photos to Digital Ocean Spaces (S3-compatible)
actor StorageService {
    static let shared = StorageService()
    
    private init() {}
    
    /// Uploads a photo to Digital Ocean Spaces and returns the URL
    func uploadPhoto(_ imageData: Data, userId: String) async throws -> String {
        // Generate unique filename
        let timestamp = Date().timeIntervalSince1970
        let filename = "\(userId)/\(UUID().uuidString)_\(Int(timestamp)).jpg"
        
        // Create S3 upload request
        let url = URL(string: "\(SpacesConfig.endpoint)/\(SpacesConfig.bucket)/\(filename)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("public-read", forHTTPHeaderField: "x-amz-acl")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        
        // Sign the request with AWS Signature V4
        let signature = try await signRequest(
            method: "PUT",
            path: "/\(SpacesConfig.bucket)/\(filename)",
            headers: [
                "x-amz-acl": "public-read",
                "Content-Type": "image/jpeg"
            ],
            body: imageData
        )
        
        // Add authorization header
        request.setValue(signature.authorization, forHTTPHeaderField: "Authorization")
        request.setValue(signature.date, forHTTPHeaderField: "x-amz-date")
        request.httpBody = imageData
        
        // Upload
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw StorageError.uploadFailed
        }
        
        return filename
    }
    
    /// Deletes a photo from Digital Ocean Spaces
    func deletePhoto(key: String) async throws {
        let url = URL(string: "\(SpacesConfig.endpoint)/\(SpacesConfig.bucket)/\(key)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // Sign the request
        let signature = try await signRequest(
            method: "DELETE",
            path: "/\(SpacesConfig.bucket)/\(key)",
            headers: [:],
            body: nil
        )
        
        request.setValue(signature.authorization, forHTTPHeaderField: "Authorization")
        request.setValue(signature.date, forHTTPHeaderField: "x-amz-date")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw StorageError.deleteFailed
        }
    }
    
    // MARK: - AWS Signature V4
    
    private func signRequest(
        method: String,
        path: String,
        headers: [String: String],
        body: Data?
    ) async throws -> (authorization: String, date: String) {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        let now = Date()
        let amzDate = dateFormatter.string(from: now).replacingOccurrences(of: "-", with: "").replacingOccurrences(of: ":", with: "").components(separatedBy: ".")[0] + "Z"
        let dateStamp = String(amzDate.prefix(8))
        
        // Create canonical request
        let payloadHash = (body ?? Data()).sha256Hash
        var canonicalHeaders = headers
        canonicalHeaders["host"] = URL(string: SpacesConfig.endpoint)!.host!
        canonicalHeaders["x-amz-date"] = amzDate
        
        let sortedHeaders = canonicalHeaders.sorted { $0.key < $1.key }
        let canonicalHeadersString = sortedHeaders.map { "\($0.key.lowercased()):\($0.value)" }.joined(separator: "\n")
        let signedHeaders = sortedHeaders.map { $0.key.lowercased() }.joined(separator: ";")
        
        let canonicalRequest = """
        \(method)
        \(path)
        
        \(canonicalHeadersString)
        
        \(signedHeaders)
        \(payloadHash)
        """
        
        // Create string to sign
        let algorithm = "AWS4-HMAC-SHA256"
        let credentialScope = "\(dateStamp)/\(SpacesConfig.region)/s3/aws4_request"
        let stringToSign = """
        \(algorithm)
        \(amzDate)
        \(credentialScope)
        \(canonicalRequest.sha256Hash)
        """
        
        // Calculate signature
        let kDate = hmacSHA256(key: "AWS4\(SpacesConfig.secretKey)".data(using: .utf8)!, data: dateStamp.data(using: .utf8)!)
        let kRegion = hmacSHA256(key: kDate, data: SpacesConfig.region.data(using: .utf8)!)
        let kService = hmacSHA256(key: kRegion, data: "s3".data(using: .utf8)!)
        let kSigning = hmacSHA256(key: kService, data: "aws4_request".data(using: .utf8)!)
        let signature = hmacSHA256(key: kSigning, data: stringToSign.data(using: .utf8)!).hexString
        
        // Create authorization header
        let authorization = "\(algorithm) Credential=\(SpacesConfig.accessKey)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)"
        
        return (authorization, amzDate)
    }
    
    private func hmacSHA256(key: Data, data: Data) -> Data {
        var hmac = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        key.withUnsafeBytes { keyBytes in
            data.withUnsafeBytes { dataBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyBytes.baseAddress, key.count, dataBytes.baseAddress, data.count, &hmac)
            }
        }
        return Data(hmac)
    }
}

extension Data {
    var sha256Hash: String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(self.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}

enum StorageError: LocalizedError {
    case uploadFailed
    case deleteFailed
    case invalidImage
    
    var errorDescription: String? {
        switch self {
        case .uploadFailed:
            return "Failed to upload photo"
        case .deleteFailed:
            return "Failed to delete photo"
        case .invalidImage:
            return "Invalid image data"
        }
    }
}

import CommonCrypto

//
//  S3Manager.swift
//  grassy
//
//  Created by jason on 1/14/26.
//

import Foundation
import CryptoKit

/// Manager for uploading photos to Digital Ocean Spaces (S3-compatible storage)
actor S3Manager {
    static let shared = S3Manager()
    
    private let endpoint: String
    private let region: String
    private let bucket: String
    private let accessKey: String
    private let secretKey: String
    
    private init() {
        self.endpoint = SupabaseConfig.spacesEndpoint
        self.region = SupabaseConfig.spacesRegion
        self.bucket = SupabaseConfig.spacesBucket
        self.accessKey = SupabaseConfig.spacesAccessKey
        self.secretKey = SupabaseConfig.spacesSecretKey
    }
    
    /// Upload an image to Digital Ocean Spaces
    /// - Parameters:
    ///   - imageData: The image data to upload
    ///   - userId: The ID of the user uploading the image
    /// - Returns: The public URL of the uploaded image
    func uploadImage(_ imageData: Data, userId: UUID) async throws -> String {
        let fileName = "\(userId.uuidString)/\(UUID().uuidString).jpg"
        let urlString = "\(endpoint)/\(bucket)/\(fileName)"
        
        guard let url = URL(string: urlString) else {
            throw S3Error.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = imageData
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("public-read", forHTTPHeaderField: "x-amz-acl")
        
        // Add AWS Signature Version 4 authentication
        let date = Date()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        let amzDate = dateFormatter.string(from: date).replacingOccurrences(of: "-", with: "").replacingOccurrences(of: ":", with: "").split(separator: ".").first! + "Z"
        
        request.setValue(String(amzDate), forHTTPHeaderField: "x-amz-date")
        
        // Sign the request
        signRequest(&request, date: date, fileName: fileName)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw S3Error.uploadFailed
        }
        
        // Return the public URL
        return urlString
    }
    
    /// Delete an image from Digital Ocean Spaces
    /// - Parameter imageURL: The URL of the image to delete
    func deleteImage(at imageURL: String) async throws {
        guard let url = URL(string: imageURL) else {
            throw S3Error.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let date = Date()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        let amzDate = dateFormatter.string(from: date).replacingOccurrences(of: "-", with: "").replacingOccurrences(of: ":", with: "").split(separator: ".").first! + "Z"
        
        request.setValue(String(amzDate), forHTTPHeaderField: "x-amz-date")
        
        // Extract filename from URL for signing
        let fileName = url.path.replacingOccurrences(of: "/\(bucket)/", with: "")
        signRequest(&request, date: date, fileName: fileName)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw S3Error.deleteFailed
        }
    }
    
    // MARK: - AWS Signature V4 Signing
    
    private func signRequest(_ request: inout URLRequest, date: Date, fileName: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let dateStamp = dateFormatter.string(from: date)
        
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime]
        let amzDate = iso8601Formatter.string(from: date).replacingOccurrences(of: "-", with: "").replacingOccurrences(of: ":", with: "").split(separator: ".").first! + "Z"
        
        let method = request.httpMethod ?? "PUT"
        let canonicalURI = "/\(bucket)/\(fileName)"
        let canonicalQueryString = ""
        let canonicalHeaders = "host:\(URL(string: endpoint)!.host!)\nx-amz-date:\(amzDate)\n"
        let signedHeaders = "host;x-amz-date"
        
        let payloadHash = SHA256.hash(data: request.httpBody ?? Data())
        let payloadHashString = payloadHash.compactMap { String(format: "%02x", $0) }.joined()
        
        let canonicalRequest = "\(method)\n\(canonicalURI)\n\(canonicalQueryString)\n\(canonicalHeaders)\n\(signedHeaders)\n\(payloadHashString)"
        
        let algorithm = "AWS4-HMAC-SHA256"
        let credentialScope = "\(dateStamp)/\(region)/s3/aws4_request"
        
        let canonicalRequestHash = SHA256.hash(data: Data(canonicalRequest.utf8))
        let canonicalRequestHashString = canonicalRequestHash.compactMap { String(format: "%02x", $0) }.joined()
        
        let stringToSign = "\(algorithm)\n\(amzDate)\n\(credentialScope)\n\(canonicalRequestHashString)"
        
        let signature = calculateSignature(stringToSign: stringToSign, dateStamp: dateStamp)
        
        let authorizationHeader = "\(algorithm) Credential=\(accessKey)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)"
        
        request.setValue(authorizationHeader, forHTTPHeaderField: "Authorization")
    }
    
    private func calculateSignature(stringToSign: String, dateStamp: String) -> String {
        let kDate = hmac(key: Data("AWS4\(secretKey)".utf8), data: Data(dateStamp.utf8))
        let kRegion = hmac(key: kDate, data: Data(region.utf8))
        let kService = hmac(key: kRegion, data: Data("s3".utf8))
        let kSigning = hmac(key: kService, data: Data("aws4_request".utf8))
        let signature = hmac(key: kSigning, data: Data(stringToSign.utf8))
        
        return signature.map { String(format: "%02x", $0) }.joined()
    }
    
    private func hmac(key: Data, data: Data) -> Data {
        var hmac = HMAC<SHA256>(key: SymmetricKey(data: key))
        hmac.update(data: data)
        return Data(hmac.finalize())
    }
}

enum S3Error: LocalizedError {
    case invalidURL
    case uploadFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for image upload"
        case .uploadFailed:
            return "Failed to upload image to storage"
        case .deleteFailed:
            return "Failed to delete image from storage"
        }
    }
}

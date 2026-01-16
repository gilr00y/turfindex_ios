//
//  S3Manager.swift
//  grassy
//
//  Created by jason on 1/14/26.
//

import Foundation
import CryptoKit

/// Manager for Digital Ocean Spaces (S3-compatible) storage
class S3Manager {
    static let shared = S3Manager()
    
    // TODO: Replace with your Digital Ocean Spaces credentials
    private let accessKey = "YOUR_DO_SPACES_ACCESS_KEY"
    private let secretKey = "YOUR_DO_SPACES_SECRET_KEY"
    private let endpoint = "https://YOUR_REGION.digitaloceanspaces.com"
    private let bucketName = "grassy-photos"
    private let region = "YOUR_REGION" // e.g., "nyc3", "sfo3"
    
    private init() {}
    
    /// Upload image data to Digital Ocean Spaces
    func uploadImage(_ imageData: Data, userId: String) async throws -> String {
        let fileName = "\(userId)/\(UUID().uuidString).jpg"
        let url = "\(endpoint)/\(bucketName)/\(fileName)"
        
        guard let uploadURL = URL(string: url) else {
            throw S3Error.invalidURL
        }
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("\(imageData.count)", forHTTPHeaderField: "Content-Length")
        request.setValue("public-read", forHTTPHeaderField: "x-amz-acl")
        
        // Create AWS Signature Version 4
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        let dateString = dateFormatter.string(from: Date())
        request.setValue(dateString, forHTTPHeaderField: "x-amz-date")
        
        // Sign the request
        signRequest(&request, payload: imageData, date: Date())
        
        let (_, response) = try await URLSession.shared.upload(for: request, from: imageData)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw S3Error.uploadFailed
        }
        
        // Return the public URL
        return url
    }
    
    /// Delete image from Digital Ocean Spaces
    func deleteImage(at url: String) async throws {
        guard let deleteURL = URL(string: url) else {
            throw S3Error.invalidURL
        }
        
        var request = URLRequest(url: deleteURL)
        request.httpMethod = "DELETE"
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        let dateString = dateFormatter.string(from: Date())
        request.setValue(dateString, forHTTPHeaderField: "x-amz-date")
        
        signRequest(&request, payload: Data(), date: Date())
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw S3Error.deleteFailed
        }
    }
    
    // MARK: - AWS Signature V4
    
    private func signRequest(_ request: inout URLRequest, payload: Data, date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let dateStamp = dateFormatter.string(from: date)
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        let amzDate = isoFormatter.string(from: date)
        
        // Create canonical request
        let payloadHash = sha256Hash(payload)
        request.setValue(payloadHash, forHTTPHeaderField: "x-amz-content-sha256")
        
        let canonicalRequest = createCanonicalRequest(request: request, payloadHash: payloadHash)
        let canonicalRequestHash = sha256Hash(Data(canonicalRequest.utf8))
        
        // Create string to sign
        let credentialScope = "\(dateStamp)/\(region)/s3/aws4_request"
        let stringToSign = """
        AWS4-HMAC-SHA256
        \(amzDate)
        \(credentialScope)
        \(canonicalRequestHash)
        """
        
        // Calculate signature
        let signature = calculateSignature(stringToSign: stringToSign, dateStamp: dateStamp)
        
        // Create authorization header
        let authorizationHeader = """
        AWS4-HMAC-SHA256 Credential=\(accessKey)/\(credentialScope), \
        SignedHeaders=content-type;host;x-amz-acl;x-amz-content-sha256;x-amz-date, \
        Signature=\(signature)
        """
        
        request.setValue(authorizationHeader, forHTTPHeaderField: "Authorization")
    }
    
    private func createCanonicalRequest(request: URLRequest, payloadHash: String) -> String {
        let method = request.httpMethod ?? "GET"
        let uri = request.url?.path ?? "/"
        let query = request.url?.query ?? ""
        
        let host = request.url?.host ?? ""
        let contentType = request.value(forHTTPHeaderField: "Content-Type") ?? ""
        let amzAcl = request.value(forHTTPHeaderField: "x-amz-acl") ?? ""
        let amzDate = request.value(forHTTPHeaderField: "x-amz-date") ?? ""
        
        let canonicalHeaders = """
        content-type:\(contentType)
        host:\(host)
        x-amz-acl:\(amzAcl)
        x-amz-content-sha256:\(payloadHash)
        x-amz-date:\(amzDate)
        
        """
        
        let signedHeaders = "content-type;host;x-amz-acl;x-amz-content-sha256;x-amz-date"
        
        return """
        \(method)
        \(uri)
        \(query)
        \(canonicalHeaders)
        \(signedHeaders)
        \(payloadHash)
        """
    }
    
    private func calculateSignature(stringToSign: String, dateStamp: String) -> String {
        let kDate = hmac(key: Data("AWS4\(secretKey)".utf8), data: Data(dateStamp.utf8))
        let kRegion = hmac(key: kDate, data: Data(region.utf8))
        let kService = hmac(key: kRegion, data: Data("s3".utf8))
        let kSigning = hmac(key: kService, data: Data("aws4_request".utf8))
        let signature = hmac(key: kSigning, data: Data(stringToSign.utf8))
        
        return signature.map { String(format: "%02x", $0) }.joined()
    }
    
    private func sha256Hash(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    private func hmac(key: Data, data: Data) -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: symmetricKey)
        return Data(signature)
    }
}

enum S3Error: LocalizedError {
    case invalidURL
    case uploadFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .uploadFailed:
            return "Failed to upload image"
        case .deleteFailed:
            return "Failed to delete image"
        }
    }
}

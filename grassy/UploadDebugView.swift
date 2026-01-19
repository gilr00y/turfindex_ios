//
//  UploadDebugView.swift
//  grassy
//
//  Created by jason on 1/18/26.
//

import SwiftUI

#if DEBUG
/// Debug view for monitoring and testing image uploads
struct UploadDebugView: View {
    @State private var testResults: [TestResult] = []
    @State private var isRunningTests = false
    @State private var selectedImageData: Data?
    @State private var userId = "debug_user_\(UUID().uuidString.prefix(8))"
    
    var body: some View {
        NavigationStack {
            List {
                Section("Configuration") {
                    LabeledContent("API Base URL", value: UploadConfig.apiBaseURL)
                    LabeledContent("Upload Timeout", value: "\(Int(UploadConfig.uploadTimeout))s")
                    LabeledContent("Max Retries", value: "\(UploadConfig.maxRetryAttempts)")
                    
                    TextField("User ID", text: $userId)
                        .textInputAutocapitalization(.never)
                }
                
                Section("Quick Tests") {
                    Button("Test Single Image Upload") {
                        runTest(.singleImage)
                    }
                    .disabled(isRunningTests)
                    
                    Button("Test Multiple Images Upload") {
                        runTest(.multipleImages)
                    }
                    .disabled(isRunningTests)
                    
                    Button("Test With Retry") {
                        runTest(.withRetry)
                    }
                    .disabled(isRunningTests)
                    
                    Button("Test Large Image") {
                        runTest(.largeImage)
                    }
                    .disabled(isRunningTests)
                }
                
                Section("API Endpoints") {
                    EndpointRow(
                        title: "Upload Init",
                        endpoint: "POST /images/upload",
                        url: "\(UploadConfig.apiBaseURL)/images/upload"
                    )
                    
                    EndpointRow(
                        title: "Confirm Upload",
                        endpoint: "POST /images/:id/confirm",
                        url: "\(UploadConfig.apiBaseURL)/images/{recordId}/confirm"
                    )
                }
                
                if !testResults.isEmpty {
                    Section("Test Results") {
                        ForEach(testResults) { result in
                            TestResultRow(result: result)
                        }
                    }
                }
            }
            .navigationTitle("Upload Debug")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if isRunningTests {
                        ProgressView()
                    } else {
                        Button("Clear") {
                            testResults.removeAll()
                        }
                        .disabled(testResults.isEmpty)
                    }
                }
            }
        }
    }
    
    private func runTest(_ type: TestType) {
        Task {
            isRunningTests = true
            defer { isRunningTests = false }
            
            let startTime = Date()
            var success = false
            var errorMessage: String?
            var details: String?
            
            do {
                switch type {
                case .singleImage:
                    guard let imageData = ImageUploadExample.generateTestImage() else {
                        throw TestError.imageGenerationFailed
                    }
                    let photoUrl = try await ImageUploadExample.uploadSingleImage(
                        userId: userId,
                        imageData: imageData
                    )
                    success = true
                    details = "Photo URL: \(photoUrl)"
                    
                case .multipleImages:
                    let images = [
                        ImageUploadExample.generateTestImage()!,
                        ImageUploadExample.generateTestImage()!,
                        ImageUploadExample.generateTestImage()!
                    ]
                    let result = try await ImageUploadExample.uploadMultipleImages(
                        userId: userId,
                        imageDatas: images
                    )
                    success = true
                    details = "Record ID: \(result.recordId)\nUploaded \(result.photoUrls.count) images"
                    
                case .withRetry:
                    guard let imageData = ImageUploadExample.generateTestImage() else {
                        throw TestError.imageGenerationFailed
                    }
                    let photoUrl = try await ImageUploadExample.uploadWithRetry(
                        userId: userId,
                        imageData: imageData,
                        maxRetries: 3
                    )
                    success = true
                    details = "Photo URL: \(photoUrl)"
                    
                case .largeImage:
                    guard let imageData = ImageUploadExample.generateTestImage(width: 2000, height: 2000) else {
                        throw TestError.imageGenerationFailed
                    }
                    let photoUrl = try await ImageUploadExample.uploadSingleImage(
                        userId: userId,
                        imageData: imageData
                    )
                    success = true
                    let sizeKB = imageData.count / 1024
                    details = "Photo URL: \(photoUrl)\nSize: \(sizeKB) KB"
                }
            } catch {
                success = false
                errorMessage = error.localizedDescription
            }
            
            let duration = Date().timeIntervalSince(startTime)
            
            let result = TestResult(
                type: type,
                success: success,
                duration: duration,
                errorMessage: errorMessage,
                details: details
            )
            
            testResults.insert(result, at: 0)
        }
    }
}

// MARK: - Supporting Views

struct EndpointRow: View {
    let title: String
    let endpoint: String
    let url: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            
            Text(endpoint)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospaced()
            
            Text(url)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .monospaced()
        }
    }
}

struct TestResultRow: View {
    let result: TestResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(result.success ? .green : .red)
                
                Text(result.type.rawValue)
                    .font(.headline)
                
                Spacer()
                
                Text(String(format: "%.2fs", result.duration))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let errorMessage = result.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            if let details = result.details {
                Text(details)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(result.timestamp, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Models

enum TestType: String, CaseIterable {
    case singleImage = "Single Image"
    case multipleImages = "Multiple Images"
    case withRetry = "With Retry"
    case largeImage = "Large Image"
}

struct TestResult: Identifiable {
    let id = UUID()
    let type: TestType
    let success: Bool
    let duration: TimeInterval
    let errorMessage: String?
    let details: String?
    let timestamp = Date()
}

enum TestError: LocalizedError {
    case imageGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .imageGenerationFailed:
            return "Failed to generate test image"
        }
    }
}

// MARK: - Preview

#Preview {
    UploadDebugView()
}
#endif

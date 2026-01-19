//
//  LeaderboardService.swift
//  grassy
//
//  Created by jason on 1/19/26.
//

import Foundation

/// Service for fetching leaderboard data
actor LeaderboardService {
    static let shared = LeaderboardService()
    
    private let baseURL: String
    
    init(baseURL: String = UploadConfig.apiBaseURL) {
        self.baseURL = baseURL
    }
    
    /// Fetch the top 100 images from the leaderboard
    func fetchTop100() async throws -> [LeaderboardResponse] {
        print("\n╔═══════════════════════════════════════════╗")
        print("║     FETCHING TOP 100 LEADERBOARD          ║")
        print("╚═══════════════════════════════════════════╝")
        
        let url = URL(string: "\(baseURL)/images/top100")!
        print("🌐 GET \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw LeaderboardError.invalidResponse
        }
        
        print("📥 Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Server returned error status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📋 Response body: \(responseString)")
            }
            throw LeaderboardError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let entries = try decoder.decode([LeaderboardResponse].self, from: data)
        
        print("✅ Fetched \(entries.count) leaderboard entries")
        print("╚═══════════════════════════════════════════╝\n")
        
        return entries
    }
}

// MARK: - Errors

enum LeaderboardError: LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let statusCode):
            return "Server error: \(statusCode)"
        case .decodingError:
            return "Failed to decode leaderboard data"
        }
    }
}

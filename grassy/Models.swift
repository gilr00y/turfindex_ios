//
//  Models.swift
//  grassy
//
//  Created by jason on 1/14/26.
//

import Foundation
import SwiftUI

/// Represents a user profile in Supabase
struct UserProfile: Identifiable, Codable {
    let id: String // Supabase auth user ID
    var username: String
    var createdAt: Date
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Represents a post with photo and metadata stored in Supabase
struct Post: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String
    var caption: String
    var location: String
    var tags: [String]
    let photoUrl: String // URL to photo in Digital Ocean Spaces
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case username
        case caption
        case location
        case tags
        case photoUrl = "photo_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Request body for creating a post
struct CreatePostRequest: Encodable {
    let userId: String
    let username: String
    let caption: String
    let location: String
    let tags: [String]
    let photoUrl: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case caption
        case location
        case tags
        case photoUrl = "photo_url"
    }
}
/// Supabase database table names
enum Tables {
    static let profiles = "profiles"
    static let posts = "posts"
}


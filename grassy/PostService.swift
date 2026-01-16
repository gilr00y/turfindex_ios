//
//  PostService.swift
//  grassy
//
//  Created by jason on 1/14/26.
//

import Foundation
import Supabase

/// Service for managing posts in Supabase
actor PostService {
    static let shared = PostService()
    
    private let client = SupabaseConfig.client
    
    private init() {}
    
    // MARK: - Create Post
    
    /// Creates a new post in the database
    func createPost(
        userId: String,
        username: String,
        caption: String,
        location: String,
        tags: [String],
        photoUrl: String
    ) async throws -> Post {
        let request = CreatePostRequest(
            userId: userId,
            username: username,
            caption: caption,
            location: location,
            tags: tags,
            photoUrl: photoUrl
        )
        
        let post: Post = try await client
            .from(Tables.posts)
            .insert(request)
            .select()
            .single()
            .execute()
            .value
        
        return post
    }
    
    // MARK: - Fetch Posts
    
    /// Fetches all posts, ordered by creation date (newest first)
    func fetchAllPosts(limit: Int = 50, offset: Int = 0) async throws -> [Post] {
        let posts: [Post] = try await client
            .from(Tables.posts)
            .select()
            .order("created_at", ascending: false)
            .limit(limit)
            .range(from: offset, to: offset + limit - 1)
            .execute()
            .value
        
        return posts
    }
    
    /// Fetches posts by a specific user
    func fetchUserPosts(userId: String, limit: Int = 50) async throws -> [Post] {
        let posts: [Post] = try await client
            .from(Tables.posts)
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return posts
    }
    
    /// Fetches posts with a specific tag
    func fetchPostsByTag(_ tag: String, limit: Int = 50) async throws -> [Post] {
        let posts: [Post] = try await client
            .from(Tables.posts)
            .select()
            .contains("tags", value: [tag])
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        return posts
    }
    
    // MARK: - Update Post
    
    /// Updates a post's caption, location, or tags
    func updatePost(
        id: String,
        caption: String? = nil,
        location: String? = nil,
        tags: [String]? = nil
    ) async throws {
        var updates: [String: Any] = [:]
        if let caption = caption {
            updates["caption"] = caption
        }
        if let location = location {
            updates["location"] = location
        }
        if let tags = tags {
            updates["tags"] = tags
        }
        
        try await client
            .from(Tables.posts)
            .update(updates)
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Delete Post
    
    /// Deletes a post and its associated photo
    func deletePost(id: String, photoUrl: String) async throws {
        // Delete from database
        try await client
            .from(Tables.posts)
            .delete()
            .eq("id", value: id)
            .execute()
        
        // Delete photo from storage
        try await StorageService.shared.deletePhoto(key: photoUrl)
    }
    
    // MARK: - Real-time Subscriptions
    
    /// Subscribe to new posts (for real-time feed updates)
    func subscribeToNewPosts() -> AsyncStream<Post> {
        AsyncStream { continuation in
            Task {
                let channel = await client.channel("posts")
                
                await channel
                    .on("postgres_changes", filter: ChannelFilter(
                        event: "INSERT",
                        schema: "public",
                        table: Tables.posts
                    )) { payload in
                        if let post = try? payload.decodeRecord(as: Post.self) {
                            continuation.yield(post)
                        }
                    }
                    .subscribe()
            }
        }
    }
}

enum PostError: LocalizedError {
    case createFailed
    case fetchFailed
    case updateFailed
    case deleteFailed
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .createFailed:
            return "Failed to create post"
        case .fetchFailed:
            return "Failed to load posts"
        case .updateFailed:
            return "Failed to update post"
        case .deleteFailed:
            return "Failed to delete post"
        case .unauthorized:
            return "You don't have permission to perform this action"
        }
    }
}

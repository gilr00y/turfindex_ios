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
        print("\n┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓")
        print("┃   POST SERVICE: Creating Post    ┃")
        print("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛")
        print("👤 User ID: \(userId)")
        print("👤 Username: @\(username)")
        print("📝 Caption: '\(caption)'")
        print("📍 Location: '\(location)'")
        print("🏷️ Tags: \(tags)")
        print("🖼️ Photo URL: \(photoUrl)")
        
        let request = CreatePostRequest(
            userId: userId,
            username: username,
            caption: caption,
            location: location,
            tags: tags,
            photoUrl: photoUrl
        )
        
        print("📤 Inserting into Supabase...")
        
        do {
            let post: Post = try await client
                .from(Tables.posts)
                .insert(request)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ Post created successfully!")
            print("📌 Post ID: \(post.id)")
            print("🕒 Created at: \(post.createdAt)")
            print("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n")
            
            return post
            
        } catch {
            print("❌ Failed to create post!")
            print("📋 Error: \(error)")
            print("📋 Localized: \(error.localizedDescription)")
            print("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛\n")
            throw error
        }
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
    struct PostUpdate: Encodable {
        var caption: String?
        var location: String?
        var tags: [String]?
    }

    func updatePost(
        id: String,
        caption: String? = nil,
        location: String? = nil,
        tags: [String]? = nil
    ) async throws {
        let updates = PostUpdate(
            caption: caption,
            location: location,
            tags: tags
        )
        
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
                let channel = client.channel("posts")
                
                let _ = channel.onPostgresChange(
                    InsertAction.self,
                    schema: "public",
                    table: Tables.posts
                ) { (payload: InsertAction) in
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: payload.record)
                        let post = try JSONDecoder().decode(Post.self, from: jsonData)
                        continuation.yield(post)
                    } catch {
                        print("Failed to decode post: \(error)")
                    }
                }
                
                // Subscribe is called on the channel, after setting up listeners
                await channel.subscribe()
                
                continuation.onTermination = { _ in
                    Task { await channel.unsubscribe() }
                }
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

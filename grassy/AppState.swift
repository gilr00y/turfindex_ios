//
//  AppState.swift
//  grassy
//
//  Created by jason on 1/14/26.
//

import Foundation
import UIKit

/// Main app state that manages users and posts with Supabase
@Observable
class AppState {
    var currentUser: UserProfile?
    var posts: [Post] = []
    var isLoading = false
    var error: Error?
    
    // Cached images
    private var imageCache: [String: UIImage] = [:]
    
    init() {
        Task {
            await loadCurrentUser()
            if currentUser != nil {
                await fetchPosts()
            }
        }
    }
    
    // MARK: - User Management
    
    @MainActor
    func signUp(email: String, password: String, username: String) async {
        isLoading = true
        error = nil
        
        do {
            let profile = try await AuthService.shared.signUp(
                email: email,
                password: password,
                username: username
            )
            currentUser = profile
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    @MainActor
    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil
        
        do {
            let profile = try await AuthService.shared.signIn(
                email: email,
                password: password
            )
            currentUser = profile
            await fetchPosts()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    @MainActor
    func logout() async {
        do {
            try await AuthService.shared.signOut()
            currentUser = nil
            posts = []
            imageCache = [:]
        } catch {
            self.error = error
        }
    }
    
    @MainActor
    private func loadCurrentUser() async {
        do {
            currentUser = try await AuthService.shared.getCurrentUserProfile()
        } catch {
            // No current user, that's okay
            print("No current user session")
        }
    }
    
    // MARK: - Post Management
    
    @MainActor
    func createPost(caption: String, location: String, tags: [String], imageData: Data) async {
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📬 APPSTATE: createPost() called")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        guard let user = currentUser else {
            print("❌ APPSTATE: No current user!")
            return
        }
        
        print("✅ APPSTATE: Current user: @\(user.username) (ID: \(user.id))")
        print("📝 APPSTATE: Caption: '\(caption)'")
        print("📍 APPSTATE: Location: '\(location)'")
        print("🏷️ APPSTATE: Tags: \(tags)")
        print("📦 APPSTATE: Image data: \(imageData.count) bytes")
        
        isLoading = true
        error = nil
        
        do {
            // Generate a unique filename
            let filename = "\(UUID().uuidString).jpg"
            print("📄 APPSTATE: Generated filename: \(filename)")
            
            print("\n🚀 APPSTATE: Step 1 - Uploading image...")
            
            // 1. Upload photo using new API service (3-step process)
            let recordId = try await ImageUploadService.shared.uploadImages(
                userId: user.id,
                images: [
                    (key: "1", data: imageData, filename: filename)
                ]
            )
            
            print("✅ APPSTATE: Image uploaded! Record ID: \(recordId)")
            
            // 2. Construct the photo URL from recordId and filename
            // Format: user_id/record_id/filename
            let photoUrl = "\(user.id)/\(recordId)/\(filename)"
            print("🔗 APPSTATE: Photo URL: \(photoUrl)")
            
            print("\n💾 APPSTATE: Step 2 - Creating post in database...")
            
            // 3. Create post in Supabase
            let post = try await PostService.shared.createPost(
                userId: user.id,
                username: user.username,
                caption: caption,
                location: location,
                tags: tags,
                photoUrl: photoUrl
            )
            
            print("✅ APPSTATE: Post created in database!")
            print("📌 APPSTATE: Post ID: \(post.id)")
            
            // 4. Add to local posts array
            posts.insert(post, at: 0)
            print("✅ APPSTATE: Post added to local array (now \(posts.count) posts)")
            
            // 5. Cache the image
            if let image = UIImage(data: imageData) {
                imageCache[photoUrl] = image
                print("✅ APPSTATE: Image cached")
            }
            
            print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("🎉 APPSTATE: Post creation complete!")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            
        } catch {
            print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("❌ APPSTATE: Post creation failed!")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("📋 Error type: \(type(of: error))")
            print("📋 Error: \(error)")
            print("📋 Localized: \(error.localizedDescription)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            
            self.error = error
        }
        
        isLoading = false
    }
    
    @MainActor
    func fetchPosts() async {
        isLoading = true
        error = nil
        
        do {
            posts = try await PostService.shared.fetchAllPosts()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    @MainActor
    func deletePost(_ post: Post) async {
        guard let user = currentUser, user.id == post.userId else {
            error = PostError.unauthorized
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            try await PostService.shared.deletePost(id: post.id, photoUrl: post.photoUrl)
            posts.removeAll { $0.id == post.id }
            imageCache.removeValue(forKey: post.photoUrl)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    @MainActor
    func refreshPosts() async {
        await fetchPosts()
    }
    
    // MARK: - Image Caching
    
    func cachedImage(for url: String) -> UIImage? {
        imageCache[url]
    }
    
    func cacheImage(_ image: UIImage, for url: String) {
        imageCache[url] = image
    }
}

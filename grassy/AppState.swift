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
        guard let user = currentUser else { return }
        
        isLoading = true
        error = nil
        
        do {
            // 1. Upload photo to Digital Ocean Spaces
            let photoKey = try await StorageService.shared.uploadPhoto(imageData, userId: user.id)
            
            // 2. Create post in Supabase
            let post = try await PostService.shared.createPost(
                userId: user.id,
                username: user.username,
                caption: caption,
                location: location,
                tags: tags,
                photoUrl: photoKey
            )
            
            // 3. Add to local posts array
            posts.insert(post, at: 0)
            
            // 4. Cache the image
            if let image = UIImage(data: imageData) {
                imageCache[photoKey] = image
            }
        } catch {
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

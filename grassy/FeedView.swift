//
//  FeedView.swift
//  grassy
//
//  Created by jason on 1/14/26.
//

import SwiftUI

struct FeedView: View {
    @Environment(AppState.self) private var appState
    @State private var showingCreatePost = false
    
    var body: some View {
        NavigationStack {
            Group {
                if appState.isLoading && appState.posts.isEmpty {
                    ProgressView("Loading posts...")
                } else if appState.posts.isEmpty {
                    emptyState
                } else {
                    postsList
                }
            }
            .navigationTitle("Grassy")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreatePost = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        if let user = appState.currentUser {
                            Text("@\(user.username)")
                            Divider()
                        }
                        
                        Button(role: .destructive) {
                            Task {
                                await appState.logout()
                            }
                        } label: {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
            .sheet(isPresented: $showingCreatePost) {
                CreatePostView()
            }
            .refreshable {
                await appState.refreshPosts()
            }
        }
    }
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Posts Yet", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text("Be the first to share something!")
        } actions: {
            Button {
                showingCreatePost = true
            } label: {
                Text("Create Post")
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var postsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(appState.posts) { post in
                    PostCard(post: post)
                }
            }
            .padding()
        }
    }
}

struct PostCard: View {
    @Environment(AppState.self) private var appState
    let post: Post
    @State private var image: UIImage?
    @State private var isLoadingImage = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(post.username)")
                        .font(.headline)
                    
                    Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Delete button for own posts
                if appState.currentUser?.id == post.userId {
                    Menu {
                        Button(role: .destructive) {
                            Task {
                                await appState.deletePost(post)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Photo
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if isLoadingImage {
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            ProgressView()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .task {
                await loadImage()
            }
            
            // Caption
            if !post.caption.isEmpty {
                Text(post.caption)
                    .font(.body)
            }
            
            // Location
            if !post.location.isEmpty {
                Label(post.location, systemImage: "location.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Tags
            if !post.tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(post.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.green.opacity(0.1))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func loadImage() async {
        // Check cache first
        if let cached = appState.cachedImage(for: post.photoUrl) {
            image = cached
            isLoadingImage = false
            return
        }
        
        // Download from Digital Ocean Spaces
        guard let url = SpacesConfig.photoURL(for: post.photoUrl) else {
            isLoadingImage = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let downloadedImage = UIImage(data: data) {
                image = downloadedImage
                appState.cacheImage(downloadedImage, for: post.photoUrl)
            }
        } catch {
            print("Failed to load image: \(error)")
        }
        
        isLoadingImage = false
    }
}

#Preview {
    FeedView()
        .environment(AppState())
}

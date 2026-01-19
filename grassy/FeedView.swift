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
            ZStack {
                // Dark navy background
                TurfTheme.navyBackground
                    .ignoresSafeArea()
                
                Group {
                    if appState.isLoading && appState.posts.isEmpty {
                        ProgressView("Loading posts...")
                            .tint(TurfTheme.primary)
                            .foregroundStyle(.white)
                    } else if appState.posts.isEmpty {
                        emptyState
                    } else {
                        postsList
                    }
                }
            }
            .navigationTitle("Turf Index")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TurfTheme.navyBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                // Optional: Use logo in navigation bar instead of text
                // Uncomment below and remove .navigationTitle() to use logo
                /*
                ToolbarItem(placement: .principal) {
                    NavigationLogoTitle()
                }
                */
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreatePost = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(TurfTheme.primary)
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        if let user = appState.currentUser {
                            Label("@\(user.username)", systemImage: "person.circle")
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
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundStyle(TurfTheme.greenGradient)
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
                .foregroundStyle(.white)
        } description: {
            Text("Be the first to share your turf!")
                .foregroundStyle(.white.opacity(0.7))
        } actions: {
            Button {
                showingCreatePost = true
            } label: {
                Text("Create Post")
            }
            .buttonStyle(.turfPrimary)
            .padding(.horizontal, 40)
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
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(TurfTheme.primary, TurfTheme.limeGreen)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(post.username)")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
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
                            .foregroundStyle(.white.opacity(0.7))
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
                        .fill(TurfTheme.limeGreen.opacity(0.1))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            ProgressView()
                                .tint(TurfTheme.primary)
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
                    .foregroundStyle(.white)
            }
            
            // Location
            if !post.location.isEmpty {
                Label(post.location, systemImage: "location.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            // Tags
            if !post.tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(post.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(TurfTheme.limeGreen.opacity(0.2))
                            .foregroundStyle(TurfTheme.limeGreen)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(TurfTheme.navyBackground.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(TurfTheme.limeGreen.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
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

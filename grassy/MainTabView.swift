//
//  MainTabView.swift
//  grassy
//
//  Created by jason on 1/18/26.
//

import SwiftUI

/// Main tab view for authenticated users
struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Leaderboard Tab
            LeaderboardAuthenticatedView()
                .tabItem {
                    Label("Leaderboard", systemImage: "chart.bar.fill")
                }
                .tag(0)
            
            // Feed Tab
            FeedView()
                .tabItem {
                    Label("Feed", systemImage: "square.grid.2x2.fill")
                }
                .tag(1)
            
            // Profile Tab (optional - add if you have a profile view)
            ProfileTabView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(2)
        }
        .tint(TurfTheme.primary)
    }
}

/// Leaderboard view for authenticated users (without sign-in prompt)
struct LeaderboardAuthenticatedView: View {
    @Environment(AppState.self) private var appState
    @State private var entries: [LeaderboardEntry] = []
    @State private var showingCreatePost = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark navy background
                TurfTheme.navyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header section
                        headerSection
                            .padding(.bottom, 20)
                        
                        // Leaderboard entries
                        LazyVStack(spacing: 12) {
                            ForEach(entries) { entry in
                                NavigationLink {
                                    PostDetailView(entry: entry)
                                } label: {
                                    LeaderboardCard(entry: entry)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100) // Space for floating button
                    }
                }
                
                // Floating submit button (instead of join)
                VStack {
                    Spacer()
                    Button {
                        showingCreatePost = true
                    } label: {
                        Label("Submit Your Turf", systemImage: "plus.circle.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.turfPrimary)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                }
            }
            .navigationTitle("Weekly Top 100")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TurfTheme.navyBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
        }
        .onAppear {
            loadMockData()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Logo
            Image("turf-index-no-bg")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
            
            // Title
            VStack(spacing: 4) {
                Text("This Week's Best Turf")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                Text("January 11 - 17, 2026")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            // Stats row
            HStack(spacing: 30) {
                StatPill(value: "100", label: "Entries")
                StatPill(value: "2.4K", label: "Images")
                StatPill(value: "5d", label: "Remaining")
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 20)
        .background(TurfTheme.navyBackground.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(TurfTheme.limeGreen.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    private func loadMockData() {
        // Generate 100 mock entries
        entries = (1...100).map { rank in
            let photoCount = Int.random(in: 2...5)
            let additionalPhotos = (1..<photoCount).map { offset in
                "https://picsum.photos/400/30\(offset)?random=\(rank)\(offset)"
            }
            
            return LeaderboardEntry(
                rank: rank,
                post: Post(
                    id: UUID().uuidString,
                    userId: UUID().uuidString,
                    username: mockUsernames.randomElement() ?? "user\(rank)",
                    caption: mockCaptions.randomElement() ?? "Beautiful lawn!",
                    location: mockLocations.randomElement() ?? "Backyard",
                    tags: mockTags.shuffled().prefix(Int.random(in: 1...3)).map { $0 },
                    photoUrl: "https://picsum.photos/400/300?random=\(rank)",
                    additionalPhotos: additionalPhotos,
                    createdAt: Date().addingTimeInterval(-Double.random(in: 0...604800)),
                    updatedAt: nil
                ),
                score: max(1, 1000 - (rank * 10) + Int.random(in: -20...20))
            )
        }
    }
}

/// Simple profile tab view
struct ProfileTabView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        NavigationStack {
            ZStack {
                TurfTheme.navyBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if let user = appState.currentUser {
                        // Profile header
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 80))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(TurfTheme.primary, TurfTheme.limeGreen)
                            
                            Text("@\(user.username)")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            
                            if let email = user.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .padding(.top, 40)
                        
                        Spacer()
                        
                        // Logout button
                        Button(role: .destructive) {
                            Task {
                                await appState.logout()
                            }
                        } label: {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TurfTheme.navyBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// Mock data (same as LeaderboardView)
private let mockUsernames = [
    "grassmaster", "lawnking", "turfpro", "greenthumb",
    "yardgoals", "grassguru", "mowtime", "lushlife",
    "grassyknoll", "turfwar", "bladesofglory", "greenkeeper",
    "yardartist", "lawnlegend", "grassroots", "turftalker",
    "greenscape", "mowerpower", "grassgame", "yardvibes"
]

private let mockCaptions = [
    "Finally got the stripes perfect! 🌿",
    "Morning dew hits different ✨",
    "This corner of my yard is my pride and joy",
    "Three months of hard work paying off",
    "My backyard oasis 🌱",
    "That post-mow satisfaction",
    "Weekend project complete!",
    "Living my best lawn life",
    "Nature's carpet at its finest",
    "So proud of this transformation"
]

private let mockLocations = [
    "Backyard", "Front Lawn", "Side Yard", "Garden",
    "Park Strip", "Corner Lot", "Courtyard", "Terrace",
    "Community Garden", "Rooftop Garden"
]

private let mockTags = [
    "lush", "stripes", "organic", "native",
    "drought-tolerant", "zoysia", "bermuda", "fescue",
    "kentucky-blue", "clover", "wildflower", "maintenance-free",
    "eco-friendly", "pollinator-friendly", "no-mow"
]

#Preview {
    MainTabView()
        .environment(AppState())
}

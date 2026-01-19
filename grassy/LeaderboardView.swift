//
//  LeaderboardView.swift
//  grassy
//
//  Created by jason on 1/17/26.
//

import SwiftUI

/// Mock data model for leaderboard entries
struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let post: Post
    let votes: Int
}

struct LeaderboardView: View {
    @State private var showOnboarding = false
    @State private var entries: [LeaderboardEntry] = []
    
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
                
                // Floating join button
                VStack {
                    Spacer()
                    Button {
                        showOnboarding = true
                    } label: {
                        Label("Join the Competition", systemImage: "person.crop.circle.fill.badge.plus")
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
                    Button {
                        showOnboarding = true
                    } label: {
                        Text("Sign In")
                            .font(.subheadline)
                            .foregroundStyle(TurfTheme.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
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
                StatPill(value: "2.4K", label: "Votes")
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
                    photoUrl: "https://picsum.photos/400/300?random=\(rank)", // Placeholder images
                    additionalPhotos: additionalPhotos,
                    createdAt: Date().addingTimeInterval(-Double.random(in: 0...604800)), // Within last week
                    updatedAt: nil
                ),
                votes: max(1, 1000 - (rank * 10) + Int.random(in: -20...20))
            )
        }
    }
}

// MARK: - Leaderboard Card

struct LeaderboardCard: View {
    let entry: LeaderboardEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            AsyncImage(url: URL(string: entry.post.photoUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(TurfTheme.limeGreen.opacity(0.2))
                    .overlay {
                        ProgressView()
                            .tint(TurfTheme.primary)
                    }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text("@\(entry.post.username)")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(entry.post.location)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                
                // Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(entry.post.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(TurfTheme.limeGreen.opacity(0.2))
                                .foregroundStyle(TurfTheme.limeGreen)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            Spacer()
            
            // Votes
            VStack(spacing: 4) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(TurfTheme.primary)
                
                Text("\(entry.votes)")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding()
        .background(TurfTheme.navyBackground.opacity(0.5))
        .overlay(alignment: .topLeading) {
            // Rank badge tucked in top-left corner
            Text("#\(entry.rank)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(rankColor.gradient)
                .clipShape(Capsule())
                .padding(8)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(TurfTheme.limeGreen.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var rankColor: Color {
        switch entry.rank {
        case 1:
            return TurfTheme.sunYellow // Gold
        case 2:
            return Color.gray // Silver
        case 3:
            return TurfTheme.sunOrange // Bronze
        default:
            return TurfTheme.forestGreen
        }
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(TurfTheme.primary)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(minWidth: 70)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(TurfTheme.limeGreen.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Mock Data

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
    LeaderboardView()
}

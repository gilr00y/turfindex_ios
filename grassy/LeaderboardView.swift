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
    let score: Int
    let rating: ImageRating? // Individual rating breakdown
}

struct LeaderboardView: View {
    @State private var showOnboarding = false
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var refreshID = UUID() // Force view refresh
    
    private var totalImages: Int {
        entries.reduce(0) { total, entry in
            total + 1 + (entry.post.additionalPhotos?.count ?? 0)
        }
    }
    
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
                        
                        // Loading state
                        if isLoading {
                            ProgressView()
                                .tint(TurfTheme.primary)
                                .scaleEffect(1.5)
                                .padding(.top, 50)
                        }
                        // Error state
                        else if let errorMessage = errorMessage {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(TurfTheme.sunOrange)
                                
                                Text("Oops!")
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                                
                                Text(errorMessage)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Button {
                                    Task {
                                        await loadLeaderboardData()
                                    }
                                } label: {
                                    Label("Try Again", systemImage: "arrow.clockwise")
                                        .font(.headline)
                                }
                                .buttonStyle(.turfPrimary)
                                .padding(.top, 8)
                            }
                            .padding(.top, 50)
                        }
                        // Leaderboard entries
                        else {
                            // Debug banner to confirm real data
                            if entries.count < 10 {
                                Text("🔴 LIVE API DATA - \(entries.count) entries loaded")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .background(Color.red)
                                    .cornerRadius(8)
                                    .padding(.bottom, 8)
                            }
                            
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
                }
                .id(refreshID) // Force refresh when ID changes
                
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
            Task {
                await loadLeaderboardData()
            }
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
                StatPill(value: "\(entries.count)", label: "Entries")
                StatPill(value: "\(totalImages)", label: "Images")
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
    
    private func loadLeaderboardData() async {
        print("🔄 loadLeaderboardData() called")
        isLoading = true
        errorMessage = nil
        
        do {
            print("📞 Calling LeaderboardService.shared.fetchTop100()")
            let responses = try await LeaderboardService.shared.fetchTop100()
            print("✅ Received \(responses.count) responses from API")
            
            // Convert API responses to LeaderboardEntry objects
            let newEntries = responses.enumerated().map { (index, response) -> LeaderboardEntry in
                // Get the primary image (first one with a rating, or just the first one)
                let primaryImage = response.images.first { $0.rating != nil } ?? response.images.first
                
                // Get additional photo URLs (all images except the primary one)
                let additionalPhotos = response.images
                    .filter { $0.url != primaryImage?.url }
                    .map { $0.url }
                
                // Calculate score from rating
                let score = response.rating?.overall ?? primaryImage?.rating?.overall ?? 0
                
                // Create a Post object from the response
                let post = Post(
                    id: response.id,
                    userId: response.userId,
                    username: extractUsername(from: response.userId),
                    caption: {
                        // Use the image rating feedback if available and not just a period
                        if let feedback = response.rating?.feedback, feedback != ".", !feedback.isEmpty {
                            return feedback
                        }
                        if let imageFeedback = primaryImage?.rating?.feedback, imageFeedback != ".", !imageFeedback.isEmpty {
                            return imageFeedback
                        }
                        return "Amazing turf submission! 🌿"
                    }(),
                    location: "Community",
                    tags: extractTags(from: response),
                    photoUrl: primaryImage?.url ?? "",
                    additionalPhotos: additionalPhotos.isEmpty ? nil : additionalPhotos,
                    createdAt: parseDate(response.createdAt) ?? Date(),
                    updatedAt: parseDate(response.updatedAt)
                )
                
                return LeaderboardEntry(
                    rank: index + 1,
                    post: post,
                    score: score * 10, // Scale up the score for display
                    rating: response.rating ?? primaryImage?.rating // Store the rating breakdown
                )
            }
            
            print("📝 Created \(newEntries.count) leaderboard entries")
            
            // Debug: Print first entry details
            if let firstEntry = newEntries.first {
                print("🔍 First entry details:")
                print("   Rank: #\(firstEntry.rank)")
                print("   Username: @\(firstEntry.post.username)")
                print("   Photo URL: \(firstEntry.post.photoUrl)")
                print("   Caption: \(firstEntry.post.caption)")
                print("   Score: \(firstEntry.score)")
            }
            
            // Update UI on main thread
            await MainActor.run {
                entries = newEntries
                refreshID = UUID() // Force refresh
                isLoading = false
                print("✅ Successfully loaded leaderboard data - UI updated with \(entries.count) entries")
                print("   Current entries count in state: \(entries.count)")
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load leaderboard: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Error loading leaderboard: \(error)")
        }
    }
    
    // Helper function to extract a username from userId (using last part)
    private func extractUsername(from userId: String) -> String {
        let components = userId.split(separator: "-")
        return components.last.map(String.init) ?? userId
    }
    
    // Helper function to extract tags from response metadata
    private func extractTags(from response: LeaderboardResponse) -> [String] {
        var tags: [String] = []
        
        // Add status as a tag
        if response.status == "upload_completed" {
            tags.append("verified")
        }
        
        // Add quality indicators based on ratings
        if let rating = response.rating {
            if rating.overall >= 8 {
                tags.append("top-rated")
            }
            if rating.composition >= 8 {
                tags.append("well-composed")
            }
            if rating.lighting >= 8 {
                tags.append("great-lighting")
            }
        }
        
        return tags
    }
    
    // Helper function to parse ISO8601 date strings
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString)
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
            
            // Change
            VStack(spacing: 4) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(TurfTheme.primary)
                
                Text("\(entry.score)")
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
    // Note: Preview uses mock data. Run the app to see real API data.
    LeaderboardView()
}

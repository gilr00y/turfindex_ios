//
//  PostDetailView.swift
//  grassy
//
//  Created by jason on 1/17/26.
//

import SwiftUI

struct PostDetailView: View {
    let entry: LeaderboardEntry
    @State private var userProfile: UserProfile
    @State private var currentPhotoIndex = 0
    @Environment(\.dismiss) private var dismiss
    
    init(entry: LeaderboardEntry) {
        self.entry = entry
        // Initialize with mock business profile
        _userProfile = State(initialValue: Self.mockUserProfile(for: entry.post))
    }
    
    var body: some View {
        ZStack {
            // Dark navy background
            TurfTheme.navyBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Photo carousel
                    photoCarousel
                    
                    // Content sections
                    VStack(alignment: .leading, spacing: 24) {
                        // Rank and votes section
                        rankSection
                        
                        // Post details
                        postDetailsSection
                        
                        Divider()
                            .background(.white.opacity(0.2))
                        
                        // Business info
                        businessInfoSection
                        
                        Divider()
                            .background(.white.opacity(0.2))
                        
                        // Contact buttons
                        contactButtonsSection
                        
                        Divider()
                            .background(.white.opacity(0.2))
                        
                        // Social links
                        if let socialLinks = userProfile.socialLinks, !socialLinks.isEmpty {
                            socialLinksSection(links: socialLinks)
                            
                            Divider()
                                .background(.white.opacity(0.2))
                        }
                        
                        // Location details
                        locationSection
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TurfTheme.navyBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // Share action
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(TurfTheme.primary)
                }
            }
        }
    }
    
    // MARK: - Photo Carousel
    
    private var photoCarousel: some View {
        TabView(selection: $currentPhotoIndex) {
            // Main photo
            photoView(url: entry.post.photoUrl, index: 0)
            
            // Additional photos
            if let additionalPhotos = entry.post.additionalPhotos {
                ForEach(Array(additionalPhotos.enumerated()), id: \.offset) { index, url in
                    photoView(url: url, index: index + 1)
                }
            }
        }
        .tabViewStyle(.page)
        .frame(height: 400)
        .overlay(alignment: .bottomTrailing) {
            if totalPhotoCount > 1 {
                Text("\(currentPhotoIndex + 1)/\(totalPhotoCount)")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding()
            }
        }
    }
    
    private func photoView(url: String, index: Int) -> some View {
        AsyncImage(url: URL(string: url)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(TurfTheme.limeGreen.opacity(0.2))
                .overlay {
                    ProgressView()
                }
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .tag(index)
    }
    
    private var totalPhotoCount: Int {
        1 + (entry.post.additionalPhotos?.count ?? 0)
    }
    
    // MARK: - Rank Section
    
    private var rankSection: some View {
        HStack {
            // Rank badge
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(rankColor.gradient)
                        .frame(width: 60, height: 60)
                    
                    Text("#\(entry.rank)")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("This Week")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Text(rankDescription)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            
            Spacer()
            
            // Votes
            VStack(spacing: 4) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(TurfTheme.primary)
                
                Text("\(entry.votes)")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                
                Text("votes")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
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
    
    private var rankColor: Color {
        switch entry.rank {
        case 1: return TurfTheme.sunYellow
        case 2: return Color.gray
        case 3: return TurfTheme.sunOrange
        default: return TurfTheme.forestGreen
        }
    }
    
    private var rankDescription: String {
        switch entry.rank {
        case 1: return "1st Place"
        case 2: return "2nd Place"
        case 3: return "3rd Place"
        default: return "Top 100"
        }
    }
    
    // MARK: - Post Details
    
    private var postDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(entry.post.caption)
                .font(.body)
                .foregroundStyle(.white)
            
            // Tags
            FlowLayout(spacing: 8) {
                ForEach(entry.post.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(TurfTheme.limeGreen.opacity(0.15))
                        .foregroundStyle(TurfTheme.limeGreen)
                        .clipShape(Capsule())
                }
            }
            
            // Posted date
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption)
                Text("Posted \(entry.post.createdAt.formatted(.relative(presentation: .named)))")
                    .font(.caption)
            }
            .foregroundStyle(.white.opacity(0.7))
        }
    }
    
    // MARK: - Business Info
    
    private var businessInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Business name
            if let businessName = userProfile.businessName {
                HStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(TurfTheme.primary)
                    
                    Text(businessName)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
            }
            
            // Username
            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .foregroundStyle(TurfTheme.primary)
                
                Text("@\(userProfile.username)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            // Bio
            if let bio = userProfile.bio {
                Text(bio)
                    .font(.body)
                    .foregroundStyle(.white)
                    .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Contact Buttons
    
    private var contactButtonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact")
                .font(.headline)
                .foregroundStyle(.white)
            
            HStack(spacing: 12) {
                // Call button
                if let phone = userProfile.phone {
                    Link(destination: URL(string: "tel:\(phone)")!) {
                        Label("Call", systemImage: "phone.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(TurfTheme.primary.gradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                // Email button
                if let email = userProfile.email {
                    Link(destination: URL(string: "mailto:\(email)")!) {
                        Label("Email", systemImage: "envelope.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(TurfTheme.forestGreen.gradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            
            // Website button
            if let website = userProfile.website, let url = URL(string: website) {
                Link(destination: url) {
                    Label("Visit Website", systemImage: "safari.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(TurfTheme.skyBlue.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    // MARK: - Social Links
    
    private func socialLinksSection(links: [SocialLink]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Follow Us")
                .font(.headline)
                .foregroundStyle(.white)
            
            FlowLayout(spacing: 12) {
                ForEach(links) { link in
                    if let url = URL(string: link.url) {
                        Link(destination: url) {
                            HStack(spacing: 6) {
                                Image(systemName: socialIcon(for: link.platform))
                                    .font(.subheadline)
                                
                                Text(link.platform.capitalized)
                                    .font(.subheadline.bold())
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(TurfTheme.limeGreen.opacity(0.2))
                            .foregroundStyle(TurfTheme.limeGreen)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }
    
    private func socialIcon(for platform: String) -> String {
        switch platform.lowercased() {
        case "instagram": return "camera.fill"
        case "facebook": return "f.square.fill"
        case "twitter", "x": return "bird.fill"
        case "linkedin": return "briefcase.fill"
        case "youtube": return "play.rectangle.fill"
        default: return "link"
        }
    }
    
    // MARK: - Location Section
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)
                .foregroundStyle(.white)
            
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundStyle(TurfTheme.primary)
                
                Text(entry.post.location)
                    .font(.body)
                    .foregroundStyle(.white)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TurfTheme.limeGreen.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Mock Data
    
    private static func mockUserProfile(for post: Post) -> UserProfile {
        UserProfile(
            id: post.userId,
            username: post.username,
            bio: mockBios.randomElement(),
            businessName: mockBusinessNames.randomElement(),
            phone: mockPhones.randomElement(),
            email: "\(post.username)@turfcare.com",
            website: "https://www.\(post.username).com",
            socialLinks: [
                SocialLink(platform: "Instagram", url: "https://instagram.com/\(post.username)"),
                SocialLink(platform: "Facebook", url: "https://facebook.com/\(post.username)"),
            ],
            createdAt: Date(),
            updatedAt: nil
        )
    }
}

// MARK: - Mock Business Data

private let mockBios = [
    "Professional lawn care since 2015. Specializing in organic treatments and sustainable landscaping. Your yard is our passion! 🌱",
    "Family-owned business serving the community for over 20 years. From maintenance to full landscape design, we do it all!",
    "Eco-friendly lawn services. We believe in working with nature, not against it. Certified organic specialists.",
    "Transform your outdoor space into a paradise. Expert team, quality service, beautiful results every time.",
    "Award-winning landscape design and maintenance. Making yards beautiful one lawn at a time since 2010."
]

private let mockBusinessNames = [
    "Green Dream Lawn Care",
    "Perfect Turf Solutions",
    "EcoScape Services",
    "Premier Lawn Professionals",
    "Nature's Touch Landscaping",
    "GreenThumb Yard Care",
    "Pristine Lawns & Landscapes",
    "Elite Turf Management"
]

private let mockPhones = [
    "(555) 123-4567",
    "(555) 234-5678",
    "(555) 345-6789",
    "(555) 456-7890",
    "(555) 567-8901"
]

#Preview {
    NavigationStack {
        PostDetailView(entry: LeaderboardEntry(
            rank: 1,
            post: Post(
                id: "1",
                userId: "user1",
                username: "grassmaster",
                caption: "Finally got the stripes perfect! Three months of hard work paying off. 🌿",
                location: "Backyard Oasis, Portland OR",
                tags: ["lush", "stripes", "organic"],
                photoUrl: "https://picsum.photos/400/300",
                additionalPhotos: [
                    "https://picsum.photos/400/301",
                    "https://picsum.photos/400/302",
                    "https://picsum.photos/400/303"
                ],
                createdAt: Date().addingTimeInterval(-86400),
                updatedAt: nil
            ),
            votes: 1247
        ))
    }
}

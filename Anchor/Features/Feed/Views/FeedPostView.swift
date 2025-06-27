import SwiftUI
import AnchorKit

struct FeedPostView: View {
    let post: FeedPost

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Author info
            Button {
                openBlueskyProfile(handle: post.author.handle)
            } label: {
                HStack(spacing: 8) {
                    AsyncImage(url: post.author.avatar.flatMap(URL.init)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(.secondary)
                            .overlay {
                                Text(String(post.author.handle.prefix(1).uppercased()))
                                    .font(.caption)
                                    .foregroundStyle(.white)
                            }
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.author.displayName ?? post.author.handle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Text("@\(post.author.handle)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(post.record.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            // Check-in content
            VStack(alignment: .leading, spacing: 4) {
                Text(.init(post.record.formattedText))
                    .font(.caption)
                
                // Show non-geo location info if available from checkin record
                if let checkinRecord = post.checkinRecord,
                   let locations = checkinRecord.locations,
                   !locations.isEmpty,
                   let locationText = formatInlineLocationInfo(locations), !locationText.isEmpty {
                    HStack(spacing: 4) {
                        Text(checkinRecord.categoryIcon ?? extractCategoryIcon(from: post.record.text))
                            .foregroundStyle(.secondary)
                            .font(.caption2)
                        
                        Text(locationText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Full-width footer for geo coordinates
            if let checkinRecord = post.checkinRecord,
               let locations = checkinRecord.locations,
               let geoText = formatGeoLocationFooter(locations) {
                Divider()
                
                HStack {
                    Text(geoText)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func openBlueskyProfile(handle: String) {
        if let url = URL(string: "https://bsky.app/profile/\(handle)") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func formatInlineLocationInfo(_ locations: [LocationItem]) -> String? {
        for location in locations {
            switch location {
            case .address(let address):
                var components: [String] = []
                if let name = address.name {
                    components.append(name)
                }
                if let locality = address.locality {
                    components.append(locality)
                }
                if !components.isEmpty {
                    return components.joined(separator: ", ")
                }
            case .geo:
                // Skip geo coordinates for inline display
                continue
            }
        }
        return nil
    }
    
    private func formatGeoLocationFooter(_ locations: [LocationItem]) -> String? {
        for location in locations {
            switch location {
            case .address:
                // Skip addresses for footer
                continue
            case .geo(let geo):
                return "📍 \(geo.latitude), \(geo.longitude)"
            }
        }
        return nil
    }
    
    private func extractCategoryIcon(from text: String) -> String {
        // Extract category from text pattern like "Place Name (category)"
        let pattern = #"\(([^)]+)\)"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            let category = String(text[range])
            
            // Try different tag types to find the best icon
            for tag in ["amenity", "leisure", "shop", "tourism"] {
                let icon = PlaceCategorization.getIcon(for: tag, value: category)
                if icon != "📍" {
                    return icon
                }
            }
            
            // Fallback for common categories
            switch category.lowercased() {
            case "restaurant", "fast_food": return "🍽️"
            case "cafe": return "☕"
            case "bar", "pub": return "🍺"
            case "climbing": return "🧗‍♂️"
            case "museum": return "🏛️"
            case "hotel": return "🏨"
            case "park": return "🌳"
            default: return "📍"
            }
        }
        return "📍"
    }
}

#Preview("Basic Check-in") {
    let mockAuthor = FeedAuthor(
        did: "did:plc:example",
        handle: "alice.test",
        displayName: "Alice Smith",
        avatar: nil
    )
    
    let mockRecord = ATProtoRecord(
        text: "Just dropped anchor at Central Park! 🌳",
        createdAt: Date()
    )
    
    let mockPost = FeedPost(
        id: "test-post",
        author: mockAuthor,
        record: mockRecord,
        checkinRecord: nil
    )
    
    FeedPostView(post: mockPost)
        .padding()
        .frame(width: 300)
}

#Preview("Check-in with Location") {
    let mockAuthor = FeedAuthor(
        did: "did:plc:example2",
        handle: "bob.climbing",
        displayName: "Bob Johnson",
        avatar: "https://example.com/avatar.jpg"
    )
    
    let mockRecord = ATProtoRecord(
        text: "Crushing some routes at Brooklyn Boulders! 🧗‍♂️",
        createdAt: Date().addingTimeInterval(-3600) // 1 hour ago
    )
    
    let mockAddress = CommunityAddressLocation(
        locality: "Brooklyn",
        region: "NY",
        name: "Brooklyn Boulders"
    )
    
    let mockGeo = CommunityGeoLocation(
        latitude: 40.6782,
        longitude: -73.9442
    )
    
    let mockCheckinRecord = AnchorPDSCheckinRecord(
        text: "At the climbing gym",
        createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)),
        locations: [.address(mockAddress), .geo(mockGeo)],
        categoryIcon: "🧗‍♂️"
    )
    
    let mockPost = FeedPost(
        id: "test-post-2",
        author: mockAuthor,
        record: mockRecord,
        checkinRecord: mockCheckinRecord
    )
    
    FeedPostView(post: mockPost)
        .padding()
        .frame(width: 300)
}

#Preview("Check-in with Geo Only") {
    let mockAuthor = FeedAuthor(
        did: "did:plc:example3",
        handle: "charlie.explorer",
        displayName: nil, // Test without display name
        avatar: nil
    )
    
    let mockRecord = ATProtoRecord(
        text: "Found an amazing hidden spot! 📍",
        createdAt: Date().addingTimeInterval(-7200) // 2 hours ago
    )
    
    let mockGeo = CommunityGeoLocation(
        latitude: 40.7128,
        longitude: -74.0060
    )
    
    let mockCheckinRecord = AnchorPDSCheckinRecord(
        text: "Secret location",
        createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-7200)),
        locations: [.geo(mockGeo)],
        categoryIcon: nil
    )
    
    let mockPost = FeedPost(
        id: "test-post-3",
        author: mockAuthor,
        record: mockRecord,
        checkinRecord: mockCheckinRecord
    )
    
    FeedPostView(post: mockPost)
        .padding()
        .frame(width: 300)
}

#Preview("Multiple Posts") {
    let posts = [
        // Basic post
        FeedPost(
            id: "post-1",
            author: FeedAuthor(
                did: "did:plc:1",
                handle: "alice.test",
                displayName: "Alice",
                avatar: nil
            ),
            record: ATProtoRecord(
                text: "Morning coffee ☕",
                createdAt: Date()
            ),
            checkinRecord: nil
        ),
        
        // Post with location
        FeedPost(
            id: "post-2", 
            author: FeedAuthor(
                did: "did:plc:2",
                handle: "bob.climber",
                displayName: "Bob",
                avatar: nil
            ),
            record: ATProtoRecord(
                text: "Great session at the gym! 🧗‍♂️",
                createdAt: Date().addingTimeInterval(-1800)
            ),
            checkinRecord: AnchorPDSCheckinRecord(
                text: "Climbing session",
                createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-1800)),
                locations: [
                    .address(CommunityAddressLocation(locality: "Brooklyn", region: "NY", name: "Local Climbing Gym")),
                    .geo(CommunityGeoLocation(latitude: 40.6782, longitude: -73.9442))
                ],
                categoryIcon: "🧗‍♂️"
            )
        )
    ]
    
    ScrollView {
        LazyVStack(spacing: 12) {
            ForEach(posts, id: \.id) { post in
                FeedPostView(post: post)
            }
        }
        .padding()
    }
    .frame(width: 300, height: 600)
} 

//
//  FeedMockData.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import Foundation
import AnchorKit

// MARK: - Shared Mock Data for Feed Posts

/// Mock coffee shop check-in post for previews and testing
public let sampleCoffeeShopPost = FeedPost(
    id: "at://did:plc:sample1234/app.bsky.feed.post/123",
    author: FeedAuthor(
        did: "did:plc:sample1234",
        handle: "coffee.lover.bsky.social",
        displayName: "Coffee Enthusiast",
        avatar: nil
    ),
    record: ATProtoRecord(
        text: "Great coffee and amazing atmosphere! Perfect spot for morning work sessions ☕️",
        createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
    ),
    checkinRecord: AnchorPDSCheckinRecord(
        text: "Great coffee and amazing atmosphere! Perfect spot for morning work sessions ☕️",
        createdAt: ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()),
        locations: [
            .geo(CommunityGeoLocation(latitude: 37.7749, longitude: -122.4194)),
            .address(CommunityAddressLocation(
                street: "1234 Coffee Street",
                locality: "San Francisco",
                region: "CA",
                country: "USA",
                name: "Blue Bottle Coffee"
            ))
        ],
        category: "cafe",
        categoryGroup: "Food & Drink",
        categoryIcon: "☕️"
    )
)

/// Mock restaurant check-in post for previews and testing
public let sampleRestaurantPost = FeedPost(
    id: "at://did:plc:sample5678/app.bsky.feed.post/456",
    author: FeedAuthor(
        did: "did:plc:sample5678",
        handle: "foodie.adventures.bsky.social",
        displayName: "Sarah Chen",
        avatar: nil
    ),
    record: ATProtoRecord(
        text: "Incredible dim sum! The har gow was perfectly steamed and the xiaolongbao had amazing broth 🥟",
        createdAt: Calendar.current.date(byAdding: .hour, value: -5, to: Date()) ?? Date()
    ),
    checkinRecord: AnchorPDSCheckinRecord(
        text: "Incredible dim sum! The har gow was perfectly steamed and the xiaolongbao had amazing broth 🥟",
        createdAt: ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .hour, value: -5, to: Date()) ?? Date()),
        locations: [
            .geo(CommunityGeoLocation(latitude: 37.7849, longitude: -122.4094)),
            .address(CommunityAddressLocation(
                street: "567 Chinatown Avenue",
                locality: "San Francisco",
                region: "CA",
                country: "USA",
                name: "Golden Dragon Restaurant"
            ))
        ],
        category: "restaurant",
        categoryGroup: "Food & Drink",
        categoryIcon: "🍽️"
    )
)

/// Mock climbing check-in post for previews and testing
public let sampleClimbingPost = FeedPost(
    id: "at://did:plc:sample9999/app.bsky.feed.post/789",
    author: FeedAuthor(
        did: "did:plc:sample9999",
        handle: "mountain.goat.bsky.social",
        displayName: "Alex Rodriguez",
        avatar: nil
    ),
    record: ATProtoRecord(
        text: "Sent my first 5.11a! The crimps were brutal but so worth it. Yosemite never disappoints 🧗‍♂️",
        createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    ),
    checkinRecord: AnchorPDSCheckinRecord(
        text: "Sent my first 5.11a! The crimps were brutal but so worth it. Yosemite never disappoints 🧗‍♂️",
        createdAt: ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()),
        locations: [
            .geo(CommunityGeoLocation(latitude: 37.8651, longitude: -119.5383)),
            .address(CommunityAddressLocation(
                locality: "Yosemite Valley",
                region: "CA",
                country: "USA",
                name: "El Capitan"
            ))
        ],
        category: "climbing",
        categoryGroup: "Sports & Fitness",
        categoryIcon: "🧗‍♂️"
    )
)

/// Array of all sample posts for easy iteration in previews
public let allSamplePosts: [FeedPost] = [
    sampleCoffeeShopPost,
    sampleRestaurantPost,
    sampleClimbingPost
] 

//
//  FeedMockData.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 27/06/2025.
//

import Foundation
import AnchorKit

// MARK: - Shared Mock Data for Feed Posts

// Helper: create mock FeedPost directly
private func makeMockPost(id: String, authorDid: String, authorHandle: String, text: String, createdAt: Date, latitude: Double?, longitude: Double?, addressName: String?, distance: Double? = nil, likesCount: Int? = nil) -> FeedPost {
    let coords = (latitude != nil && longitude != nil) ?
        FeedCoordinates(latitude: latitude!, longitude: longitude!) : nil
    let address = addressName != nil ? FeedAddress(name: addressName) : nil

    return FeedPost(
        id: id,
        author: FeedAuthor(
            did: authorDid,
            handle: authorHandle,
            displayName: nil,
            avatar: nil
        ),
        record: ATProtoRecord(
            text: text,
            createdAt: createdAt
        ),
        coordinates: coords,
        address: address,
        distance: distance,
        likesCount: likesCount
    )
}

public let sampleCoffeeShopPost: FeedPost = {
    return makeMockPost(
        id: "sample1234",
        authorDid: "did:plc:sample1234",
        authorHandle: "coffee.lover.bsky.social",
        text: "Great coffee and amazing atmosphere! Perfect spot for morning work sessions ☕️",
        createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
        latitude: 37.7749,
        longitude: -122.4194,
        addressName: "Blue Bottle Coffee",
        likesCount: 12
    )
}()

public let sampleRestaurantPost: FeedPost = {
    return makeMockPost(
        id: "sample5678",
        authorDid: "did:plc:sample5678",
        authorHandle: "foodie.adventures.bsky.social",
        text: "Incredible dim sum! The har gow was perfectly steamed and the xiaolongbao had amazing broth 🥟",
        createdAt: Calendar.current.date(byAdding: .hour, value: -5, to: Date()) ?? Date(),
        latitude: 37.7849,
        longitude: -122.4094,
        addressName: "Golden Dragon Restaurant",
        likesCount: 8
    )
}()

public let sampleClimbingPost: FeedPost = {
    return makeMockPost(
        id: "sample9999",
        authorDid: "did:plc:sample9999",
        authorHandle: "mountain.goat.bsky.social",
        text: "Sent my first 5.11a! The crimps were brutal but so worth it. Yosemite never disappoints 🧗‍♂️",
        createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
        latitude: 37.8651,
        longitude: -119.5383,
        addressName: "El Capitan",
        likesCount: 23
    )
}()

public let allSamplePosts: [FeedPost] = [
    sampleCoffeeShopPost,
    sampleRestaurantPost,
    sampleClimbingPost
] 

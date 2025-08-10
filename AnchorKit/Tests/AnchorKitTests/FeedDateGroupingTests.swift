import Testing
import Foundation
@testable import AnchorKit

@Suite("Feed Date Grouping")
struct FeedDateGroupingTests {
    
    @Test("Empty posts array returns empty sections")
    func emptyPostsGrouping() {
        let posts: [FeedPost] = []
        let sections = posts.groupedByDate()
        
        #expect(sections.isEmpty)
    }
    
    @Test("Posts from same day are grouped together")
    func sameDay() {
        let today = Date()
        let laterToday = Calendar.current.date(byAdding: .hour, value: 2, to: today)!
        
        let posts = [
            createMockPost(createdAt: today, text: "First post"),
            createMockPost(createdAt: laterToday, text: "Second post")
        ]
        
        let sections = posts.groupedByDate()
        
        #expect(sections.count == 1)
        #expect(sections[0].posts.count == 2)
        
        // Should be sorted by time descending (newest first)
        #expect(sections[0].posts[0].record.text == "Second post")
        #expect(sections[0].posts[1].record.text == "First post")
    }
    
    @Test("Posts from different days are in separate sections")
    func differentDays() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        let posts = [
            createMockPost(createdAt: yesterday, text: "Yesterday post"),
            createMockPost(createdAt: today, text: "Today post")
        ]
        
        let sections = posts.groupedByDate()
        
        #expect(sections.count == 2)
        
        // Sections should be sorted by date descending (newest first)
        #expect(sections[0].posts[0].record.text == "Today post")
        #expect(sections[1].posts[0].record.text == "Yesterday post")
    }
    
    @Test("Multiple posts across multiple days are correctly grouped and sorted")
    func multipleDaysMultiplePosts() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!
        
        // Create posts with specific timestamps to ensure proper ordering
        let todayFirst = createMockPost(createdAt: today, text: "Today - first")
        let todaySecond = createMockPost(createdAt: Calendar.current.date(byAdding: .minute, value: 1, to: today)!, text: "Today - second")
        let twoDaysAgoFirst = createMockPost(createdAt: twoDaysAgo, text: "Two days ago - first")
        let twoDaysAgoSecond = createMockPost(createdAt: Calendar.current.date(byAdding: .minute, value: 1, to: twoDaysAgo)!, text: "Two days ago - second")
        
        let posts = [
            twoDaysAgoFirst,
            todayFirst,
            createMockPost(createdAt: yesterday, text: "Yesterday - first"),
            todaySecond,
            twoDaysAgoSecond
        ]
        
        let sections = posts.groupedByDate()
        
        #expect(sections.count == 3)
        
        // Check section ordering (newest to oldest)
        #expect(sections[0].posts.count == 2) // Today
        #expect(sections[1].posts.count == 1) // Yesterday
        #expect(sections[2].posts.count == 2) // Two days ago
        
        // Check post ordering within each section (newest to oldest)
        #expect(sections[0].posts[0].record.text == "Today - second")
        #expect(sections[0].posts[1].record.text == "Today - first")
        #expect(sections[1].posts[0].record.text == "Yesterday - first")
        #expect(sections[2].posts[0].record.text == "Two days ago - second")
        #expect(sections[2].posts[1].record.text == "Two days ago - first")
    }
    
    // MARK: - Helper Methods
    
    private func createMockPost(createdAt: Date, text: String) -> FeedPost {
        FeedPost(
            id: UUID().uuidString,
            author: FeedAuthor(
                did: "did:plc:test",
                handle: "test.bsky.social",
                displayName: "Test User",
                avatar: nil
            ),
            record: ATProtoRecord(
                text: text,
                createdAt: createdAt
            )
        )
    }
}
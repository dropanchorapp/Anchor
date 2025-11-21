@testable import ATProtoFoundation
import Testing

/// Centralized test tags for organizing and filtering tests
extension Tag {
    @Tag static var unit: Self
    @Tag static var integration: Self
    @Tag static var network: Self
    @Tag static var markdown: Self
    @Tag static var facets: Self
    @Tag static var models: Self
    @Tag static var services: Self
    @Tag static var stores: Self
    @Tag static var auth: Self
    @Tag static var oauth: Self
    @Tag static var session: Self
    @Tag static var location: Self
    @Tag static var feed: Self
    @Tag static var bluesky: Self
}

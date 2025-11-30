import Foundation
import ATProtoFoundation

// MARK: - StrongRef Checkin Models

/// New checkin record using StrongRef to reference separate address records
public struct CheckinRecord: Codable, Sendable, Hashable {
    public let type: String = "app.dropanchor.checkin"
    public let text: String
    public let createdAt: String
    public let addressRef: StrongRef
    public let coordinates: GeoCoordinates

    // Optional place categorization fields
    public let category: String?
    public let categoryGroup: String?
    public let categoryIcon: String?

    private enum CodingKeys: String, CodingKey {
        case text, createdAt, addressRef, coordinates, category, categoryGroup, categoryIcon
        case type = "$type"
    }

    public init(
        text: String,
        createdAt: String,
        addressRef: StrongRef,
        coordinates: GeoCoordinates,
        category: String? = nil,
        categoryGroup: String? = nil,
        categoryIcon: String? = nil
    ) {
        self.text = text
        self.createdAt = createdAt
        self.addressRef = addressRef
        self.coordinates = coordinates
        self.category = category
        self.categoryGroup = categoryGroup
        self.categoryIcon = categoryIcon
    }
}

/// Error types for checkin content integrity
public enum CheckinError: LocalizedError, Sendable {
    case addressContentMismatch
    case missingLocationData
    case invalidFormat

    public var errorDescription: String? {
        switch self {
        case .addressContentMismatch:
            "Address record content has been modified since checkin creation"
        case .missingLocationData:
            "Checkin record is missing location data"
        case .invalidFormat:
            "Invalid checkin record format"
        }
    }
}

/// Resolved checkin with address data from strongref
public struct ResolvedCheckin: Sendable {
    public let checkin: CheckinRecord
    public let address: CommunityAddress
    public let isVerified: Bool // CID verification result

    public init(checkin: CheckinRecord, address: CommunityAddress, isVerified: Bool = true) {
        self.checkin = checkin
        self.address = address
        self.isVerified = isVerified
    }
}

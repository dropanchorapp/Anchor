public protocol LocationRepresentable: Sendable {
    var displayName: String? { get }
    var street: String? { get }
    var locality: String? { get }
    var region: String? { get }
    var country: String? { get }
    var postalCode: String? { get }
    var coordinate: (Double, Double)? { get }
}

public enum LocationItem: Sendable {
    case address(AddressLocation)
    case geo(GeoLocation)
}

public struct AddressLocation: Sendable {
    public let name: String?
    public let street: String?
    public let locality: String?
    public let region: String?
    public let country: String?
    public let postalCode: String?

    public init(
        name: String? = nil,
        street: String? = nil,
        locality: String? = nil,
        region: String? = nil,
        country: String? = nil,
        postalCode: String? = nil
    ) {
        self.name = name
        self.street = street
        self.locality = locality
        self.region = region
        self.country = country
        self.postalCode = postalCode
    }
}

public struct GeoLocation: Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

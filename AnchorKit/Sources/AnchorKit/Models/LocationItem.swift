public protocol LocationRepresentable: Sendable {
    var displayName: String? { get }
    var street: String? { get }
    var locality: String? { get }
    var region: String? { get }
    var country: String? { get }
    var postalCode: String? { get }
    var coordinate: (Double, Double)? { get }
}

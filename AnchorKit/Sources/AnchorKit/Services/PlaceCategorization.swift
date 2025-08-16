import Foundation

public struct PlaceCategorization {

    // MARK: - OpenStreetMap Category Definitions

    public static let amenityCategories: [String] = [
        // Food & Drink
        "restaurant",
        "cafe",
        "bar",
        "pub",
        "fast_food",
        "food_court",
        "ice_cream",
        "biergarten",

        // Education
        "school",
        "university",
        "college",
        "library",
        "driving_school",
        "language_school",
        "music_school",

        // Healthcare
        "hospital",
        "clinic",
        "pharmacy",
        "dentist",
        "veterinary",
        "nursing_home",

        // Entertainment & Culture
        "cinema",
        "theatre",
        "nightclub",
        "casino",
        "arts_centre",
        "community_centre",
        "exhibition_centre",
        "music_venue",

        // Transportation
        "bus_station",
        "taxi",
        "ferry_terminal",
        "fuel",
        "charging_station",
        "car_wash",
        "parking",
        "bicycle_parking",

        // Public Services
        "townhall",
        "courthouse",
        "police",
        "fire_station",
        "post_office",
        "bank",
        "bureau_de_change",
        "atm",

        // Facilities
        "toilets",
        "drinking_water",
        "shower",
        "bench",
        "shelter",
        "waste_disposal",
        "recycling"
    ]

    public static let leisureCategories: [String] = [
        // Sports & Fitness
        "fitness_centre",
        "sports_centre",
        "sports_hall",
        "swimming_pool",
        "pitch",
        "track",
        "golf_course",
        "climbing",
        "horse_riding",
        "bowling_alley",
        "ice_rink",
        "stadium",

        // Entertainment & Gaming
        "amusement_arcade",
        "escape_game",
        "trampoline_park",
        "water_park",
        "dance",
        "adult_gaming_centre",
        "miniature_golf",

        // Relaxation & Nature
        "park",
        "beach_resort",
        "nature_reserve",
        "garden",
        "bird_hide",
        "wildlife_hide",
        "sauna",
        "picnic_site",
        "playground",

        // Marine & Adventure
        "marina",
        "slipway",
        "summer_camp",
        "high_ropes"
    ]

    public static let shopCategories: [String] = [
        // Food & Beverage
        "supermarket",
        "convenience",
        "bakery",
        "butcher",
        "greengrocer",
        "wine",
        "coffee",
        "deli",
        "confectionery",
        "cheese",
        "seafood",
        "spices",
        "tea",

        // Clothing & Fashion
        "clothes",
        "shoes",
        "jewelry",
        "tailor",
        "fabric",
        "fashion_accessories",
        "bag",
        "watches",

        // Electronics & Technology
        "electronics",
        "computer",
        "mobile_phone",
        "camera",
        "hifi",
        "video_games",

        // Home & Lifestyle
        "furniture",
        "appliance",
        "doityourself",
        "hardware",
        "paint",
        "lighting",
        "kitchen",
        "interior_decoration",
        "curtain",
        "florist",
        "garden_centre",

        // Books & Media
        "books",
        "stationery",
        "newsagent",
        "art",
        "music",
        "video",

        // Health & Beauty
        "cosmetics",
        "hairdresser",
        "beauty",
        "massage",
        "optician",
        "medical_supply",

        // Sports & Outdoor
        "sports",
        "outdoor",
        "bicycle",
        "fishing",
        "hunting",
        "ski",

        // Vehicles
        "car",
        "car_parts",
        "motorcycle",
        "tyres",

        // Specialty & Services
        "gift",
        "lottery",
        "pet",
        "tobacco",
        "trade",
        "travel_agency",
        "copyshop",
        "laundry",
        "dry_cleaning",
        "funeral_directors"
    ]

    public static let tourismCategories: [String] = [
        // Accommodations
        "hotel",
        "motel",
        "guest_house",
        "hostel",
        "chalet",
        "apartment",
        "camp_site",
        "caravan_site",
        "alpine_hut",
        "wilderness_hut",

        // Attractions
        "attraction",
        "museum",
        "gallery",
        "aquarium",
        "zoo",
        "theme_park",
        "viewpoint",
        "artwork",

        // Services
        "information",
        "picnic_site",
        "trail_riding_station"
    ]

    // MARK: - Category Grouping for UI

    public enum CategoryGroup: String, CaseIterable {
        case foodAndDrink = "Food & Drink"
        case entertainment = "Entertainment"
        case sports = "Sports & Fitness"
        case shopping = "Shopping"
        case accommodation = "Accommodation"
        case transportation = "Transportation"
        case services = "Services"
        case nature = "Nature & Parks"
        case culture = "Culture"
        case health = "Health"
        case education = "Education"

        public var icon: String {
            switch self {
            case .foodAndDrink: return "🍽️"
            case .entertainment: return "🎭"
            case .sports: return "🏃‍♂️"
            case .shopping: return "🛍️"
            case .accommodation: return "🏨"
            case .transportation: return "🚌"
            case .services: return "🏛️"
            case .nature: return "🌳"
            case .culture: return "🎨"
            case .health: return "🏥"
            case .education: return "📚"
            }
        }
    }

    // MARK: - Category to Group Mapping

    public static func getCategoryGroup(for tag: String, value: String) -> CategoryGroup? {

        switch tag {
        case "amenity":
            switch value {
            case "restaurant", "cafe", "bar", "pub", "fast_food", "food_court", "ice_cream", "biergarten":
                return .foodAndDrink
            case "cinema", "theatre", "nightclub", "casino", "arts_centre", "community_centre", "exhibition_centre", "music_venue":
                return .entertainment
            case "hospital", "clinic", "pharmacy", "dentist", "veterinary", "nursing_home":
                return .health
            case "school", "university", "college", "library", "driving_school", "language_school", "music_school":
                return .education
            case "bus_station", "taxi", "ferry_terminal", "fuel", "charging_station", "car_wash", "parking", "bicycle_parking":
                return .transportation
            case "townhall", "courthouse", "police", "fire_station", "post_office", "bank", "bureau_de_change", "atm":
                return .services
            default:
                return .services
            }

        case "leisure":
            switch value {
            case "fitness_centre", "sports_centre", "sports_hall", "swimming_pool", "pitch", "track", "golf_course", "climbing", "horse_riding", "bowling_alley", "ice_rink", "stadium":
                return .sports
            case "amusement_arcade", "escape_game", "trampoline_park", "water_park", "dance", "adult_gaming_centre", "miniature_golf":
                return .entertainment
            case "park", "beach_resort", "nature_reserve", "garden", "bird_hide", "wildlife_hide", "picnic_site", "playground":
                return .nature
            default:
                return .entertainment
            }

        case "shop":
            switch value {
            case "supermarket", "convenience", "bakery", "butcher", "greengrocer", "wine", "coffee", "deli", "confectionery", "cheese", "seafood", "spices", "tea":
                return .foodAndDrink
            case "cosmetics", "hairdresser", "beauty", "massage", "optician", "medical_supply":
                return .health
            case "books", "stationery", "newsagent", "art", "music", "video":
                return .culture
            default:
                return .shopping
            }

        case "tourism":
            switch value {
            case "hotel", "motel", "guest_house", "hostel", "chalet", "apartment", "camp_site", "caravan_site", "alpine_hut", "wilderness_hut":
                return .accommodation
            case "museum", "gallery", "artwork":
                return .culture
            case "attraction", "aquarium", "zoo", "theme_park", "viewpoint":
                return .entertainment
            default:
                return .services
            }

        default:
            return nil
        }
    }

    // MARK: - Icon Mapping

    public static func getIcon(for tag: String, value: String) -> String {
        let fullTag = "\(tag)=\(value)"

        switch fullTag {
        // Food & Drink
        case "amenity=restaurant", "amenity=fast_food": return "🍽️"
        case "amenity=cafe", "shop=coffee": return "☕"
        case "amenity=bar", "amenity=pub": return "🍺"
        case "amenity=ice_cream": return "🍦"
        case "amenity=biergarten": return "🍻"
        case "shop=bakery": return "🥖"
        case "shop=wine": return "🍷"

        // Entertainment
        case "amenity=cinema": return "🎬"
        case "amenity=theatre": return "🎭"
        case "amenity=nightclub": return "💃"
        case "amenity=casino": return "🎰"
        case "leisure=bowling_alley": return "🎳"
        case "leisure=amusement_arcade": return "🕹️"
        case "tourism=theme_park": return "🎢"

        // Sports & Fitness
        case "leisure=fitness_centre", "leisure=sports_centre": return "🏋️‍♂️"
        case "leisure=swimming_pool": return "🏊‍♂️"
        case "leisure=climbing": return "🧗‍♂️"
        case "leisure=golf_course": return "⛳"
        case "leisure=stadium": return "🏟️"
        case "leisure=ice_rink": return "⛸️"

        // Shopping
        case "shop=supermarket": return "🛒"
        case "shop=clothes": return "👕"
        case "shop=shoes": return "👟"
        case "shop=books": return "📚"
        case "shop=electronics": return "📱"
        case "shop=jewelry": return "💍"
        case "shop=florist": return "💐"

        // Accommodation
        case "tourism=hotel": return "🏨"
        case "tourism=hostel": return "🏠"
        case "tourism=camp_site": return "🏕️"

        // Transportation
        case "amenity=bus_station": return "🚌"
        case "amenity=fuel": return "⛽"
        case "amenity=parking": return "🅿️"
        case "amenity=bicycle_parking": return "🚲"

        // Culture & Education
        case "tourism=museum", "amenity=library": return "🏛️"
        case "tourism=gallery": return "🎨"
        case "amenity=school", "amenity=university": return "🎓"

        // Health
        case "amenity=hospital": return "🏥"
        case "amenity=pharmacy": return "💊"
        case "amenity=dentist": return "🦷"

        // Nature
        case "leisure=park": return "🌳"
        case "leisure=beach_resort": return "🏖️"
        case "tourism=viewpoint": return "🔭"
        case "leisure=playground": return "🛝"

        // Services
        case "amenity=bank": return "🏦"
        case "amenity=post_office": return "📮"
        case "amenity=police": return "👮‍♂️"
        case "amenity=fire_station": return "🚒"

        default: return "📍"
        }
    }

    // MARK: - Complete Category List Generation

    public static func getAllCategories() -> [String] {
        var allCategories: [String] = []

        // Add all amenity categories
        allCategories.append(contentsOf: amenityCategories.map { "amenity=\($0)" })

        // Add all leisure categories
        allCategories.append(contentsOf: leisureCategories.map { "leisure=\($0)" })

        // Add all shop categories
        allCategories.append(contentsOf: shopCategories.map { "shop=\($0)" })

        // Add all tourism categories
        allCategories.append(contentsOf: tourismCategories.map { "tourism=\($0)" })

        return allCategories.sorted()
    }

    // MARK: - Priority Categories for Performance

    public static func getPrioritizedCategories() -> [String] {
        // Most commonly visited places - prioritize these in queries
        [
            // Food & Drink (most common check-ins)
            "amenity=restaurant",
            "amenity=cafe",
            "amenity=bar",
            "amenity=pub",

            // Entertainment & Culture
            "amenity=cinema",
            "tourism=attraction",
            "tourism=museum",

            // Sports & Fitness
            "leisure=fitness_centre",
            "leisure=climbing",

            // Shopping (essentials only)
            "shop=supermarket",

            // Nature
            "leisure=park"
        ]
    }

    // MARK: - Group to Categories Mapping

    public static func getCategoriesForGroup(_ group: String) -> [String] {
        let categoryGroup = CategoryGroup(rawValue: group)
        return getCategoriesForGroup(categoryGroup)
    }

    public static func getCategoriesForGroup(_ group: CategoryGroup?) -> [String] {
        guard let group = group else {
            return getPrioritizedCategories()
        }

        switch group {
        case .foodAndDrink:
            return amenityCategories.filter { ["restaurant", "cafe", "bar", "pub", "fast_food", "food_court", "ice_cream", "biergarten"].contains($0) }.map { "amenity=\($0)" }
        case .entertainment:
            return (amenityCategories.filter { ["cinema", "theatre", "nightclub", "gambling", "casino"].contains($0) }.map { "amenity=\($0)" } +
                   leisureCategories.filter { ["amusement_arcade", "escape_game", "trampoline_park", "water_park", "dance", "adult_gaming_centre", "miniature_golf"].contains($0) }.map { "leisure=\($0)" })
        case .sports:
            return leisureCategories.filter { ["fitness_centre", "sports_centre", "swimming_pool", "pitch", "track", "golf_course", "climbing", "horse_riding", "bowling_alley", "ice_rink", "stadium"].contains($0) }.map { "leisure=\($0)" }
        case .shopping:
            return shopCategories.map { "shop=\($0)" }
        case .accommodation:
            return tourismCategories.filter { ["hotel", "guest_house", "motel", "hostel", "apartment", "chalet", "alpine_hut", "camp_site", "caravan_site"].contains($0) }.map { "tourism=\($0)" }
        case .transportation:
            return amenityCategories.filter { ["bus_station", "taxi", "fuel", "parking", "charging_station", "car_rental", "car_sharing", "bicycle_rental"].contains($0) }.map { "amenity=\($0)" }
        case .services:
            return amenityCategories.filter { ["bank", "atm", "post_office", "police", "fire_station", "townhall", "embassy", "courthouse", "prison"].contains($0) }.map { "amenity=\($0)" }
        case .nature:
            return (leisureCategories.filter { ["park", "nature_reserve", "garden", "bird_hide", "wildlife_hide", "picnic_site", "playground"].contains($0) }.map { "leisure=\($0)" } +
                   tourismCategories.filter { ["picnic_site", "viewpoint", "artwork"].contains($0) }.map { "tourism=\($0)" })
        case .culture:
            return (amenityCategories.filter { ["library", "community_centre", "social_centre", "arts_centre"].contains($0) }.map { "amenity=\($0)" } +
                   tourismCategories.filter { ["museum", "gallery", "attraction", "artwork", "information"].contains($0) }.map { "tourism=\($0)" })
        case .health:
            return amenityCategories.filter { ["hospital", "clinic", "pharmacy", "dentist", "veterinary", "doctors"].contains($0) }.map { "amenity=\($0)" }
        case .education:
            return amenityCategories.filter { ["school", "university", "college", "library", "driving_school", "language_school", "music_school"].contains($0) }.map { "amenity=\($0)" }
        }
    }
}

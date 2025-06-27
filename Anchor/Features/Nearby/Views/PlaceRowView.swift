import SwiftUI
import AnchorKit

struct PlaceRowView: View {
    let place: Place
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Category icon
                Text(categoryIcon)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let categoryGroup = place.categoryGroup {
                        Text(categoryGroup.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let category = place.category {
                        Text(category.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(place.description)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.separator, lineWidth: 0.5)
        )
    }

    private var categoryIcon: String {
        place.icon
    }
}

#Preview {
    VStack {
        PlaceRowView(
            place: Place(
                elementType: .way,
                elementId: 123456,
                name: "Test Climbing Gym",
                latitude: 0,
                longitude: 0,
                tags: ["leisure": "climbing"]
            )
        ) {}

        PlaceRowView(
            place: Place(
                elementType: .node,
                elementId: 789012,
                name: "Test Restaurant",
                latitude: 0,
                longitude: 0,
                tags: ["amenity": "restaurant"]
            )
        ) {}
    }
    .padding()
}

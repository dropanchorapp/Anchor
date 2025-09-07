//
//  PlaceComponents.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 06/07/2025.
//

import SwiftUI
import AnchorKit

// MARK: - Category Filter Button
struct CategoryFilterButton: View {
    let category: PlaceCategorization.CategoryGroup?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let category = category {
                    Text(category.icon)
                        .font(.caption)
                    Text(category.rawValue)
                        .font(.caption)
                        .fontWeight(isSelected ? .semibold : .regular)
                } else {
                    Text("All")
                        .font(.caption)
                        .fontWeight(isSelected ? .semibold : .regular)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.accentColor : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Place Row View
struct PlaceRowView: View {
    let placeWithDistance: AnchorPlaceWithDistance
    let onTap: () -> Void
    
    private var place: Place {
        placeWithDistance.place
    }
    
    private var distance: String {
        placeWithDistance.formattedDistance
    }
    
    private var categoryGroup: PlaceCategorization.CategoryGroup? {
        // Find the first tag that has a category group
        for (tag, value) in place.tags {
            if let group = PlaceCategorization.getCategoryGroup(for: tag, value: value) {
                return group
            }
        }
        return nil
    }
    
    private var displayIcon: String {
        // Use backend icon from search results if available, otherwise use category group icon
        return placeWithDistance.backendIcon ?? categoryGroup?.icon ?? "📍"
    }
    
    private var displayCategory: String? {
        // Use backend category from search results if available, otherwise use category group
        if let backendCategory = placeWithDistance.backendCategory {
            return backendCategory
        }
        return categoryGroup?.rawValue
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Category icon
                Text(displayIcon)
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color(.systemGray6))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(distance)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let displayCategory = displayCategory {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(displayCategory)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("Category Filter Buttons") {
    ScrollView(.horizontal) {
        HStack(spacing: 12) {
            CategoryFilterButton(
                category: nil,
                isSelected: true,
                action: {}
            )
            
            ForEach(PlaceCategorization.CategoryGroup.allCases, id: \.self) { category in
                CategoryFilterButton(
                    category: category,
                    isSelected: false,
                    action: {}
                )
            }
        }
        .padding(.horizontal)
    }
}

#Preview("Place Row") {
    List {
        PlaceRowView(
            placeWithDistance: AnchorPlaceWithDistance(
                place: Place(
                    elementType: .node,
                    elementId: 123,
                    name: "Blue Bottle Coffee",
                    latitude: 37.7749,
                    longitude: -122.4194,
                    tags: ["amenity": "cafe"]
                ),
                distance: 150.0
            ),
            onTap: {}
        )
    }
}
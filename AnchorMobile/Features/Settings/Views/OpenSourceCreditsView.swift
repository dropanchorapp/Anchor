//
//  OpenSourceCreditsView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 04/10/2025.
//

import SwiftUI

struct OpenSourceCreditsView: View {
    var body: some View {
        List {
            // GitHub Repository
            Section {
                Link(destination: URL(string: "https://github.com/dropanchorapp/anchor")!) {
                    HStack {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.title2)
                            .foregroundStyle(.purple)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Anchor on GitHub")
                                .font(.headline)

                            Text("github.com/dropanchorapp/anchor")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Source Code")
            } footer: {
                Text("Anchor is open source and available under the MIT license.")
            }

            // Built With Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    PackageRow(
                        name: "SwiftUI",
                        description: "Apple's declarative UI framework",
                        license: "Apple SDK"
                    )

                    Divider()

                    PackageRow(
                        name: "CoreLocation",
                        description: "Location services framework",
                        license: "Apple SDK"
                    )

                    Divider()

                    PackageRow(
                        name: "SwiftData",
                        description: "Data persistence framework",
                        license: "Apple SDK"
                    )
                }
                .padding(.vertical, 4)
            } header: {
                Text("Apple Frameworks")
            }

            // Third-Party Services
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    PackageRow(
                        name: "OpenStreetMap",
                        description: "Geographic data and place information",
                        license: "ODbL"
                    )

                    Divider()

                    PackageRow(
                        name: "Overpass API",
                        description: "OpenStreetMap query service",
                        license: "AGPL"
                    )

                    Divider()

                    PackageRow(
                        name: "Nominatim",
                        description: "OpenStreetMap search service",
                        license: "GPL 2.0"
                    )

                    Divider()

                    PackageRow(
                        name: "AT Protocol",
                        description: "Decentralized social networking protocol",
                        license: "MIT/Apache 2.0"
                    )

                    Divider()

                    PackageRow(
                        name: "Bluesky",
                        description: "Social network built on AT Protocol",
                        license: "MIT"
                    )
                }
                .padding(.vertical, 4)
            } header: {
                Text("Services & APIs")
            } footer: {
                Text("Special thanks to the open source community and all contributors.")
            }
        }
        .navigationTitle("Open Source")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PackageRow: View {
    let name: String
    let description: String
    let license: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.headline)

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(license)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
    }
}

#Preview {
    NavigationStack {
        OpenSourceCreditsView()
    }
}

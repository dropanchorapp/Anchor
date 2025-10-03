//
//  CheckInComposeComponents.swift
//  AnchorMobile
//
//  UI components for check-in composition view
//

import SwiftUI
import AnchorKit

// MARK: - Place Info Section

struct PlaceInfoSection: View {
    let place: Place
    let displayIcon: String
    let displayCategory: String?

    private var coordinatesText: String {
        String(format: "Latitude: %.4f, Longitude: %.4f", place.latitude, place.longitude)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Check-in Location")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 12) {
                Text(displayIcon)
                    .font(.title)
                    .frame(width: 50, height: 50)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(.headline)
                        .fontWeight(.medium)

                    if let displayCategory = displayCategory {
                        Text(displayCategory)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(coordinatesText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding()
            .background(Color.secondary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - Message Input Section

struct MessageInputSection: View {
    @Binding var message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add a Message")
                .font(.headline)
                .fontWeight(.semibold)

            TextField("What's happening?", text: $message, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }
}

// MARK: - Authentication Prompt Section

struct AuthenticationPromptSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Authentication Required")
                .font(.headline)
                .fontWeight(.semibold)

            Text("You need to sign in to your Bluesky account to post check-ins.")
                .font(.body)
                .foregroundColor(.secondary)

            NavigationLink("Sign In") {
                Text("Authentication View")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Submit Button

struct SubmitButton: View {
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button("Drop Anchor") {
            action()
        }
        .disabled(isDisabled)
        .fontWeight(.semibold)
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    var body: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Dropping anchor...")
                .font(.headline)
                .fontWeight(.medium)
        }
        .padding(30)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Check-In Success View

struct CheckInSuccessView: View {
    let place: Place
    let checkinId: String?
    let userMessage: String?
    let sharedToFollowers: Bool
    let onDismiss: () -> Void

    private var successMessage: String {
        if sharedToFollowers {
            return "Your check-in at \(place.name) has been saved and shared with your followers."
        } else {
            return "Your check-in at \(place.name) has been saved to your personal feed."
        }
    }

    private func shareText(for checkinId: String) -> String {
        if let userMessage = userMessage {
            return "\(userMessage) https://dropanchor.app/checkin/\(checkinId)"
        } else {
            return "Dropped anchor at \(place.name) https://dropanchor.app/checkin/\(checkinId)"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("Anchor Dropped!")
                .font(.title)
                .fontWeight(.bold)

            Text(successMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                if let checkinId = checkinId {
                    ShareLink(
                        item: shareText(for: checkinId),
                        subject: Text("Check-in at \(place.name)")
                    ) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Check-in")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                Button("Done") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
        .presentationDetents([.medium])
    }
}

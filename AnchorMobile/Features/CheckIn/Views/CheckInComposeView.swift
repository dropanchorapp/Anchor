//
//  CheckInComposeView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 06/07/2025.
//

import SwiftUI
import AnchorKit

struct CheckInComposeView: View {
    let place: Place
    @Environment(AuthStore.self) private var authStore
    @Environment(CheckInStore.self) private var checkInStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var message = ""
    @State private var isPosting = false
    @State private var showingSuccess = false
    @State private var error: Error?
    @State private var checkinResult: CheckinResult?
    
    private var categoryGroup: PlaceCategorization.CategoryGroup? {
        place.categoryGroup
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PlaceInfoSection(place: place, categoryGroup: categoryGroup)
                    MessageInputSection(message: $message)
                    
                    if !authStore.isAuthenticated {
                        AuthenticationPromptSection()
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Drop Anchor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CancelButton()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    SubmitButton(
                        isDisabled: !authStore.isAuthenticated || isPosting,
                        action: {
                            Task {
                                await submitCheckIn()
                            }
                        }
                    )
                }
            }
            .overlay {
                if isPosting {
                    LoadingOverlay()
                }
            }
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK") {
                error = nil
            }
        } message: {
            Text(error?.localizedDescription ?? "An error occurred")
        }
        .sheet(isPresented: $showingSuccess) {
            if let result = checkinResult {
                CheckInSuccessView(
                    place: place, 
                    checkinId: result.checkinId,
                    sharedToFollowers: false
                ) {
                    dismiss()
                }
            }
        }
    }
    
    private func submitCheckIn() async {
        guard authStore.isAuthenticated else { return }
        
        isPosting = true
        error = nil
        
        do {
            let result = try await checkInStore.createCheckin(
                place: place,
                customMessage: message.isEmpty ? nil : message
            )
            
            checkinResult = result
            showingSuccess = true
        } catch {
            self.error = error
        }
        
        isPosting = false
    }
}

// MARK: - Component Views

struct PlaceInfoSection: View {
    let place: Place
    let categoryGroup: PlaceCategorization.CategoryGroup?
    
    private var coordinatesText: String {
        String(format: "Latitude: %.4f, Longitude: %.4f", place.latitude, place.longitude)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Check-in Location")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                Text(categoryGroup?.icon ?? "📍")
                    .font(.title)
                    .frame(width: 50, height: 50)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(.headline)
                        .fontWeight(.medium)
                    
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

struct CancelButton: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button("Cancel") {
            dismiss()
        }
    }
}

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

struct CheckInSuccessView: View {
    let place: Place
    let checkinId: String?
    let sharedToFollowers: Bool
    let onDismiss: () -> Void
    
    private var successMessage: String {
        if sharedToFollowers {
            return "Your check-in at \(place.name) has been saved and shared with your followers."
        } else {
            return "Your check-in at \(place.name) has been saved to your personal feed."
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
                        item: "Dropped anchor at \(place.name) https://dropanchor.app/checkin/\(checkinId)",
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

#Preview("Compose View") {
    let authStore = AuthStore(storage: InMemoryCredentialsStorage())
    let place = Place(
        elementType: .node,
        elementId: 12345,
        name: "Test Coffee Shop",
        latitude: 37.7749,
        longitude: -122.4194,
        tags: ["amenity": "cafe"]
    )
    
    CheckInComposeView(place: place)
        .environment(authStore)
        .environment(CheckInStore(authStore: authStore))
}

#Preview("Success View") {
    let place = Place(
        elementType: .node,
        elementId: 12345,
        name: "Test Coffee Shop",
        latitude: 37.7749,
        longitude: -122.4194,
        tags: ["amenity": "cafe"]
    )
    
    CheckInSuccessView(place: place, checkinId: "3lw2aztgeua2o", sharedToFollowers: true) {
        print("Dismissed")
    }
}

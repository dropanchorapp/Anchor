//
//  CheckInComposeView.swift
//  AnchorMobile
//
//  Created by Tijs Teulings on 06/07/2025.
//

import SwiftUI
import AnchorKit

struct CheckInComposeView: View {
    let placeWithDistance: AnchorPlaceWithDistance
    
    private var place: Place {
        placeWithDistance.place
    }
    @Environment(AuthStore.self) private var authStore
    @Environment(CheckInStore.self) private var checkInStore
    @Environment(FeedStore.self) private var feedStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var message = ""
    @State private var isPosting = false
    @State private var showingSuccess = false
    @State private var error: Error?
    @State private var checkinResult: CheckinResult?

    // Image upload state
    @State private var selectedImage: UIImage?
    @State private var processedImageData: Data?
    @State private var imageAltText = ""
    @State private var showImagePicker = false
    @State private var showImageSourceActionSheet = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isProcessingImage = false
    @State private var imageSizeText: String?
    
    private var categoryGroup: PlaceCategorization.CategoryGroup? {
        place.categoryGroup
    }
    
    // Use backend category info when available (from search results)
    private var displayIcon: String {
        return placeWithDistance.backendIcon ?? categoryGroup?.icon ?? "📍"
    }
    
    private var displayCategory: String? {
        if let backendCategory = placeWithDistance.backendCategory {
            return backendCategory
        }
        return categoryGroup?.rawValue
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PlaceInfoSection(place: place, displayIcon: displayIcon, displayCategory: displayCategory)
                    MessageInputSection(message: $message)

                    ImageAttachmentSection(
                        selectedImage: $selectedImage,
                        processedImageData: $processedImageData,
                        imageAltText: $imageAltText,
                        imageSizeText: $imageSizeText,
                        isProcessingImage: $isProcessingImage,
                        showImageSourceActionSheet: $showImageSourceActionSheet
                    )

                    if !authStore.isAuthenticated {
                        AuthenticationPromptSection()
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
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
                    userDid: authStore.credentials?.did,
                    userMessage: message.isEmpty ? nil : message,
                    sharedToFollowers: false
                ) {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(
                image: $selectedImage,
                sourceType: imageSourceType
            )
        }
        .confirmationDialog(
            "Choose Photo Source",
            isPresented: $showImageSourceActionSheet,
            titleVisibility: .visible
        ) {
            Button("Camera") {
                imageSourceType = .camera
                showImagePicker = true
            }
            Button("Photo Library") {
                imageSourceType = .photoLibrary
                showImagePicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .onChange(of: selectedImage) { _, newImage in
            if let newImage = newImage {
                processImage(newImage)
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
                customMessage: message.isEmpty ? nil : message,
                imageData: processedImageData,
                imageAlt: imageAltText.isEmpty ? nil : imageAltText
            )

            checkinResult = result
            showingSuccess = true

            // Refresh feed to show the new check-in
            if let userDid = authStore.credentials?.did {
                _ = try? await feedStore.fetchUserFeed(for: userDid)
            }
        } catch {
            self.error = error
        }

        isPosting = false
    }

    private func processImage(_ image: UIImage) {
        isProcessingImage = true

        Task {
            // Process in background
            let imageData = await Task.detached(priority: .userInitiated) {
                return ImageProcessor.processImageForUpload(image)
            }.value

            await MainActor.run {
                if let imageData = imageData {
                    processedImageData = imageData
                    imageSizeText = ImageProcessor.formatFileSize(imageData.count)
                    isProcessingImage = false
                } else {
                    // Processing failed
                    selectedImage = nil
                    processedImageData = nil
                    imageSizeText = nil
                    isProcessingImage = false
                    error = NSError(
                        domain: "ImageProcessing",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to process image"]
                    )
                }
            }
        }
    }
}

// MARK: - Previews

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

    let placeWithDistance = AnchorPlaceWithDistance(place: place, distance: 150.0)
    CheckInComposeView(placeWithDistance: placeWithDistance)
        .environment(authStore)
        .environment(CheckInStore(authStore: authStore))
        .environment(FeedStore())
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

    CheckInSuccessView(
        place: place,
        checkinId: "3lw2aztgeua2o",
        userDid: "did:plc:example123",
        userMessage: "Great coffee here!",
        sharedToFollowers: true
    ) {
        print("Dismissed")
    }
}

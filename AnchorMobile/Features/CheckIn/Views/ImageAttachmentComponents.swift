//
//  ImageAttachmentComponents.swift
//  AnchorMobile
//
//  Image attachment UI components for check-ins
//

import SwiftUI
import UIKit

// MARK: - Image Attachment Section

struct ImageAttachmentSection: View {
    @Binding var selectedImage: UIImage?
    @Binding var processedImageData: Data?
    @Binding var imageAltText: String
    @Binding var imageSizeText: String?
    @Binding var isProcessingImage: Bool
    @Binding var showImageSourceActionSheet: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Photo (Optional)")
                .font(.headline)
                .fontWeight(.semibold)

            if let selectedImage = selectedImage {
                // Image preview
                VStack(spacing: 12) {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    if isProcessingImage {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Processing image...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if let sizeText = imageSizeText {
                        Text("Size: \(sizeText)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Alt text field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Alt Text (Recommended)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        TextField("Describe the image for accessibility", text: $imageAltText)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button(role: .destructive) {
                        self.selectedImage = nil
                        self.processedImageData = nil
                        self.imageAltText = ""
                        self.imageSizeText = nil
                    } label: {
                        Label("Remove Photo", systemImage: "trash")
                            .font(.callout)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Button {
                    showImageSourceActionSheet = true
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Add Photo")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    var sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

//
//  ImageProcessor.swift
//  AnchorKit
//
//  Image processing utilities for check-in attachments
//  Handles EXIF stripping (preserving orientation), resizing, and compression
//

#if canImport(UIKit)
import UIKit
import ImageIO

/// Utility for processing images before upload
/// - Strips EXIF data while preserving correct orientation
/// - Resizes images to prevent memory issues
/// - Compresses to target file size
public enum ImageProcessor {
    // MARK: - Constants

    /// Maximum file size for uploaded images (5MB)
    public nonisolated(unsafe) static let maxFileSizeBytes = 5 * 1024 * 1024

    /// Maximum dimension for images (prevents memory issues)
    public nonisolated(unsafe) static let maxDimension: CGFloat = 2048

    /// Starting JPEG compression quality
    private static let initialCompressionQuality: CGFloat = 0.8

    /// Minimum JPEG compression quality
    private static let minCompressionQuality: CGFloat = 0.3

    // MARK: - Public Methods

    /// Process image for upload: normalize orientation, strip EXIF, resize, and compress
    /// - Parameter image: Original UIImage from camera or photo library
    /// - Returns: Processed JPEG data ready for upload, or nil if processing fails
    public nonisolated static func processImageForUpload(_ image: UIImage) -> Data? {
        // Step 1: Normalize orientation (fixes rotation from EXIF)
        let orientedImage = normalizeOrientation(image)

        // Step 2: Resize if needed (strips EXIF in the process)
        let resizedImage = resizeIfNeeded(orientedImage)

        // Step 3: Compress to target size
        return compressToTargetSize(resizedImage)
    }

    /// Normalize image orientation by redrawing into bitmap context
    /// This fixes rotation issues from EXIF orientation tag
    /// - Parameter image: Image with potential orientation issues
    /// - Returns: Image with normalized orientation (EXIF stripped)
    public nonisolated static func normalizeOrientation(_ image: UIImage) -> UIImage {
        // If already in .up orientation, no need to process
        if image.imageOrientation == .up {
            return stripEXIFData(from: image)
        }

        // Calculate transform for orientation
        let size = image.size
        let transform = calculateOrientationTransform(for: image.imageOrientation, size: size)

        // Create and configure bitmap context
        guard let cgImage = image.cgImage,
              let context = createBitmapContext(for: cgImage, size: size) else {
            return image
        }

        context.concatenate(transform)

        // Draw image with proper rect
        let drawRect = calculateDrawRect(for: image.imageOrientation, size: size)
        context.draw(cgImage, in: drawRect)

        guard let newCGImage = context.makeImage() else {
            return image
        }

        return UIImage(cgImage: newCGImage)
    }

    /// Strip EXIF data from image by redrawing into new context
    /// - Parameter image: Image with potential EXIF data
    /// - Returns: Image without EXIF data
    public nonisolated static func stripEXIFData(from image: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: image.size))

        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return image
        }

        return newImage
    }

    // MARK: - Private Methods

    /// Calculate orientation transform for image
    private static func calculateOrientationTransform(
        for orientation: UIImage.Orientation,
        size: CGSize
    ) -> CGAffineTransform {
        var transform = CGAffineTransform.identity

        // Set up transform based on orientation
        switch orientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
        default:
            break
        }

        // Handle mirroring
        switch orientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }

        return transform
    }

    /// Create bitmap context for image processing
    private static func createBitmapContext(for cgImage: CGImage, size: CGSize) -> CGContext? {
        guard let colorSpace = cgImage.colorSpace else { return nil }

        return CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: cgImage.bitmapInfo.rawValue
        )
    }

    /// Calculate draw rect based on orientation
    private static func calculateDrawRect(for orientation: UIImage.Orientation, size: CGSize) -> CGRect {
        switch orientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            return CGRect(x: 0, y: 0, width: size.height, height: size.width)
        default:
            return CGRect(x: 0, y: 0, width: size.width, height: size.height)
        }
    }

    /// Resize image if it exceeds maximum dimensions
    /// - Parameter image: Image to potentially resize
    /// - Returns: Resized image or original if within limits
    private static func resizeIfNeeded(_ image: UIImage) -> UIImage {
        let size = image.size

        // Check if resizing is needed
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        let newSize: CGSize

        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        // Render at new size
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: newSize))

        guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return image
        }

        return resizedImage
    }

    /// Compress image to target file size
    /// - Parameter image: Image to compress
    /// - Returns: JPEG data compressed to target size, or nil if compression fails
    private static func compressToTargetSize(_ image: UIImage) -> Data? {
        var quality = initialCompressionQuality
        var imageData = image.jpegData(compressionQuality: quality)

        // Iteratively reduce quality until we're under the target size
        while let data = imageData,
              data.count > maxFileSizeBytes,
              quality > minCompressionQuality {
            quality -= 0.1
            imageData = image.jpegData(compressionQuality: quality)
        }

        // If still too large, try more aggressive resizing
        if let data = imageData, data.count > maxFileSizeBytes {
            let scaleFactor = sqrt(Double(maxFileSizeBytes) / Double(data.count))
            let newSize = CGSize(
                width: image.size.width * scaleFactor,
                height: image.size.height * scaleFactor
            )

            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            defer { UIGraphicsEndImageContext() }

            image.draw(in: CGRect(origin: .zero, size: newSize))

            guard let smallerImage = UIGraphicsGetImageFromCurrentImageContext() else {
                return imageData
            }

            imageData = smallerImage.jpegData(compressionQuality: minCompressionQuality)
        }

        return imageData
    }

    /// Get formatted size string from byte count
    /// - Parameter bytes: Number of bytes
    /// - Returns: Formatted string (e.g., "2.5 MB", "450 KB")
    public nonisolated static func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

#endif

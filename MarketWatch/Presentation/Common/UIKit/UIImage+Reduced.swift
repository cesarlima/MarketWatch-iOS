import ImageIO
import UIKit

extension UIImage {
    /// Creates an image from encoded data (PNG, JPEG...) already shrunk so its longest side is at most
    /// `maxPixelSize` pixels, keeping the aspect ratio. Images smaller than that keep their size.
    ///
    /// Why: a decoded image takes width × height × 4 bytes in memory, whatever the file size. A 250 px icon
    /// shown at 32 pt (96 px on a 3x screen) would waste about 7 times the memory it needs.
    /// `UIImage(data:)` decodes the full image first; this reads the data and decodes straight to the
    /// smaller size, so the full-size bitmap never exists.
    ///
    /// Returns `nil` when the data is not an image.
    static func reduced(from data: Data, maxPixelSize: Int) -> UIImage? {
        // Only reads the file header for now; nothing is decoded or kept yet.
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return nil
        }

        let thumbnailOptions = [
            // Builds the small version from the full image, even if the file carries its own thumbnail.
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            // Applies the photo's orientation, so it isn't shown rotated.
            kCGImageSourceCreateThumbnailWithTransform: true,
            // Decodes right away, when the image is created, instead of later on its first draw.
            kCGImageSourceShouldCacheImmediately: true,
            // Longest side, in pixels.
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

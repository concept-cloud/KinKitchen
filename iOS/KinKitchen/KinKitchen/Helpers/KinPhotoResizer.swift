//
//  KinPhotoResizer.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/16/26.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Turns a picked photo into a JPEG small enough to upload quickly.
///
/// iPhone photos are 12 to 48 megapixels, often HEIC, and can be
/// 5 to 25 MB as JPEG. Uploading that is slow on cellular and can be
/// over a storage bucket's size limit.
nonisolated enum KinPhotoResizer {

    /// Where a photo ends up decides how big it's kept. The sizes and
    /// quality for every photo in the app live here.
    enum Use {
        /// Profile and event photos: only ever shown on a phone.
        /// A few hundred KB.
        case screen
        /// Recipe photos and cookbook covers, which can go in a
        /// printed cookbook. 4096 px is a full page or cover at about
        /// 300 DPI. 1.5 to 3 MB.
        case print

        var maxPixelSize: Int {
            switch self {
            case .screen: 2048
            case .print: 4096
            }
        }

        var quality: Double {
            switch self {
            case .screen: 0.8
            case .print: 0.9
            }
        }
    }

    /// A JPEG no larger than the use's size on its long side, turned
    /// the right way up. Nil if the data isn't an image.
    static func jpegData(
        from data: Data,
        for use: Use = .screen
    ) -> Data? {

        let maxPixelSize = use.maxPixelSize
        let quality = use.quality

        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        // Reads only what it needs, so a 48 MP photo never has to be
        // fully decoded in memory.
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true
        ]

        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }

        CGImageDestinationAddImage(
            destination,
            image,
            [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
        )

        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return output as Data
    }

    /// Same, off the main thread so the screen doesn't freeze.
    static func prepared(_ data: Data, for use: Use = .screen) async -> Data? {
        await Task.detached(priority: .userInitiated) {
            jpegData(from: data, for: use)
        }.value
    }
}

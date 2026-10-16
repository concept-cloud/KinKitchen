//
//  KinPhotoResizerTests.swift
//  KinKitchenTests
//

import Testing
import UIKit
@testable import KinKitchen

struct KinPhotoResizerTests {

    private func photo(width: CGFloat, height: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    private func resized(_ data: Data, for use: KinPhotoResizer.Use) throws -> UIImage {
        let jpeg = try #require(KinPhotoResizer.jpegData(from: data, for: use))
        return try #require(UIImage(data: jpeg))
    }

    @Test func screenPhotosShrinkButPrintPhotosKeepTheirSize() throws {
        let data = try #require(photo(width: 4000, height: 3000).pngData())

        let screen = try resized(data, for: .screen)
        let print = try resized(data, for: .print)

        #expect(max(screen.size.width, screen.size.height) == 2048)
        #expect(max(print.size.width, print.size.height) == 4000)
    }

    @Test func shrinksAPrintPhotoToFullPageSize() throws {
        let data = try #require(photo(width: 6000, height: 8000).jpegData(compressionQuality: 0.5))

        let image = try resized(data, for: .print)

        #expect(image.size.height == 4096)
        #expect(image.size.width == 3072)
    }

    @Test func rejectsDataThatIsNotAnImage() {
        #expect(KinPhotoResizer.jpegData(from: Data("not a photo".utf8)) == nil)
    }
}

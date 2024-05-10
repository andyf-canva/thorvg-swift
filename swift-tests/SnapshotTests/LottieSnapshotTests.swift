import XCTest

import SnapshotTesting

@testable import thorvg_swift

class LottieSnapshotTests: XCTestCase {

    let size = CGSize(width: 1024, height: 1024)
    let contentRect = CGRect(x: 0, y: 0, width: 1024, height: 1024)
    let colorspace = Colorspace.argb

    var lottie: Lottie!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let url = Bundle.module.url(forResource: "test", withExtension: "json")!
        lottie = try Lottie(path: url.path)
    }

    func testRenderFrame_WhenValidBufferAndSize_ReturnsCorrectImageSnapshot() throws {
        var buffer = [UInt32](repeating: 0, count: Int(size.width * size.height))
        let renderer = LottieRenderer(lottie, size: size, buffer: &buffer, stride: Int(size.width), colorspace: colorspace)

        try renderer.render(frameIndex: 0, contentRect: contentRect)

        guard let image = UIImage(buffer: &buffer, size: size, colorspace: colorspace) else {
            XCTFail("Unable to create UIImage from buffer")
            return
        }

        assertSnapshot(matching: image, as: .image)
    }

    func testRenderFrame_WhenDesiredSizeIsLargerThanLottieOriginalSize_ReturnsScaledImageSnapshot() throws {
        let size = CGSize(width: 2048, height: 2048)
        let contentRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        var buffer = [UInt32](repeating: 0, count: Int(size.width * size.height))
        let renderer = LottieRenderer(lottie, size: size, buffer: &buffer, stride: Int(size.width), colorspace: colorspace)

        try renderer.render(frameIndex: 0, contentRect: contentRect)

        guard let image = UIImage(buffer: &buffer, size: size, colorspace: colorspace) else {
            XCTFail("Unable to create UIImage from buffer")
            return
        }

        assertSnapshot(matching: image, as: .image)
    }

    func testRenderFrame_WhenDesiredSizeIsSmallerThanLottieOriginalSize_ReturnsScaledImageSnapshot() throws {
        let size = CGSize(width: 512, height: 512)
        let contentRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        var buffer = [UInt32](repeating: 0, count: Int(size.width * size.height))
        let renderer = LottieRenderer(lottie, size: size, buffer: &buffer, stride: Int(size.width), colorspace: colorspace)

        try renderer.render(frameIndex: 0, contentRect: contentRect)

        guard let image = UIImage(buffer: &buffer, size: size, colorspace: colorspace) else {
            XCTFail("Unable to create UIImage from buffer")
            return
        }

        assertSnapshot(matching: image, as: .image)
    }

    func testRenderFrame_WhenCropped_ReturnsCroppedAndScaledImageSnapshot() throws {
        var buffer = [UInt32](repeating: 0, count: Int(size.width * size.height))
        let renderer = LottieRenderer(lottie, size: size, buffer: &buffer, stride: Int(size.width), colorspace: colorspace)

        let crop = CGRect(x: 0, y: 0, width: 512, height: 512)

        try renderer.render(frameIndex: 0, contentRect: crop)

        guard let image = UIImage(buffer: &buffer, size: size, colorspace: colorspace) else {
            XCTFail("Unable to create UIImage from buffer")
            return
        }

        assertSnapshot(matching: image, as: .image)
    }

    func testRenderFrame_WhenCroppedWithNonUniformRectangle_ReturnsCroppedAndScaledImageSnapshot() throws {
        var buffer = [UInt32](repeating: 0, count: Int(size.width * size.height))
        let renderer = LottieRenderer(lottie, size: size, buffer: &buffer, stride: Int(size.width), colorspace: colorspace)

        let crop = CGRect(x: 0, y: 0, width: 750, height: 1000)

        try renderer.render(frameIndex: 0, contentRect: crop)

        guard let image = UIImage(buffer: &buffer, size: size, colorspace: colorspace) else {
            XCTFail("Unable to create UIImage from buffer")
            return
        }

        assertSnapshot(matching: image, as: .image)
    }

    func testRenderFrame_WhenCenterCropped_ReturnsCroppedAndScaledImageSnapshot() throws {
        var buffer = [UInt32](repeating: 0, count: Int(size.width * size.height))
        let renderer = LottieRenderer(lottie, size: size, buffer: &buffer, stride: Int(size.width), colorspace: colorspace)

        let crop = CGRect(x: 384, y: 384, width: 256, height: 256)

        try renderer.render(frameIndex: 0, contentRect: crop)

        guard let image = UIImage(buffer: &buffer, size: size, colorspace: colorspace) else {
            XCTFail("Unable to create UIImage from buffer")
            return
        }

        assertSnapshot(matching: image, as: .image)
    }

    func testRenderFrame_WhenCenterCroppedAndRotated_ReturnsCroppedScaledAndRotatedImageSnapshot() throws {
        var buffer = [UInt32](repeating: 0, count: Int(size.width * size.height))
        let renderer = LottieRenderer(lottie, size: size, buffer: &buffer, stride: Int(size.width), colorspace: colorspace)

        let crop = CGRect(x: 384, y: 384, width: 256, height: 256)

        try renderer.render(frameIndex: 0, contentRect: crop, rotation: 90)

        guard let image = UIImage(buffer: &buffer, size: size, colorspace: colorspace) else {
            XCTFail("Unable to create UIImage from buffer")
            return
        }

        assertSnapshot(matching: image, as: .image)
    }

    func testRenderFrame_WhenRotated_ReturnsRotatedImageSnapshot() throws {
        var buffer = [UInt32](repeating: 0, count: Int(size.width * size.height))
        let renderer = LottieRenderer(lottie, size: size, buffer: &buffer, stride: Int(size.width), colorspace: colorspace)

        let rotation = 90.0

        try renderer.render(frameIndex: 0, contentRect: contentRect, rotation: rotation)

        guard let image = UIImage(buffer: &buffer, size: size, colorspace: colorspace) else {
            XCTFail("Unable to create UIImage from buffer")
            return
        }

        assertSnapshot(matching: image, as: .image)
    }

    func testRenderFrame_WhenCroppedAndRotated_ReturnsCroppedAndRotatedImageSnapshot() throws {
        var buffer = [UInt32](repeating: 0, count: Int(size.width * size.height))
        let renderer = LottieRenderer(lottie, size: size, buffer: &buffer, stride: Int(size.width), colorspace: colorspace)

        let crop = CGRect(x: 0, y: 0, width: 512, height: 512)
        let rotation = 90.0

        try renderer.render(frameIndex: 0, contentRect: crop, rotation: rotation)

        guard let image = UIImage(buffer: &buffer, size: size, colorspace: colorspace) else {
            XCTFail("Unable to create UIImage from buffer")
            return
        }

        assertSnapshot(matching: image, as: .image)
    }

    func testRenderFrame_WhenScaledCroppedAndRotated_ReturnsScaleCroppedAndRotatedImageSnapshot() throws {
        let size = CGSize(width: 2048, height: 2048)
        let crop = CGRect(x: 0, y: 0, width: 1024, height: 1024)
        let rotation = 90.0

        var buffer = [UInt32](repeating: 0, count: Int(size.width * size.height))
        let renderer = LottieRenderer(lottie, size: size, buffer: &buffer, stride: Int(size.width), colorspace: colorspace)

        try renderer.render(frameIndex: 0, contentRect: crop, rotation: rotation)

        guard let image = UIImage(buffer: &buffer, size: size, colorspace: colorspace) else {
            XCTFail("Unable to create UIImage from buffer")
            return
        }

        assertSnapshot(matching: image, as: .image)
    }

    func testRenderFrame_WhenUsingABGRColorspace_ReturnsImageWithCorrectPixelValues() throws {
        let colorspace = Colorspace.abgr
        var buffer = [UInt32](repeating: 0, count: Int(size.width * size.height))
        let renderer = LottieRenderer(lottie, size: size, buffer: &buffer, stride: Int(size.width), colorspace: colorspace)

        try renderer.render(frameIndex: 0, contentRect: contentRect)

        guard let image = UIImage(buffer: &buffer, size: size, colorspace: colorspace) else {
            XCTFail("Unable to create UIImage from buffer")
            return
        }

        assertSnapshot(matching: image, as: .image)
    }
}

extension UIImage {
    convenience init?(buffer: Buffer, size: CGSize, colorspace: Colorspace) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = colorspace.bitmapInfo.rawValue
        let bitsPerComponent = 8
        let bytesPerRow = Int(size.width) * 4

        guard let context = CGContext(
            data: buffer,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }

        guard let cgImage = context.makeImage() else {
            return nil
        }

        self.init(cgImage: cgImage, scale: 1.0, orientation: .up)
    }
}

extension Colorspace {
    // Note: These bitmap operators are around the wrong way. I think it's a macOS thing.
    var bitmapInfo: CGBitmapInfo {
        switch self {
        case .argb:
            return [.byteOrder32Little, CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)]
        case .abgr:
            return [.byteOrder32Big, CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)]
        }
    }
}

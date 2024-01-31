import XCTest

import SnapshotTesting

@testable import thorvg_swift

class LottieSamplerSnapshotTests: XCTestCase {
    private let testLottieUrl: URL = Bundle.module.url(forResource: "test", withExtension: "json")!
    private let testSize = CGSize(width: 1024, height: 1024)

    func testRenderFrame_WhenGivenValidBufferAndSize_ProducesCorrectImageSnapshot() throws {
        let lottie = try Lottie(path: testLottieUrl.path)
        var buffer = [UInt32](repeating: 0, count: Int(testSize.width * testSize.height))

        try lottie.renderFrame(at: 0, into: &buffer, stride: Int(testSize.width), size: testSize)

        guard let image = UIImage(buffer: &buffer, size: testSize) else {
            XCTFail("Unable to create UIImage from buffer")
            return
        }

        assertSnapshot(matching: image, as: .image)
    }

    func testRenderFrame_WhenDesiredSizeIsLargerThanLottieOriginalSize_ProducesScaledImageSnapshot() throws {
        let size = CGSize(width: 2048, height: 2048)
        let lottie = try Lottie(path: testLottieUrl.path)
        var buffer = [UInt32](repeating: 0, count: Int(size.width * size.height))

        try lottie.renderFrame(at: 0, into: &buffer, stride: Int(size.width), size: size)

        guard let image = UIImage(buffer: &buffer, size: size) else {
            XCTFail("Unable to create UIImage from buffer")
            return
        }

        assertSnapshot(matching: image, as: .image)
    }

    func testRenderFrame_WhenDesiredSizeIsSmallerThanLottieOriginalSize_ProducesScaledImageSnapshot() throws {
        let size = CGSize(width: 512, height: 512)
        let lottie = try Lottie(path: testLottieUrl.path)
        var buffer = [UInt32](repeating: 0, count: Int(size.width * size.height))

        try lottie.renderFrame(at: 0, into: &buffer, stride: Int(size.width), size: size)

        guard let image = UIImage(buffer: &buffer, size: size) else {
            XCTFail("Unable to create UIImage from buffer")
            return
        }

        assertSnapshot(matching: image, as: .image)
    }

    func testRenderFrame_WhenCenterCropped_ProducesCroppedAndScaledImageSnapshot() throws {
        let lottie = try Lottie(path: testLottieUrl.path)
        var buffer = [UInt32](repeating: 0, count: Int(testSize.width * testSize.height))
        let crop = CGRect(x: 384, y: 384, width: 256, height: 256)

        try lottie.renderFrame(at: 0, into: &buffer, stride: Int(testSize.width), size: testSize, crop: crop)

        guard let image = UIImage(buffer: &buffer, size: testSize) else {
            XCTFail("Unable to create UIImage from buffer")
            return
        }

        assertSnapshot(matching: image, as: .image)
    }
}

extension UIImage {
    convenience init?(buffer: Buffer, size: CGSize) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
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

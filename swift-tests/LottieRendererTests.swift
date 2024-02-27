import CoreMedia
import XCTest

@testable import thorvg_swift

final class LottieRendererTests: XCTestCase {

    let lottie: Lottie = {
        let url = Bundle.module.url(forResource: "test", withExtension: "json")!
        return try! Lottie(path: url.path)
    }()

    let size = CGSize(width: 1024, height: 1024)

    func testRender_WithValidFrameIndex_BufferPopulatedWithContent() throws {
        var buffer = [UInt32](repeating: 0, count: Int(size.width * size.height))
        let renderer = LottieRenderer(size: size, buffer: &buffer, stride: Int(size.width))

        try renderer.render(lottie, frameIndex: 0)

        let bufferHasContent = buffer.contains { $0 != 0 }
        XCTAssertTrue(bufferHasContent, "Buffer should have non-zero values after rendering.")
    }

    func testRender_WithAllFrames_Succeeds() throws {
        var buffer = [UInt32](repeating: 0, count: Int(size.width * size.height))
        let renderer = LottieRenderer(size: size, buffer: &buffer, stride: Int(size.width))

        do {
            for index in 0 ..< lottie.numberOfFrames {
                try renderer.render(lottie, frameIndex: index)
            }
        } catch {
            XCTFail("Expected to render all lottie frames successfully, but \(error) error was thrown")
        }
    }

    func testRenderFrame_WithFrameIndexBelowBounds_ThrowsError() throws {
        var buffer = [UInt32](repeating: 0, count: Int(size.width * size.height))
        let renderer = LottieRenderer(size: size, buffer: &buffer, stride: Int(size.width))

        do {
            try renderer.render(lottie, frameIndex: -1)

            XCTFail("Expected frameIndexOutOfRange error to be thrown, but no error was thrown.")
        } catch {
            XCTAssertEqual(error as? ThorVGError, .frameIndexOutOfRange)
        }
    }

    func testRenderFrame_WithFrameIndexAboveBounds_ThrowsError() throws {
        var buffer = [UInt32](repeating: 0, count: Int(size.width * size.height))
        let renderer = LottieRenderer(size: size, buffer: &buffer, stride: Int(size.width))

        do {
            try renderer.render(lottie, frameIndex: 180)

            XCTFail("Expected frameIndexOutOfRange error to be thrown, but no error was thrown.")
        } catch {
            XCTAssertEqual(error as? ThorVGError, .frameIndexOutOfRange)
        }
    }
}

private extension CMTime {
    init(seconds: TimeInterval) {
        self.init(seconds: seconds, preferredTimescale: 600)
    }
}

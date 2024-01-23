import CoreMedia
import XCTest

@testable import thorvg_swift

final class LottieTests: XCTestCase {

    let testLottieUrl = Bundle.module.url(forResource: "test", withExtension: "json")!
    let testSize = CGSize(width: 2048, height: 2048)

    // MARK: Initialiser tests

    func testInit_WithValidPath_ReturnsCorrectNumberOfFrames() throws {
        let lottie = try Lottie(path: testLottieUrl.path, size: testSize)

        XCTAssertEqual(lottie.numberOfFrames, 180)
    }

    func testInit_WithValidPath_ReturnsCorrectDuration() throws {
        let lottie = try Lottie(path: testLottieUrl.path, size: testSize)

        XCTAssertEqual(lottie.duration, CMTime(seconds: 3))
    }

    func testInit_WithValidPath_ReturnsCorrectSize() throws {
        let lottie = try Lottie(path: testLottieUrl.path, size: testSize)

        XCTAssertEqual(lottie.size.height, 2048)
        XCTAssertEqual(lottie.size.width, 2048)
    }

    func testInit_WithValidPath_AndCropped_ReturnsCorrectSize() throws {
        let cropRect = CGRect(x: 0, y: 0, width: 1024, height: 1024)
        let lottie = try Lottie(path: testLottieUrl.path, size: testSize, crop: cropRect)

        XCTAssertEqual(lottie.size.height, 2048)
        XCTAssertEqual(lottie.size.width, 2048)
    }

    func testInit_WithInvalidPath_ThrowsError() {
        do {
            _ = try Lottie(path: "", size: testSize)

            XCTFail("Expected failedToLoadLottieFromPath error to be thrown, but no error was thrown.")
        } catch {
            XCTAssertEqual(error as? LottieError, .failedToLoadLottieFromPath)
        }
    }

    func testInit_WithValidString_Succeeds() throws {
        let animationJson = try NSMutableString(contentsOf: testLottieUrl, encoding: String.Encoding.utf8.rawValue)
        let lottie = try Lottie(string: animationJson as String, size: testSize)

        XCTAssertEqual(lottie.numberOfFrames, 180)
    }

    func testInit_WithInvalidString_ThrowsError() throws {
        do {
            _ = try Lottie(string: "", size: testSize)

            XCTFail("Expected failedToLoadLottieFromString error to be thrown, but no error was thrown.")
        } catch {
            XCTAssertEqual(error as? LottieError, .failedToLoadLottieFromString)
        }
    }

    // MARK: Render tests

    func testRender_WithValidFrameIndex_BufferPopulatedWithContent() throws {
        let lottie = try Lottie(path: testLottieUrl.path, size: testSize)
        var buffer = [UInt32](repeating: 0, count: Int(testSize.width * testSize.height))

        try lottie.render(frameAt: 0, into: &buffer, stride: Int(testSize.width))

        let bufferHasContent = buffer.contains { $0 != 0 }
        XCTAssertTrue(bufferHasContent, "Buffer should have non-zero values after rendering.")
    }

    func testRender_WithValidFrameIndex_ReturnedBufferPopulatedWithContent() throws {
        let lottie = try Lottie(path: testLottieUrl.path, size: testSize)

        let bufferPointer = try lottie.render(frameAt: 0, stride: Int(testSize.width))

        let buffer = UnsafeBufferPointer(start: bufferPointer, count: Int(testSize.width * testSize.height)).map { $0 }

        let bufferHasContent = buffer.contains { $0 != 0 }
        XCTAssertTrue(bufferHasContent, "Buffer should have non-zero values after rendering.")
    }

    func testRender_WithFrameIndexBelowBounds_ThrowsError() throws {
        let lottie = try Lottie(path: testLottieUrl.path, size: testSize)
        var buffer = [UInt32](repeating: 0, count: Int(testSize.width * testSize.height))

        do {
            try lottie.render(frameAt: -1, into: &buffer, stride: Int(testSize.width))

            XCTFail("Expected frameIndexOutOfBounds error to be thrown, but no error was thrown.")
        } catch {
            XCTAssertEqual(error as? LottieError, .frameIndexOutOfBounds)
        }
    }

    func testRender_WithFrameIndexAboveBounds_ThrowsError() throws {
        let lottie = try Lottie(path: testLottieUrl.path, size: testSize)
        var buffer = [UInt32](repeating: 0, count: Int(testSize.width * testSize.height))

        do {
            try lottie.render(frameAt: 180, into: &buffer, stride: Int(testSize.width))

            XCTFail("Expected frameIndexOutOfBounds error to be thrown, but no error was thrown.")
        } catch {
            XCTAssertEqual(error as? LottieError, .frameIndexOutOfBounds)
        }
    }
}

private extension CMTime {
    init(seconds: TimeInterval) {
        self.init(seconds: seconds, preferredTimescale: 600)
    }
}

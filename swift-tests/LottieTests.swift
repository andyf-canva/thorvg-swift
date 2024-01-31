import CoreMedia
import XCTest

@testable import thorvg_swift

final class LottieTests: XCTestCase {

    let testLottieUrl = Bundle.module.url(forResource: "test", withExtension: "json")!
    let testSize = CGSize(width: 1024, height: 1024)

    // MARK: Initialiser tests

    func testInit_WithValidPath_ReturnsCorrectNumberOfFrames() throws {
        let lottie = try Lottie(path: testLottieUrl.path)

        XCTAssertEqual(lottie.numberOfFrames, 180)
    }

    func testInit_WithValidPath_ReturnsCorrectDuration() throws {
        let lottie = try Lottie(path: testLottieUrl.path)

        XCTAssertEqual(lottie.duration, CMTime(seconds: 3))
    }

    func testInit_WithValidPath_ReturnsCorrectSize() throws {
        let lottie = try Lottie(path: testLottieUrl.path)

        XCTAssertEqual(lottie.size, CGSize(width: 1024, height: 1024))
    }

    func testInit_WithInvalidPath_ThrowsError() {
        do {
            _ = try Lottie(path: "")

            XCTFail("Expected failedToLoadLottieFromPath error to be thrown, but no error was thrown.")
        } catch {
            XCTAssertEqual(error as? LottieError, .failedToLoadLottieFromPath)
        }
    }

    func testInit_WithValidString_Succeeds() throws {
        let animationJson = try NSMutableString(contentsOf: testLottieUrl, encoding: String.Encoding.utf8.rawValue) as String
        let lottie = try Lottie(string: animationJson)

        XCTAssertEqual(lottie.numberOfFrames, 180)
    }

    func testInit_WithInvalidString_ThrowsError() throws {
        do {
            _ = try Lottie(string: "")

            XCTFail("Expected failedToLoadLottieFromString error to be thrown, but no error was thrown.")
        } catch {
            XCTAssertEqual(error as? LottieError, .failedToLoadLottieFromString)
        }
    }

    // MARK: Render Frame tests

    func testRenderFrame_WithValidFrameIndex_BufferPopulatedWithContent() throws {
        let lottie = try Lottie(path: testLottieUrl.path)
        var buffer = [UInt32](repeating: 0, count: Int(testSize.width * testSize.height))

        try lottie.renderFrame(at: 0, into: &buffer, stride: Int(testSize.width), size: testSize)

        let bufferHasContent = buffer.contains { $0 != 0 }
        XCTAssertTrue(bufferHasContent, "Buffer should have non-zero values after rendering.")
    }

    func testRender_WithAllAvailableFramesOfLottie_Succeeds() throws {
        let lottie = try Lottie(path: testLottieUrl.path)
        var buffer = [UInt32](repeating: 0, count: Int(testSize.width * testSize.height))

        do {
            for index in 0 ..< lottie.numberOfFrames {
                try lottie.renderFrame(at: index, into: &buffer, stride: Int(testSize.width), size: testSize)
            }
        } catch {
            XCTFail("Expected to render all lottie frames successfully, but \(error) error was thrown")
        }
    }

    func testRenderFrame_WithFrameIndexBelowBounds_ThrowsError() throws {
        let lottie = try Lottie(path: testLottieUrl.path)
        var buffer = [UInt32](repeating: 0, count: Int(testSize.width * testSize.height))

        do {
            try lottie.renderFrame(at: -1, into: &buffer, stride: Int(testSize.width), size: testSize)

            XCTFail("Expected frameIndexOutOfBounds error to be thrown, but no error was thrown.")
        } catch {
            XCTAssertEqual(error as? LottieError, .frameIndexOutOfBounds)
        }
    }

    func testRenderFrame_WithFrameIndexAboveBounds_ThrowsError() throws {
        let lottie = try Lottie(path: testLottieUrl.path)
        var buffer = [UInt32](repeating: 0, count: Int(testSize.width * testSize.height))

        do {
            try lottie.renderFrame(at: 180, into: &buffer, stride: Int(testSize.width), size: testSize)

            XCTFail("Expected frameIndexOutOfBounds error to be thrown, but no error was thrown.")
        } catch {
            XCTAssertEqual(error as? LottieError, .frameIndexOutOfBounds)
        }
    }

    func testRenderFrame_WithCropLargerThanSize_ThrowsError() throws {
        let lottie = try Lottie(path: testLottieUrl.path)
        var buffer = [UInt32](repeating: 0, count: Int(testSize.width * testSize.height))
        let crop = CGRect(x: 0, y: 0, width: 2048, height: 2048)

        do {
            try lottie.renderFrame(at: 0, into: &buffer, stride: Int(testSize.width), size: testSize, crop: crop)

            XCTFail("Expected croppingRectangleOutsideOfFrameBounds error to be thrown, but no error was thrown.")
        } catch {
            XCTAssertEqual(error as? LottieError, .croppingRectangleOutsideOfFrameBounds)
        }
    }
}

private extension CMTime {
    init(seconds: TimeInterval) {
        self.init(seconds: seconds, preferredTimescale: 600)
    }
}

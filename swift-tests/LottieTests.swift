import CoreMedia
import XCTest

@testable import thorvg_swift

final class LottieTests: XCTestCase {

    let testLottieUrl = Bundle.module.url(forResource: "test", withExtension: "json")!

    func testInit_WithValidJson_ReturnsNumberOfFrames() {
        let lottie = Lottie(source: testLottieUrl.path)

        XCTAssertEqual(lottie.numberOfFrames, 180)
    }

    func testInit_WithValidJson_ReturnsDuration() {
        let lottie = Lottie(source: testLottieUrl.path)

        XCTAssertEqual(lottie.duration, CMTime(seconds: 3))
    }

    func testInit_WithValidJson_ReturnsSize() {
        let size = CGSize(width: 2048, height: 2048)
        let lottie = Lottie(source: testLottieUrl.path)

//        XCTAssertEqual(lottie.size.height, 2048)
//        XCTAssertEqual(lottie.size.width, 2048)
    }

    func test_newAPI() {
        let source = testLottieUrl.path


        let size = CGSize(width: 2048, height: 2048)
        let stride = size.width
        var buffer = [UInt32](repeating: 0, count: Int(size.width * size.height))

        let lottie = Lottie(source: source)

        let crop = CGRect(x: 1024, y: 1024, width: 1024, height: 1024)

        for index in 0 ..< lottie.numberOfFrames {
            lottie.render(
                frameAt: index,
                into: &buffer,
                stride: Int(stride),
                size: size,
                crop: crop
            )
        }
    }

    func oldImplemetation() throws {
        let animation = Animation(path: "andy.json")

        let sampler = AnimationFrameSampler(animation: animation)

        let size = CGSize(width: 2048, height: 2048)
        let stride = size.width
        var buffer = [UInt32](repeating: 0, count: Int(size.width * size.height))

        let renderer = Renderer(buffer: &buffer, stride: UInt32(stride), width: UInt32(size.width), height: UInt32(size.height))

        renderer.pushAnimationOntoCanvas(animation)

        while sampler.hasMoreSamples() {
            renderer.clear()
            try sampler.nextSample()

            renderer.render(animation: animation)
        }
    }

    // Things to test
    // cropping
    // size is correct
    // initialisers - path versus data string
}

private extension CMTime {
    init(seconds: TimeInterval) {
        self.init(seconds: seconds, preferredTimescale: 600)
    }
}

private func writeBufferDataToImage(frame: Int, buffer: inout [UInt32], width: UInt32, height: UInt32) {

    let widthInt = Int(width)
    let heightInt = Int(height)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
    let bitsPerComponent = 8
    let bytesPerRow = widthInt * 4

    // Create a CGContext using the buffer
    guard let context = CGContext(data: &buffer,
                                  width: widthInt,
                                  height: heightInt,
                                  bitsPerComponent: bitsPerComponent,
                                  bytesPerRow: bytesPerRow,
                                  space: colorSpace,
                                  bitmapInfo: bitmapInfo) else {
        print("Unable to create CGContext")
        return
    }

    // Create a CGImage from the context
    guard let cgImage = context.makeImage() else {
        print("Unable to create CGImage from CGContext")
        return
    }

    // Convert the CGImage to a UIImage
    let image = UIImage(cgImage: cgImage)

    // Get PNG data from the UIImage
    guard let pngData = image.pngData() else {
        print("Unable to get PNG data from UIImage")
        return
    }

    // Define the file name and the directory to save the image
    let fileName = "frame_\(frame).png"
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    print(documentsDirectory)
    let fileURL = documentsDirectory.appendingPathComponent(fileName)

    do {
        // Write the PNG data to a file
        try pngData.write(to: fileURL, options: .atomic)
        print("Image saved to \(fileURL)")
    } catch {
        print("Error saving image: \(error)")
    }
}

// file:///Users/andyf/Library/Developer/CoreSimulator/Devices/74BC5A93-5EA4-4C18-82F6-298028503AA3/data/Documents

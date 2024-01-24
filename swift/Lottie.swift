import CoreGraphics
import CoreMedia

import thorvg

/// Represents errors that can occur while working with Lottie animations.
public enum LottieError: Error {
    case failedToLoadLottieFromString
    case failedToLoadLottieFromPath
    case failedToDrawLottieFrameOntoCanvas
    case failedToInitialiseTvgEngine
    case frameIndexOutOfBounds
}

/// Shorthand for the buffer type used to represent image pixel data.
public typealias Buffer = UnsafeMutablePointer<UInt32>

/// A class representing a Lottie animation, providing functionalities to load and render Lottie frames.
public class Lottie {
    /// The number of frames in the Lottie animation.
    public let numberOfFrames: Int

    /// The duration of the Lottie animation.
    public let duration: CMTime

    /// The size of the Lottie animation.
    public let size: CGSize

    /// An optional cropping rectangle to crop the animation.
    /// If set, the animation will be cropped to the specified rectangle before rendering.
    public let crop: CGRect?

    private let animation: OpaquePointer?
    private var canvas: OpaquePointer? = nil

    /// Initializes a new Lottie instance from a file path.
    /// - Parameters:
    ///   - path: The file path of the Lottie animation.
    ///   - size: The size to render the Lottie animation.
    ///   - crop: An optional cropping rectangle to crop the animation before rendering.
    public convenience init(path: String, size: CGSize, crop: CGRect? = nil) throws {
        let animation = tvg_animation_new()
        let picture = tvg_animation_get_picture(animation)

        guard tvg_picture_load(picture, path) == TVG_RESULT_SUCCESS else {
            throw LottieError.failedToLoadLottieFromPath
        }

        try self.init(animation: animation, size: size, crop: crop)
    }

    /// Initializes a new Lottie instance from a string representing the animation.
    /// - Parameters:
    ///   - string: The string representing the Lottie animation.
    ///   - size: The size to render the Lottie animation.
    ///   - crop: An optional cropping rectangle to crop the animation before rendering.
    public convenience init(string: String, size: CGSize, crop: CGRect? = nil) throws {
        let animation = tvg_animation_new()
        let picture = tvg_animation_get_picture(animation)

        guard let cString = string.cString(using: .utf8),
              tvg_picture_load_data(picture, cString, UInt32(cString.count), "lottie", "", false) == TVG_RESULT_SUCCESS
        else {
            throw LottieError.failedToLoadLottieFromString
        }

        try self.init(animation: animation, size: size, crop: crop)
    }

    private init(animation: OpaquePointer?, size: CGSize, crop: CGRect?) throws {
        var numberOfFrames: Float = 0
        tvg_animation_get_total_frame(animation, &numberOfFrames)

        var duration: Float = 0
        tvg_animation_get_duration(animation, &duration)

        let picture = tvg_animation_get_picture(animation)
        tvg_picture_set_size(picture, Float(size.width), Float(size.height))

        if let crop {
            let cropShape = tvg_shape_new()
            tvg_shape_append_rect(
                cropShape,
                Float(crop.origin.x),
                Float(crop.origin.y),
                Float(crop.width),
                Float(crop.height), 0, 0
            )
            tvg_paint_set_composite_method(picture, cropShape, TVG_COMPOSITE_METHOD_CLIP_PATH)
        }

        self.animation = animation
        self.numberOfFrames = Int(numberOfFrames)
        self.duration = CMTime(seconds: Double(duration), preferredTimescale: 600)
        self.size = size
        self.crop = crop
    }

    /// Renders a Lottie frame into a new buffer.
    /// - Parameters:
    ///   - index: The index of the frame to render.
    ///   - stride: The stride of the buffer.
    /// - Returns: A buffer containing the rendered Lottie frame.
    func render(frameAt index: Int, stride: Int) throws -> Buffer {
        let bufferSize = Int(size.width * size.height)
        let buffer = Buffer.allocate(capacity: bufferSize)
        buffer.initialize(repeating: 0, count: bufferSize)

        try render(frameAt: index, into: buffer, stride: stride)
        return buffer
    }

    /// Renders a Lottie frame into an existing buffer.
    /// - Parameters:
    ///   - index: The index of the frame to render.
    ///   - buffer: The buffer to render the frame into.
    ///   - stride: The stride of the buffer.
    func render(frameAt index: Int, into buffer: Buffer, stride: Int) throws {
        guard index < numberOfFrames, index >= 0 else {
            throw LottieError.frameIndexOutOfBounds
        }

        if canvas == nil {
            canvas = try createCanvas(with: buffer, stride: stride, size: size)
        }

        tvg_canvas_clear(canvas, false, true)
        tvg_animation_set_frame(animation, Float(index))

        let picture = tvg_animation_get_picture(animation)
        tvg_canvas_update_paint(canvas, picture)

        guard tvg_canvas_draw(canvas) == TVG_RESULT_SUCCESS else {
            throw LottieError.failedToDrawLottieFrameOntoCanvas
        }

        tvg_canvas_sync(canvas)
    }

    private func createCanvas(with buffer: Buffer, stride: Int, size: CGSize) throws -> OpaquePointer! {
        guard tvg_engine_init(TVG_ENGINE_SW, 4) == TVG_RESULT_SUCCESS else {
            throw LottieError.failedToInitialiseTvgEngine
        }

        let canvas = tvg_swcanvas_create()
        tvg_swcanvas_set_target(canvas, buffer, UInt32(stride), UInt32(size.width), UInt32(size.height), TVG_COLORSPACE_ARGB8888)

        let picture = tvg_animation_get_picture(animation)
        tvg_canvas_push(canvas, picture)

        return canvas
    }

    deinit {
        tvg_animation_del(animation)
        tvg_canvas_destroy(canvas)
    }
}

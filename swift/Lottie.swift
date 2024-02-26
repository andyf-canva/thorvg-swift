import CoreGraphics
import CoreMedia

import thorvg

/// Errors that can occur while working with Lottie animations.
public enum LottieError: Error {
    case failedToLoadLottieFromString
    case failedToLoadLottieFromPath
    case failedToDrawLottieFrameOntoCanvas
    case failedToPushToCanvas
    case failedToInitializeTVGEngine
    case frameIndexOutOfBounds
    case croppingRectangleOutsideOfFrameBounds
}

/// Shorthand for the buffer type used to represent image pixel data.
public typealias Buffer = UnsafeMutablePointer<UInt32>

/// Object used to load and render Lottie frames.
public class Lottie {
    /// The number of frames in the Lottie animation.
    public let numberOfFrames: Int

    /// The duration of the Lottie animation.
    public let duration: CMTime

    /// The original size of the Lottie animation.
    public let size: CGSize

    /// The internal animation object, used for manipulating and rendering frames.
    private let animation: OpaquePointer?

    /// The internal canvas used for rendering the animation frames, allowing reuse across renders.
    private var canvas: OpaquePointer? = nil

    /// Initializes a new Lottie instance from a file path.
    /// - Parameters:
    ///   - path: The file path of the Lottie animation.
    public convenience init(path: String) throws {
        let animation = tvg_animation_new()
        let picture = tvg_animation_get_picture(animation)

        guard tvg_picture_load(picture, path) == TVG_RESULT_SUCCESS else {
            throw LottieError.failedToLoadLottieFromPath
        }

        try self.init(animation: animation)
    }

    /// Initializes a new Lottie instance from a string representing the animation.
    /// - Parameters:
    ///   - string: The string representing the Lottie animation.
    public convenience init(string: String) throws {
        let animation = tvg_animation_new()
        let picture = tvg_animation_get_picture(animation)

        guard let cString = string.cString(using: .utf8),
              tvg_picture_load_data(picture, cString, UInt32(cString.count), "lottie", false) == TVG_RESULT_SUCCESS
        else {
            throw LottieError.failedToLoadLottieFromString
        }

        try self.init(animation: animation)
    }

    /// Initializes the Lottie instance with frame count and duration extracted from the animation pointer.
    private init(animation: OpaquePointer?) throws {
        var numberOfFrames: Float = 0
        tvg_animation_get_total_frame(animation, &numberOfFrames)

        var duration: Float = 0
        tvg_animation_get_duration(animation, &duration)

        var width: Float = 0
        var height: Float = 0
        let picture = tvg_animation_get_picture(animation)
        tvg_picture_get_size(picture, &width, &height)

        self.animation = animation
        self.numberOfFrames = Int(numberOfFrames)
        self.duration = CMTime(seconds: Double(duration), preferredTimescale: 600)
        self.size = CGSize(width: Double(width), height: Double(height))
    }

    /// Renders a Lottie frame into a buffer.
    /// - Parameters:
    ///   - index: The index of the frame to render.
    ///   - buffer: The buffer to render the frame into.
    ///   - stride: The stride of the buffer.
    ///   - size: The desired size of the rendered frame.
    ///   - crop: Optional rectangle to crop the rendered frame. If provided, the cropped area is scaled and positioned to fit the specified size while preserving its aspect ratio.
    public func renderFrame(at index: Int, into buffer: Buffer, stride: Int, size: CGSize, crop: CGRect? = nil) throws {
        guard index < numberOfFrames, index >= 0 else {
            throw LottieError.frameIndexOutOfBounds
        }

        if canvas == nil {
            canvas = try createCanvas(with: buffer, stride: stride, size: size)
        }

        try prepareCanvasForRendering(frameIndex: index, size: size, crop: crop)
        try renderCanvas()
    }

    /// Creates a new canvas for rendering, initializing the TVG engine and setting the target buffer.
    private func createCanvas(with buffer: Buffer, stride: Int, size: CGSize) throws -> OpaquePointer? {
        guard tvg_engine_init(TVG_ENGINE_SW, UInt32(ProcessInfo.processInfo.activeProcessorCount)) == TVG_RESULT_SUCCESS else {
            throw LottieError.failedToInitializeTVGEngine
        }

        let canvas = tvg_swcanvas_create()
        tvg_swcanvas_set_target(canvas, buffer, UInt32(stride), UInt32(size.width), UInt32(size.height), TVG_COLORSPACE_ARGB8888)
        tvg_swcanvas_set_mempool(canvas, TVG_MEMPOOL_POLICY_DEFAULT)

        let picture = tvg_animation_get_picture(animation)
        guard tvg_canvas_push(canvas, picture) == TVG_RESULT_SUCCESS else {
            throw LottieError.failedToPushToCanvas
        }

        return canvas
    }

    /// Prepares the canvas for rendering by setting the frame, adjusting the picture size, and optionally applying a crop.
    private func prepareCanvasForRendering(frameIndex index: Int, size: CGSize, crop: CGRect?) throws {
        tvg_animation_set_frame(animation, Float(index))

        let picture = tvg_animation_get_picture(animation)
        tvg_picture_set_size(picture, Float(size.width), Float(size.height))

        if let crop {
            try applyCropping(crop, to: picture, relativeTo: size)
        }

        tvg_canvas_update_paint(canvas, picture)
    }

    /// Applies cropping to the Lottie animation by resizing and translating the picture to fit within a specified cropping rectangle, relative to a given size.
    /// Note: The function ensures that the cropped area is scaled and positioned correctly to fit within the specified size, maintaining the aspect ratio of the cropped area.
    private func applyCropping(_ crop: CGRect, to picture: OpaquePointer?, relativeTo size: CGSize) throws {
        guard crop.width <= size.width, crop.height <= size.height else {
            throw LottieError.croppingRectangleOutsideOfFrameBounds
        }

        // Calculate the uniform scale factor to fit the cropped area within the specified size.
        let uniformScale = Float(min(size.width / crop.width, size.height / crop.height))
        tvg_paint_scale(picture, uniformScale)

        // Calculate the position to translate the picture after scaling.
        let translateX = -Float(crop.origin.x) * uniformScale
        let translateY = -Float(crop.origin.y) * uniformScale
        tvg_paint_translate(picture, translateX, translateY)

        // Define the cropping shape based on the scaled and translated dimensions.
        let cropShape = tvg_shape_new()
        tvg_shape_append_rect(
            cropShape,
            0,
            0,
            Float(size.width),
            Float(size.height),
            0,
            0
        )

        // Apply the cropping shape as a clipping path to the picture.
        tvg_paint_set_composite_method(picture, cropShape, TVG_COMPOSITE_METHOD_CLIP_PATH)
    }

    /// Renders the prepared content of the canvas onto the actual canvas.
    private func renderCanvas() throws {
        tvg_canvas_clear(canvas, false)

        guard tvg_canvas_draw(canvas) == TVG_RESULT_SUCCESS else {
            throw LottieError.failedToDrawLottieFrameOntoCanvas
        }

        tvg_canvas_sync(canvas)
    }

    deinit {
        tvg_canvas_destroy(canvas)
        tvg_animation_del(animation)
        tvg_engine_term(TVG_ENGINE_SW)
    }
}

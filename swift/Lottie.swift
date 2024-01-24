import CoreGraphics
import CoreMedia

import thorvg

/// Errors that can occur while working with Lottie animations.
public enum LottieError: Error {
    case failedToLoadLottieFromString
    case failedToLoadLottieFromPath
    case failedToDrawLottieFrameOntoCanvas
    case failedToInitialiseTvgEngine
    case frameIndexOutOfBounds
}

/// Shorthand for the buffer type used to represent image pixel data.
public typealias Buffer = UnsafeMutablePointer<UInt32>

/// Shorthand for a pointer to an internal Lottie animation object
private typealias Animation = OpaquePointer

/// Shorthand for a pointer to an internal rendering canvas
private typealias Canvas = OpaquePointer

/// Object used to load and render Lottie frames.
public class Lottie {
    /// The number of frames in the Lottie animation.
    public let numberOfFrames: Int

    /// The duration of the Lottie animation.
    public let duration: CMTime

    /// The Lottie animation, used for manipulating and rendering frames.
    private let animation: Animation?

    /// The canvas used for rendering the animation frames, allowing reuse across renders.
    private var canvas: Canvas? = nil

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
              tvg_picture_load_data(picture, cString, UInt32(cString.count), "lottie", "", false) == TVG_RESULT_SUCCESS
        else {
            throw LottieError.failedToLoadLottieFromString
        }

        try self.init(animation: animation)
    }

    /// Initializes the Lottie instance with frame count and duration extracted from the animation pointer.
    private init(animation: Animation?) throws {
        var numberOfFrames: Float = 0
        tvg_animation_get_total_frame(animation, &numberOfFrames)

        var duration: Float = 0
        tvg_animation_get_duration(animation, &duration)

        self.animation = animation
        self.numberOfFrames = Int(numberOfFrames)
        self.duration = CMTime(seconds: Double(duration), preferredTimescale: 600)
    }

    /// Renders a Lottie frame into a buffer.
    /// - Parameters:
    ///   - index: The index of the frame to render.
    ///   - buffer: The buffer to render the frame into.
    ///   - stride: The stride of the buffer.
    ///   - size: The desired size of the rendered frame.
    ///   - crop: Optional rectangle to crop the rendered frame.
    public func render(frameAt index: Int, into buffer: Buffer, stride: Int, size: CGSize, crop: CGRect? = nil) throws {
        guard index < numberOfFrames, index >= 0 else {
            throw LottieError.frameIndexOutOfBounds
        }

        if canvas == nil {
            canvas = try createCanvas(with: buffer, stride: stride, size: size)
        }

        prepareCanvasForRendering(frameIndex: index, size: size, crop: crop)
        try renderCanvas()
    }

    /// Creates a new canvas for rendering, initializing the TVG engine and setting the target buffer.
    private func createCanvas(with buffer: Buffer, stride: Int, size: CGSize) throws -> Canvas? {
        guard tvg_engine_init(TVG_ENGINE_SW, 4) == TVG_RESULT_SUCCESS else {
            throw LottieError.failedToInitialiseTvgEngine
        }

        let canvas = tvg_swcanvas_create()
        tvg_swcanvas_set_target(canvas, buffer, UInt32(stride), UInt32(size.width), UInt32(size.height), TVG_COLORSPACE_ARGB8888)

        let picture = tvg_animation_get_picture(animation)
        tvg_canvas_push(canvas, picture)

        return canvas
    }

    /// Prepares the canvas for rendering by setting the frame, adjusting the picture size, and optionally applying a crop.
    private func prepareCanvasForRendering(frameIndex index: Int, size: CGSize, crop: CGRect?) {
        tvg_canvas_clear(canvas, false, true)
        tvg_animation_set_frame(animation, Float(index))

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

        tvg_canvas_update_paint(canvas, picture)
    }

    /// Renders the prepared content of the canvas onto the actual canvas.
    private func renderCanvas() throws {
        guard tvg_canvas_draw(canvas) == TVG_RESULT_SUCCESS else {
            throw LottieError.failedToDrawLottieFrameOntoCanvas
        }

        tvg_canvas_sync(canvas)
    }

    deinit {
        tvg_animation_del(animation)
        tvg_canvas_destroy(canvas)
    }
}

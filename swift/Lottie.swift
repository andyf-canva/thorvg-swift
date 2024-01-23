import CoreGraphics
import CoreMedia

import thorvg

public typealias Buffer = UnsafeMutablePointer<UInt32>

public class Lottie {
    let numberOfFrames: Int
    let duration: CMTime

    private let animation: OpaquePointer?
    private var canvas: OpaquePointer? = nil

    // TODO: Need to separate initialisers based on path/string data.
    init(source: String) {
        let animation = tvg_animation_new()
        let picture = tvg_animation_get_picture(animation)

        tvg_picture_load(picture, source) // TODO: Need error handling here.

        var numberOfFrames: Float = 0
        tvg_animation_get_total_frame(animation, &numberOfFrames)

        var duration: Float = 0
        tvg_animation_get_duration(animation, &duration)

        self.animation = animation
        self.numberOfFrames = Int(numberOfFrames)
        self.duration = CMTime(seconds: Double(duration), preferredTimescale: 600) // TODO: Why is our preferred timescale 600?
    }


    /// Renders a Lottie frame, creating a new buffer at runtime.
    func render(frameAt index: Int, stride: Int, size: CGSize, crop: CGRect? = nil) -> Buffer {
        let bufferSize = Int(size.width * size.height)
        let buffer = UnsafeMutablePointer<UInt32>.allocate(capacity: bufferSize)
        buffer.initialize(repeating: 0, count: bufferSize)

        render(frameAt: index, into: buffer, stride: stride, size: size, crop: crop)

        return buffer
    }

    /// Renders a Lottie frame into a buffer.
    func render(frameAt index: Int, into buffer: Buffer, stride: Int, size: CGSize, crop: CGRect? = nil) {
        if (canvas == nil) {
            // Initialise the engine and canvas
            tvg_engine_init(TVG_ENGINE_SW, 4) // TODO: What do we do with the thread count...
            let canvas = tvg_swcanvas_create()
            tvg_swcanvas_set_target(canvas, buffer, UInt32(stride), UInt32(size.width), UInt32(size.height), TVG_COLORSPACE_ARGB8888)

            // Begin preprocessing
            let picture = tvg_animation_get_picture(animation)
            tvg_canvas_push(canvas, picture)

            self.canvas = canvas
        }

        tvg_canvas_clear(canvas, false, true)

        tvg_animation_set_frame(animation, Float(index))

        let picture = tvg_animation_get_picture(animation)

        if let crop {
            cropped(to: crop)
        }
        tvg_picture_set_size(picture, Float(size.width), Float(size.height))

        tvg_canvas_update_paint(canvas, picture)
        tvg_canvas_draw(canvas)
        tvg_canvas_sync(canvas)
    }

    private func cropped(to rect: CGRect) {
        let picture = tvg_animation_get_picture(animation)

        // Create a cropping shape
        let cropShape = tvg_shape_new()
        tvg_shape_append_rect(cropShape, Float(rect.origin.x), Float(rect.origin.y), Float(rect.width), Float(rect.height), 0, 0)

        // Apply the shape as a clip path
        tvg_paint_set_composite_method(picture, cropShape, TVG_COMPOSITE_METHOD_CLIP_PATH)
    }

    deinit {
        tvg_animation_del(animation)
        tvg_canvas_destroy(canvas)
    }

}

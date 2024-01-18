import thorvg

// TODO: Do we name this canvas???
/// Coordinates rendering frames.
public struct Renderer {

    private var canvas: OpaquePointer?

    public init(
        buffer: inout [UInt32],
        stride: UInt32,
        width: UInt32,
        height: UInt32 // TODO: Do these needs to be Ints?
    ) {
        // TODO: Can we run this on the OpenGL renderer?
        // TODO: Do we need to do anything with the threads? Is 4 ok? Can we pull that into a config
        // Initialize a SW engine
        tvg_engine_init(TVG_ENGINE_SW, 4)

        let canvas = tvg_swcanvas_create()

        // TODO: Do we need to handle colorspaces better?
        // TODO: And can we set this target after loading the Lottie into an animation?
        // TODO: Be careful of stride (3rd parameter)
        // Setup the canvas target
        tvg_swcanvas_set_target(canvas, &buffer, stride, width, height, TVG_COLORSPACE_ARGB8888)

        self.canvas = canvas
    }


    // Needs to be called before trying to render anything. - Preprocessing step
    public func pushToCanvas(animation: Animation) {
        let picture = tvg_animation_get_picture(animation.animation)
        tvg_canvas_push(canvas, picture)
    }

    // Renders the animation into the buffer (with its current frame)
    public func render(animation: Animation) {
        // Update the picture to be redrawn
        let picture = tvg_animation_get_picture(animation.animation)
        // TODO: Do additional processing - scaling, cropping etc.
        tvg_canvas_update_paint(canvas, picture)

        // Draw to the canvas
        tvg_canvas_draw(canvas)

        // Sync the canvas
        tvg_canvas_sync(canvas)
    }

    public func clear() {
        // Flush the buffer - do this once we've got the image. At the start of each render pass?
        // Note: second param is false to not remove the paint objects. Third param resets the buffer between renders.
        tvg_canvas_clear(canvas, false, true)
    }

}

import thorvg

public class Animation {

    let animation: OpaquePointer? // TODO: Maybe this name isn't correct.
    let duration: Float // TODO: CMTime
    let numberOfFrames: Int

    public init(
        path: String // TODO: We can also make multiple initialisers to make it easier (not just a string path, maybe even Data?)
    ) {
        // Generate an animation
        let animation = tvg_animation_new()

        // Acquire a picture which is associated with the animation
        let picture = tvg_animation_get_picture(animation)

        // Load an animation file
        tvg_picture_load(picture, path)

        // Figure out the animation duration time in seconds
        var duration: Float = 0
        tvg_animation_get_duration(animation, &duration)

        var numberOfFrames: Float = 0
        tvg_animation_get_total_frame(animation, &numberOfFrames)

        self.animation = animation
        self.duration = duration
        self.numberOfFrames = Int(numberOfFrames)
    }

    deinit {
        // TODO: Should do something here.
    }
}

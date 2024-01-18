import thorvg

public class AnimationFrameSampler {
    // TODO: Is this nice sitting here?
    public enum Error: Swift.Error {
        case noMoreSamplesAvailable
    }

    let animation: Animation

    var nextFrameIndex: Int = 0

    public init(
        animation: Animation
    ) {
        self.animation = animation
    }

    public func hasMoreSamples() -> Bool {
        return nextFrameIndex <= animation.numberOfFrames
    }

    // TODO: Should this return something?
    public func nextSample() throws {
        guard hasMoreSamples() else {
            throw Error.noMoreSamplesAvailable
        }

        tvg_animation_set_frame(animation.animation, Float(nextFrameIndex))
        nextFrameIndex += 1
    }

    public func reset() {
        nextFrameIndex = 0
    }
}

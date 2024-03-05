import CoreGraphics

import thorvg

/// Shorthand alias for the buffer type, representing image pixel data in a mutable pointer to UInt32.
public typealias Buffer = UnsafeMutablePointer<UInt32>

/// Object responsible for rendering a Lottie animation using ThorVG.
public class LottieRenderer {
    private let lottie: Lottie
    private let engine: Engine
    private let canvas: Canvas

    /// Initializes the LottieRenderer with a specific Lottie object, engine, size, buffer, and stride.
    /// - Parameters:
    ///   - lottie: The `Lottie` object containing the animation to render.
    ///   - engine: An optional `Engine` object to use. If not provided, the default engine configuration is used.
    ///   - size: The size of the rendering canvas. This size determines the final size of the rendered Lottie content.
    ///   - buffer: A buffer to hold the rendered pixel data.
    ///   - stride: The number of bytes in a row of the buffer.
    public init(
        _ lottie: Lottie,
        engine: Engine = .default,
        size: CGSize,
        buffer: Buffer,
        stride: Int
    ) {
        self.lottie = lottie
        self.engine = engine
        self.canvas = Canvas(size: size, buffer: buffer, stride: stride)

        let picture = lottie.animation.getPicture()
        canvas.push(picture: picture)
    }

    /// Renders a specific frame of the Lottie animation using a specified area of the content, applying optional rotation.
    /// - Parameters:
    ///   - frameIndex: Index of the frame in the animation.
    ///   - contentRect: Specifies the area of the content to be rendered. This rectangle defines the portion of the animation that should be visible in the final rendered frame, scaled to fit the canvas size.
    ///   - rotation: Rotation angle in degrees to apply to the renderered frame.
    public func render(
        frameIndex: Int,
        contentRect: CGRect,
        rotation: Double = 0.0
    ) throws {
        guard frameIndex < lottie.numberOfFrames, frameIndex >= 0 else {
            throw ThorVGError.frameIndexOutOfRange
        }

        lottie.animation.setFrame(frameIndex)

        let picture = lottie.animation.getPicture()
        picture.resize(canvas.size)
        picture.resetTransform()

        let radians = rotation * .pi / 180.0
        picture.apply(transform: CGAffineTransform(rotationAngle: radians))
        picture.stretchToFit(contentRect)

        canvas.clear()
        canvas.update(picture: picture)
        try canvas.draw()
    }
}

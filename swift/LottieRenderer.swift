import CoreGraphics

import thorvg

/// Shorthand alias for the buffer type, representing image pixel data in a mutable pointer to UInt32.
public typealias Buffer = UnsafeMutablePointer<UInt32>

/// Object responsible for rendering Lottie animations using ThorVG.
public class LottieRenderer {
    private let canvas: Canvas
    private let engine: Engine

    /// Initializes the Lottie renderer, setting up the canvas.
    /// - Parameters:
    ///   - engine: An optional `Engine` object to use. If not provided, the default engine configuration is used.
    ///   - size: The size of the canvas on which to render.
    ///   - buffer: A buffer to hold the rendered pixel data.
    ///   - stride: The number of bytes in a row of the buffer.
    public init(
        engine: Engine = .default,
        size: CGSize,
        buffer: Buffer,
        stride: Int
    ) {
        self.engine = engine
        self.canvas = Canvas(size: size, buffer: buffer, stride: stride)
    }

    /// Renders a specific frame of a Lottie animation, with optional cropping and rotation.
    /// - Parameters:
    ///   - lottie: The `Lottie` object containing the animation to render.
    ///   - frameIndex: The index of the frame to render.
    ///   - crop: An optional `CGRect` to crop the rendered frame.
    ///   - rotation: An optional rotation angle in degrees.
    public func render(
        _ lottie: Lottie,
        frameIndex: Int,
        crop: CGRect? = nil,
        rotation: Double? = nil
    ) throws {
        guard frameIndex < lottie.numberOfFrames, frameIndex >= 0 else {
            throw ThorVGError.frameIndexOutOfRange
        }

        lottie.animation.setFrame(frameIndex)

        let picture = lottie.animation.getPicture()
        picture.setSize(canvas.size)
        picture.setTransform(.identity)

        if let crop {
            picture.crop(crop)
        }

        if let rotation {
            picture.rotateAboutCenter(rotation)
        }

        if canvas.isEmpty {
            try canvas.push(picture: picture)
        }

        canvas.clear()
        canvas.update(picture: picture)
        try canvas.draw()
    }

    deinit {
        canvas.destroy()
    }
}

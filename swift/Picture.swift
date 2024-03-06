import CoreGraphics

import thorvg

/// A Swift wrapper for ThorVG's Picture, facilitating picture manipulation.
class Picture {
    /// Supported MIME types for loading picture data.
    enum MimeType: String {
        case svg = "svg"
        case lottie = "lottie"
        case jpg = "jpg"
        case jpeg = "jpeg"
        case svgxml = "svg+xml"
        case png = "png"
    }

    /// Pointer to the underlying ThorVG picture object.
    let pointer: OpaquePointer

    /// Initializes a new Picture instance with an empty ThorVG picture object.
    convenience init() {
        let pointer: OpaquePointer = tvg_picture_new()
        self.init(pointer: pointer)
    }

    /// Initializes a Picture instance from an existing ThorVG picture pointer.
    init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    /// Loads a picture from a given file path.
    func load(fromPath path: String) throws {
        guard tvg_picture_load(pointer, path) == TVG_RESULT_SUCCESS else {
            throw ThorVGError.failedToLoadFromPath
        }
    }

    /// Loads a picture from a given data string.
    ///
    /// Use the `mimeType` to indicate the data format for correct parsing.
    func load(fromString string: String, mimeType: MimeType) throws {
        guard let cString = string.cString(using: .utf8),
              tvg_picture_load_data(pointer, cString, UInt32(cString.count), mimeType.rawValue, false) == TVG_RESULT_SUCCESS
        else {
            throw ThorVGError.failedToLoadFromDataString
        }
    }

    /// Resizes the picture content to the given size.
    func resize(_ size: CGSize) {
        tvg_picture_set_size(pointer, Float(size.width), Float(size.height))
    }

    /// Retrieves the size of the picture.
    private func getSize() -> CGSize {
        var width: Float = 0
        var height: Float = 0
        tvg_picture_get_size(pointer, &width, &height)
        return CGSize(width: Double(width), height: Double(height))
    }

    /// Applies a transformation matrix to the picture, with an optional anchor point for rotation and scaling.
    ///
    /// Note: the anchorPoint defaults to (0.5, 0.5), which is the center of the picture.
    func apply(transform: CGAffineTransform, anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5)) {
        let size = getSize()

        let pivotPoint = CGPoint(
            x: size.width * anchorPoint.x,
            y: size.height * anchorPoint.y
        )

        let transform = getTransform()
            .concatenating(CGAffineTransform(translationX: -pivotPoint.x, y: -pivotPoint.y))
            .concatenating(transform)
            .concatenating(CGAffineTransform(translationX: pivotPoint.x, y: pivotPoint.y))

        setTransform(transform)
    }

    /// Resets the picture's transform matrix to the identity.
    func resetTransform() {
        setTransform(.identity)
    }

    /// Retrieves the current transform applied to the picture.
    private func getTransform() -> CGAffineTransform {
        var matrix = Tvg_Matrix()
        tvg_paint_get_transform(pointer, &matrix)

        return CGAffineTransform(
            CGFloat(matrix.e11), CGFloat(matrix.e21), CGFloat(matrix.e12),
            CGFloat(matrix.e22), CGFloat(matrix.e13), CGFloat(matrix.e23)
        )
    }

    /// Applies a new transform to the picture.
    private func setTransform(_ transform: CGAffineTransform) {
        var matrix = Tvg_Matrix(
            e11: Float(transform.a), e12: Float(transform.c), e13: Float(transform.tx),
            e21: Float(transform.b), e22: Float(transform.d), e23: Float(transform.ty),
            e31: 0, e32: 0, e33: 1
        )

        tvg_paint_set_transform(pointer, &matrix)
    }

    /// Stretches the picture to a fit inside a specified rectangle.
    ///
    /// This behaviour is akin to a "stretch-to-fit" resizing as the picture's original aspect ratio is not preserved.
    func stretchToFit(_ rect: CGRect) {
        // Calculate the scale ratio of the picture size versus the rectangle.
        let size = getSize()
        let xRatio = size.width / rect.width
        let yRatio = size.height / rect.height
        
        // Scale the size of the picture relative to that ratio.
        apply(transform: CGAffineTransform(scaleX: xRatio, y: yRatio), anchorPoint: CGPoint(x: 0, y: 0))

        // Translate the picture to the origin of the content rectangle.
        let x = rect.minX * xRatio
        let y = rect.minY * yRatio
        apply(transform: CGAffineTransform(translationX: -x, y: -y))
    }
}

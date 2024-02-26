import CoreGraphics

import thorvg

/// A Swift wrapper for ThorVG's Picture, facilitating picture manipulation.
class Picture {
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

    /// Loads a picture from a given string, typically containing SVG or Lottie data.
    ///
    /// Use the `mimeType` to indicate the data format to ThorVG for correct parsing and rendering.
    func load(fromString string: String, mimeType: String) throws {
        guard let cString = string.cString(using: .utf8),
              tvg_picture_load_data(pointer, cString, UInt32(cString.count), mimeType, false) == TVG_RESULT_SUCCESS
        else {
            throw ThorVGError.failedToLoadFromString
        }
    }

    /// Retrieves the size of the picture.
    func getSize() -> CGSize {
        var width: Float = 0
        var height: Float = 0
        tvg_picture_get_size(pointer, &width, &height)
        return CGSize(width: Double(width), height: Double(height))
    }

    /// Sets the size of the picture.
    func setSize(_ size: CGSize) {
        tvg_picture_set_size(pointer, Float(size.width), Float(size.height))
    }

    /// Retrieves the current transform applied to the picture.
    func getTransform() -> CGAffineTransform {
        var matrix = Tvg_Matrix()
        tvg_paint_get_transform(pointer, &matrix)

        return CGAffineTransform(
            CGFloat(matrix.e11), CGFloat(matrix.e21), CGFloat(matrix.e12),
            CGFloat(matrix.e22), CGFloat(matrix.e13), CGFloat(matrix.e23)
        )
    }

    /// Applies a new transform to the picture.
    func setTransform(_ transform: CGAffineTransform) {
        var matrix = Tvg_Matrix(
            e11: Float(transform.a), e12: Float(transform.c), e13: Float(transform.tx),
            e21: Float(transform.b), e22: Float(transform.d), e23: Float(transform.ty),
            e31: 0, e32: 0, e33: 1
        )

        tvg_paint_set_transform(pointer, &matrix)
    }

    /// Rotates the picture about its center point.
    ///
    /// Note: We need to set the transform manually here because ThorVG's
    /// default transformation behaviour rotates about the origin (not the center)
    /// which is by default, the top-left of the picture.
    func rotateAboutCenter(_ degrees: Double) {
        let size = getSize()
        let cx = size.width / 2
        let cy = size.height / 2

        let radians = degrees * .pi / 180.0

        var transform = getTransform()
        transform = transform
            .translatedBy(x: cx, y: cy)
            .rotated(by: radians)
            .translatedBy(x: -cx, y: -cy)
        setTransform(transform)
    }

    /// Crops the picture to a specified rectangle, maintaining its perceived size.
    ///
    /// Note: We "crop" the picture by scaling it relative to it's original size.
    /// This means that we maintain the same perceived size of the picture before and after cropping.
    func crop(_ crop: CGRect) {
        // Get rid of the unneeded content.
        let cropShape = tvg_shape_new()
        tvg_shape_append_rect(
            cropShape,
            Float(crop.minX),
            Float(crop.minY),
            Float(crop.width),
            Float(crop.height),
            0,
            0
        )
        tvg_paint_set_composite_method(cropShape, pointer, TVG_COMPOSITE_METHOD_CLIP_PATH)

        // Calculate the scale ratio of the picture size versus the crop rectangle.
        let size = getSize()
        let xRatio = size.width / crop.width
        let yRatio = size.height / crop.height

        // Scale the size of the picture relative to that ratio.
        let width = size.width * xRatio
        let height = size.height * yRatio
        setSize(CGSize(width: width, height: height))

        // Translate the picture back to the origin of the crop rectangle after scaling.
        let x = crop.minX * xRatio
        let y = crop.minY * yRatio

        var transform = getTransform()
        transform = transform.translatedBy(x: -x, y: -y)
        setTransform(transform)
    }
}

import thorvg

/// Specifiies the methods of combining the 8-bit color channels into 32-bit color.
public enum Colorspace {
    /// The channels are joined in the order: alpha, blue, green, red. Colors are alpha-premultiplied. (a << 24 | b << 16 | g << 8 | r)
    case abgr
    /// The channels are joined in the order: alpha, red, green, blue. Colors are alpha-premultiplied. (a << 24 | r << 16 | g << 8 | b)
    case argb
    /// The channels are joined in the order: alpha, blue, green, red. Colors are un-alpha-premultiplied.
    case abgrs
    /// The channels are joined in the order: alpha, red, green, blue. Colors are un-alpha-premultiplied.
    case argbs
}

extension Colorspace {
    /// Provides the corresponding `Tvg_Colorspace` value for a `Colorspace` instance.
    var tvgColorspace: Tvg_Colorspace {
        switch self {
        case .abgr:
            return TVG_COLORSPACE_ABGR8888
        case .argb:
            return TVG_COLORSPACE_ARGB8888
        case .abgrs:
            return TVG_COLORSPACE_ABGR8888S
        case .argbs:
            return TVG_COLORSPACE_ARGB8888S
        }
    }
}

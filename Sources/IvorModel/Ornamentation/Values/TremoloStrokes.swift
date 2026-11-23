// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

/// The total subdivision of a measured tremolo, as a number of strokes from `1` through `8`.
///
/// A tremolo with `n` strokes divides its note into notes of a whole note divided by 2^(`n` + 2):
/// one stroke is eighths, two are sixteenths, three are thirty-seconds. The count includes the flags or
/// beams of the written note, which MusicXML’s mark count excludes.
public struct TremoloStrokes {

    // MARK: Public Initializers

    /// Creates a stroke count from an unsigned integer value, returning `nil` if the value is
    /// out of range.
    ///
    /// - Parameter uintValue:  An unsigned integer from `1` through `8`.
    public init?(uintValue: UInt) {
        guard Self.isValid(uintValue)
        else { return nil }

        self.uintValue = uintValue
    }

    // MARK: Public Instance Properties

    /// The unsigned integer value of this stroke count, from `1` through `8`.
    public let uintValue: UInt
}

// MARK: -

extension TremoloStrokes {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the given unsigned integer is a valid
    /// stroke count.
    ///
    /// - Parameter uintValue:  The unsigned integer to validate.
    ///
    /// - Returns:  `true` if `uintValue` is from `1` through `8`; otherwise, `false`.
    public static func isValid(_ uintValue: UInt) -> Bool {
        (1...8).contains(uintValue)
    }
}

// MARK: - UIntRepresentable

extension TremoloStrokes: UIntRepresentable {
}

// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

/// The number that joins tones into one rolled chord, as an unsigned integer of at least `1`.
///
/// Tones anywhere in a work that share an attack and an arpeggio group are one roll, so a roll across
/// both hands of a piano, written in two parts, plays as one gesture.
public struct ArpeggioGroup {

    // MARK: Public Initializers

    /// Creates an arpeggio group from an unsigned integer value, returning `nil` if the value is
    /// out of range.
    ///
    /// - Parameter uintValue:  An unsigned integer at least `1`.
    public init?(uintValue: UInt) {
        guard Self.isValid(uintValue)
        else { return nil }

        self.uintValue = uintValue
    }

    // MARK: Public Instance Properties

    /// The unsigned integer value of this arpeggio group, at least `1`.
    public let uintValue: UInt
}

// MARK: -

extension ArpeggioGroup {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the given unsigned integer is a valid
    /// arpeggio group.
    ///
    /// - Parameter uintValue:  The unsigned integer to validate.
    ///
    /// - Returns:  `true` if `uintValue` is at least `1`; otherwise, `false`.
    public static func isValid(_ uintValue: UInt) -> Bool {
        uintValue >= 1
    }
}

// MARK: - UIntRepresentable

extension ArpeggioGroup: UIntRepresentable {
}

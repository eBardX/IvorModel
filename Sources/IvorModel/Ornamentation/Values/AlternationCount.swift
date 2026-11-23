// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

/// How many times an ornament sounds its partner, as an unsigned integer of at least `1`.
///
/// A mordent sounds its partner once; a short trill played as one alternation has a count of `1`
/// too. A count is one way to give an ornament’s extent (see ``OrnamentExtent``).
public struct AlternationCount {

    // MARK: Public Initializers

    /// Creates an alternation count from an unsigned integer value, returning `nil` if the value is
    /// out of range.
    ///
    /// - Parameter uintValue:  An unsigned integer at least `1`.
    public init?(uintValue: UInt) {
        guard Self.isValid(uintValue)
        else { return nil }

        self.uintValue = uintValue
    }

    // MARK: Public Instance Properties

    /// The unsigned integer value of this alternation count, at least `1`.
    public let uintValue: UInt
}

// MARK: -

extension AlternationCount {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the given unsigned integer is a valid
    /// alternation count.
    ///
    /// - Parameter uintValue:  The unsigned integer to validate.
    ///
    /// - Returns:  `true` if `uintValue` is at least `1`; otherwise, `false`.
    public static func isValid(_ uintValue: UInt) -> Bool {
        uintValue >= 1
    }
}

// MARK: - UIntRepresentable

extension AlternationCount: UIntRepresentable {
}

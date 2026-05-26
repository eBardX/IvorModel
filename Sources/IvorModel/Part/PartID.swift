// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

/// A one-based part ID represented as a positive integer.
public struct PartID: IntRepresentable {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the given integer is a valid part ID.
    ///
    /// - Parameter intValue:   The integer to validate.
    ///
    /// - Returns:  `true` if `intValue` is greater than zero; otherwise, `false`.
    public static func isValid(_ intValue: Int) -> Bool {
        intValue > 0
    }

    // MARK: Public Initializers

    /// Creates a part ID from an integer value, returning `nil` if the value is not positive.
    ///
    /// - Parameter intValue:   A positive one-based part number.
    public init?(intValue: Int) {
        guard Self.isValid(intValue)
        else { return nil }

        self.intValue = intValue
    }

    // MARK: Public Instance Properties

    /// The one-based integer value of this part ID.
    public let intValue: Int
}

// MARK: - (conversion)

extension PartID {

    // MARK: Public Initializers

    /// Creates a part ID from a zero-based index, returning `nil` if the index is negative.
    ///
    /// - Parameter index:  A zero-based part index.
    public init?(index: Int) {
        self.init(intValue: index + 1)
    }

    // MARK: Public Instance Properties

    /// The zero-based index corresponding to this part ID.
    public var index: Int {
        intValue - 1
    }
}

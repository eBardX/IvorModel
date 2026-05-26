// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

/// A stereo pan position represented as a rational number in the range `[-1, 1]`.
public struct Pan: NumberRepresentable {

    // MARK: Public Type Properties

    /// The fully left pan position (`-1`).
    public static let left = Self(-1)

    /// The center pan position (`0`).
    public static let center = Self(0)

    /// The fully right pan position (`1`).
    public static let right = Self(1)

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the given number is a valid
    /// pan position.
    ///
    /// - Parameter numberValue:    The number to validate.
    ///
    /// - Returns:  `true` if `numberValue` is rational and in the range `[-1,
    ///             1]`; otherwise, `false`.
    public static func isValid(_ numberValue: Number) -> Bool {
        numberValue.isRational && (-1...1) ~= numberValue
    }

    // MARK: Public Initializers

    /// Creates a pan position from a number value, returning `nil` if the value is
    /// out of range.
    ///
    /// - Parameter numberValue:    A rational number in the range `[-1, 1]`.
    public init?(numberValue: Number) {
        guard Self.isValid(numberValue)
        else { return nil }

        self.numberValue = numberValue
    }

    // MARK: Public Instance Properties

    /// The numeric value of this pan position, in the range `[-1, 1]`.
    public let numberValue: Number
}

// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

/// A dynamic level represented as a rational number in the range `[0, 1]`.
public struct Dynamic: NumberRepresentable {

    // MARK: Public Type Properties

    /// The fortissississimo dynamic level (`1`).
    public static let ffff = Self(Number(numerator: 10, denominator: 10))

    /// The fortississimo dynamic level (`9/10`).
    public static let fff = Self(Number(numerator: 9, denominator: 10))

    /// The fortissimo dynamic level (`8/10`).
    public static let ff = Self(Number(numerator: 8, denominator: 10))

    /// The forte dynamic level (`7/10`).
    public static let f = Self(Number(numerator: 7, denominator: 10))

    /// The mezzo-forte dynamic level (`6/10`).
    public static let mf = Self(Number(numerator: 6, denominator: 10))

    /// The mezzo-piano dynamic level (`5/10`).
    public static let mp = Self(Number(numerator: 5, denominator: 10))

    /// The piano dynamic level (`4/10`).
    public static let p = Self(Number(numerator: 4, denominator: 10))

    /// The pianissimo dynamic level (`3/10`).
    public static let pp = Self(Number(numerator: 3, denominator: 10))

    /// The pianississimo dynamic level (`2/10`).
    public static let ppp = Self(Number(numerator: 2, denominator: 10))

    /// The pianissississimo dynamic level (`1/10`).
    public static let pppp = Self(Number(numerator: 1, denominator: 10))

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the given number is a valid dynamic level.
    ///
    /// - Parameter numberValue:    The number to validate.
    ///
    /// - Returns:  `true` if `numberValue` is rational and in the range `[0, 1]`; otherwise, `false`.
    public static func isValid(_ numberValue: Number) -> Bool {
        numberValue.isRational && (0...1) ~= numberValue
    }

    // MARK: Public Initializers

    /// Creates a dynamic level from a number value, returning `nil` if the value is out of range.
    ///
    /// - Parameter numberValue:    A rational number in the range `[0, 1]`.
    public init?(numberValue: Number) {
        guard Self.isValid(numberValue)
        else { return nil }

        self.numberValue = numberValue
    }

    // MARK: Public Instance Properties

    /// The numeric value of this dynamic level, in the range `[0, 1]`.
    public let numberValue: Number
}

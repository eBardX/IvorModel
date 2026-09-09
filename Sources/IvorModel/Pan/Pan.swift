// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

private import Foundation

/// A stereo pan position represented as a rational number in the range `[-1, 1]`.
public struct Pan {

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

    /// Creates a pan position by parsing its plain string representation, returning `nil` if the
    /// string cannot be parsed or is out of range.
    ///
    /// - Parameter plain:  The plain string representation of the pan position (as produced by
    ///                     `plain`).
    public init?(plain: String) {
        guard let numberValue = try? Self.plainParseStrategy.parse(plain)
        else { return nil }

        self.init(numberValue: numberValue)
    }

    // MARK: Public Instance Properties

    /// The numeric value of this pan position, in the range `[-1, 1]`.
    public let numberValue: Number

    /// The plain string representation of this pan position.
    public var plain: String {
        Self.plainFormatStyle.format(numberValue)
    }
}

// MARK: -

extension Pan {

    // MARK: Public Type Properties

    /// The center pan position (`0`).
    public static let center = Self(0)

    /// The fully left pan position (`-1`).
    public static let left = Self(-1)

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

    // MARK: Private Type Properties

    private static let plainFormatStyle = Number.FormatStyle(locale: plainLocale)
        .decimalPrecision(0...6)
        .fractionDisplay(strategy: .simple(alwaysShowDenominator: false))
        .grouping(false)

    private static let plainLocale = Locale(identifier: "en_US_POSIX")

    private static let plainParseStrategy = plainFormatStyle.parseStrategy
}

// MARK: - NumberRepresentable

extension Pan: NumberRepresentable {
}

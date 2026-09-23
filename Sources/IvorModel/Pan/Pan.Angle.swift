// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

private import Foundation

extension Pan {

    // MARK: Public Nested Types

    /// An angle, in degrees, that wraps into the half-open range `(-180, 180]`.
    ///
    /// Any finite value is a valid representation of an angle: a value outside
    /// the canonical range is silently wrapped into it, so `190` and `-170`
    /// denote the same angle. Consequently, each angle has exactly one stored
    /// representation, and `==` compares angles, not the values they were
    /// created from.
    ///
    /// Addition and subtraction wrap the same way. In particular, `b - a` is
    /// always the signed *shortest* rotation from `a` to `b`, with an exact
    /// half-turn resolving to `180` — that is, clockwise when viewed from
    /// above.
    ///
    /// - Note: The `Comparable` conformance orders angles by their stored
    ///         value. It is suitable for sorting, but does not say which of two
    ///         directions is further clockwise.
    public struct Angle {

        // MARK: Public Initializers

        /// Creates an angle from a number value, wrapping it into the range
        /// `(-180, 180]`, or returning `nil` if the value is not finite.
        ///
        /// - Parameter numberValue:    A finite rational number of degrees.
        public init?(numberValue: Number) {
            guard Self.isValid(numberValue)
            else { return nil }

            self.numberValue = Self._wrapped(numberValue)
        }

        /// Creates an angle by parsing its plain string representation,
        /// returning `nil` if the string cannot be parsed or is not finite.
        ///
        /// - Parameter plain:  The plain string representation of the angle
        ///                     (as produced by `plain`).
        public init?(plain: String) {
            guard let numberValue = try? Self.plainParseStrategy.parse(plain)
            else { return nil }

            self.init(numberValue: numberValue)
        }

        // MARK: Public Instance Properties

        /// The number of degrees in this angle, in the range `(-180, 180]`.
        public let numberValue: Number

        /// The plain string representation of this angle.
        public var plain: String {
            Self.plainFormatStyle.format(numberValue)
        }
    }
}

// MARK: -

extension Pan.Angle {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the given number is a valid
    /// angle.
    ///
    /// - Parameter numberValue:    The number to validate.
    ///
    /// - Returns:  `true` if `numberValue` is rational (that is, finite);
    ///             otherwise, `false`. Values outside `(-180, 180]` are valid
    ///             and are wrapped on creation.
    public static func isValid(_ numberValue: Number) -> Bool {
        numberValue.isRational
    }

    /// Returns the sum of two angles, wrapped into the range `(-180, 180]`.
    ///
    /// - Parameter lhs:    The first angle.
    /// - Parameter rhs:    The second angle.
    ///
    /// - Returns:  The wrapped sum.
    public static func + (lhs: Self,
                          rhs: Self) -> Self {
        Self(lhs.numberValue + rhs.numberValue)
    }

    /// Returns the negation of an angle, wrapped into the range `(-180, 180]`.
    ///
    /// - Parameter angle:  The angle to negate.
    ///
    /// - Returns:  The wrapped negation. Negating `180` yields `180`.
    public static prefix func - (angle: Self) -> Self {
        Self(-angle.numberValue)
    }

    /// Returns the signed shortest rotation from one angle to another.
    ///
    /// - Parameter lhs:    The angle rotated to.
    /// - Parameter rhs:    The angle rotated from.
    ///
    /// - Returns:  The wrapped difference, in the range `(-180, 180]`.
    public static func - (lhs: Self,
                          rhs: Self) -> Self {
        Self(lhs.numberValue - rhs.numberValue)
    }

    // MARK: Private Type Properties

    private static let plainFormatStyle = Number.FormatStyle(locale: plainLocale)
        .decimalPrecision(0...6)
        .fractionDisplay(strategy: .simple(alwaysShowDenominator: false))
        .grouping(false)

    private static let plainLocale = Locale(identifier: "en_US_POSIX")

    private static let plainParseStrategy = plainFormatStyle.parseStrategy

    // MARK: Private Type Methods

    private static func _wrapped(_ degrees: Number) -> Number {
        let result = degrees - 360 * ceiling((degrees - 180) / 360)

        //
        // Exact values land in `(-180, 180]` by construction; the guard only
        // catches an inexact value that rounding nudged onto `-180`.
        //
        return result > -180 ? result : result + 360
    }
}

// MARK: - NumberRepresentable

extension Pan.Angle: NumberRepresentable {
}

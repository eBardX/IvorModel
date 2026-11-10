// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

private import Foundation

extension Pedal {

    // MARK: Public Nested Types

    /// How far a pedal is down, represented as a rational number in the range `[0, 1]`.
    ///
    /// `0` is all the way up (``up``) and `1` all the way down (``down``). Values in between
    /// describe a partly lowered pedal, such as a half-pedaled damper; a pedal counts as down
    /// (``isDown``) from `1/2`.
    public struct Level {

        // MARK: Public Initializers

        /// Creates a pedal level from a number value, returning `nil` if the value is out of
        /// range.
        ///
        /// - Parameter numberValue:    A rational number in the range `[0, 1]`.
        public init?(numberValue: Number) {
            guard Self.isValid(numberValue)
            else { return nil }

            self.numberValue = numberValue
        }

        /// Creates a pedal level by parsing its plain string representation, returning `nil` if
        /// the string cannot be parsed or is out of range.
        ///
        /// - Parameter plain:  The plain string representation of the pedal level (as produced
        ///                     by ``plain``): `down`, `up`, or a number such as `64/127`.
        public init?(plain: String) {
            switch plain {
            case Self.downPlain:
                self = .down

            case Self.upPlain:
                self = .up

            default:
                guard let numberValue = try? Self.plainParseStrategy.parse(plain)
                else { return nil }

                self.init(numberValue: numberValue)
            }
        }

        // MARK: Public Instance Properties

        /// The numeric value of this pedal level, in the range `[0, 1]`.
        public let numberValue: Number
    }
}

// MARK: -

extension Pedal.Level {

    // MARK: Public Type Properties

    /// The level of a pedal all the way down (`1`).
    public static let down = Self(Number(numerator: 1,
                                         denominator: 1))

    /// The level of a pedal all the way up (`0`).
    public static let up = Self(Number(numerator: 0,
                                       denominator: 1))

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the given number is a valid pedal level.
    ///
    /// - Parameter numberValue:    The number to validate.
    ///
    /// - Returns:  `true` if `numberValue` is rational and in the range `[0, 1]`; otherwise, `false`.
    public static func isValid(_ numberValue: Number) -> Bool {
        numberValue.isRational && (0...1) ~= numberValue
    }

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether this pedal level counts as down: at least `1/2`.
    public var isDown: Bool {
        numberValue >= Self.downThreshold
    }

    /// The plain string representation of this pedal level: `down` for ``down``, `up` for
    /// ``up``, and otherwise its number, such as `64/127`.
    public var plain: String {
        switch self {
        case .down:
            Self.downPlain

        case .up:
            Self.upPlain

        default:
            Self.plainFormatStyle.format(numberValue)
        }
    }

    // MARK: Private Type Properties

    private static let downPlain = "down"
    private static let downThreshold = Number(numerator: 1,
                                              denominator: 2)

    private static let plainFormatStyle = Number.FormatStyle(locale: plainLocale)
        .decimalPrecision(0...6)
        .fractionDisplay(strategy: .simple(alwaysShowDenominator: false))
        .grouping(false)

    private static let plainLocale = Locale(identifier: "en_US_POSIX")

    private static let plainParseStrategy = plainFormatStyle.parseStrategy

    private static let upPlain = "up"
}

// MARK: - NumberRepresentable

extension Pedal.Level: NumberRepresentable {
}

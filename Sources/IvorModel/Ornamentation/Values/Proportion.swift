// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

/// A share of a note, as a rational number greater than `0` and at most `1`.
///
/// Executions and interpretation rules give amounts of time as proportions wherever they can, because a
/// share of a note survives every transform and time-basis conversion unchanged: how much of the main
/// note a grace figure takes, how much of the note an ornament fills, or how much of the shortest tone
/// an arpeggio spreads over.
public struct Proportion {

    // MARK: Public Initializers

    /// Creates a proportion from a number value, returning `nil` if the value is out of
    /// range.
    ///
    /// - Parameter numberValue:    A rational number greater than `0` and at most `1`.
    public init?(numberValue: Number) {
        guard Self.isValid(numberValue)
        else { return nil }

        self.numberValue = numberValue
    }

    // MARK: Public Instance Properties

    /// The numeric value of this proportion, greater than `0` and at most `1`.
    public let numberValue: Number
}

// MARK: -

extension Proportion {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the given number is a valid proportion.
    ///
    /// - Parameter numberValue:    The number to validate.
    ///
    /// - Returns:  `true` if `numberValue` is rational and greater than `0` and at most `1`; otherwise, `false`.
    public static func isValid(_ numberValue: Number) -> Bool {
        numberValue.isRational && numberValue > 0 && numberValue <= 1
    }
}

// MARK: - Codable

extension Proportion {

    // MARK: Public Initializers

    /// Creates a proportion by decoding a number, throwing a `DecodingError` if it is out
    /// of range.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        try self.init(validatingFrom: decoder)
    }
}

// MARK: - NumberRepresentable

extension Proportion: NumberRepresentable {
}

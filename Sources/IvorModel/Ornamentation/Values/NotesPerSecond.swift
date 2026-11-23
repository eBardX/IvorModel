// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

/// A rate of notes per second, as a rational number greater than `0`.
///
/// An ornament played at a fixed speed, whatever the tempo, gives its rate this way: a trill at
/// twelve notes per second, for example.
public struct NotesPerSecond {

    // MARK: Public Initializers

    /// Creates a rate from a number value, returning `nil` if the value is out of
    /// range.
    ///
    /// - Parameter numberValue:    A rational number greater than `0`.
    public init?(numberValue: Number) {
        guard Self.isValid(numberValue)
        else { return nil }

        self.numberValue = numberValue
    }

    // MARK: Public Instance Properties

    /// The numeric value of this rate, greater than `0`.
    public let numberValue: Number
}

// MARK: -

extension NotesPerSecond {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the given number is a valid rate.
    ///
    /// - Parameter numberValue:    The number to validate.
    ///
    /// - Returns:  `true` if `numberValue` is rational and greater than `0`; otherwise, `false`.
    public static func isValid(_ numberValue: Number) -> Bool {
        numberValue.isRational && numberValue > 0
    }
}

// MARK: - Codable

extension NotesPerSecond {

    // MARK: Public Initializers

    /// Creates a rate by decoding a number, throwing a `DecodingError` if it is out
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

extension NotesPerSecond: NumberRepresentable {
}

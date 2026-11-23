// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

/// The factor a fermata stretches its held span by, as a rational number of at least `1`.
///
/// A stretch of `2` makes the held span last twice its written length. A fermata never shortens
/// what it holds, so a stretch is never less than `1`.
public struct FermataStretch {

    // MARK: Public Initializers

    /// Creates a fermata stretch from a number value, returning `nil` if the value is out of
    /// range.
    ///
    /// - Parameter numberValue:    A rational number at least `1`.
    public init?(numberValue: Number) {
        guard Self.isValid(numberValue)
        else { return nil }

        self.numberValue = numberValue
    }

    // MARK: Public Instance Properties

    /// The numeric value of this fermata stretch, at least `1`.
    public let numberValue: Number
}

// MARK: -

extension FermataStretch {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the given number is a valid fermata stretch.
    ///
    /// - Parameter numberValue:    The number to validate.
    ///
    /// - Returns:  `true` if `numberValue` is rational and at least `1`; otherwise, `false`.
    public static func isValid(_ numberValue: Number) -> Bool {
        numberValue.isRational && numberValue >= 1
    }
}

// MARK: - Codable

extension FermataStretch {

    // MARK: Public Initializers

    /// Creates a fermata stretch by decoding a number, throwing a `DecodingError` if it is out
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

extension FermataStretch: NumberRepresentable {
}

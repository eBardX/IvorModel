// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiNumbers

/// A duration greater than zero.
///
/// Ornamentation uses it wherever a length of time must be positive: a grace note’s written
/// value, a trill’s note value, or how long a fermata adds. A length in seconds is a
/// `PositiveDuration<WallDuration>`.
public struct PositiveDuration<DurationType: DurationProtocol> {

    // MARK: Public Initializers

    /// Creates a positive duration, returning `nil` if `duration` is zero.
    ///
    /// - Parameter duration:   The duration, which must not be zero.
    public init?(_ duration: DurationType) {
        guard Self.isValid(duration)
        else { return nil }

        self.duration = duration
    }

    // MARK: Public Instance Properties

    /// The duration, which is never zero.
    public let duration: DurationType
}

// MARK: -

extension PositiveDuration {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the given duration is a valid positive
    /// duration.
    ///
    /// - Parameter duration:   The duration to validate.
    ///
    /// - Returns:  `true` if `duration` is not zero; otherwise, `false`.
    public static func isValid(_ duration: DurationType) -> Bool {
        !duration.isZero
    }

    // MARK: Public Instance Methods

    /// Returns this duration multiplied by a factor, or `nil` if the result is zero or can’t be
    /// computed.
    ///
    /// - Parameter factor: The factor, such as `2` for an augmentation.
    ///
    /// - Returns:  The scaled duration, or `nil`.
    public func scaled(by factor: Number) -> Self? {
        duration.multiplied(by: factor).flatMap(Self.init)
    }
}

// MARK: - Codable

extension PositiveDuration: Codable {

    // MARK: Public Initializers

    /// Creates a positive duration by decoding a duration, throwing a `DecodingError` if it is
    /// zero.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        guard let value = try Self(container.decode(DurationType.self))
        else { throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
                                                                       debugDescription: "Duration must not be zero")) }

        self = value
    }

    // MARK: Public Instance Methods

    /// Encodes this positive duration as its duration.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        try container.encode(duration)
    }
}

// MARK: - Hashable

extension PositiveDuration: Hashable {
}

// MARK: - Sendable

extension PositiveDuration: Sendable {
}

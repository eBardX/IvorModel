// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiNumbers

/// Time inserted at a moment, during which nothing new starts: the pause after a fermata, or at
/// a caesura.
///
/// A pause holds up every part, not just the one its sign is in.
public enum Pause<TimeType: TimeProtocol> {

    /// A pause of this length in the work’s own time: beats in a beat work, seconds in a wall
    /// work. It scales with augmentation and diminution.
    case added(PositiveDuration<TimeType.DurationType>)

    /// A pause of this many seconds, whatever the tempo. It doesn’t scale with augmentation or
    /// diminution.
    case seconds(PositiveDuration<WallDuration>)
}

// MARK: -

extension Pause {

    // MARK: Public Instance Methods

    /// Returns this pause with its length in the work’s own time scaled by a factor, or `nil` if
    /// the scaled length is zero or can’t be computed. A pause in seconds is unchanged.
    ///
    /// - Parameter factor: The factor, such as `2` for an augmentation.
    ///
    /// - Returns:  The scaled pause, or `nil`.
    public func scaled(by factor: Number) -> Self? {
        switch self {
        case let .added(duration):
            duration.scaled(by: factor).map { .added($0) }

        case .seconds:
            self
        }
    }
}

// MARK: - Codable

extension Pause: Codable {

    // MARK: Public Initializers

    /// Creates a pause by decoding its one case, `{"added": d}` or `{"seconds": s}`.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CaseCodingKey.self)
        let key = try CaseCodingKey.caseKey(of: container, typeName: "Pause")

        switch key.stringValue {
        case Self.addedKey:
            self = try .added(container.decode(PositiveDuration<TimeType.DurationType>.self, forKey: key))

        case Self.secondsKey:
            self = try .seconds(container.decode(PositiveDuration<WallDuration>.self, forKey: key))

        default:
            throw CaseCodingKey.unknownCase(key, in: container, typeName: "Pause")
        }
    }

    // MARK: Public Instance Methods

    /// Encodes this pause as its one case, `{"added": d}` or `{"seconds": s}`.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CaseCodingKey.self)

        switch self {
        case let .added(duration):
            try container.encode(duration, forKey: CaseCodingKey(Self.addedKey))

        case let .seconds(duration):
            try container.encode(duration, forKey: CaseCodingKey(Self.secondsKey))
        }
    }

    // MARK: Private Type Properties

    private static var addedKey: String {
        "added"
    }

    private static var secondsKey: String {
        "seconds"
    }
}

// MARK: - Hashable

extension Pause: Hashable {
}

// MARK: - Sendable

extension Pause: Sendable {
}

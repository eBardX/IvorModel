// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiNumbers

extension FermataExecution {

    // MARK: Public Nested Types

    /// How much longer a fermata’s held span lasts.
    ///
    /// Every case lengthens the span; none shortens it.
    public enum Hold {

        /// The span lasts its written length plus this, in the work’s own time. It scales with
        /// augmentation and diminution.
        case added(PositiveDuration<TimeType.DurationType>)

        /// The span lasts its written length plus this many seconds, at the local tempo in a beat
        /// work. It doesn’t scale with augmentation or diminution.
        case seconds(PositiveDuration<WallDuration>)

        /// The span lasts this factor times its written length.
        case stretch(FermataStretch)
    }
}

// MARK: -

extension FermataExecution.Hold {

    // MARK: Public Instance Methods

    /// Returns this hold with its length in the work’s own time scaled by a factor, or `nil` if
    /// the scaled length is zero or can’t be computed. A stretch or a hold in seconds is
    /// unchanged.
    ///
    /// - Parameter factor: The factor, such as `2` for an augmentation.
    ///
    /// - Returns:  The scaled hold, or `nil`.
    public func scaled(by factor: Number) -> Self? {
        switch self {
        case let .added(duration):
            duration.scaled(by: factor).map { .added($0) }

        case .seconds,
             .stretch:
            self
        }
    }
}

// MARK: - Codable

extension FermataExecution.Hold: Codable {

    // MARK: Public Initializers

    /// Creates a hold by decoding its one case: `{"added": d}`, `{"seconds": s}` or
    /// `{"stretch": f}`.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CaseCodingKey.self)
        let key = try CaseCodingKey.caseKey(of: container, typeName: "FermataExecution.Hold")

        switch key.stringValue {
        case Self.addedKey:
            self = try .added(container.decode(PositiveDuration<TimeType.DurationType>.self, forKey: key))

        case Self.secondsKey:
            self = try .seconds(container.decode(PositiveDuration<WallDuration>.self, forKey: key))

        case Self.stretchKey:
            self = try .stretch(container.decode(FermataStretch.self, forKey: key))

        default:
            throw CaseCodingKey.unknownCase(key, in: container, typeName: "FermataExecution.Hold")
        }
    }

    // MARK: Public Instance Methods

    /// Encodes this hold as its one case: `{"added": d}`, `{"seconds": s}` or `{"stretch": f}`.
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

        case let .stretch(stretch):
            try container.encode(stretch, forKey: CaseCodingKey(Self.stretchKey))
        }
    }

    // MARK: Private Type Properties

    private static var addedKey: String {
        "added"
    }

    private static var secondsKey: String {
        "seconds"
    }

    private static var stretchKey: String {
        "stretch"
    }
}

// MARK: - Hashable

extension FermataExecution.Hold: Hashable {
}

// MARK: - Sendable

extension FermataExecution.Hold: Sendable {
}

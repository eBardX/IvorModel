// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

extension ArpeggioRules {

    // MARK: Public Nested Types

    /// How far apart an arpeggio’s tones start, in time-neutral units.
    public enum Spread {

        /// The tones start this many seconds apart (at the local tempo in a beat work).
        case perTone(PositiveDuration<WallDuration>)

        /// The whole roll takes this share of the chord’s shortest tone, so every tone still
        /// sounds.
        case total(Proportion)
    }
}

// MARK: - Codable

extension ArpeggioRules.Spread: Codable {

    // MARK: Public Initializers

    /// Creates a spread by decoding its one case, `{"perTone": s}` or `{"total": p}`.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CaseCodingKey.self)
        let key = try CaseCodingKey.caseKey(of: container, typeName: "ArpeggioRules.Spread")

        switch key.stringValue {
        case Self.perToneKey:
            self = try .perTone(container.decode(PositiveDuration<WallDuration>.self, forKey: key))

        case Self.totalKey:
            self = try .total(container.decode(Proportion.self, forKey: key))

        default:
            throw CaseCodingKey.unknownCase(key, in: container, typeName: "ArpeggioRules.Spread")
        }
    }

    // MARK: Public Instance Methods

    /// Encodes this spread as its one case, `{"perTone": s}` or `{"total": p}`.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CaseCodingKey.self)

        switch self {
        case let .perTone(duration):
            try container.encode(duration, forKey: CaseCodingKey(Self.perToneKey))

        case let .total(proportion):
            try container.encode(proportion, forKey: CaseCodingKey(Self.totalKey))
        }
    }

    // MARK: Private Type Properties

    private static var perToneKey: String {
        "perTone"
    }

    private static var totalKey: String {
        "total"
    }
}

// MARK: - Hashable

extension ArpeggioRules.Spread: Hashable {
}

// MARK: - Sendable

extension ArpeggioRules.Spread: Sendable {
}

// © 2026 John Gary Pusey (see LICENSE.md)

/// How much of its note an ornament fills: a number of alternations, or a share of the note.
///
/// An ornament’s sign gives the default: a trill fills its note, a mordent sounds its partner
/// once, and a tremolo follows its strokes. An extent in an ornament’s execution overrides it,
/// so a `tr` on a short note played as one alternation keeps its `tr`. MusicXML’s `beats`
/// attribute is a count, and its `last-beat` a span.
public enum OrnamentExtent {

    /// The ornament sounds its partner this many times, then holds the main note.
    case count(AlternationCount)

    /// The ornament fills this share of its note, from the start, then holds the main note.
    case span(Proportion)
}

// MARK: - Codable

extension OrnamentExtent: Codable {

    // MARK: Public Initializers

    /// Creates an extent by decoding its one case, `{"count": n}` or `{"span": p}`.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CaseCodingKey.self)
        let key = try CaseCodingKey.caseKey(of: container, typeName: "OrnamentExtent")

        switch key.stringValue {
        case Self.countKey:
            self = try .count(container.decode(AlternationCount.self, forKey: key))

        case Self.spanKey:
            self = try .span(container.decode(Proportion.self, forKey: key))

        default:
            throw CaseCodingKey.unknownCase(key, in: container, typeName: "OrnamentExtent")
        }
    }

    // MARK: Public Instance Methods

    /// Encodes this extent as its one case, `{"count": n}` or `{"span": p}`.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CaseCodingKey.self)

        switch self {
        case let .count(count):
            try container.encode(count, forKey: CaseCodingKey(Self.countKey))

        case let .span(proportion):
            try container.encode(proportion, forKey: CaseCodingKey(Self.spanKey))
        }
    }

    // MARK: Private Type Properties

    private static let countKey = "count"
    private static let spanKey  = "span"
}

// MARK: - Hashable

extension OrnamentExtent: Hashable {
}

// MARK: - Sendable

extension OrnamentExtent: Sendable {
}

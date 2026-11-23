// © 2026 John Gary Pusey (see LICENSE.md)

extension NoteTable.Ornament {

    // MARK: Public Nested Types

    /// Whether a tremolo is measured, with a written subdivision, or unmeasured.
    public enum TremoloKind {

        /// A measured tremolo, dividing its note into notes of the subdivision its strokes give.
        case measured(TremoloStrokes)

        /// An unmeasured tremolo, as fast as possible.
        case unmeasured
    }
}

// MARK: - Codable

extension NoteTable.Ornament.TremoloKind: Codable {

    // MARK: Public Initializers

    /// Creates a tremolo kind by decoding its one case, `{"measured": n}` or
    /// `{"unmeasured": true}`.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CaseCodingKey.self)
        let key = try CaseCodingKey.caseKey(of: container, typeName: "TremoloKind")

        switch key.stringValue {
        case Self.measuredKey:
            self = try .measured(container.decode(TremoloStrokes.self, forKey: key))

        case Self.unmeasuredKey where try container.decode(Bool.self, forKey: key):
            self = .unmeasured

        default:
            throw CaseCodingKey.unknownCase(key, in: container, typeName: "TremoloKind")
        }
    }

    // MARK: Public Instance Methods

    /// Encodes this tremolo kind as its one case, `{"measured": n}` or `{"unmeasured": true}`.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CaseCodingKey.self)

        switch self {
        case let .measured(strokes):
            try container.encode(strokes, forKey: CaseCodingKey(Self.measuredKey))

        case .unmeasured:
            try container.encode(true, forKey: CaseCodingKey(Self.unmeasuredKey))
        }
    }

    // MARK: Private Type Properties

    private static var measuredKey: String {
        "measured"
    }

    private static var unmeasuredKey: String {
        "unmeasured"
    }
}

// MARK: - Hashable

extension NoteTable.Ornament.TremoloKind: Hashable {
}

// MARK: - Sendable

extension NoteTable.Ornament.TremoloKind: Sendable {
}

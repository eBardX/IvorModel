// © 2026 John Gary Pusey (see LICENSE.md)

extension NoteTable.Ornament {

    // MARK: Public Nested Types

    /// The standard sign an ornament is written with.
    ///
    /// The sign is only what’s written. It allows certain partners (see
    /// ``NoteTable/Ornament/init(sign:partner:execution:)``) and supplies defaults for how the
    /// ornament is played: a trill fills its note, a mordent sounds its partner once, and a
    /// tremolo follows its strokes.
    public enum Sign {

        /// A mordent (`𝆔` above, `𝆕` below): one quick alternation with a step partner on either
        /// side. Above is the upper mordent (main, upper, main).
        case mordent

        /// A tremolo, single (the main pitch repeated) or two-note (alternating with written
        /// pitches).
        case tremolo(TremoloKind)

        /// A trill (`tr`): alternation with the step above, filling the note.
        case trill
    }
}

// MARK: -

extension NoteTable.Ornament.Sign {

    // MARK: Public Instance Methods

    /// Returns a Boolean value indicating whether this sign can be written with the given
    /// partner.
    ///
    /// A trill needs a step partner above, a mordent a step partner on either side, and a
    /// tremolo the main pitch repeated or written pitches.
    ///
    /// - Parameter partner:    The partner to check.
    ///
    /// - Returns:  `true` if the sign allows `partner`; otherwise, `false`.
    public func allows(_ partner: NoteTable.Ornament.Partner) -> Bool {
        switch (self, partner) {
        case (.mordent, .step),
             (.tremolo, .pitches),
             (.tremolo, .repeat),
             (.trill, .step(.above, _)):
            true

        default:
            false
        }
    }
}

// MARK: - Codable

extension NoteTable.Ornament.Sign: Codable {

    // MARK: Public Initializers

    /// Creates a sign by decoding its one case: `{"mordent": true}`, `{"tremolo": kind}` or
    /// `{"trill": true}`.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CaseCodingKey.self)
        let key = try CaseCodingKey.caseKey(of: container, typeName: "Sign")

        switch key.stringValue {
        case Self.mordentKey where try container.decode(Bool.self, forKey: key):
            self = .mordent

        case Self.tremoloKey:
            self = try .tremolo(container.decode(NoteTable.Ornament.TremoloKind.self, forKey: key))

        case Self.trillKey where try container.decode(Bool.self, forKey: key):
            self = .trill

        default:
            throw CaseCodingKey.unknownCase(key, in: container, typeName: "Sign")
        }
    }

    // MARK: Public Instance Methods

    /// Encodes this sign as its one case: `{"mordent": true}`, `{"tremolo": kind}` or
    /// `{"trill": true}`.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CaseCodingKey.self)

        switch self {
        case .mordent:
            try container.encode(true, forKey: CaseCodingKey(Self.mordentKey))

        case let .tremolo(kind):
            try container.encode(kind, forKey: CaseCodingKey(Self.tremoloKey))

        case .trill:
            try container.encode(true, forKey: CaseCodingKey(Self.trillKey))
        }
    }

    // MARK: Private Type Properties

    private static var mordentKey: String {
        "mordent"
    }

    private static var tremoloKey: String {
        "tremolo"
    }

    private static var trillKey: String {
        "trill"
    }
}

// MARK: - Hashable

extension NoteTable.Ornament.Sign: Hashable {
}

// MARK: - Sendable

extension NoteTable.Ornament.Sign: Sendable {
}

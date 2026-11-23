// © 2026 John Gary Pusey (see LICENSE.md)

extension NoteTable.Ornament {

    // MARK: Public Nested Types

    /// The pitch an ornament’s main note alternates with.
    ///
    /// “Partner” is the one term for it: a trill’s or mordent’s step, a single tremolo’s
    /// repeated main pitch, or a two-note tremolo’s second note.
    public enum Partner {

        /// Written pitches: a two-note tremolo’s second note, one or more pitches sounding for
        /// the whole span. They are non-empty, sorted ascending, and free of duplicates.
        case pitches([PitchType])

        /// The main pitch itself, repeated: a single tremolo.
        case `repeat`

        /// A step to one side of the main note: a trill or mordent. The written pitch, if any
        /// (an accidental on the sign, or Guido’s `note=`), takes precedence over the
        /// execution’s ``PartnerRule``.
        case step(PartnerSide, written: PitchType?)
    }
}

// MARK: -

extension NoteTable.Ornament.Partner {

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether this partner is valid: written pitches must be
    /// non-empty, sorted ascending, and free of duplicates.
    public var isValid: Bool {
        guard case let .pitches(pitches) = self
        else { return true }

        return NoteTable.isPitchSet(pitches)
    }

    /// Every written pitch of this partner, in ascending order; empty for a repeat or a step
    /// with no written pitch.
    public var pitches: [PitchType] {
        switch self {
        case let .pitches(pitches):
            pitches

        case .repeat:
            []

        case let .step(_, written):
            written.map { [$0] } ?? []
        }
    }

    // MARK: Public Instance Methods

    /// Returns this partner with each written pitch transformed. Written pitches of a two-note
    /// tremolo are sorted again, with any duplicates removed. Which side a step lies on is
    /// unchanged: an inversion flips it separately.
    ///
    /// - Parameter transform:  The pitch mapping, such as a transposition.
    ///
    /// - Returns:  The mapped partner.
    ///
    /// - Throws:   Any error that `transform` throws.
    public func mapPitches(_ transform: (PitchType) throws -> PitchType) rethrows -> Self {
        switch self {
        case let .pitches(pitches):
            try .pitches(NoteTable.pitchSet(pitches.map(transform)))

        case .repeat:
            .repeat

        case let .step(side, written):
            try .step(side, written: written.map(transform))
        }
    }
}

// MARK: - Codable

extension NoteTable.Ornament.Partner: Codable {

    // MARK: Public Initializers

    /// Creates a partner by decoding its one case: `{"pitches": [p, …]}`, `{"repeat": true}`
    /// or `{"step": {"side": s, "written": p}}`, throwing a `DecodingError` if it isn’t valid.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CaseCodingKey.self)
        let key = try CaseCodingKey.caseKey(of: container, typeName: "Partner")

        switch key.stringValue {
        case Self.pitchesKey:
            self = try .pitches(container.decode([PitchType].self, forKey: key))

        case Self.repeatKey where try container.decode(Bool.self, forKey: key):
            self = .repeat

        case Self.stepKey:
            let step = try container.nestedContainer(keyedBy: StepCodingKeys.self, forKey: key)

            self = try .step(step.decode(PartnerSide.self, forKey: .side),
                             written: step.decodeIfPresent(PitchType.self, forKey: .written))

        default:
            throw CaseCodingKey.unknownCase(key, in: container, typeName: "Partner")
        }

        guard isValid
        else { throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
                                                                       debugDescription: "Partner pitches must be non-empty, sorted and unique")) }
    }

    // MARK: Public Instance Methods

    /// Encodes this partner as its one case: `{"pitches": [p, …]}`, `{"repeat": true}` or
    /// `{"step": {"side": s, "written": p}}`, leaving out a written pitch that is `nil`.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CaseCodingKey.self)

        switch self {
        case let .pitches(pitches):
            try container.encode(pitches, forKey: CaseCodingKey(Self.pitchesKey))

        case .repeat:
            try container.encode(true, forKey: CaseCodingKey(Self.repeatKey))

        case let .step(side, written):
            var step = container.nestedContainer(keyedBy: StepCodingKeys.self, forKey: CaseCodingKey(Self.stepKey))

            try step.encode(side, forKey: .side)
            try step.encodeIfPresent(written, forKey: .written)
        }
    }

    // MARK: Private Nested Types

    private enum StepCodingKeys: String, CodingKey {
        case side
        case written
    }

    // MARK: Private Type Properties

    private static var pitchesKey: String {
        "pitches"
    }

    private static var repeatKey: String {
        "repeat"
    }

    private static var stepKey: String {
        "step"
    }
}

// MARK: - Hashable

extension NoteTable.Ornament.Partner: Hashable {
}

// MARK: - Sendable

extension NoteTable.Ornament.Partner: Sendable {
}

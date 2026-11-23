// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

/// How a work or part plays its ornaments, fermatas and caesuras by default: the composer’s
/// general instructions, like a score’s preface.
///
/// Rules are the third of four layers. For each field of how an ornament is played, the most
/// specific layer that sets it wins: the ornament’s own execution, then its part’s rules, then
/// its work’s rules, then a built-in default. A part’s rules override its work’s field by field
/// (see ``resolved(work:part:)``).
///
/// Every field is time-neutral — shares of a note, factors, counts, notes per second and
/// seconds — so the rules never need converting between beat and wall time. Written note values
/// belong in an ornament’s own execution, where they convert with the note.
public struct InterpretationRules {

    // MARK: Public Initializers

    /// Creates interpretation rules with the provided fields, each `nil` by default.
    ///
    /// - Parameter grace:      How grace figures are played.
    /// - Parameter trill:      How trills are played, and ornaments with a step partner but no
    ///                         standard sign (such as a lower trill).
    /// - Parameter mordent:    How mordents are played.
    /// - Parameter tremolo:    How tremolos are played, and ornaments with a repeated or written
    ///                         partner but no standard sign. Its rate applies to unmeasured
    ///                         tremolos only.
    /// - Parameter arpeggio:   How arpeggios are played.
    /// - Parameter fermata:    How fermatas are played.
    /// - Parameter caesura:    The pause at each caesura that has no execution of its own.
    public init(grace: GraceRules? = nil,
                trill: OrnamentRules? = nil,
                mordent: OrnamentRules? = nil,
                tremolo: OrnamentRules? = nil,
                arpeggio: ArpeggioRules? = nil,
                fermata: FermataRules? = nil,
                caesura: PositiveDuration<WallDuration>? = nil) {
        self.arpeggio = Self._normalized(arpeggio, \.isEmpty)
        self.caesura = caesura
        self.fermata = Self._normalized(fermata, \.isEmpty)
        self.grace = Self._normalized(grace, \.isEmpty)
        self.mordent = Self._normalized(mordent, \.isEmpty)
        self.tremolo = Self._normalized(tremolo, \.isEmpty)
        self.trill = Self._normalized(trill, \.isEmpty)
    }

    // MARK: Public Instance Properties

    /// How arpeggios are played, or `nil` for the defaults.
    public let arpeggio: ArpeggioRules?

    /// The pause at each caesura that has no execution of its own, or `nil` for the default.
    public let caesura: PositiveDuration<WallDuration>?

    /// How fermatas are played, or `nil` for the defaults.
    public let fermata: FermataRules?

    /// How grace figures are played, or `nil` for the defaults.
    public let grace: GraceRules?

    /// How mordents are played, or `nil` for the defaults.
    public let mordent: OrnamentRules?

    /// How tremolos are played, and ornaments with a repeated or written partner but no standard
    /// sign, or `nil` for the defaults.
    public let tremolo: OrnamentRules?

    /// How trills are played, and ornaments with a step partner but no standard sign, or `nil`
    /// for the defaults.
    public let trill: OrnamentRules?
}

// MARK: -

extension InterpretationRules {

    // MARK: Public Type Methods

    /// Returns the rules in effect for a part: the part’s rules over its work’s, field by field,
    /// down to the fields of each nested rules value and each shape’s fermata hold.
    ///
    /// - Parameter work:   The work’s rules, if any.
    /// - Parameter part:   The part’s rules, if any.
    ///
    /// - Returns:  The rules in effect, empty if neither has any. A field still `nil` comes from
    ///             a built-in default.
    public static func resolved(work: Self?,
                                part: Self?) -> Self {
        (work ?? Self()).overridden(by: part)
    }

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether every field is `nil`.
    public var isEmpty: Bool {
        arpeggio == nil && caesura == nil && fermata == nil && grace == nil
            && mordent == nil && tremolo == nil && trill == nil
    }

    // MARK: Public Instance Methods

    /// Returns these rules with each field that `other` sets replaced by its value, down to the
    /// fields of each nested rules value and each shape’s fermata hold.
    ///
    /// - Parameter other:  The more specific rules, such as a part’s over its work’s.
    ///
    /// - Returns:  The combined rules.
    public func overridden(by other: Self?) -> Self {
        guard let other
        else { return self }

        return Self(grace: Self._overridden(grace, other.grace) { $0.overridden(by: $1) },
                    trill: Self._overridden(trill, other.trill) { $0.overridden(by: $1) },
                    mordent: Self._overridden(mordent, other.mordent) { $0.overridden(by: $1) },
                    tremolo: Self._overridden(tremolo, other.tremolo) { $0.overridden(by: $1) },
                    arpeggio: Self._overridden(arpeggio, other.arpeggio) { $0.overridden(by: $1) },
                    fermata: Self._overridden(fermata, other.fermata) { $0.overridden(by: $1) },
                    caesura: other.caesura ?? caesura)
    }

    // MARK: Private Type Methods

    private static func _normalized<Value>(_ value: Value?,
                                           _ isEmpty: (Value) -> Bool) -> Value? {
        guard let value,
              !isEmpty(value)
        else { return nil }

        return value
    }

    private static func _overridden<Value>(_ base: Value?,
                                           _ other: Value?,
                                           _ combine: (Value, Value) -> Value) -> Value? {
        guard let base
        else { return other }

        guard let other
        else { return base }

        return combine(base, other)
    }
}

// MARK: - Codable

extension InterpretationRules: Codable {

    // MARK: Public Initializers

    /// Creates interpretation rules by decoding them. A nested rules value with no fields is
    /// read as `nil`.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        try self.init(grace: container.decodeIfPresent(GraceRules.self, forKey: .grace),
                      trill: container.decodeIfPresent(OrnamentRules.self, forKey: .trill),
                      mordent: container.decodeIfPresent(OrnamentRules.self, forKey: .mordent),
                      tremolo: container.decodeIfPresent(OrnamentRules.self, forKey: .tremolo),
                      arpeggio: container.decodeIfPresent(ArpeggioRules.self, forKey: .arpeggio),
                      fermata: container.decodeIfPresent(FermataRules.self, forKey: .fermata),
                      caesura: container.decodeIfPresent(PositiveDuration<WallDuration>.self, forKey: .caesura))
    }

    // MARK: Public Instance Methods

    /// Encodes these rules, leaving out every field that is `nil`.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(grace, forKey: .grace)
        try container.encodeIfPresent(trill, forKey: .trill)
        try container.encodeIfPresent(mordent, forKey: .mordent)
        try container.encodeIfPresent(tremolo, forKey: .tremolo)
        try container.encodeIfPresent(arpeggio, forKey: .arpeggio)
        try container.encodeIfPresent(fermata, forKey: .fermata)
        try container.encodeIfPresent(caesura, forKey: .caesura)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case arpeggio
        case caesura
        case fermata
        case grace
        case mordent
        case tremolo
        case trill
    }
}

// MARK: - Hashable

extension InterpretationRules: Hashable {
}

// MARK: - Sendable

extension InterpretationRules: Sendable {
}

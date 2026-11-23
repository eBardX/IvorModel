// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

extension NoteTable {

    // MARK: Public Nested Types

    /// A trill, mordent or tremolo: the main note alternating with a partner.
    ///
    /// The three differ only in their partner and their extent, so they are one type. The
    /// ``sign`` and ``partner`` are the sign; the ``execution``, if any, is how this occurrence
    /// is played. An ornament with no standard sign, such as a lower trill, still plays and
    /// exports to MIDI; notation exporters drop it.
    public struct Ornament {

        // MARK: Public Initializers

        /// Creates an ornament, returning `nil` if the parts don’t fit together.
        ///
        /// The sign must allow the partner (see ``Sign/allows(_:)``), the partner must be valid
        /// (see ``Partner/isValid``), and an execution’s ``OrnamentExecution/partnerRule`` is
        /// only allowed with a step partner.
        ///
        /// - Parameter sign:       The standard sign the ornament is written with, or `nil` if
        ///                         it has none. Defaults to `nil`.
        /// - Parameter partner:    The pitch the main note alternates with.
        /// - Parameter execution:  How this ornament is played, or `nil` to follow the rules.
        ///                         Defaults to `nil`.
        public init?(sign: Sign? = nil,
                     partner: Partner,
                     execution: OrnamentExecution? = nil) {
            guard Self._isValid(sign, partner, execution)
            else { return nil }

            self.execution = execution
            self.partner = partner
            self.sign = sign
        }

        // MARK: Public Instance Properties

        /// How this ornament is played, or `nil` to follow the rules. Part of the execution.
        public let execution: OrnamentExecution?

        /// The pitch the main note alternates with. Part of the sign.
        public let partner: Partner

        /// The standard sign the ornament is written with, or `nil` if it has none. Part of the
        /// sign.
        public let sign: Sign?

        // MARK: Private Initializers

        private init(unchecked sign: Sign?,
                     partner: Partner,
                     execution: OrnamentExecution?) {
            self.execution = execution
            self.partner = partner
            self.sign = sign
        }
    }
}

// MARK: -

extension NoteTable.Ornament {

    // MARK: Public Instance Properties

    /// Every written pitch of the partner (see ``Partner/pitches``).
    public var pitches: [PitchType] {
        partner.pitches
    }

    // MARK: Public Instance Methods

    /// Returns this ornament with each written partner pitch transformed (see
    /// ``Partner/mapPitches(_:)``).
    ///
    /// - Parameter transform:  The pitch mapping, such as a transposition.
    ///
    /// - Returns:  The mapped ornament.
    ///
    /// - Throws:   Any error that `transform` throws.
    public func mapPitches(_ transform: (PitchType) throws -> PitchType) rethrows -> Self {
        try Self(unchecked: sign,
                 partner: partner.mapPitches(transform),
                 execution: execution)
    }

    /// Returns this ornament with a note-value rate scaled by a factor, or `nil` if the scaled
    /// value is zero or can’t be computed.
    ///
    /// - Parameter factor: The factor, such as `2` for an augmentation.
    ///
    /// - Returns:  The scaled ornament, or `nil`.
    public func scaled(by factor: Number) -> Self? {
        guard let execution
        else { return self }

        return execution.scaled(by: factor).map {
            Self(unchecked: sign,
                 partner: partner,
                 execution: $0)
        }
    }

    // MARK: Private Type Methods

    private static func _isValid(_ sign: Sign?,
                                 _ partner: Partner,
                                 _ execution: NoteTable.OrnamentExecution?) -> Bool {
        guard partner.isValid,
              sign?.allows(partner) ?? true
        else { return false }

        if execution?.partnerRule != nil,
           case .step = partner {
            return true
        }

        return execution?.partnerRule == nil
    }
}

// MARK: -

extension NoteTable.Ornament {

    // MARK: Internal Instance Methods

    //
    // This ornament as it reads once its note is inverted: a step partner moves to the other
    // side. A trill whose partner ends up below loses its sign, becoming an unnotated lower
    // trill (resolution 19 of the grace-notes plan); a mordent keeps its sign, since it allows
    // either side. Written pitches are mapped separately, by `mapPitches(_:)`.
    //
    internal func flippingPartnerSide() -> Self {
        guard case let .step(side, written) = partner
        else { return self }

        let newPartner = Partner.step(side == .above ? .below : .above,
                                      written: written)

        return Self(unchecked: sign?.allows(newPartner) ?? false ? sign : nil,
                    partner: newPartner,
                    execution: execution)
    }

    //
    // This ornament without its written partner pitch, so the partner falls back to its rule.
    // Used when a conversion would put the written pitch on or past the main pitch.
    //
    internal func withoutWrittenPartner() -> Self {
        guard case let .step(side, _) = partner
        else { return self }

        return Self(unchecked: sign,
                    partner: .step(side, written: nil),
                    execution: execution)
    }
}

// MARK: - Codable

extension NoteTable.Ornament: Codable {

    // MARK: Public Initializers

    /// Creates an ornament by decoding it, throwing a `DecodingError` if its parts don’t fit
    /// together (see ``init(sign:partner:execution:)``).
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let sign = try container.decodeIfPresent(Sign.self, forKey: .sign)
        let partner = try container.decode(Partner.self, forKey: .partner)
        let execution = try container.decodeIfPresent(NoteTable.OrnamentExecution.self, forKey: .execution)

        guard let value = Self(sign: sign,
                               partner: partner,
                               execution: execution)
        else { throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
                                                                       debugDescription: "Mismatched ornament sign, partner and execution")) }

        self = value
    }

    // MARK: Public Instance Methods

    /// Encodes this ornament, leaving out a sign or execution that is `nil`.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(sign, forKey: .sign)
        try container.encode(partner, forKey: .partner)
        try container.encodeIfPresent(execution, forKey: .execution)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case execution
        case partner
        case sign
    }
}

// MARK: - Hashable

extension NoteTable.Ornament: Hashable {
}

// MARK: - Sendable

extension NoteTable.Ornament: Sendable {
}

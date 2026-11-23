// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

extension NoteTable {

    // MARK: Public Nested Types

    /// Everything that ornaments one note: grace figures before and after it, a trill,
    /// mordent or tremolo, an arpeggio, and a fermata.
    ///
    /// Each slot is optional and holds at most one value. Each value keeps its sign (what the
    /// score shows) apart from its execution (how this occurrence is played), so a transform
    /// keeps the meaning, and a plain sign stays compact.
    public struct Ornamentation {

        // MARK: Public Initializers

        /// Creates an ornamentation with the provided slots, each `nil` by default.
        ///
        /// - Parameter graceBefore:    The grace figure before the note.
        /// - Parameter graceAfter:     The grace figure after the note (a *Nachschlag*, or a
        ///                             trill’s written ending).
        /// - Parameter ornament:       The trill, mordent or tremolo on the note.
        /// - Parameter arpeggio:       The note’s part in a rolled chord.
        /// - Parameter fermata:        The fermata on the note, which spans the note.
        public init(graceBefore: GraceFigure? = nil,
                    graceAfter: GraceFigure? = nil,
                    ornament: Ornament? = nil,
                    arpeggio: Arpeggio? = nil,
                    fermata: Fermata<TimeType>? = nil) {
            self.arpeggio = arpeggio
            self.fermata = fermata
            self.graceAfter = graceAfter
            self.graceBefore = graceBefore
            self.ornament = ornament
        }

        // MARK: Public Instance Properties

        /// The note’s part in a rolled chord, if any.
        public let arpeggio: Arpeggio?

        /// The fermata on the note, if any. It spans the note.
        public let fermata: Fermata<TimeType>?

        /// The grace figure after the note, if any.
        public let graceAfter: GraceFigure?

        /// The grace figure before the note, if any.
        public let graceBefore: GraceFigure?

        /// The trill, mordent or tremolo on the note, if any.
        public let ornament: Ornament?
    }
}

// MARK: -

extension NoteTable.Ornamentation {

    // MARK: Public Type Methods

    /// Returns the ornamentation of the one note that two tied notes are joined into: the first
    /// note’s figure before, ornament, arpeggio and fermata, and the last note’s figure after.
    ///
    /// A figure before the second note breaks the tie, so the notes shouldn’t be joined at all
    /// then; this keeps only the first note’s.
    ///
    /// - Parameter first:  The ornamentation of the first of the tied notes.
    /// - Parameter last:   The ornamentation of the last of the tied notes.
    ///
    /// - Returns:  The joined note’s ornamentation, or `nil` if it has none.
    public static func merged(first: Self?,
                              last: Self?) -> Self? {
        let merged = Self(graceBefore: first?.graceBefore,
                          graceAfter: last?.graceAfter,
                          ornament: first?.ornament,
                          arpeggio: first?.arpeggio,
                          fermata: first?.fermata)

        return merged.isEmpty ? nil : merged
    }

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether every slot is `nil`.
    public var isEmpty: Bool {
        arpeggio == nil && fermata == nil && graceAfter == nil && graceBefore == nil && ornament == nil
    }

    /// Every pitch of the ornamentation, in performance order: the figure before, the
    /// ornament’s written partner, then the figure after.
    public var pitches: [PitchType] {
        (graceBefore?.pitches ?? []) + (ornament?.pitches ?? []) + (graceAfter?.pitches ?? [])
    }

    // MARK: Public Instance Methods

    /// Returns this ornamentation with each grace pitch and written partner pitch transformed.
    ///
    /// - Parameter transform:  The pitch mapping, such as a transposition.
    ///
    /// - Returns:  The mapped ornamentation.
    ///
    /// - Throws:   Any error that `transform` throws.
    public func mapPitches(_ transform: (PitchType) throws -> PitchType) rethrows -> Self {
        try Self(graceBefore: graceBefore?.mapPitches(transform),
                 graceAfter: graceAfter?.mapPitches(transform),
                 ornament: ornament?.mapPitches(transform),
                 arpeggio: arpeggio,
                 fermata: fermata)
    }

    /// Returns this ornamentation as it reads once its note’s part is reversed: the figure
    /// before becomes the figure after, and the reverse, each reversed (see
    /// ``NoteTable/GraceFigure/reversed()``). The ornament, arpeggio and fermata are
    /// unchanged.
    ///
    /// - Returns:  The reversed ornamentation.
    public func reversed() -> Self {
        Self(graceBefore: graceAfter?.reversed(),
             graceAfter: graceBefore?.reversed(),
             ornament: ornament,
             arpeggio: arpeggio,
             fermata: fermata)
    }

    /// Returns this ornamentation with its written durations scaled by a factor, or `nil` if a
    /// scaled duration is zero or can’t be computed. Shares, factors, rates per second and
    /// seconds are unchanged.
    ///
    /// - Parameter factor: The factor, such as `2` for an augmentation.
    ///
    /// - Returns:  The scaled ornamentation, or `nil`.
    public func scaled(by factor: Number) -> Self? {
        func scale<Value>(_ value: Value?,
                          _ scaled: (Value) -> Value?) -> Value?? {
            guard let value
            else { return .some(nil) }

            return scaled(value).map { .some($0) }
        }

        guard let graceBefore = scale(graceBefore, { $0.scaled(by: factor) }),
              let graceAfter = scale(graceAfter, { $0.scaled(by: factor) }),
              let ornament = scale(ornament, { $0.scaled(by: factor) }),
              let arpeggio = scale(arpeggio, { $0.scaled(by: factor) }),
              let fermata = scale(fermata, { $0.scaled(by: factor) })
        else { return nil }

        return Self(graceBefore: graceBefore,
                    graceAfter: graceAfter,
                    ornament: ornament,
                    arpeggio: arpeggio,
                    fermata: fermata)
    }
}

// MARK: - Codable

extension NoteTable.Ornamentation: Codable {
}

// MARK: - Hashable

extension NoteTable.Ornamentation: Hashable {
}

// MARK: - Sendable

extension NoteTable.Ornamentation: Sendable {
}

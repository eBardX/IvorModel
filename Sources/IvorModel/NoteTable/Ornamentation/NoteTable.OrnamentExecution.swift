// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

extension NoteTable {

    // MARK: Public Nested Types

    /// How one trill, mordent or tremolo is played: the composer’s instructions for this
    /// occurrence.
    ///
    /// Every field is optional; one left out comes from the work’s or part’s interpretation
    /// rules, or else from a built-in default. There is no ending (a written ending is a grace
    /// figure after the note) and no acceleration: an ornament plays at a steady rate.
    public struct OrnamentExecution {

        // MARK: Public Initializers

        /// Creates an ornament execution with the provided fields, each `nil` by default.
        ///
        /// - Parameter startNote:      Whether the ornament starts on its main note or its
        ///                             partner.
        /// - Parameter partnerRule:    How far a step partner with no written pitch lies from
        ///                             the main note. Only for a step partner.
        /// - Parameter rate:           How fast the ornament alternates.
        /// - Parameter extent:         How much of the note the ornament fills, overriding its
        ///                             sign’s default.
        public init(startNote: OrnamentStart? = nil,
                    partnerRule: PartnerRule? = nil,
                    rate: Rate? = nil,
                    extent: OrnamentExtent? = nil) {
            self.extent = extent
            self.partnerRule = partnerRule
            self.rate = rate
            self.startNote = startNote
        }

        // MARK: Public Instance Properties

        /// How much of the note the ornament fills, or `nil` to take it from the sign: MusicXML’s
        /// `beats` (as a count) and `last-beat` (as a span).
        public let extent: OrnamentExtent?

        /// How far a step partner with no written pitch lies from the main note, or `nil` to
        /// take it from the rules.
        public let partnerRule: PartnerRule?

        /// How fast the ornament alternates, or `nil` to take it from the rules.
        public let rate: Rate?

        /// Whether the ornament starts on its main note or its partner, or `nil` to take it
        /// from the rules.
        public let startNote: OrnamentStart?
    }
}

// MARK: -

extension NoteTable.OrnamentExecution {

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether every field is `nil`.
    public var isEmpty: Bool {
        extent == nil && partnerRule == nil && rate == nil && startNote == nil
    }

    // MARK: Public Instance Methods

    /// Returns this execution with a note-value rate scaled by a factor, or `nil` if the scaled
    /// value is zero or can’t be computed.
    ///
    /// - Parameter factor: The factor, such as `2` for an augmentation.
    ///
    /// - Returns:  The scaled execution, or `nil`.
    public func scaled(by factor: Number) -> Self? {
        guard let rate
        else { return self }

        return rate.scaled(by: factor).map {
            Self(startNote: startNote,
                 partnerRule: partnerRule,
                 rate: $0,
                 extent: extent)
        }
    }
}

// MARK: - Codable

extension NoteTable.OrnamentExecution: Codable {
}

// MARK: - Hashable

extension NoteTable.OrnamentExecution: Hashable {
}

// MARK: - Sendable

extension NoteTable.OrnamentExecution: Sendable {
}

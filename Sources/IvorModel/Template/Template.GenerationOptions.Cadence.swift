// © 2026 John Gary Pusey (see LICENSE.md)

extension Template.GenerationOptions {

    // MARK: Public Nested Types

    /// A note event on which generation ends, once a minimum length has been generated.
    ///
    /// If the cadence never comes, the recipe’s ``Template/GenerationOptions/length`` still
    /// stops generation.
    public struct Cadence {

        // MARK: Public Initializers

        /// Creates a new cadence.
        ///
        /// - Parameter pitches:        The pitches of the final note event: one for a final
        ///                             note, several for a final chord, none for a final rest.
        /// - Parameter duration:       The duration the final note event must have, or `nil`
        ///                             for any duration. Defaults to `nil`.
        /// - Parameter minimumLength:  How much must be generated before the cadence can end
        ///                             generation.
        public init(pitches: Set<PitchType>,
                    duration: DurationType? = nil,
                    minimumLength: Length) {
            self.duration = duration
            self.minimumLength = minimumLength
            self.pitches = pitches
        }

        // MARK: Public Instance Properties

        /// The duration the final note event must have, or `nil` for any duration.
        public var duration: DurationType?

        /// How much must be generated before the cadence can end generation.
        public var minimumLength: Length

        /// The pitches of the final note event.
        public var pitches: Set<PitchType>
    }
}

// MARK: -

extension Template.GenerationOptions.Cadence {

    // MARK: Public Instance Methods

    /// Returns a Boolean value indicating whether the given note event matches this cadence.
    ///
    /// Ties are ignored: a note event matches if it has exactly this cadence’s pitches and,
    /// if this cadence has a duration, that duration.
    ///
    /// - Parameter noteEvent:  The note event to test.
    ///
    /// - Returns:  `true` if `noteEvent` matches.
    public func matches(_ noteEvent: NoteEvent<TimeType, PitchType>) -> Bool {
        if let duration, noteEvent.duration != duration {
            return false
        }

        return Set(noteEvent.tiedPitches.map(\.pitch)) == pitches
    }
}

// MARK: - Codable

extension Template.GenerationOptions.Cadence: Codable {
}

// MARK: - Hashable

extension Template.GenerationOptions.Cadence: Hashable {
}

// MARK: - Sendable

extension Template.GenerationOptions.Cadence: Sendable {
}

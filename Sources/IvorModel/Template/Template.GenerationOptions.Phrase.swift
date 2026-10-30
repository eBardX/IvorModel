// © 2026 John Gary Pusey (see LICENSE.md)

extension Template.GenerationOptions {

    // MARK: Public Nested Types

    /// A phrase for generation to continue, instead of generating from scratch.
    ///
    /// The phrase is learned as the template learns: its note events take the template’s
    /// duration and pitch tolerances and become states of the template’s state recipe. Its
    /// variants and timing tolerance play no part. The template’s chains then continue from those
    /// states, and the continuation starts from the phrase’s last pitch and duration.
    ///
    /// The note events are copied into the recipe, so that a recorded recipe regenerates the same
    /// way after the phrase’s source is edited.
    public struct Phrase {

        // MARK: Public Initializers

        /// Creates a new phrase.
        ///
        /// - Parameter noteEvents:     The phrase’s note events, in order. Must not be empty.
        /// - Parameter includesPhrase: Whether the generated work starts with the phrase itself.
        ///                             Defaults to `true`.
        public init(noteEvents: [NoteEvent<TimeType, PitchType>],
                    includesPhrase: Bool = true) {
            self.includesPhrase = includesPhrase
            self.noteEvents = noteEvents
        }

        // MARK: Public Instance Properties

        /// Whether the generated work starts with the phrase itself, followed by the
        /// continuation; otherwise, the work is the continuation alone.
        public var includesPhrase: Bool

        /// The phrase’s note events, in order.
        public var noteEvents: [NoteEvent<TimeType, PitchType>]
    }
}

// MARK: - Codable

extension Template.GenerationOptions.Phrase: Codable {
}

// MARK: - Hashable

extension Template.GenerationOptions.Phrase: Hashable {
}

// MARK: - Sendable

extension Template.GenerationOptions.Phrase: Sendable {
}

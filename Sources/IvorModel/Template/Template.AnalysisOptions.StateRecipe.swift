// © 2026 John Gary Pusey (see LICENSE.md)

extension Template.AnalysisOptions {

    // MARK: Public Nested Types

    /// What a template learns about each note event: which features of it make up a state.
    ///
    /// Relative features let related material share states. With intervals, a melody and its
    /// transpositions are the same states; with pitch classes, octave displacements are; with
    /// relative durations, augmented and diminished forms are.
    public struct StateRecipe {

        // MARK: Public Initializers

        /// Creates a new state recipe.
        ///
        /// - Parameter pitch:      What a state records of an event’s pitches. Defaults to
        ///                         ``PitchFeature/absolute``.
        /// - Parameter duration:   What a state records of an event’s duration. Defaults to
        ///                         ``DurationFeature/absolute``.
        public init(pitch: PitchFeature = .absolute,
                    duration: DurationFeature = .absolute) {
            self.duration = duration
            self.pitch = pitch
        }

        // MARK: Public Instance Properties

        /// What a state records of an event’s duration.
        public var duration: DurationFeature

        /// What a state records of an event’s pitches.
        public var pitch: PitchFeature
    }
}

// MARK: -

extension Template.AnalysisOptions.StateRecipe {

    // MARK: Public Type Properties

    /// The recipe that records exact pitches and durations, as earlier versions did.
    public static let exact = Self()

    // MARK: Internal Instance Properties

    //
    // Whether realizing a state depends on what came before it.
    //
    internal var isRelative: Bool {
        pitch == .interval || pitch == .pitchClass || duration == .relative
    }

    // MARK: Internal Instance Methods

    internal func validate() throws(Template.Error) {
        guard pitch != .omitted || duration != .omitted
        else { throw .invalidStateRecipe }
    }
}

// MARK: - Codable

extension Template.AnalysisOptions.StateRecipe: Codable {
}

// MARK: - Hashable

extension Template.AnalysisOptions.StateRecipe: Hashable {
}

// MARK: - Sendable

extension Template.AnalysisOptions.StateRecipe: Sendable {
}

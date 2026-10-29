// © 2026 John Gary Pusey (see LICENSE.md)

extension Template.AnalysisOptions.StateRecipe {

    // MARK: Public Nested Types

    /// What a state records of an event’s pitches.
    public enum PitchFeature {
        /// The pitches themselves, as earlier versions did.
        case absolute

        /// The pitches’ intervals: the bass’s from the previous sounding bass, and each pitch’s
        /// above its own bass. So the same chord shape is the same over any bass, and a passage
        /// and its transpositions are the same states.
        case interval

        /// Nothing about pitch: the template learns rhythm only.
        case omitted

        /// The pitches’ classes, so that octave displacements are the same states.
        case pitchClass
    }
}

// MARK: - Codable

extension Template.AnalysisOptions.StateRecipe.PitchFeature: Codable {
}

// MARK: - Hashable

extension Template.AnalysisOptions.StateRecipe.PitchFeature: Hashable {
}

// MARK: - Sendable

extension Template.AnalysisOptions.StateRecipe.PitchFeature: Sendable {
}

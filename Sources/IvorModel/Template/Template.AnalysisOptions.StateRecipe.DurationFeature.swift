// © 2026 John Gary Pusey (see LICENSE.md)

extension Template.AnalysisOptions.StateRecipe {

    // MARK: Public Nested Types

    /// What a state records of an event’s duration.
    public enum DurationFeature {
        /// The duration itself, as earlier versions did.
        case absolute

        /// Nothing about duration: the template learns pitch only.
        case omitted

        /// The duration’s ratio to the previous event’s, so that augmented and diminished forms
        /// are the same states. See ``TemplateDuration/templateRatio(to:)``.
        case relative
    }
}

// MARK: - Codable

extension Template.AnalysisOptions.StateRecipe.DurationFeature: Codable {
}

// MARK: - Hashable

extension Template.AnalysisOptions.StateRecipe.DurationFeature: Hashable {
}

// MARK: - Sendable

extension Template.AnalysisOptions.StateRecipe.DurationFeature: Sendable {
}

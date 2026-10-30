// © 2026 John Gary Pusey (see LICENSE.md)

extension Template {

    // MARK: Public Nested Types

    /// What one of a template’s Markov chains learns.
    ///
    /// A template learns either one joint chain or, when its
    /// ``AnalysisOptions/StateRecipe/separatesPitchAndDuration`` is set, a duration chain and a
    /// pitch chain (see ``Template/Model/Chains``).
    public enum ChainRole {
        /// The duration chain of a separated template: every event’s duration, and whether it is
        /// a rest.
        case duration

        /// The one chain of a joint template: each event’s pitches and duration together.
        case joint

        /// The pitch chain of a separated template: the pitches of its sounding events.
        case pitch
    }
}

// MARK: - Codable

extension Template.ChainRole: Codable {
}

// MARK: - Hashable

extension Template.ChainRole: Hashable {
}

// MARK: - Sendable

extension Template.ChainRole: Sendable {
}

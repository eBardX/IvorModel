// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

extension Template {

    // MARK: Public Nested Types

    /// A template’s analysis at its concrete time and pitch types: its Markov chains of states,
    /// and the vocabulary of concrete values its source contained.
    public struct Model<TimeType: TimeProtocol, PitchType: TemplatePitch> where TimeType.DurationType: TemplateDuration {

        // MARK: Public Initializers

        /// Creates a new model.
        ///
        /// - Parameter chains:     The Markov chains of states.
        /// - Parameter vocabulary: The concrete values the source contained. Defaults to an
        ///                         empty vocabulary.
        public init(chains: Chains,
                    vocabulary: Vocabulary<TimeType, PitchType> = Vocabulary()) {
            self.chains = chains
            self.vocabulary = vocabulary
        }

        // MARK: Public Instance Properties

        /// The Markov chains of states.
        public let chains: Chains

        /// The concrete values the source contained.
        public let vocabulary: Vocabulary<TimeType, PitchType>
    }
}

// MARK: - Codable

extension Template.Model: Codable {
}

// MARK: - Sendable

extension Template.Model: Sendable {
}

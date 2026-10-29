// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiMarkov

extension Template {

    // MARK: Public Nested Types

    /// A template’s analysis at its concrete time and pitch types: its Markov chain of states, and
    /// the vocabulary of concrete values its source contained.
    public struct Model<TimeType: TimeProtocol, PitchType: TemplatePitch> where TimeType.DurationType: TemplateDuration {

        // MARK: Public Initializers

        /// Creates a new model.
        ///
        /// - Parameter markovChain:    The Markov chain of states.
        /// - Parameter vocabulary:     The concrete values the source contained. Defaults to an
        ///                             empty vocabulary.
        public init(markovChain: MarkovChain<State<TimeType, PitchType>>,
                    vocabulary: Vocabulary<TimeType, PitchType> = Vocabulary()) {
            self.markovChain = markovChain
            self.vocabulary = vocabulary
        }

        // MARK: Public Instance Properties

        /// The Markov chain of states.
        public let markovChain: MarkovChain<State<TimeType, PitchType>>

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

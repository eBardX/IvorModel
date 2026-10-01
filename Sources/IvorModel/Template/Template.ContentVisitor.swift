// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning
public import XestiMarkov

extension Template {
    /// A type that works with a template’s Markov chain at its concrete time
    /// and pitch types.
    ///
    /// A template’s ``Template/Content`` holds one of six Markov chain types,
    /// one for each combination of time basis and pitch notation. Rather than
    /// switch over all six cases, write the code once, generically, in a
    /// visitor’s ``visit(_:)`` method, and pass the visitor to
    /// ``Template/accept(_:)``.
    public protocol ContentVisitor {

        // MARK: Public Associated Types

        /// The type of value the visitor returns.
        associatedtype Result

        // MARK: Public Instance Methods

        /// Visits a template’s Markov chain.
        ///
        /// - Parameter markovChain:    The template’s Markov chain.
        ///
        /// - Returns:  The result of the visit.
        func visit(_ markovChain: MarkovChain<NoteEvent<some TimeProtocol, some PitchProtocol>>) -> Result
    }
}

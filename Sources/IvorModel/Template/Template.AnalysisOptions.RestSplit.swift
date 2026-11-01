// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

extension Template.AnalysisOptions {

    // MARK: Public Nested Types

    /// How long a rest must be to split a part into separate sequences.
    ///
    /// A long rest is usually a break between phrases, or bars where the part is silent, rather
    /// than part of a phrase. Splitting there ends one sequence at the note before the rest and
    /// starts another at the note after it, as if they were separate parts: the template learns
    /// each phrase’s ending as an ending and its opening as an opening, and never learns the rest
    /// itself. Shorter rests are learned as usual.
    public enum RestSplit {
        /// Splits at each rest lasting at least this many beats. For beat-time works only.
        case beat(BeatDuration)

        /// Splits at each rest lasting at least this long. For wall-time works only.
        case wall(WallDuration)
    }
}

// MARK: -

extension Template.AnalysisOptions.RestSplit {

    // MARK: Internal Instance Methods

    internal func validate() throws(Template.Error) {
        switch self {
        case let .beat(duration):
            guard !duration.isZero
            else { throw .invalidTolerance }

        case let .wall(duration):
            guard !duration.isZero
            else { throw .invalidTolerance }
        }
    }
}

// MARK: - Codable

extension Template.AnalysisOptions.RestSplit: Codable {
}

// MARK: - Hashable

extension Template.AnalysisOptions.RestSplit: Hashable {
}

// MARK: - Sendable

extension Template.AnalysisOptions.RestSplit: Sendable {
}

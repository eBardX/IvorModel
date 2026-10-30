// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTuning

extension Template.AnalysisOptions {

    // MARK: Public Nested Types

    /// A transposition of the part being analyzed, in the interval type of one pitch notation.
    ///
    /// ``Template/AnalysisOptions`` isn’t generic, so each case carries the interval type of the
    /// pitch notation it suits. A transposition that doesn’t suit the work’s pitch notation makes
    /// analysis throw ``Template/Error/incompatibleOptions``.
    public enum Transposition {
        /// A spelled interval, for standard pitch.
        case interval(DirectedInterval<Interval>)

        /// A number of semitones, for keyboard pitch.
        case noteDistance(DirectedInterval<NoteDistance>)

        /// A frequency ratio, for absolute pitch.
        case ratio(DirectedInterval<Ratio>)
    }
}

// MARK: -

extension Template.AnalysisOptions.Transposition {

    // MARK: Internal Instance Properties

    internal var isUnison: Bool {
        switch self {
        case let .interval(directedInterval):
            directedInterval.interval.isUnison

        case let .noteDistance(directedInterval):
            directedInterval.interval.isUnison

        case let .ratio(directedInterval):
            directedInterval.interval.isUnison
        }
    }
}

// MARK: - Codable

extension Template.AnalysisOptions.Transposition: Codable {
}

// MARK: - Hashable

extension Template.AnalysisOptions.Transposition: Hashable {
}

// MARK: - Sendable

extension Template.AnalysisOptions.Transposition: Sendable {
}

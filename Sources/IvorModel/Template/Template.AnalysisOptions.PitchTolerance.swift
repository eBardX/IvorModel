// © 2026 John Gary Pusey (see LICENSE.md)

extension Template.AnalysisOptions {

    // MARK: Public Nested Types

    /// A way of making near-identical pitches the same.
    public enum PitchTolerance {
        /// Rounds each frequency to the nearest step of the given number of cents, counted from
        /// A4 = 440 Hz. For example, 1 rounds to the nearest cent, and 100 to the nearest
        /// equal-tempered semitone. `cents` must be positive and finite. For absolute-pitch works
        /// only; keyboard and standard pitches are already exact steps.
        case cents(Double)
    }
}

// MARK: -

extension Template.AnalysisOptions.PitchTolerance {

    // MARK: Internal Instance Methods

    internal func validate() throws(Template.Error) {
        switch self {
        case let .cents(cents):
            guard cents.isFinite,
                  cents > 0
            else { throw .invalidTolerance }
        }
    }
}

// MARK: - Codable

extension Template.AnalysisOptions.PitchTolerance: Codable {
}

// MARK: - Hashable

extension Template.AnalysisOptions.PitchTolerance: Hashable {
}

// MARK: - Sendable

extension Template.AnalysisOptions.PitchTolerance: Sendable {
}

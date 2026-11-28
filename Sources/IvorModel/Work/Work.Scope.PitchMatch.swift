// © 2026 John Gary Pusey (see LICENSE.md)

extension Work.Scope {

    // MARK: Public Nested Types

    /// Which of a note’s pitches a criteria’s pitch range tests.
    public enum PitchMatch {
        /// The note’s start pitch or its end pitch falls within the range.
        case either

        /// The note’s end pitch falls within the range.
        case end

        /// The note’s start pitch falls within the range.
        case start
    }
}

// MARK: - Equatable

extension Work.Scope.PitchMatch: Equatable {
}

// MARK: - Hashable

extension Work.Scope.PitchMatch: Hashable {
}

// MARK: - Sendable

extension Work.Scope.PitchMatch: Sendable {
}

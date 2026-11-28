// © 2026 John Gary Pusey (see LICENSE.md)

extension Work.Scope {

    // MARK: Public Nested Types

    /// Which of a note’s times a criteria’s time range tests.
    public enum TimeMatch {
        /// The note’s attack falls within the range.
        case attack

        /// The note sounds at some point within the range: it attacks by the range’s end and is
        /// released no earlier than its start.
        case sounding
    }
}

// MARK: - Equatable

extension Work.Scope.TimeMatch: Equatable {
}

// MARK: - Hashable

extension Work.Scope.TimeMatch: Hashable {
}

// MARK: - Sendable

extension Work.Scope.TimeMatch: Sendable {
}

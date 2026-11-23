// © 2026 John Gary Pusey (see LICENSE.md)

extension Work.Problem {

    // MARK: Public Nested Types

    /// How serious a ``Work/Problem`` is.
    public enum Severity {

        /// The work says two things that can’t both hold.
        case error

        /// Rendering resolved something the composer may want to say more exactly.
        case warning
    }
}

// MARK: - Hashable

extension Work.Problem.Severity: Hashable {
}

// MARK: - Sendable

extension Work.Problem.Severity: Sendable {
}

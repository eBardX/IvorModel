// © 2026 John Gary Pusey (see LICENSE.md)

extension Work {

    // MARK: Public Nested Types

    /// Something in a work that rendering can’t follow exactly as written (see
    /// ``Work/problems()``).
    ///
    /// Problems are worked out from the work each time they’re asked for, never stored. An error
    /// means the work says two things that can’t both hold; rendering still goes ahead, with the
    /// choice its documentation describes. A warning flags something rendering resolved that the
    /// composer may want to say more exactly.
    public struct Problem {

        // MARK: Public Instance Properties

        /// What the problem is.
        public let kind: Kind

        /// The note the problem is about, if it’s about one.
        public let noteID: NoteID?

        /// The index of the part the problem is in, if it’s in one part.
        public let partIndex: Int?

        /// Whether the problem is an error or a warning.
        public let severity: Severity

        /// Where in the work the problem is, if it’s at one moment.
        public let time: WorkTime?

        // MARK: Internal Initializers

        internal init(severity: Severity,
                      kind: Kind,
                      partIndex: Int? = nil,
                      noteID: NoteID? = nil,
                      time: WorkTime? = nil) {
            self.kind = kind
            self.noteID = noteID
            self.partIndex = partIndex
            self.severity = severity
            self.time = time
        }
    }
}

// MARK: - Hashable

extension Work.Problem: Hashable {
}

// MARK: - Sendable

extension Work.Problem: Sendable {
}

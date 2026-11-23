// © 2026 John Gary Pusey (see LICENSE.md)

extension Work {

    // MARK: Public Nested Types

    /// The result of rendering a work (see ``Work/rendered(options:)``).
    public struct Rendering {

        // MARK: Public Instance Properties

        /// Where each fermata’s held span starts in the rendered work, in order, whether or not
        /// it was played or realized — for an exporter that marks each fermata. A fermata on a
        /// note and fermata marks over the same moment count once.
        public let fermataTimes: [WorkTime]

        /// How much later everything sounds than written, to make room for grace notes or a
        /// rolled chord that start before the work’s first beat; `nil` if nothing does.
        public let leadIn: LeadIn?

        /// The rendered work: the same kind of content, with every note’s ornamentation turned
        /// into plain notes, and its fermatas and caesuras turned into time and removed.
        public let work: Work

        // MARK: Internal Initializers

        internal init(work: Work,
                      leadIn: LeadIn?,
                      fermataTimes: [WorkTime]) {
            self.fermataTimes = fermataTimes
            self.leadIn = leadIn
            self.work = work
        }
    }
}

// MARK: - Sendable

extension Work.Rendering: Sendable {
}

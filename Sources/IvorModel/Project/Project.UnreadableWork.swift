// © 2026 John Gary Pusey (see LICENSE.md)

internal import Foundation

extension Project {

    // MARK: Public Nested Types

    /// A work in a project’s file that couldn’t be read — saved in an older format, say.
    ///
    /// Unlike a template, a work can’t be made again, so it isn’t dropped: the project keeps its
    /// file exactly as it was, and writes it back each time it’s saved, so that a version that can
    /// read it gets the work back. Only ``Project/removeUnreadableWork(_:)`` lets it go.
    public struct UnreadableWork {

        // MARK: Internal Initializers

        internal init(workID: WorkID,
                      name: String?,
                      reason: String,
                      contents: Data?) {
            self.contents = contents
            self.name = name
            self.reason = reason
            self.workID = workID
        }

        // MARK: Public Instance Properties

        /// The work’s name, if it could be read on its own; otherwise, `nil`.
        public let name: String?

        /// Why the work couldn’t be read.
        public let reason: String

        /// The work’s ID.
        public let workID: WorkID

        // MARK: Internal Instance Properties

        //
        // The work's file as it was, or `nil` if it was missing.  A missing file has nothing to
        // keep, so it's forgotten when the project is saved.
        //
        internal let contents: Data?
    }
}

// MARK: - Hashable

extension Project.UnreadableWork: Hashable {
}

// MARK: - Sendable

extension Project.UnreadableWork: Sendable {
}

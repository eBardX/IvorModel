// © 2026 John Gary Pusey (see LICENSE.md)

extension Template {

    // MARK: Public Nested Types

    /// A strand a template learned from, as part of a ``Template/Source``.
    ///
    /// The name is copied when the template is made, so that it still reads sensibly after the
    /// strand is renamed or removed.
    public struct SourceStrand {

        // MARK: Public Initializers

        /// Creates a new source strand.
        ///
        /// - Parameter strandID:   The ID of the strand.
        /// - Parameter name:       The name of the strand, when the template learned from it;
        ///                         empty for an unnamed strand.
        public init(strandID: StrandID,
                    name: String) {
            self.name = name
            self.strandID = strandID
        }

        // MARK: Public Instance Properties

        /// The name of the strand, when the template learned from it; empty for an unnamed
        /// strand.
        public let name: String

        /// The ID of the strand.
        public let strandID: StrandID
    }
}

// MARK: - Codable

extension Template.SourceStrand: Codable {
}

// MARK: - Hashable

extension Template.SourceStrand: Hashable {
}

// MARK: - Sendable

extension Template.SourceStrand: Sendable {
}

// © 2026 John Gary Pusey (see LICENSE.md)

extension Template {

    // MARK: Public Nested Types

    /// A part a template learned from.
    ///
    /// The names are copied when the template is made, so that they still read sensibly after the
    /// work or part is renamed or deleted.
    public struct Source {

        // MARK: Public Initializers

        /// Creates a new source.
        ///
        /// - Parameter workID:     The ID of the work.
        /// - Parameter workName:   The name of the work, when the template learned from it.
        /// - Parameter partID:     The ID of the part.
        /// - Parameter partName:   The name of the part, when the template learned from it.
        public init(workID: WorkID,
                    workName: String,
                    partID: PartID,
                    partName: String) {
            self.partID = partID
            self.partName = partName
            self.workID = workID
            self.workName = workName
        }

        // MARK: Public Instance Properties

        /// The ID of the part.
        public let partID: PartID

        /// The name of the part, when the template learned from it.
        public let partName: String

        /// The ID of the work.
        public let workID: WorkID

        /// The name of the work, when the template learned from it.
        public let workName: String
    }
}

// MARK: -

extension Template.Source {

    // MARK: Internal Initializers

    //
    // The part at `index` of `work`, or `nil` if there's none.
    //
    internal init?(work: Work,
                   index: Int) {
        let partIDs = work.partIDs

        guard partIDs.indices.contains(index)
        else { return nil }

        self.init(workID: work.workID,
                  workName: work.name,
                  partID: partIDs[index],
                  partName: work.partName(at: index))
    }
}

// MARK: - Codable

extension Template.Source: Codable {
}

// MARK: - Hashable

extension Template.Source: Hashable {
}

// MARK: - Sendable

extension Template.Source: Sendable {
}

// © 2026 John Gary Pusey (see LICENSE.md)

extension Template {

    // MARK: Public Nested Types

    /// What a template learned from: a part of a work, and the strands of it that were merged
    /// into one note sequence — all of them, some of them, or some of their notes.
    ///
    /// The names are copied when the template is made, so that they still read sensibly after the
    /// work, part or strands are renamed or deleted. A template never reads its sources again.
    public struct Source {

        // MARK: Public Initializers

        /// Creates a new source.
        ///
        /// - Parameter workID:             The ID of the work.
        /// - Parameter workName:           The name of the work, when the template learned from
        ///                                 it.
        /// - Parameter partID:             The ID of the part.
        /// - Parameter partName:           The name of the part, when the template learned from
        ///                                 it.
        /// - Parameter strands:            The strands of the part the template learned from, in
        ///                                 score order.
        /// - Parameter isNoteSelection:    Whether the template learned from some of the strands’
        ///                                 notes, rather than whole strands.
        public init(workID: WorkID,
                    workName: String,
                    partID: PartID,
                    partName: String,
                    strands: [SourceStrand],
                    isNoteSelection: Bool) {
            self.isNoteSelection = isNoteSelection
            self.partID = partID
            self.partName = partName
            self.strands = strands
            self.workID = workID
            self.workName = workName
        }

        // MARK: Public Instance Properties

        /// Whether the template learned from some of the strands’ notes, such as a few bars,
        /// rather than whole strands.
        public let isNoteSelection: Bool

        /// The ID of the part.
        public let partID: PartID

        /// The name of the part, when the template learned from it.
        public let partName: String

        /// The strands of the part the template learned from, in score order: every strand the
        /// part had, unless the source named only some.
        public let strands: [SourceStrand]

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
    // What `source` takes of `work`, or `nil` if its part isn't in `work`.
    //
    internal init?(work: Work,
                   source: Template.SourceScope) {
        guard let made = Self._make(work: work,
                                    body: work.content.body,
                                    source: source)
        else { return nil }

        self = made
    }

    // MARK: Private Type Methods

    private static func _make(work: Work,
                              body: some Work.Body,
                              source: Template.SourceScope) -> Self? {
        guard let notes = source.notes(in: body.parts)
        else { return nil }

        let strands = notes.strands.map {
            Template.SourceStrand(strandID: $0.strandID,
                                  name: $0.name)
        }

        return Self(workID: work.workID,
                    workName: work.name,
                    partID: notes.part.partID,
                    partName: notes.part.name,
                    strands: strands,
                    isNoteSelection: notes.isNoteSelection)
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

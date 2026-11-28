// © 2026 John Gary Pusey (see LICENSE.md)

extension Template {

    // MARK: Internal Nested Types

    //
    // A template source's `Work.Scope`, resolved against its work: the one part it reaches into,
    // and what it takes of that part.
    //
    internal struct SourceScope {

        // MARK: Internal Initializers

        internal init(partID: PartID,
                      selection: Work.PartSelection) {
            self.partID = partID
            self.selection = selection
        }

        //
        // `scope` resolved against `work`. It must take something of exactly one part.
        //
        internal init(_ scope: Work.Scope,
                      in work: Work) throws(Template.Error) {
            let resolved: Work.ResolvedScope

            do {
                resolved = try scope.resolved(in: work.content.body)
            } catch {
                throw Self._templateError(error)
            }

            guard let (partID, selection) = resolved.selections.first
            else { throw .sourceIsEmpty }

            guard resolved.selections.count == 1
            else { throw .sourceSpansParts }

            self.init(partID: partID,
                      selection: selection)
        }

        // MARK: Internal Instance Properties

        internal let partID: PartID
        internal let selection: Work.PartSelection
    }
}

// MARK: -

extension Template.SourceScope {

    // MARK: Internal Instance Methods

    //
    // The notes this source takes of its part among `parts`, or `nil` if the part isn't there.
    //
    internal func notes<T, P>(in parts: [Part<T, P>]) -> Template.SourceNotes<T, P>? {
        parts
            .first { $0.partID == partID }
            .map { Template.SourceNotes(part: $0, selection: selection) }
    }

    // MARK: Private Type Methods

    private static func _templateError(_ error: Work.Error) -> Template.Error {
        switch error {
        case let .unknownNoteID(noteID):
            .noteNotFound(noteID)

        case let .unknownPartID(partID):
            .partNotFound(partID)

        case let .unknownStrandID(strandID):
            .strandNotFound(strandID)

        default:
            preconditionFailure("Resolving a scope fails only for an ID that isn’t in the work.")
        }
    }
}

// MARK: - Sendable

extension Template.SourceScope: Sendable {
}

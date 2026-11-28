// © 2026 John Gary Pusey (see LICENSE.md)

extension Work {

    // MARK: Internal Nested Types

    //
    // What a resolved `Work.Scope` takes of one strand: the whole strand, or some of its notes.
    // Notes never add up to a whole strand, even when they are all of its notes.
    //
    internal enum StrandSelection {
        case notes(Set<NoteID>)
        case whole
    }
}

// MARK: -

extension Work.StrandSelection {

    // MARK: Internal Instance Properties

    //
    // The `noteIDs:` a note table transform takes for this selection: `nil` (every note) for a
    // whole strand.
    //
    internal var noteIDs: Set<NoteID>? {
        switch self {
        case let .notes(noteIDs):
            noteIDs

        case .whole:
            nil
        }
    }
}

// MARK: - Equatable

extension Work.StrandSelection: Equatable {
}

// MARK: - Sendable

extension Work.StrandSelection: Sendable {
}

// © 2026 John Gary Pusey (see LICENSE.md)

extension Work {

    // MARK: Internal Nested Types

    //
    // What a resolved `Work.Scope` takes of one part: the whole part, or some of its strands.
    // Wholes add up: a scope naming every strand of a part whole resolves to `.whole`.
    //
    internal enum PartSelection {
        case strands([StrandID: StrandSelection])
        case whole
    }
}

// MARK: - Equatable

extension Work.PartSelection: Equatable {
}

// MARK: - Sendable

extension Work.PartSelection: Sendable {
}

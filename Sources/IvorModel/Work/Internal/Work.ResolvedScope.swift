// © 2026 John Gary Pusey (see LICENSE.md)

extension Work {

    // MARK: Internal Nested Types

    //
    // A `Work.Scope` resolved against a work's parts: for each part it touches, what it takes of
    // it. A part it doesn't touch has no selection.
    //
    internal struct ResolvedScope {

        // MARK: Internal Initializers

        internal init(selections: [PartID: PartSelection],
                      partIDs: [PartID]) {
            self.coversWork = partIDs.allSatisfy { selections[$0] == .whole }
            self.selections = selections
        }

        // MARK: Internal Instance Properties

        //
        // Whether the scope takes every part whole, so the work's own tables are carried.
        //
        internal let coversWork: Bool

        internal let selections: [PartID: PartSelection]
    }
}

// MARK: -

extension Work.ResolvedScope {

    // MARK: Internal Instance Methods

    //
    // The work tables (tempo map, meter table, key table) a transform carries: those `applyTo`
    // names, when the scope covers the whole work; otherwise only those `alsoCarry` opts in.
    //
    internal func workTargets(applyTo: TransformTargets,
                              alsoCarry: TransformTargets) -> TransformTargets {
        let workTables: TransformTargets = [.key, .meter, .tempo]

        return applyTo.intersection(workTables).intersection(coversWork ? workTables : alsoCarry)
    }
}

// MARK: - Sendable

extension Work.ResolvedScope: Sendable {
}

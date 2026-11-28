// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

extension Work {

    // MARK: Public Instance Methods

    /// Finds the notes that satisfy some criteria, among those another scope takes.
    ///
    /// The result names the notes one by one, so it never covers a whole strand, and a transform
    /// with it carries only what a choice of notes carries (see ``Work/Scope``).
    ///
    /// - Parameter criteria:   What a note must satisfy. Its time and pitch types must be this
    ///                         work’s.
    /// - Parameter scope:      The notes to look among. Defaults to ``Work/Scope/all``.
    ///
    /// - Returns:  A scope of the notes found.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` or
    ///             ``Work/Error/pitchNotationMismatch(expected:)`` if `criteria` is of another
    ///             time or pitch type than this work; an unknown-ID case if `scope` names
    ///             something not in this work.
    public func scope(matching criteria: Scope.Criteria<some TimeProtocol, some PitchProtocol>,
                      within scope: Scope = .all) throws(Error) -> Scope {
        try Self._scope(of: content.body,
                        matching: criteria,
                        within: scope)
    }

    // MARK: Private Type Methods

    private static func _scope<WorkBody: Body, TimeType, PitchType>(of body: WorkBody,
                                                                    matching criteria: Scope.Criteria<TimeType, PitchType>,
                                                                    within scope: Scope) throws(Error) -> Scope {
        guard WorkBody.TimeType.self == TimeType.self
        else { throw Error.timeBasisMismatch(expected: WorkBody.timeBasis) }

        guard let parts = body.parts as? [Part<TimeType, PitchType>]
        else { throw Error.pitchNotationMismatch(expected: WorkBody.pitchNotation) }

        let resolution = try scope.resolved(in: body)
        var noteIDs: [NoteID] = []

        for part in parts {
            guard let selection = resolution.selections[part.partID]
            else { continue }

            let plan = part.carryPlan(for: selection, applyTo: [], alsoCarry: [])

            for (strand, strandSelection) in zip(part.strands, plan.strandSelections) {
                guard let strandSelection
                else { continue }

                for note in strand.noteTable where strandSelection.noteIDs?.contains(note.noteID) ?? true && criteria.matches(note) {
                    noteIDs.append(note.noteID)
                }
            }
        }

        return Scope(notes: noteIDs)
    }
}

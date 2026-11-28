// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

internal import IvorTuning

extension Work {

    // MARK: Public Instance Methods

    /// Moves note attack times by a directed duration across the notes of this beat-time work
    /// that `scope` takes, along with the tables it carries.
    ///
    /// A table is carried only when `scope` covers everything that shares it (see
    /// ``Work/Scope``), and `applyTo` names its kind; `alsoCarry` opts shared tables in anyway.
    /// The work’s tempo map, meter table and key table need the whole work.
    ///
    /// The meter table moves as ``MeterTable/move(by:)`` describes: every barline stays where the
    /// music takes it, and a meter that started at 0 still does.
    ///
    /// - Parameter directedDuration:   The directed duration by which to move the attack times.
    /// - Parameter applyTo:            The kinds of table to move along with the notes. Defaults
    ///                                 to every kind.
    /// - Parameter alsoCarry:          The kinds of shared table to carry even though `scope`
    ///                                 doesn’t cover everything that shares them. Defaults to
    ///                                 none.
    /// - Parameter scope:              The notes to move. Defaults to ``Work/Scope/all``.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; an unknown-ID case if `scope` names something not in this work;
    ///             otherwise, a transform-failure case naming the part (or the tempo map) and
    ///             sub-structure that failed.
    public mutating func move(by directedDuration: DirectedDuration<BeatDuration>,
                              applyTo: TransformTargets = .all,
                              alsoCarry: TransformTargets = [],
                              scope: Scope = .all) throws(Error) {
        try ensureUnlocked()

        guard var body = content.body as? any BeatTimeBody
        else { throw Error.timeBasisMismatch(expected: .beat) }

        try Self._move(&body,
                       by: directedDuration,
                       applyTo: applyTo,
                       alsoCarry: alsoCarry,
                       scope: scope)

        content.body = body
    }

    /// Moves note attack times by a directed duration across the notes of this wall-time work
    /// that `scope` takes, along with the tables it carries.
    ///
    /// A table is carried only when `scope` covers everything that shares it (see
    /// ``Work/Scope``), and `applyTo` names its kind; `alsoCarry` opts shared tables in anyway.
    ///
    /// - Parameter directedDuration:   The directed duration by which to move the attack times.
    /// - Parameter applyTo:            The kinds of table to move along with the notes. Defaults
    ///                                 to every kind.
    /// - Parameter alsoCarry:          The kinds of shared table to carry even though `scope`
    ///                                 doesn’t cover everything that shares them. Defaults to
    ///                                 none.
    /// - Parameter scope:              The notes to move. Defaults to ``Work/Scope/all``.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use wall
    ///             time; an unknown-ID case if `scope` names something not in this work;
    ///             otherwise, a transform-failure case naming the part and sub-structure that
    ///             failed.
    public mutating func move(by directedDuration: DirectedDuration<WallDuration>,
                              applyTo: TransformTargets = .all,
                              alsoCarry: TransformTargets = [],
                              scope: Scope = .all) throws(Error) {
        try ensureUnlocked()

        guard var body = content.body as? any WallTimeBody
        else { throw Error.timeBasisMismatch(expected: .wall) }

        try Self._moveParts(&body,
                            by: directedDuration,
                            applyTo: applyTo,
                            alsoCarry: alsoCarry,
                            resolution: scope.resolved(in: body))

        content.body = body
    }

    // MARK: Private Type Methods

    private static func _move(_ body: inout some BeatTimeBody,
                              by directedDuration: DirectedDuration<BeatDuration>,
                              applyTo: TransformTargets,
                              alsoCarry: TransformTargets,
                              scope: Scope) throws(Error) {
        let resolution = try scope.resolved(in: body)
        let workTargets = resolution.workTargets(applyTo: applyTo,
                                                 alsoCarry: alsoCarry)

        try _moveParts(&body,
                       by: directedDuration,
                       applyTo: applyTo,
                       alsoCarry: alsoCarry,
                       resolution: resolution)

        body.tempoMap = try carried(tempoMap: body.tempoMap,
                                    applyTo: workTargets,
                                    kind: .move) { (tempo: inout TempoMap) throws(TempoMap.Error) in
            try tempo.move(by: directedDuration)
        }
        body.meterTable = try carried(meterTable: body.meterTable,
                                      applyTo: workTargets,
                                      kind: .move) { (meter: inout MeterTable) throws(MeterTable.Error) in
            meter.move(by: directedDuration)
        }
        body.keyTable = try carried(keyTable: body.keyTable,
                                    applyTo: workTargets,
                                    kind: .move) { (key: inout KeyTable) throws(KeyTable.Error) in
            key.move(by: directedDuration)
        }
    }

    private static func _moveParts<WorkBody: Body>(_ body: inout WorkBody,
                                                   by directedDuration: DirectedDuration<WorkBody.TimeType.DurationType>,
                                                   applyTo: TransformTargets,
                                                   alsoCarry: TransformTargets,
                                                   resolution: ResolvedScope) throws(Error) {
        typealias PartType = Part<WorkBody.TimeType, WorkBody.PitchType>

        try transform(&body,
                      resolution: resolution,
                      kind: .move) { (part: inout PartType, selection) throws(PartType.Error) in
            try part.move(by: directedDuration,
                          selection: selection,
                          applyTo: applyTo,
                          alsoCarry: alsoCarry)
        }
    }
}

// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiNumbers

internal import IvorTuning

extension Work {

    // MARK: Public Instance Methods

    /// Augments note attack times and durations by a rational factor across the notes of this
    /// beat-time work that `scope` takes, along with the tables it carries.
    ///
    /// A table is carried only when `scope` covers everything that shares it (see
    /// ``Work/Scope``), and `applyTo` names its kind; `alsoCarry` opts shared tables in anyway.
    /// The work’s tempo map, meter table and key table need the whole work.
    ///
    /// When the meter table is carried, the meter scales with the music (see
    /// ``MeterTable/augment(by:anchor:)``), so every note keeps its `bar:beat`. When it isn’t, the
    /// music spans more bars of the same meter.
    ///
    /// By default, the music sounds slower afterwards. With `keepingSound`, each tempo from the
    /// anchor on keeps its rate while its unit scales with the music (see
    /// `TempoMap.scaleUnits(by:from:)`), so nothing sounds different.
    ///
    /// - Parameter factor:         A rational number ≥ 1 by which to stretch the note timings.
    /// - Parameter anchor:         The low beat-time bound to stretch attack times relative to.
    ///                             `nil` resolves to the start of everything being augmented: the
    ///                             scope’s notes and every table carried whole.
    /// - Parameter applyTo:        The kinds of table to augment along with the notes. Defaults to
    ///                             every kind.
    /// - Parameter alsoCarry:      The kinds of shared table to carry even though `scope` doesn’t
    ///                             cover everything that shares them. Defaults to none.
    /// - Parameter keepingSound:   Whether to scale the tempo units too, so that the music
    ///                             sounds the same. It has an effect only when the tempo map is
    ///                             carried. Defaults to `false`.
    /// - Parameter scope:          The notes to augment. Defaults to ``Work/Scope/all``.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; an unknown-ID case if `scope` names something not in this work;
    ///             otherwise, a transform-failure case naming the part (or the tempo map or
    ///             meter table) and sub-structure that failed.
    public mutating func augment(by factor: Number,
                                 anchor: BeatTime? = nil,
                                 applyTo: TransformTargets = .all,
                                 alsoCarry: TransformTargets = [],
                                 keepingSound: Bool = false,
                                 scope: Scope = .all) throws(Error) {
        try ensureUnlocked()

        guard var body = content.body as? any BeatTimeBody
        else { throw Error.timeBasisMismatch(expected: .beat) }

        try Self._augment(&body,
                          by: factor,
                          anchor: anchor,
                          applyTo: applyTo,
                          alsoCarry: alsoCarry,
                          keepingSound: keepingSound,
                          scope: scope)

        content.body = body
    }

    /// Augments note attack times and durations by a rational factor across the notes of this
    /// wall-time work that `scope` takes, along with the tables it carries.
    ///
    /// A table is carried only when `scope` covers everything that shares it (see
    /// ``Work/Scope``), and `applyTo` names its kind; `alsoCarry` opts shared tables in anyway.
    ///
    /// - Parameter factor:     A rational number ≥ 1 by which to stretch the note timings.
    /// - Parameter anchor:     The low wall-time bound to stretch attack times relative to.
    ///                         `nil` resolves to the start of everything being augmented: the
    ///                         scope’s notes and every table carried whole.
    /// - Parameter applyTo:    The kinds of table to augment along with the notes. Defaults to
    ///                         every kind.
    /// - Parameter alsoCarry:  The kinds of shared table to carry even though `scope` doesn’t
    ///                         cover everything that shares them. Defaults to none.
    /// - Parameter scope:      The notes to augment. Defaults to ``Work/Scope/all``.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use wall
    ///             time; an unknown-ID case if `scope` names something not in this work;
    ///             otherwise, a transform-failure case naming the part and sub-structure that
    ///             failed.
    public mutating func augment(by factor: Number,
                                 anchor: WallTime? = nil,
                                 applyTo: TransformTargets = .all,
                                 alsoCarry: TransformTargets = [],
                                 scope: Scope = .all) throws(Error) {
        try ensureUnlocked()

        guard var body = content.body as? any WallTimeBody
        else { throw Error.timeBasisMismatch(expected: .wall) }

        try Self._augmentParts(&body,
                               by: factor,
                               anchor: anchor,
                               applyTo: applyTo,
                               alsoCarry: alsoCarry,
                               resolution: scope.resolved(in: body))

        content.body = body
    }

    // MARK: Private Type Methods

    private static func _augment(_ body: inout some BeatTimeBody,
                                 by factor: Number,
                                 anchor: BeatTime?,
                                 applyTo: TransformTargets,
                                 alsoCarry: TransformTargets,
                                 keepingSound: Bool,
                                 scope: Scope) throws(Error) {
        let resolution = try scope.resolved(in: body)
        let workTargets = resolution.workTargets(applyTo: applyTo,
                                                 alsoCarry: alsoCarry)
        let anchor = anchor ?? transformTimeRange(of: body,
                                                  resolution: resolution,
                                                  applyTo: applyTo,
                                                  alsoCarry: alsoCarry)?.lowerBound

        try _augmentParts(&body,
                          by: factor,
                          anchor: anchor,
                          applyTo: applyTo,
                          alsoCarry: alsoCarry,
                          resolution: resolution)

        (body.tempoMap, body.meterTable, body.keyTable) = try _augmentedTables(tempoMap: body.tempoMap,
                                                                               meterTable: body.meterTable,
                                                                               keyTable: body.keyTable,
                                                                               by: factor,
                                                                               anchor: anchor,
                                                                               applyTo: workTargets,
                                                                               keepingSound: keepingSound)
    }

    //
    // The scope's notes augmented, with the tables each part carries. `anchor` `nil` resolves to
    // the start of everything that moves.
    //
    private static func _augmentParts<WorkBody: Body>(_ body: inout WorkBody,
                                                      by factor: Number,
                                                      anchor: WorkBody.TimeType?,
                                                      applyTo: TransformTargets,
                                                      alsoCarry: TransformTargets,
                                                      resolution: ResolvedScope) throws(Error) {
        typealias PartType = Part<WorkBody.TimeType, WorkBody.PitchType>

        let anchor = anchor ?? partsTimeRange(of: body,
                                              resolution: resolution,
                                              applyTo: applyTo,
                                              alsoCarry: alsoCarry)?.lowerBound

        try transform(&body,
                      resolution: resolution,
                      kind: .augment) { (part: inout PartType, selection) throws(PartType.Error) in
            try part.augment(by: factor,
                             anchor: anchor,
                             selection: selection,
                             applyTo: applyTo,
                             alsoCarry: alsoCarry)
        }
    }

    //
    // The work-wide tables a beat-time augment carries along: the tempo map, meter table and key
    // table, each only when `applyTo` (the work targets the scope carries) names it.
    //
    private static func _augmentedTables(tempoMap: TempoMap,
                                         meterTable: MeterTable,
                                         keyTable: KeyTable,
                                         by factor: Number,
                                         anchor resolvedAnchor: BeatTime?,
                                         applyTo: TransformTargets,
                                         keepingSound: Bool) throws(Error) -> (TempoMap, MeterTable, KeyTable) {
        let newTempoMap = try Self.carried(tempoMap: tempoMap,
                                           applyTo: applyTo,
                                           kind: .augment) { (tempo: inout TempoMap) throws(TempoMap.Error) in
            try tempo.augment(by: factor,
                              anchor: resolvedAnchor)

            Self.scaleRampDurations(in: &tempo,
                                    by: factor.doubleValue)

            if keepingSound {
                tempo.scaleUnits(by: factor,
                                 from: resolvedAnchor ?? .zero)
            }
        }
        let newMeterTable = try Self.carried(meterTable: meterTable,
                                             applyTo: applyTo,
                                             kind: .augment) { (meter: inout MeterTable) throws(MeterTable.Error) in
            try meter.augment(by: factor,
                              anchor: resolvedAnchor ?? .zero)
        }
        let newKeyTable = try Self.carried(keyTable: keyTable,
                                           applyTo: applyTo,
                                           kind: .augment) { (key: inout KeyTable) throws(KeyTable.Error) in
            try key.augment(by: factor,
                            anchor: resolvedAnchor ?? .zero)
        }

        return (newTempoMap, newMeterTable, newKeyTable)
    }
}

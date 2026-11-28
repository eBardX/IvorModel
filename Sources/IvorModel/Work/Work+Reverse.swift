// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

internal import IvorTuning
internal import XestiNumbers
internal import XestiTools

extension Work {

    // MARK: Public Instance Methods

    /// Reverses the order of notes within a beat-time range across the notes of this beat-time
    /// work that `scope` takes, along with the tables it carries.
    ///
    /// A table is carried only when `scope` covers everything that shares it (see
    /// ``Work/Scope``), and `applyTo` names its kind; `alsoCarry` opts shared tables in anyway.
    /// The work’s tempo map, meter table and key table need the whole work.
    ///
    /// The meter table’s bars within the range are reversed as ``MeterTable/reverse(within:)``
    /// describes, and the grid after the range is kept.
    ///
    /// - Parameter timeRange:  The beat-time range to mirror attack times around; it must take in
    ///                         every note being reversed. `nil` resolves to the span of
    ///                         everything being reversed: the scope’s notes and every table
    ///                         carried whole.
    /// - Parameter applyTo:    The kinds of table to reverse along with the notes. Defaults to
    ///                         every kind.
    /// - Parameter alsoCarry:  The kinds of shared table to carry even though `scope` doesn’t
    ///                         cover everything that shares them. Defaults to none.
    /// - Parameter scope:      The notes to reverse. Defaults to ``Work/Scope/all``.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; an unknown-ID case if `scope` names something not in this work;
    ///             otherwise, a transform-failure case naming the part (or the tempo map) and
    ///             sub-structure that failed.
    public mutating func reverse(within timeRange: ClosedRange<BeatTime>? = nil,
                                 applyTo: TransformTargets = .all,
                                 alsoCarry: TransformTargets = [],
                                 scope: Scope = .all) throws(Error) {
        try ensureUnlocked()

        guard var body = content.body as? any BeatTimeBody
        else { throw Error.timeBasisMismatch(expected: .beat) }

        try Self._reverse(&body,
                          within: timeRange,
                          applyTo: applyTo,
                          alsoCarry: alsoCarry,
                          scope: scope)

        content.body = body
    }

    /// Reverses the order of notes within a wall-time range across the notes of this wall-time
    /// work that `scope` takes, along with the tables it carries.
    ///
    /// A table is carried only when `scope` covers everything that shares it (see
    /// ``Work/Scope``), and `applyTo` names its kind; `alsoCarry` opts shared tables in anyway.
    ///
    /// - Parameter timeRange:  The wall-time range to mirror attack times around; it must take in
    ///                         every note being reversed. `nil` resolves to the span of
    ///                         everything being reversed: the scope’s notes and every table
    ///                         carried whole.
    /// - Parameter applyTo:    The kinds of table to reverse along with the notes. Defaults to
    ///                         every kind.
    /// - Parameter alsoCarry:  The kinds of shared table to carry even though `scope` doesn’t
    ///                         cover everything that shares them. Defaults to none.
    /// - Parameter scope:      The notes to reverse. Defaults to ``Work/Scope/all``.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use wall
    ///             time; an unknown-ID case if `scope` names something not in this work;
    ///             otherwise, a transform-failure case naming the part and sub-structure that
    ///             failed.
    public mutating func reverse(within timeRange: ClosedRange<WallTime>? = nil,
                                 applyTo: TransformTargets = .all,
                                 alsoCarry: TransformTargets = [],
                                 scope: Scope = .all) throws(Error) {
        try ensureUnlocked()

        guard var body = content.body as? any WallTimeBody
        else { throw Error.timeBasisMismatch(expected: .wall) }

        try Self._reverseParts(&body,
                               within: timeRange,
                               applyTo: applyTo,
                               alsoCarry: alsoCarry,
                               resolution: scope.resolved(in: body))

        content.body = body
    }

    // MARK: Private Type Methods

    private static func _reverse(_ body: inout some BeatTimeBody,
                                 within timeRange: ClosedRange<BeatTime>?,
                                 applyTo: TransformTargets,
                                 alsoCarry: TransformTargets,
                                 scope: Scope) throws(Error) {
        let resolution = try scope.resolved(in: body)
        let workTargets = resolution.workTargets(applyTo: applyTo,
                                                 alsoCarry: alsoCarry)
        let timeRange = timeRange ?? transformTimeRange(of: body,
                                                        resolution: resolution,
                                                        applyTo: applyTo,
                                                        alsoCarry: alsoCarry)

        try _reverseParts(&body,
                          within: timeRange,
                          applyTo: applyTo,
                          alsoCarry: alsoCarry,
                          resolution: resolution)

        (body.tempoMap, body.meterTable, body.keyTable) = try _reversedTables(tempoMap: body.tempoMap,
                                                                              meterTable: body.meterTable,
                                                                              keyTable: body.keyTable,
                                                                              within: timeRange,
                                                                              applyTo: workTargets)
    }

    //
    // The scope's notes reversed, with the tables each part carries. `timeRange` `nil` resolves
    // to the span of everything that moves.
    //
    private static func _reverseParts<WorkBody: Body>(_ body: inout WorkBody,
                                                      within timeRange: ClosedRange<WorkBody.TimeType>?,
                                                      applyTo: TransformTargets,
                                                      alsoCarry: TransformTargets,
                                                      resolution: ResolvedScope) throws(Error) {
        typealias PartType = Part<WorkBody.TimeType, WorkBody.PitchType>

        let timeRange = timeRange ?? partsTimeRange(of: body,
                                                    resolution: resolution,
                                                    applyTo: applyTo,
                                                    alsoCarry: alsoCarry)

        try transform(&body,
                      resolution: resolution,
                      kind: .reverse) { (part: inout PartType, selection) throws(PartType.Error) in
            try part.reverse(within: timeRange,
                             selection: selection,
                             applyTo: applyTo,
                             alsoCarry: alsoCarry)
        }
    }

    //
    // The JohnnySonic ramp extras (`rampStartTempo`, `rampEndTempo` and `rampDuration`) describe
    // a ramp that starts at their entry and runs `rampDuration` whole notes, and the exporter
    // trusts them over the map. Reversing mirrors entry times, which leaves them where the ramp
    // now *ends*, still running the old way. `TempoMap.reverse` only accepts a range that holds every
    // entry, so every ramp starts within it. A ramp that also ends within it is mirrored whole:
    // its extras move to the last entry at its new start, with the start and end tempos swapped,
    // inserting an entry that holds the tempo already in effect if there's none there. A ramp
    // that runs past the range's end is only partly reversed, so no extras can describe it: drop
    // them, and the exporter rebuilds the ramp from the map. Incomplete ramp extras, which the
    // exporter ignores, are left alone.
    //
    private static func _moveRampExtras(in tempoMap: inout TempoMap,
                                        reversedFrom original: TempoMap,
                                        within timeRange: ClosedRange<BeatTime>?) {
        guard let first = original.first,
              let last = original.last
        else { return }

        let range = timeRange ?? first.beatTime...last.beatTime
        let mirrorSum = range.lowerBound.numberValue + range.upperBound.numberValue
        var moves: [(entryID: TempoMap.EntryID, ramp: [Extra], newStart: BeatTime?)] = []

        for entry in original {
            guard let ramp = _rampExtras(in: entry.extras),
                  case let .double(duration)? = ramp[2].values.first
            else { continue }

            let end = entry.beatTime.numberValue + Number(duration)
            let newStart = end <= range.upperBound.numberValue ? BeatTime(numberValue: mirrorSum - end) : nil

            moves.append((entry.entryID, ramp, newStart))
        }

        for move in moves {
            guard let entry = tempoMap.first(where: { $0.entryID == move.entryID })
            else { continue }

            let extras = move.ramp.reduce(entry.extras ?? Extras()) { $0.removing($1) }

            tempoMap.update(entryID: move.entryID,
                            tempo: entry.tempo,
                            extras: extras.isEmpty ? nil : extras)
        }

        for move in moves {
            guard let newStart = move.newStart
            else { continue }

            let newRamp = [Extra(name: Extra.rampStartTempo.name, values: move.ramp[1].values),
                           Extra(name: Extra.rampEndTempo.name, values: move.ramp[0].values),
                           move.ramp[2]]

            if let target = tempoMap.last(where: { $0.beatTime == newStart }) {
                tempoMap.update(entryID: target.entryID,
                                tempo: target.tempo,
                                extras: newRamp.reduce(target.extras ?? Extras()) { $0.inserting($1) })
            } else {
                tempoMap.insert(beatTime: newStart,
                                tempo: tempoMap[newStart],
                                extras: Extras(elements: newRamp))
            }
        }
    }

    //
    // `tempoText` labels the section that starts at its entry and runs to the next labeled
    // entry, or to the end of the range. Reversing mirrors entry times, which leaves each label
    // where its section now *ends*, so move each one to its section's new start: the last entry
    // at that beat time, so that a step's new value carries it. Every section end but the last
    // is a labeled entry's beat time, so it always has an entry to mirror; only the range's
    // upper bound may not, and its mirror is the lower bound, before every entry. There, insert
    // an entry holding the tempo already in effect, so playback doesn't change. A label whose
    // section is empty (two labeled entries at the same beat time) stays on its entry.
    //
    private static func _moveTempoText(in tempoMap: inout TempoMap,
                                       reversedFrom original: TempoMap,
                                       within timeRange: ClosedRange<BeatTime>?) {
        let labels = original.compactMap { entry in
            entry.extras?.elements.first { $0.name == Extra.tempoText.name }.map { (entry, $0) }
        }

        guard !labels.isEmpty,
              let first = original.first,
              let last = original.last
        else { return }

        let range = timeRange ?? first.beatTime...last.beatTime
        var moves: [(entryID: TempoMap.EntryID, label: Extra, newStart: BeatTime)] = []

        for (idx, (entry, label)) in labels.enumerated() {
            let sectionEnd = idx + 1 < labels.count ? labels[idx + 1].0.beatTime : range.upperBound

            guard sectionEnd > entry.beatTime,
                  let dirDur = sectionEnd.duration(to: range.upperBound),
                  let newStart = range.lowerBound.moved(by: dirDur)
            else { continue }

            moves.append((entry.entryID, label, newStart))
        }

        for move in moves {
            guard let entry = tempoMap.first(where: { $0.entryID == move.entryID })
            else { continue }

            let extras = entry.extras?.removing(move.label)

            tempoMap.update(entryID: move.entryID,
                            tempo: entry.tempo,
                            extras: extras?.isEmpty ?? true ? nil : extras)
        }

        for move in moves {
            if let target = tempoMap.last(where: { $0.beatTime == move.newStart }) {
                tempoMap.update(entryID: target.entryID,
                                tempo: target.tempo,
                                extras: (target.extras ?? Extras()).inserting(move.label))
            } else {
                tempoMap.insert(beatTime: move.newStart,
                                tempo: tempoMap[move.newStart],
                                extras: Extras(elements: [move.label]))
            }
        }
    }

    //
    // The three ramp extras on an entry, in start, end, duration order, or `nil` unless all three
    // are present.
    //
    private static func _rampExtras(in extras: Extras?) -> [Extra]? {
        let names = [Extra.rampStartTempo.name, Extra.rampEndTempo.name, Extra.rampDuration.name]
        let ramp = names.compactMap { name in extras?.elements.first { $0.name == name } }

        return ramp.count == names.count ? ramp : nil
    }

    //
    // The work-wide tables a beat-time reverse carries along: the tempo map, meter table and key
    // table, each only when `applyTo` (the work targets the scope carries) names it.
    //
    private static func _reversedTables(tempoMap: TempoMap,
                                        meterTable: MeterTable,
                                        keyTable: KeyTable,
                                        within resolvedRange: ClosedRange<BeatTime>?,
                                        applyTo: TransformTargets) throws(Error) -> (TempoMap, MeterTable, KeyTable) {
        let newTempoMap = try Self.carried(tempoMap: tempoMap,
                                           applyTo: applyTo,
                                           kind: .reverse) { (tempo: inout TempoMap) throws(TempoMap.Error) in
            let original = tempo

            try tempo.reverse(within: resolvedRange)

            Self._moveRampExtras(in: &tempo,
                                 reversedFrom: original,
                                 within: resolvedRange)
            Self._moveTempoText(in: &tempo,
                                reversedFrom: original,
                                within: resolvedRange)
        }
        let newMeterTable = try Self.carried(meterTable: meterTable,
                                             applyTo: applyTo,
                                             kind: .reverse) { (meter: inout MeterTable) throws(MeterTable.Error) in
            if let resolvedRange {
                meter.reverse(within: resolvedRange)
            }
        }
        let newKeyTable = try Self.carried(keyTable: keyTable,
                                           applyTo: applyTo,
                                           kind: .reverse) { (key: inout KeyTable) throws(KeyTable.Error) in
            if let resolvedRange {
                key.reverse(within: resolvedRange)
            }
        }

        return (newTempoMap, newMeterTable, newKeyTable)
    }
}

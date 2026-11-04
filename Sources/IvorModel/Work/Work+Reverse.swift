// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

internal import IvorTuning
internal import XestiNumbers
internal import XestiTools

extension Work {

    // MARK: Public Instance Methods

    /// Reverses the order of notes within a beat-time range across the beat-time parts in this work
    /// that `partIDs` names, along with any parameter maps selected by `applyTo` and, when
    /// `applyTo` contains ``MapTargets/tempo``, the work’s own tempo map. The tempo map is work-wide, so it is carried
    /// along whichever parts are targeted.
    ///
    /// - Parameter timeRange:   The beat-time range to mirror attack times around. `nil` resolves
    ///                          to the span of everything being reversed: the targeted parts’
    ///                          notes and the entries of every map `applyTo` selects, including
    ///                          the tempo map.
    /// - Parameter applyTo:     The parameter maps (and tempo map) to reverse along with every note
    ///                          table. Defaults to every map.
    /// - Parameter partIDs:     The IDs of the parts to transform, or `nil` (the default) for every
    ///                          part. IDs naming no part are ignored.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; otherwise, a transform-failure case naming the part (or the tempo map)
    ///             and sub-structure that failed.
    public mutating func reverse(within timeRange: ClosedRange<BeatTime>? = nil,
                                 applyTo: MapTargets = .all,
                                 partIDs: Set<PartID>? = nil) throws(Error) {
        try ensureUnlocked()

        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            let resolvedRange = timeRange ?? Self.transformTimeRange(of: Self.selected(parts, partIDs: partIDs),
                                                                     tempoMap: tempoMap,
                                                                     applyTo: applyTo)
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: resolvedRange, applyTo: applyTo)
            }
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

            content = .absoluteBeat(newParts, newTempoMap)

        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            let resolvedRange = timeRange ?? Self.transformTimeRange(of: Self.selected(parts, partIDs: partIDs),
                                                                     tempoMap: tempoMap,
                                                                     applyTo: applyTo)
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: resolvedRange,
                                 applyTo: applyTo)
            }
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

            content = .keyboardBeat(newParts, newTempoMap)

        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            let resolvedRange = timeRange ?? Self.transformTimeRange(of: Self.selected(parts, partIDs: partIDs),
                                                                     tempoMap: tempoMap,
                                                                     applyTo: applyTo)
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: resolvedRange,
                                 applyTo: applyTo)
            }
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

            content = .standardBeat(newParts, newTempoMap)

        default:
            throw Error.timeBasisMismatch(expected: .beat)
        }
    }

    /// Reverses the order of notes within a wall-time range across the wall-time parts in this work
    /// that `partIDs` names, along with any parameter maps selected by `applyTo`.
    ///
    /// - Parameter timeRange:   The wall-time range to mirror attack times around. `nil` resolves
    ///                          to the span of everything being reversed: the targeted parts’
    ///                          notes and the entries of every map `applyTo` selects.
    /// - Parameter applyTo:     The parameter maps to reverse along with each targeted note table.
    ///                          Defaults to every map.
    /// - Parameter partIDs:     The IDs of the parts to transform, or `nil` (the default) for every
    ///                          part. IDs naming no part are ignored.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use wall
    ///             time; otherwise, a transform-failure case naming the part and sub-structure
    ///             that failed.
    public mutating func reverse(within timeRange: ClosedRange<WallTime>? = nil,
                                 applyTo: MapTargets = .all,
                                 partIDs: Set<PartID>? = nil) throws(Error) {
        try ensureUnlocked()

        switch content {
        case let .absoluteWall(parts):
            typealias PartType = Part<WallTime, Frequency>

            let resolvedRange = timeRange ?? Self.transformTimeRange(of: Self.selected(parts, partIDs: partIDs),
                                                                     applyTo: applyTo)
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: resolvedRange,
                                 applyTo: applyTo)
            }

            content = .absoluteWall(newParts)

        case let .keyboardWall(parts):
            typealias PartType = Part<WallTime, NoteNumber>

            let resolvedRange = timeRange ?? Self.transformTimeRange(of: Self.selected(parts, partIDs: partIDs),
                                                                     applyTo: applyTo)
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: resolvedRange,
                                 applyTo: applyTo)
            }

            content = .keyboardWall(newParts)

        case let .standardWall(parts):
            typealias PartType = Part<WallTime, Pitch>

            let resolvedRange = timeRange ?? Self.transformTimeRange(of: Self.selected(parts, partIDs: partIDs),
                                                                     applyTo: applyTo)
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: resolvedRange,
                                 applyTo: applyTo)
            }

            content = .standardWall(newParts)

        default:
            throw Error.timeBasisMismatch(expected: .wall)
        }
    }

    // MARK: Private Type Methods

    //
    // The JohnnySonic ramp extras (`rampStartTempo`, `rampEndTempo` and `rampDuration`) describe
    // a ramp that starts at their entry and runs `rampDuration` beats, and the exporter trusts
    // them over the map. Reversing mirrors entry times, which leaves them where the ramp now
    // *ends*, still running the old way. `TempoMap.reverse` only accepts a range that holds every
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
}

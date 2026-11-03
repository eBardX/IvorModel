// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

internal import IvorTuning
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
}

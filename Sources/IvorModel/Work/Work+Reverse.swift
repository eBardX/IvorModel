// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

internal import IvorTuning

extension Work {

    // MARK: Public Instance Methods

    /// Reverses the order of notes within a beat-time range across the beat-time parts in this work
    /// that `partIDs` names, along with any parameter maps selected by `applyTo` and, unless
    /// `applyTo` is empty, the work’s own tempo map. The tempo map is work-wide, so it is carried
    /// along whichever parts are targeted.
    ///
    /// - Parameter timeRange:   The beat-time range to mirror attack times around. `nil` resolves
    ///                          to the aggregate beat-time range spanned by the targeted parts.
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

            let resolvedRange = timeRange ?? Self.aggregateTimeRange(of: Self.selected(parts, partIDs: partIDs))
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: resolvedRange, applyTo: applyTo)
            }
            let newTempoMap = try Self.carried(tempoMap: tempoMap,
                                               applyTo: applyTo,
                                               kind: .reverse) { (tempo: inout TempoMap) throws(TempoMap.Error) in
                try tempo.reverse(within: resolvedRange)
            }

            content = .absoluteBeat(newParts, newTempoMap)

        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            let resolvedRange = timeRange ?? Self.aggregateTimeRange(of: Self.selected(parts, partIDs: partIDs))
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: resolvedRange,
                                 applyTo: applyTo)
            }
            let newTempoMap = try Self.carried(tempoMap: tempoMap,
                                               applyTo: applyTo,
                                               kind: .reverse) { (tempo: inout TempoMap) throws(TempoMap.Error) in
                try tempo.reverse(within: resolvedRange)
            }

            content = .keyboardBeat(newParts, newTempoMap)

        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            let resolvedRange = timeRange ?? Self.aggregateTimeRange(of: Self.selected(parts, partIDs: partIDs))
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: resolvedRange,
                                 applyTo: applyTo)
            }
            let newTempoMap = try Self.carried(tempoMap: tempoMap,
                                               applyTo: applyTo,
                                               kind: .reverse) { (tempo: inout TempoMap) throws(TempoMap.Error) in
                try tempo.reverse(within: resolvedRange)
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
    ///                          to the aggregate wall-time range spanned by the targeted parts.
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

            let resolvedRange = timeRange ?? Self.aggregateTimeRange(of: Self.selected(parts, partIDs: partIDs))
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: resolvedRange,
                                 applyTo: applyTo)
            }

            content = .absoluteWall(newParts)

        case let .keyboardWall(parts):
            typealias PartType = Part<WallTime, NoteNumber>

            let resolvedRange = timeRange ?? Self.aggregateTimeRange(of: Self.selected(parts, partIDs: partIDs))
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: resolvedRange,
                                 applyTo: applyTo)
            }

            content = .keyboardWall(newParts)

        case let .standardWall(parts):
            typealias PartType = Part<WallTime, Pitch>

            let resolvedRange = timeRange ?? Self.aggregateTimeRange(of: Self.selected(parts, partIDs: partIDs))
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
}

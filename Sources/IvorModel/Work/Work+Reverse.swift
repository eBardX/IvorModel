// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

internal import IvorTuning

extension Work {

    // MARK: Public Instance Methods

    /// Reverses the order of notes within a beat-time range for a single beat-time part in this
    /// work, along with any parameter maps selected by `applyTo`. No-ops if no part with `partID`
    /// is found.
    ///
    /// - Parameter partID:     The ID of the part to reverse.
    /// - Parameter timeRange:  The beat-time range to mirror attack times around. `nil` resolves
    ///                         to the part’s own beat-time range.
    /// - Parameter applyTo:    The parameter maps to reverse along with the note table. Defaults
    ///                         to every map.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; otherwise, a transform-failure case naming the part and sub-structure
    ///             that failed.
    public mutating func reverse(_ partID: PartID,
                                 within timeRange: ClosedRange<BeatTime>? = nil,
                                 applyTo: MapTargets = .all) throws(Error) {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            content = try .absoluteBeat(Self.transformed(parts: parts,
                                                         partID: partID,
                                                         kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: timeRange,
                                 applyTo: applyTo)
            }, tempoMap)

        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            content = try .keyboardBeat(Self.transformed(parts: parts,
                                                         partID: partID,
                                                         kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: timeRange,
                                 applyTo: applyTo)
            }, tempoMap)

        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            content = try .standardBeat(Self.transformed(parts: parts,
                                                         partID: partID,
                                                         kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: timeRange,
                                 applyTo: applyTo)
            }, tempoMap)

        default:
            throw Error.timeBasisMismatch(expected: .beat)
        }
    }

    /// Reverses the order of notes within a wall-time range for a single wall-time part in this
    /// work, along with any parameter maps selected by `applyTo`. No-ops if no part with `partID`
    /// is found.
    ///
    /// - Parameter partID:     The ID of the part to reverse.
    /// - Parameter timeRange:  The wall-time range to mirror attack times around. `nil` resolves
    ///                         to the part’s own wall-time range.
    /// - Parameter applyTo:    The parameter maps to reverse along with the note table. Defaults
    ///                         to every map.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use wall
    ///             time; otherwise, a transform-failure case naming the part and sub-structure
    ///             that failed.
    public mutating func reverse(_ partID: PartID,
                                 within timeRange: ClosedRange<WallTime>? = nil,
                                 applyTo: MapTargets = .all) throws(Error) {
        switch content {
        case let .absoluteWall(parts):
            typealias PartType = Part<WallTime, Frequency>

            content = try .absoluteWall(Self.transformed(parts: parts,
                                                         partID: partID,
                                                         kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: timeRange,
                                 applyTo: applyTo)
            })

        case let .keyboardWall(parts):
            typealias PartType = Part<WallTime, NoteNumber>

            content = try .keyboardWall(Self.transformed(parts: parts,
                                                         partID: partID,
                                                         kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: timeRange,
                                 applyTo: applyTo)
            })

        case let .standardWall(parts):
            typealias PartType = Part<WallTime, Pitch>

            content = try .standardWall(Self.transformed(parts: parts,
                                                         partID: partID,
                                                         kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: timeRange,
                                 applyTo: applyTo)
            })

        default:
            throw Error.timeBasisMismatch(expected: .wall)
        }
    }

    /// Reverses the order of notes within a beat-time range for a set of beat-time parts in this
    /// work, along with any parameter maps selected by `applyTo`. All-or-nothing across just the
    /// targeted parts.
    ///
    /// - Parameter partIDs:    The IDs of the parts to reverse.
    /// - Parameter timeRange:  The beat-time range to mirror attack times around. `nil` resolves
    ///                         to the aggregate beat-time range spanned by the targeted parts.
    /// - Parameter applyTo:    The parameter maps to reverse along with each targeted note table.
    ///                         Defaults to every map.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; otherwise, a transform-failure case naming the part and sub-structure
    ///             that failed.
    public mutating func reverse(_ partIDs: Set<PartID>,
                                 within timeRange: ClosedRange<BeatTime>? = nil,
                                 applyTo: MapTargets = .all) throws(Error) {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            let resolvedRange = timeRange ?? Self.aggregateTimeRange(of: parts.filter { partIDs.contains($0.partID) })
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: resolvedRange,
                                 applyTo: applyTo)
            }

            content = .absoluteBeat(newParts, tempoMap)

        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            let resolvedRange = timeRange ?? Self.aggregateTimeRange(of: parts.filter { partIDs.contains($0.partID) })
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: resolvedRange,
                                 applyTo: applyTo)
            }

            content = .keyboardBeat(newParts, tempoMap)

        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            let resolvedRange = timeRange ?? Self.aggregateTimeRange(of: parts.filter { partIDs.contains($0.partID) })
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: resolvedRange,
                                 applyTo: applyTo)
            }

            content = .standardBeat(newParts, tempoMap)

        default:
            throw Error.timeBasisMismatch(expected: .beat)
        }
    }

    /// Reverses the order of notes within a wall-time range for a set of wall-time parts in this
    /// work, along with any parameter maps selected by `applyTo`. All-or-nothing across just the
    /// targeted parts.
    ///
    /// - Parameter partIDs:    The IDs of the parts to reverse.
    /// - Parameter timeRange:  The wall-time range to mirror attack times around. `nil` resolves
    ///                         to the aggregate wall-time range spanned by the targeted parts.
    /// - Parameter applyTo:    The parameter maps to reverse along with each targeted note table.
    ///                         Defaults to every map.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use wall
    ///             time; otherwise, a transform-failure case naming the part and sub-structure
    ///             that failed.
    public mutating func reverse(_ partIDs: Set<PartID>,
                                 within timeRange: ClosedRange<WallTime>? = nil,
                                 applyTo: MapTargets = .all) throws(Error) {
        switch content {
        case let .absoluteWall(parts):
            typealias PartType = Part<WallTime, Frequency>

            let resolvedRange = timeRange ?? Self.aggregateTimeRange(of: parts.filter { partIDs.contains($0.partID) })
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: resolvedRange,
                                 applyTo: applyTo)
            }

            content = .absoluteWall(newParts)

        case let .keyboardWall(parts):
            typealias PartType = Part<WallTime, NoteNumber>

            let resolvedRange = timeRange ?? Self.aggregateTimeRange(of: parts.filter { partIDs.contains($0.partID) })
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: resolvedRange,
                                 applyTo: applyTo)
            }

            content = .keyboardWall(newParts)

        case let .standardWall(parts):
            typealias PartType = Part<WallTime, Pitch>

            let resolvedRange = timeRange ?? Self.aggregateTimeRange(of: parts.filter { partIDs.contains($0.partID) })
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

    /// Reverses the order of notes within a beat-time range across every beat-time part in this
    /// work, along with any parameter maps selected by `applyTo` and, unless `applyTo` is empty,
    /// the work’s own tempo map.
    ///
    /// - Parameter timeRange:   The beat-time range to mirror attack times around. `nil` resolves
    ///                          to the aggregate beat-time range spanned by every part.
    /// - Parameter applyTo:     The parameter maps (and tempo map) to reverse along with every
    ///                          note table. Defaults to every map.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; otherwise, a transform-failure case naming the part (or the tempo map)
    ///             and sub-structure that failed.
    public mutating func reverse(within timeRange: ClosedRange<BeatTime>? = nil,
                                 applyTo: MapTargets = .all) throws(Error) {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            let resolvedRange = timeRange ?? Self.aggregateTimeRange(of: parts)
            let newParts = try Self.transformed(parts: parts,
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

            let resolvedRange = timeRange ?? Self.aggregateTimeRange(of: parts)
            let newParts = try Self.transformed(parts: parts,
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

            let resolvedRange = timeRange ?? Self.aggregateTimeRange(of: parts)
            let newParts = try Self.transformed(parts: parts,
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

    /// Reverses the order of notes within a wall-time range across every wall-time part in this
    /// work, along with any parameter maps selected by `applyTo`.
    ///
    /// - Parameter timeRange:   The wall-time range to mirror attack times around. `nil` resolves
    ///                          to the aggregate wall-time range spanned by every part.
    /// - Parameter applyTo:     The parameter maps to reverse along with every note table.
    ///                          Defaults to every map.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use wall
    ///             time; otherwise, a transform-failure case naming the part and sub-structure
    ///             that failed.
    public mutating func reverse(within timeRange: ClosedRange<WallTime>? = nil,
                                 applyTo: MapTargets = .all) throws(Error) {
        switch content {
        case let .absoluteWall(parts):
            typealias PartType = Part<WallTime, Frequency>

            let resolvedRange = timeRange ?? Self.aggregateTimeRange(of: parts)
            let newParts = try Self.transformed(parts: parts,
                                                kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: resolvedRange,
                                 applyTo: applyTo)
            }

            content = .absoluteWall(newParts)

        case let .keyboardWall(parts):
            typealias PartType = Part<WallTime, NoteNumber>

            let resolvedRange = timeRange ?? Self.aggregateTimeRange(of: parts)
            let newParts = try Self.transformed(parts: parts,
                                                kind: .reverse) { (part: inout PartType) throws(PartType.Error) in
                try part.reverse(within: resolvedRange,
                                 applyTo: applyTo)
            }

            content = .keyboardWall(newParts)

        case let .standardWall(parts):
            typealias PartType = Part<WallTime, Pitch>

            let resolvedRange = timeRange ?? Self.aggregateTimeRange(of: parts)
            let newParts = try Self.transformed(parts: parts,
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

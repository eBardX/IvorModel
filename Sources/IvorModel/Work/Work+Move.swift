// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

internal import IvorTuning

extension Work {

    // MARK: Public Instance Methods

    /// Moves note attack times by a directed duration across the beat-time parts in this work that
    /// `partIDs` names, along with any parameter maps selected by `applyTo` and, unless `applyTo`
    /// is empty, the work’s own tempo map. The tempo map is work-wide, so it is carried along
    /// whichever parts are targeted.
    ///
    /// - Parameter directedDuration:   The directed duration by which to move the targeted parts’
    ///                                 note attack times.
    /// - Parameter applyTo:            The parameter maps (and tempo map) to move along with each
    ///                                 targeted note table. Defaults to every map.
    /// - Parameter partIDs:            The IDs of the parts to transform, or `nil` (the default)
    ///                                 for every part. IDs naming no part are ignored.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; otherwise, a transform-failure case naming the part (or the tempo map)
    ///             and sub-structure that failed.
    public mutating func move(by directedDuration: DirectedDuration<BeatDuration>,
                              applyTo: MapTargets = .all,
                              partIDs: Set<PartID>? = nil) throws(Error) {
        try ensureUnlocked()

        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            let newParts = try Self.transformed(parts: parts, partIDs: partIDs, kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            }
            let newTempoMap = try Self.carried(tempoMap: tempoMap, applyTo: applyTo, kind: .move) { (tempo: inout TempoMap) throws(TempoMap.Error) in
                try tempo.move(by: directedDuration)
            }

            content = .absoluteBeat(newParts, newTempoMap)

        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            let newParts = try Self.transformed(parts: parts, partIDs: partIDs, kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            }
            let newTempoMap = try Self.carried(tempoMap: tempoMap, applyTo: applyTo, kind: .move) { (tempo: inout TempoMap) throws(TempoMap.Error) in
                try tempo.move(by: directedDuration)
            }

            content = .keyboardBeat(newParts, newTempoMap)

        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            let newParts = try Self.transformed(parts: parts, partIDs: partIDs, kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            }
            let newTempoMap = try Self.carried(tempoMap: tempoMap, applyTo: applyTo, kind: .move) { (tempo: inout TempoMap) throws(TempoMap.Error) in
                try tempo.move(by: directedDuration)
            }

            content = .standardBeat(newParts, newTempoMap)

        default:
            throw Error.timeBasisMismatch(expected: .beat)
        }
    }

    /// Moves note attack times by a directed duration across the wall-time parts in this work that
    /// `partIDs` names, along with any parameter maps selected by `applyTo`.
    ///
    /// - Parameter directedDuration:   The directed duration by which to move the targeted parts’
    ///                                 note attack times.
    /// - Parameter applyTo:            The parameter maps to move along with each targeted note
    ///                                 table. Defaults to every map.
    /// - Parameter partIDs:            The IDs of the parts to transform, or `nil` (the default)
    ///                                 for every part. IDs naming no part are ignored.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use wall
    ///             time; otherwise, a transform-failure case naming the part and sub-structure
    ///             that failed.
    public mutating func move(by directedDuration: DirectedDuration<WallDuration>,
                              applyTo: MapTargets = .all,
                              partIDs: Set<PartID>? = nil) throws(Error) {
        try ensureUnlocked()

        switch content {
        case let .absoluteWall(parts):
            typealias PartType = Part<WallTime, Frequency>

            let newParts = try Self.transformed(parts: parts, partIDs: partIDs, kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            }

            content = .absoluteWall(newParts)

        case let .keyboardWall(parts):
            typealias PartType = Part<WallTime, NoteNumber>

            let newParts = try Self.transformed(parts: parts, partIDs: partIDs, kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            }

            content = .keyboardWall(newParts)

        case let .standardWall(parts):
            typealias PartType = Part<WallTime, Pitch>

            let newParts = try Self.transformed(parts: parts, partIDs: partIDs, kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            }

            content = .standardWall(newParts)

        default:
            throw Error.timeBasisMismatch(expected: .wall)
        }
    }
}

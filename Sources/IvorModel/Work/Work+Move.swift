// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

internal import IvorTuning

extension Work {

    // MARK: Public Instance Methods

    /// Moves note attack times by a directed duration for a single beat-time part in this work,
    /// along with any parameter maps selected by `applyTo`. No-ops if no part with `partID` is
    /// found.
    ///
    /// - Parameter partID:            The ID of the part to move.
    /// - Parameter directedDuration:  The directed duration by which to move the part’s note
    ///                                attack times.
    /// - Parameter applyTo:           The parameter maps to move along with the note table.
    ///                                Defaults to every map.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; otherwise, a transform-failure case naming the part and sub-structure
    ///             that failed.
    public mutating func move(_ partID: PartID,
                              by directedDuration: DirectedDuration<BeatDuration>,
                              applyTo: MapTargets = .all) throws(Error) {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            content = try .absoluteBeat(Self.transformed(parts: parts, partID: partID, kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            }, tempoMap)

        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            content = try .keyboardBeat(Self.transformed(parts: parts, partID: partID, kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            }, tempoMap)

        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            content = try .standardBeat(Self.transformed(parts: parts, partID: partID, kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            }, tempoMap)

        default:
            throw Error.timeBasisMismatch(expected: .beat)
        }
    }

    /// Moves note attack times by a directed duration for a single wall-time part in this work,
    /// along with any parameter maps selected by `applyTo`. No-ops if no part with `partID` is
    /// found.
    ///
    /// - Parameter partID:            The ID of the part to move.
    /// - Parameter directedDuration:  The directed duration by which to move the part’s note
    ///                                attack times.
    /// - Parameter applyTo:           The parameter maps to move along with the note table.
    ///                                Defaults to every map.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use wall
    ///             time; otherwise, a transform-failure case naming the part and sub-structure
    ///             that failed.
    public mutating func move(_ partID: PartID,
                              by directedDuration: DirectedDuration<WallDuration>,
                              applyTo: MapTargets = .all) throws(Error) {
        switch content {
        case let .absoluteWall(parts):
            typealias PartType = Part<WallTime, Frequency>

            content = try .absoluteWall(Self.transformed(parts: parts, partID: partID, kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            })

        case let .keyboardWall(parts):
            typealias PartType = Part<WallTime, NoteNumber>

            content = try .keyboardWall(Self.transformed(parts: parts, partID: partID, kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            })

        case let .standardWall(parts):
            typealias PartType = Part<WallTime, Pitch>

            content = try .standardWall(Self.transformed(parts: parts, partID: partID, kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            })

        default:
            throw Error.timeBasisMismatch(expected: .wall)
        }
    }

    /// Moves note attack times by a directed duration for a set of beat-time parts in this work,
    /// along with any parameter maps selected by `applyTo`. All-or-nothing across just the
    /// targeted parts.
    ///
    /// - Parameter partIDs:           The IDs of the parts to move.
    /// - Parameter directedDuration:  The directed duration by which to move the targeted parts’
    ///                                note attack times.
    /// - Parameter applyTo:           The parameter maps to move along with each targeted note
    ///                                table. Defaults to every map.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; otherwise, a transform-failure case naming the part and sub-structure
    ///             that failed.
    public mutating func move(_ partIDs: Set<PartID>,
                              by directedDuration: DirectedDuration<BeatDuration>,
                              applyTo: MapTargets = .all) throws(Error) {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            content = try .absoluteBeat(Self.transformed(parts: parts,
                                                         partIDs: partIDs,
                                                         kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            }, tempoMap)

        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            content = try .keyboardBeat(Self.transformed(parts: parts,
                                                         partIDs: partIDs,
                                                         kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            }, tempoMap)

        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            content = try .standardBeat(Self.transformed(parts: parts,
                                                         partIDs: partIDs,
                                                         kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            }, tempoMap)

        default:
            throw Error.timeBasisMismatch(expected: .beat)
        }
    }

    /// Moves note attack times by a directed duration for a set of wall-time parts in this work,
    /// along with any parameter maps selected by `applyTo`. All-or-nothing across just the
    /// targeted parts.
    ///
    /// - Parameter partIDs:           The IDs of the parts to move.
    /// - Parameter directedDuration:  The directed duration by which to move the targeted parts’
    ///                                note attack times.
    /// - Parameter applyTo:           The parameter maps to move along with each targeted note
    ///                                table. Defaults to every map.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use wall
    ///             time; otherwise, a transform-failure case naming the part and sub-structure
    ///             that failed.
    public mutating func move(_ partIDs: Set<PartID>,
                              by directedDuration: DirectedDuration<WallDuration>,
                              applyTo: MapTargets = .all) throws(Error) {
        switch content {
        case let .absoluteWall(parts):
            typealias PartType = Part<WallTime, Frequency>

            content = try .absoluteWall(Self.transformed(parts: parts,
                                                         partIDs: partIDs,
                                                         kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            })

        case let .keyboardWall(parts):
            typealias PartType = Part<WallTime, NoteNumber>

            content = try .keyboardWall(Self.transformed(parts: parts,
                                                         partIDs: partIDs,
                                                         kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            })

        case let .standardWall(parts):
            typealias PartType = Part<WallTime, Pitch>

            content = try .standardWall(Self.transformed(parts: parts,
                                                         partIDs: partIDs,
                                                         kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            })

        default:
            throw Error.timeBasisMismatch(expected: .wall)
        }
    }

    /// Moves note attack times by a directed duration across every beat-time part in this work,
    /// along with any parameter maps selected by `applyTo` and, unless `applyTo` is empty, the
    /// work’s own tempo map.
    ///
    /// - Parameter directedDuration:   The directed duration by which to move every part’s note
    ///                                 attack times.
    /// - Parameter applyTo:            The parameter maps (and tempo map) to move along with
    ///                                 every note table. Defaults to every map.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; otherwise, a transform-failure case naming the part (or the tempo map)
    ///             and sub-structure that failed.
    public mutating func move(by directedDuration: DirectedDuration<BeatDuration>,
                              applyTo: MapTargets = .all) throws(Error) {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            let newParts = try Self.transformed(parts: parts, kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            }
            let newTempoMap = try Self.carried(tempoMap: tempoMap, applyTo: applyTo, kind: .move) { (tempo: inout TempoMap) throws(TempoMap.Error) in
                try tempo.move(by: directedDuration)
            }

            content = .absoluteBeat(newParts, newTempoMap)

        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            let newParts = try Self.transformed(parts: parts, kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            }
            let newTempoMap = try Self.carried(tempoMap: tempoMap, applyTo: applyTo, kind: .move) { (tempo: inout TempoMap) throws(TempoMap.Error) in
                try tempo.move(by: directedDuration)
            }

            content = .keyboardBeat(newParts, newTempoMap)

        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            let newParts = try Self.transformed(parts: parts, kind: .move) { (part: inout PartType) throws(PartType.Error) in
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

    /// Moves note attack times by a directed duration across every wall-time part in this work,
    /// along with any parameter maps selected by `applyTo`.
    ///
    /// - Parameter directedDuration:   The directed duration by which to move every part’s note
    ///                                 attack times.
    /// - Parameter applyTo:            The parameter maps to move along with every note table.
    ///                                 Defaults to every map.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use wall
    ///             time; otherwise, a transform-failure case naming the part and sub-structure
    ///             that failed.
    public mutating func move(by directedDuration: DirectedDuration<WallDuration>,
                              applyTo: MapTargets = .all) throws(Error) {
        switch content {
        case let .absoluteWall(parts):
            typealias PartType = Part<WallTime, Frequency>

            let newParts = try Self.transformed(parts: parts, kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            }

            content = .absoluteWall(newParts)

        case let .keyboardWall(parts):
            typealias PartType = Part<WallTime, NoteNumber>

            let newParts = try Self.transformed(parts: parts, kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            }

            content = .keyboardWall(newParts)

        case let .standardWall(parts):
            typealias PartType = Part<WallTime, Pitch>

            let newParts = try Self.transformed(parts: parts, kind: .move) { (part: inout PartType) throws(PartType.Error) in
                try part.move(by: directedDuration, applyTo: applyTo)
            }

            content = .standardWall(newParts)

        default:
            throw Error.timeBasisMismatch(expected: .wall)
        }
    }
}

// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiNumbers

internal import IvorTuning

extension Work {

    // MARK: Public Instance Methods

    /// Diminishes note attack times and durations by a rational factor across the beat-time parts
    /// in this work that `partIDs` names, along with any parameter maps selected by `applyTo` and,
    /// unless `applyTo` is empty, the work’s own tempo map. The tempo map is work-wide, so it is
    /// carried along whichever parts are targeted.
    ///
    /// - Parameter factor:     A rational number ≥ 1 by which to compress the targeted parts’ note
    ///                         timings.
    /// - Parameter anchor:     The low beat-time bound to compress attack times relative to. `nil`
    ///                         resolves to the aggregate beat-time range spanned by every part.
    /// - Parameter applyTo:    The parameter maps (and tempo map) to diminish along with every note
    ///                         table. Defaults to every map.
    /// - Parameter partIDs:    The IDs of the parts to transform, or `nil` (the default) for every
    ///                         part. IDs naming no part are ignored.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; otherwise, a transform-failure case naming the part (or the tempo map)
    ///             and sub-structure that failed.
    public mutating func diminish(by factor: Number,
                                  anchor: BeatTime? = nil,
                                  applyTo: MapTargets = .all,
                                  partIDs: Set<PartID>? = nil) throws(Error) {
        try ensureUnlocked()

        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            let resolvedAnchor = anchor ?? Self.aggregateTimeRange(of: Self.selected(parts, partIDs: partIDs))?.lowerBound
            let newParts = try Self.transformed(parts: parts, partIDs: partIDs, kind: .diminish) { (part: inout PartType) throws(PartType.Error) in
                try part.diminish(by: factor, anchor: resolvedAnchor, applyTo: applyTo)
            }
            let newTempoMap = try Self.carried(tempoMap: tempoMap,
                                               applyTo: applyTo,
                                               kind: .diminish) { (tempo: inout TempoMap) throws(TempoMap.Error) in
                try tempo.diminish(by: factor, anchor: resolvedAnchor)
            }

            content = .absoluteBeat(newParts, newTempoMap)

        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            let resolvedAnchor = anchor ?? Self.aggregateTimeRange(of: Self.selected(parts, partIDs: partIDs))?.lowerBound
            let newParts = try Self.transformed(parts: parts, partIDs: partIDs, kind: .diminish) { (part: inout PartType) throws(PartType.Error) in
                try part.diminish(by: factor, anchor: resolvedAnchor, applyTo: applyTo)
            }
            let newTempoMap = try Self.carried(tempoMap: tempoMap,
                                               applyTo: applyTo,
                                               kind: .diminish) { (tempo: inout TempoMap) throws(TempoMap.Error) in
                try tempo.diminish(by: factor, anchor: resolvedAnchor)
            }

            content = .keyboardBeat(newParts, newTempoMap)

        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            let resolvedAnchor = anchor ?? Self.aggregateTimeRange(of: Self.selected(parts, partIDs: partIDs))?.lowerBound
            let newParts = try Self.transformed(parts: parts, partIDs: partIDs, kind: .diminish) { (part: inout PartType) throws(PartType.Error) in
                try part.diminish(by: factor, anchor: resolvedAnchor, applyTo: applyTo)
            }
            let newTempoMap = try Self.carried(tempoMap: tempoMap,
                                               applyTo: applyTo,
                                               kind: .diminish) { (tempo: inout TempoMap) throws(TempoMap.Error) in
                try tempo.diminish(by: factor, anchor: resolvedAnchor)
            }

            content = .standardBeat(newParts, newTempoMap)

        default:
            throw Error.timeBasisMismatch(expected: .beat)
        }
    }

    /// Diminishes note attack times and durations by a rational factor across the wall-time parts
    /// in this work that `partIDs` names, along with any parameter maps selected by `applyTo`.
    ///
    /// - Parameter factor:     A rational number ≥ 1 by which to compress the targeted parts’ note
    ///                         timings.
    /// - Parameter anchor:     The low wall-time bound to compress attack times relative to. `nil`
    ///                         resolves to the aggregate wall-time range spanned by every part.
    /// - Parameter applyTo:    The parameter maps to diminish along with each targeted note table.
    ///                         Defaults to every map.
    /// - Parameter partIDs:    The IDs of the parts to transform, or `nil` (the default) for every
    ///                         part. IDs naming no part are ignored.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use wall
    ///             time; otherwise, a transform-failure case naming the part and sub-structure
    ///             that failed.
    public mutating func diminish(by factor: Number,
                                  anchor: WallTime? = nil,
                                  applyTo: MapTargets = .all,
                                  partIDs: Set<PartID>? = nil) throws(Error) {
        try ensureUnlocked()

        switch content {
        case let .absoluteWall(parts):
            typealias PartType = Part<WallTime, Frequency>

            let resolvedAnchor = anchor ?? Self.aggregateTimeRange(of: Self.selected(parts, partIDs: partIDs))?.lowerBound
            let newParts = try Self.transformed(parts: parts, partIDs: partIDs, kind: .diminish) { (part: inout PartType) throws(PartType.Error) in
                try part.diminish(by: factor, anchor: resolvedAnchor, applyTo: applyTo)
            }

            content = .absoluteWall(newParts)

        case let .keyboardWall(parts):
            typealias PartType = Part<WallTime, NoteNumber>

            let resolvedAnchor = anchor ?? Self.aggregateTimeRange(of: Self.selected(parts, partIDs: partIDs))?.lowerBound
            let newParts = try Self.transformed(parts: parts, partIDs: partIDs, kind: .diminish) { (part: inout PartType) throws(PartType.Error) in
                try part.diminish(by: factor, anchor: resolvedAnchor, applyTo: applyTo)
            }

            content = .keyboardWall(newParts)

        case let .standardWall(parts):
            typealias PartType = Part<WallTime, Pitch>

            let resolvedAnchor = anchor ?? Self.aggregateTimeRange(of: Self.selected(parts, partIDs: partIDs))?.lowerBound
            let newParts = try Self.transformed(parts: parts, partIDs: partIDs, kind: .diminish) { (part: inout PartType) throws(PartType.Error) in
                try part.diminish(by: factor, anchor: resolvedAnchor, applyTo: applyTo)
            }

            content = .standardWall(newParts)

        default:
            throw Error.timeBasisMismatch(expected: .wall)
        }
    }
}

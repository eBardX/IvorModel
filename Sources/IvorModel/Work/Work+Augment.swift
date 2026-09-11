// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiNumbers

internal import IvorTuning

extension Work {

    // MARK: Public Instance Methods

    /// Augments note attack times and durations by a rational factor for a single beat-time part
    /// in this work, along with any parameter maps selected by `applyTo`. No-ops if no part with
    /// `partID` is found.
    ///
    /// - Parameter partID:     The ID of the part to augment.
    /// - Parameter factor:     A rational number ≥ 1 by which to stretch the part’s note timings.
    /// - Parameter anchor:     The low beat-time bound to stretch attack times relative to. `nil`
    ///                         resolves to the part’s own beat-time range.
    /// - Parameter applyTo:    The parameter maps to augment along with the note table. Defaults
    ///                         to every map.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; otherwise, a transform-failure case naming the part and sub-structure
    ///             that failed.
    public mutating func augment(_ partID: PartID,
                                 by factor: Number,
                                 anchor: BeatTime? = nil,
                                 applyTo: MapTargets = .all) throws(Error) {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            content = try .absoluteBeat(Self.transformed(parts, partID: partID, kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor, anchor: anchor, applyTo: applyTo)
            }, tempoMap)

        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            content = try .keyboardBeat(Self.transformed(parts, partID: partID, kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor, anchor: anchor, applyTo: applyTo)
            }, tempoMap)

        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            content = try .standardBeat(Self.transformed(parts, partID: partID, kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor, anchor: anchor, applyTo: applyTo)
            }, tempoMap)

        default:
            throw Error.timeBasisMismatch(expected: .beat)
        }
    }

    /// Augments note attack times and durations by a rational factor for a single wall-time part
    /// in this work, along with any parameter maps selected by `applyTo`. No-ops if no part with
    /// `partID` is found.
    ///
    /// - Parameter partID:     The ID of the part to augment.
    /// - Parameter factor:     A rational number ≥ 1 by which to stretch the part’s note timings.
    /// - Parameter anchor:     The low wall-time bound to stretch attack times relative to. `nil`
    ///                         resolves to the part’s own wall-time range.
    /// - Parameter applyTo:    The parameter maps to augment along with the note table. Defaults
    ///                         to every map.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use wall
    ///             time; otherwise, a transform-failure case naming the part and sub-structure
    ///             that failed.
    public mutating func augment(_ partID: PartID,
                                 by factor: Number,
                                 anchor: WallTime? = nil,
                                 applyTo: MapTargets = .all) throws(Error) {
        switch content {
        case let .absoluteWall(parts):
            typealias PartType = Part<WallTime, Frequency>

            content = try .absoluteWall(Self.transformed(parts, partID: partID, kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor, anchor: anchor, applyTo: applyTo)
            })

        case let .keyboardWall(parts):
            typealias PartType = Part<WallTime, NoteNumber>

            content = try .keyboardWall(Self.transformed(parts, partID: partID, kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor, anchor: anchor, applyTo: applyTo)
            })

        case let .standardWall(parts):
            typealias PartType = Part<WallTime, Pitch>

            content = try .standardWall(Self.transformed(parts, partID: partID, kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor, anchor: anchor, applyTo: applyTo)
            })

        default:
            throw Error.timeBasisMismatch(expected: .wall)
        }
    }

    /// Augments note attack times and durations by a rational factor for a set of beat-time parts
    /// in this work, along with any parameter maps selected by `applyTo`. All-or-nothing across
    /// just the targeted parts.
    ///
    /// - Parameter partIDs:    The IDs of the parts to augment.
    /// - Parameter factor:     A rational number ≥ 1 by which to stretch the targeted parts’ note
    ///                         timings.
    /// - Parameter anchor:     The low beat-time bound to stretch attack times relative to. `nil`
    ///                         resolves to the aggregate beat-time range spanned by the targeted
    ///                         parts.
    /// - Parameter applyTo:    The parameter maps to augment along with each targeted note table.
    ///                         Defaults to every map.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; otherwise, a transform-failure case naming the part and sub-structure
    ///             that failed.
    public mutating func augment(_ partIDs: Set<PartID>,
                                 by factor: Number,
                                 anchor: BeatTime? = nil,
                                 applyTo: MapTargets = .all) throws(Error) {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            let resolvedAnchor = anchor ?? Self.aggregateTimeRange(of: parts.filter { partIDs.contains($0.partID) })?.lowerBound
            let newParts = try Self.transformed(parts, partIDs: partIDs, kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor, anchor: resolvedAnchor, applyTo: applyTo)
            }

            content = .absoluteBeat(newParts, tempoMap)

        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            let resolvedAnchor = anchor ?? Self.aggregateTimeRange(of: parts.filter { partIDs.contains($0.partID) })?.lowerBound
            let newParts = try Self.transformed(parts, partIDs: partIDs, kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor, anchor: resolvedAnchor, applyTo: applyTo)
            }

            content = .keyboardBeat(newParts, tempoMap)

        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            let resolvedAnchor = anchor ?? Self.aggregateTimeRange(of: parts.filter { partIDs.contains($0.partID) })?.lowerBound
            let newParts = try Self.transformed(parts, partIDs: partIDs, kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor, anchor: resolvedAnchor, applyTo: applyTo)
            }

            content = .standardBeat(newParts, tempoMap)

        default:
            throw Error.timeBasisMismatch(expected: .beat)
        }
    }

    /// Augments note attack times and durations by a rational factor for a set of wall-time parts
    /// in this work, along with any parameter maps selected by `applyTo`. All-or-nothing across
    /// just the targeted parts.
    ///
    /// - Parameter partIDs:    The IDs of the parts to augment.
    /// - Parameter factor:     A rational number ≥ 1 by which to stretch the targeted parts’ note
    ///                         timings.
    /// - Parameter anchor:     The low wall-time bound to stretch attack times relative to. `nil`
    ///                         resolves to the aggregate wall-time range spanned by the targeted
    ///                         parts.
    /// - Parameter applyTo:    The parameter maps to augment along with each targeted note table.
    ///                         Defaults to every map.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use wall
    ///             time; otherwise, a transform-failure case naming the part and sub-structure
    ///             that failed.
    public mutating func augment(_ partIDs: Set<PartID>,
                                 by factor: Number,
                                 anchor: WallTime? = nil,
                                 applyTo: MapTargets = .all) throws(Error) {
        switch content {
        case let .absoluteWall(parts):
            typealias PartType = Part<WallTime, Frequency>

            let resolvedAnchor = anchor ?? Self.aggregateTimeRange(of: parts.filter { partIDs.contains($0.partID) })?.lowerBound
            let newParts = try Self.transformed(parts, partIDs: partIDs, kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor, anchor: resolvedAnchor, applyTo: applyTo)
            }

            content = .absoluteWall(newParts)

        case let .keyboardWall(parts):
            typealias PartType = Part<WallTime, NoteNumber>

            let resolvedAnchor = anchor ?? Self.aggregateTimeRange(of: parts.filter { partIDs.contains($0.partID) })?.lowerBound
            let newParts = try Self.transformed(parts, partIDs: partIDs, kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor, anchor: resolvedAnchor, applyTo: applyTo)
            }

            content = .keyboardWall(newParts)

        case let .standardWall(parts):
            typealias PartType = Part<WallTime, Pitch>

            let resolvedAnchor = anchor ?? Self.aggregateTimeRange(of: parts.filter { partIDs.contains($0.partID) })?.lowerBound
            let newParts = try Self.transformed(parts, partIDs: partIDs, kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor, anchor: resolvedAnchor, applyTo: applyTo)
            }

            content = .standardWall(newParts)

        default:
            throw Error.timeBasisMismatch(expected: .wall)
        }
    }

    /// Augments note attack times and durations by a rational factor across every beat-time part
    /// in this work, along with any parameter maps selected by `applyTo` and, unless `applyTo` is
    /// empty, the work’s own tempo map.
    ///
    /// - Parameter factor:     A rational number ≥ 1 by which to stretch every part’s note
    ///                         timings.
    /// - Parameter anchor:     The low beat-time bound to stretch attack times relative to. `nil`
    ///                         resolves to the aggregate beat-time range spanned by every part.
    /// - Parameter applyTo:    The parameter maps (and tempo map) to augment along with every note
    ///                         table. Defaults to every map.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; otherwise, a transform-failure case naming the part (or the tempo map)
    ///             and sub-structure that failed.
    public mutating func augment(by factor: Number,
                                 anchor: BeatTime? = nil,
                                 applyTo: MapTargets = .all) throws(Error) {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            let resolvedAnchor = anchor ?? Self.aggregateTimeRange(of: parts)?.lowerBound
            let newParts = try Self.transformed(parts, kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor, anchor: resolvedAnchor, applyTo: applyTo)
            }
            let newTempoMap = try Self.carriedTempoMap(tempoMap, applyTo: applyTo, kind: .augment) { (tempo: inout TempoMap) throws(TempoMap.Error) in
                try tempo.augment(by: factor, anchor: resolvedAnchor)
            }

            content = .absoluteBeat(newParts, newTempoMap)

        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            let resolvedAnchor = anchor ?? Self.aggregateTimeRange(of: parts)?.lowerBound
            let newParts = try Self.transformed(parts, kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor, anchor: resolvedAnchor, applyTo: applyTo)
            }
            let newTempoMap = try Self.carriedTempoMap(tempoMap, applyTo: applyTo, kind: .augment) { (tempo: inout TempoMap) throws(TempoMap.Error) in
                try tempo.augment(by: factor, anchor: resolvedAnchor)
            }

            content = .keyboardBeat(newParts, newTempoMap)

        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            let resolvedAnchor = anchor ?? Self.aggregateTimeRange(of: parts)?.lowerBound
            let newParts = try Self.transformed(parts, kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor, anchor: resolvedAnchor, applyTo: applyTo)
            }
            let newTempoMap = try Self.carriedTempoMap(tempoMap, applyTo: applyTo, kind: .augment) { (tempo: inout TempoMap) throws(TempoMap.Error) in
                try tempo.augment(by: factor, anchor: resolvedAnchor)
            }

            content = .standardBeat(newParts, newTempoMap)

        default:
            throw Error.timeBasisMismatch(expected: .beat)
        }
    }

    /// Augments note attack times and durations by a rational factor across every wall-time part
    /// in this work, along with any parameter maps selected by `applyTo`.
    ///
    /// - Parameter factor:     A rational number ≥ 1 by which to stretch every part’s note
    ///                         timings.
    /// - Parameter anchor:     The low wall-time bound to stretch attack times relative to. `nil`
    ///                         resolves to the aggregate wall-time range spanned by every part.
    /// - Parameter applyTo:    The parameter maps to augment along with every note table. Defaults
    ///                         to every map.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use wall
    ///             time; otherwise, a transform-failure case naming the part and sub-structure
    ///             that failed.
    public mutating func augment(by factor: Number,
                                 anchor: WallTime? = nil,
                                 applyTo: MapTargets = .all) throws(Error) {
        switch content {
        case let .absoluteWall(parts):
            typealias PartType = Part<WallTime, Frequency>

            let resolvedAnchor = anchor ?? Self.aggregateTimeRange(of: parts)?.lowerBound
            let newParts = try Self.transformed(parts, kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor, anchor: resolvedAnchor, applyTo: applyTo)
            }

            content = .absoluteWall(newParts)

        case let .keyboardWall(parts):
            typealias PartType = Part<WallTime, NoteNumber>

            let resolvedAnchor = anchor ?? Self.aggregateTimeRange(of: parts)?.lowerBound
            let newParts = try Self.transformed(parts, kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor, anchor: resolvedAnchor, applyTo: applyTo)
            }

            content = .keyboardWall(newParts)

        case let .standardWall(parts):
            typealias PartType = Part<WallTime, Pitch>

            let resolvedAnchor = anchor ?? Self.aggregateTimeRange(of: parts)?.lowerBound
            let newParts = try Self.transformed(parts, kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor, anchor: resolvedAnchor, applyTo: applyTo)
            }

            content = .standardWall(newParts)

        default:
            throw Error.timeBasisMismatch(expected: .wall)
        }
    }
}

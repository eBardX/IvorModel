// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiNumbers

internal import IvorTuning

extension Work {

    // MARK: Public Instance Methods

    /// Augments note attack times and durations by a rational factor across the beat-time parts in
    /// this work that `partIDs` names, along with any parameter maps selected by `applyTo` and,
    /// when `applyTo` contains ``TransformTargets/tempo``, ``TransformTargets/meter`` or
    /// ``TransformTargets/key``, the work’s own tempo map, meter table or key
    /// table. All three are work-wide, so they’re carried along whichever parts are targeted.
    ///
    /// When the meter table is carried, the meter scales with the music (see
    /// ``MeterTable/augment(by:anchor:)``), so every note keeps its `bar:beat`. When it isn’t, the
    /// music spans more bars of the same meter.
    ///
    /// By default, the music sounds slower afterwards. With `keepingSound`, each tempo from the
    /// anchor on keeps its rate while its unit scales with the music (see
    /// `TempoMap.scaleUnits(by:from:)`), so nothing sounds different.
    ///
    /// - Parameter factor:         A rational number ≥ 1 by which to stretch the targeted parts’
    ///                             note timings.
    /// - Parameter anchor:         The low beat-time bound to stretch attack times relative to.
    /// `nil` resolves to the start of everything being augmented: the targeted parts’ notes and the
    /// entries of every map `applyTo` selects, including the tempo map, the meter table and the key
    /// table.
    /// - Parameter applyTo:        The parameter maps (and the work-wide tables) to augment
    ///                             along with each targeted note table. Defaults to every map.
    /// - Parameter keepingSound:   Whether to scale the tempo units too, so that the music
    ///                             sounds the same. It has an effect only when `applyTo`
    ///                             contains ``TransformTargets/tempo``. Defaults to `false`.
    /// - Parameter partIDs:        The IDs of the parts to transform, or `nil` (the default) for
    ///                             every part. IDs naming no part are ignored.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; otherwise, a transform-failure case naming the part (or the tempo map or
    ///             meter table) and sub-structure that failed.
    public mutating func augment(by factor: Number,
                                 anchor: BeatTime? = nil,
                                 applyTo: TransformTargets = .all,
                                 keepingSound: Bool = false,
                                 partIDs: Set<PartID>? = nil) throws(Error) {
        try ensureUnlocked()

        switch content.cases {
        case let .absoluteBeat(parts, tempoMap, meterTable, keyTable):
            typealias PartType = Part<BeatTime, Frequency>

            let resolvedAnchor = anchor ?? Self.transformTimeRange(of: Self.selected(parts, partIDs: partIDs),
                                                                   tempoMap: tempoMap,
                                                                   meterTable: meterTable,
                                                                   keyTable: keyTable,
                                                                   applyTo: applyTo)?.lowerBound
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor, anchor: resolvedAnchor, applyTo: applyTo)
            }
            let (newTempoMap, newMeterTable, newKeyTable) = try Self._augmentedTables(tempoMap: tempoMap,
                                                                                      meterTable: meterTable,
                                                                                      keyTable: keyTable,
                                                                                      by: factor,
                                                                                      anchor: resolvedAnchor,
                                                                                      applyTo: applyTo,
                                                                                      keepingSound: keepingSound)

            content = .absoluteBeat(newParts, newTempoMap, newMeterTable, newKeyTable)

        case let .keyboardBeat(parts, tempoMap, meterTable, keyTable):
            typealias PartType = Part<BeatTime, NoteNumber>

            let resolvedAnchor = anchor ?? Self.transformTimeRange(of: Self.selected(parts, partIDs: partIDs),
                                                                   tempoMap: tempoMap,
                                                                   meterTable: meterTable,
                                                                   keyTable: keyTable,
                                                                   applyTo: applyTo)?.lowerBound
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor, anchor: resolvedAnchor, applyTo: applyTo)
            }
            let (newTempoMap, newMeterTable, newKeyTable) = try Self._augmentedTables(tempoMap: tempoMap,
                                                                                      meterTable: meterTable,
                                                                                      keyTable: keyTable,
                                                                                      by: factor,
                                                                                      anchor: resolvedAnchor,
                                                                                      applyTo: applyTo,
                                                                                      keepingSound: keepingSound)

            content = .keyboardBeat(newParts, newTempoMap, newMeterTable, newKeyTable)

        case let .standardBeat(parts, tempoMap, meterTable, keyTable):
            typealias PartType = Part<BeatTime, Pitch>

            let resolvedAnchor = anchor ?? Self.transformTimeRange(of: Self.selected(parts, partIDs: partIDs),
                                                                   tempoMap: tempoMap,
                                                                   meterTable: meterTable,
                                                                   keyTable: keyTable,
                                                                   applyTo: applyTo)?.lowerBound
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor, anchor: resolvedAnchor, applyTo: applyTo)
            }
            let (newTempoMap, newMeterTable, newKeyTable) = try Self._augmentedTables(tempoMap: tempoMap,
                                                                                      meterTable: meterTable,
                                                                                      keyTable: keyTable,
                                                                                      by: factor,
                                                                                      anchor: resolvedAnchor,
                                                                                      applyTo: applyTo,
                                                                                      keepingSound: keepingSound)

            content = .standardBeat(newParts, newTempoMap, newMeterTable, newKeyTable)

        default:
            throw Error.timeBasisMismatch(expected: .beat)
        }
    }

    /// Augments note attack times and durations by a rational factor across the wall-time parts in
    /// this work that `partIDs` names, along with any parameter maps selected by `applyTo`.
    ///
    /// - Parameter factor:     A rational number ≥ 1 by which to stretch the targeted parts’ note
    ///                         timings.
    /// - Parameter anchor:     The low wall-time bound to stretch attack times relative to. `nil`
    ///                         resolves to the start of everything being augmented: the targeted
    ///                         parts’ notes and the entries of every map `applyTo` selects.
    /// - Parameter applyTo:    The parameter maps to augment along with each targeted note table.
    ///                         Defaults to every map.
    /// - Parameter partIDs:    The IDs of the parts to transform, or `nil` (the default) for every
    ///                         part. IDs naming no part are ignored.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use wall
    ///             time; otherwise, a transform-failure case naming the part and sub-structure
    ///             that failed.
    public mutating func augment(by factor: Number,
                                 anchor: WallTime? = nil,
                                 applyTo: TransformTargets = .all,
                                 partIDs: Set<PartID>? = nil) throws(Error) {
        try ensureUnlocked()

        switch content.cases {
        case let .absoluteWall(parts):
            typealias PartType = Part<WallTime, Frequency>

            let resolvedAnchor = anchor ?? Self.transformTimeRange(of: Self.selected(parts, partIDs: partIDs),
                                                                   applyTo: applyTo)?.lowerBound
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor,
                                 anchor: resolvedAnchor,
                                 applyTo: applyTo)
            }

            content = .absoluteWall(newParts)

        case let .keyboardWall(parts):
            typealias PartType = Part<WallTime, NoteNumber>

            let resolvedAnchor = anchor ?? Self.transformTimeRange(of: Self.selected(parts, partIDs: partIDs),
                                                                   applyTo: applyTo)?.lowerBound
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor,
                                 anchor: resolvedAnchor,
                                 applyTo: applyTo)
            }

            content = .keyboardWall(newParts)

        case let .standardWall(parts):
            typealias PartType = Part<WallTime, Pitch>

            let resolvedAnchor = anchor ?? Self.transformTimeRange(of: Self.selected(parts, partIDs: partIDs),
                                                                   applyTo: applyTo)?.lowerBound
            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .augment) { (part: inout PartType) throws(PartType.Error) in
                try part.augment(by: factor,
                                 anchor: resolvedAnchor,
                                 applyTo: applyTo)
            }

            content = .standardWall(newParts)

        default:
            throw Error.timeBasisMismatch(expected: .wall)
        }
    }

    // MARK: Private Type Methods

    //
    // The work-wide tables a beat-time augment carries along: the tempo map, meter table and key
    // table, each only when `applyTo` names it.
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

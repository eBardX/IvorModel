// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTuning

internal import IvorTiming

extension Work {

    // MARK: Public Instance Methods

    /// Inverts note pitches around a frequency range across the parts in this work that `partIDs`
    /// names.
    ///
    /// In beat time, the work’s keys are removed, unless `movesKeys` is
    /// `false`: inverting them would need an assignment of frequencies to pitch classes, which an
    /// absolute-pitch work doesn’t have.
    ///
    /// - Parameter pitchRange:         The frequency range to invert pitches around. `nil`
    ///                                 resolves to the aggregate frequency range spanned by the
    ///                                 targeted parts.
    /// - Parameter movesKeys:          Whether to invert (or, in absolute pitch, remove) the
    ///                                 work’s keys too. Defaults to `true`.
    /// - Parameter partIDs:            The IDs of the parts to transform, or `nil` (the default)
    ///                                 for every part. IDs naming no part are ignored.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             absolute (frequency) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(kind:partID:detail:)`` naming the part that failed.
    public mutating func invert(around pitchRange: ClosedRange<Frequency>? = nil,
                                movesKeys: Bool = true,
                                partIDs: Set<PartID>? = nil) throws(Error) {
        try ensureUnlocked()

        switch content.cases {
        case let .absoluteBeat(parts, tempoMap, meterTable, keyTable):
            typealias PartType = Part<BeatTime, Frequency>

            let resolvedRange = pitchRange ?? Self.aggregatePitchRange(of: Self.selected(parts, partIDs: partIDs))

            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: resolvedRange)
            }

            var newKeyTable = keyTable

            //
            // Inverting keys needs an assignment of frequencies to pitch classes, which
            // an absolute-pitch work doesn't have, so they're removed instead.
            //
            if movesKeys,
               resolvedRange != nil {
                newKeyTable.removeAll()
            }

            content = .absoluteBeat(newParts, tempoMap, meterTable, newKeyTable)

        case let .absoluteWall(parts):
            typealias PartType = Part<WallTime, Frequency>

            let resolvedRange = pitchRange ?? Self.aggregatePitchRange(of: Self.selected(parts, partIDs: partIDs))

            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: resolvedRange)
            }

            content = .absoluteWall(newParts)

        default:
            throw Error.pitchNotationMismatch(expected: .absolute)
        }
    }

    /// Inverts note pitches around a MIDI note number range across the parts in this work that
    /// `partIDs` names.
    ///
    /// In beat time, the work’s keys are inverted too, unless `movesKeys` is `false`, assuming
    /// 12 keys to the octave; a diatonic key’s mode is mapped. If any key can’t be inverted,
    /// they’re all removed.
    ///
    /// - Parameter pitchRange:         The note number range to invert pitches around. `nil`
    ///                                 resolves to the aggregate note number range spanned by the
    ///                                 targeted parts.
    /// - Parameter movesKeys:          Whether to invert (or, in absolute pitch, remove) the
    ///                                 work’s keys too. Defaults to `true`.
    /// - Parameter partIDs:            The IDs of the parts to transform, or `nil` (the default)
    ///                                 for every part. IDs naming no part are ignored.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             keyboard (MIDI note number) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(kind:partID:detail:)`` naming the part that failed.
    public mutating func invert(around pitchRange: ClosedRange<NoteNumber>? = nil,
                                movesKeys: Bool = true,
                                partIDs: Set<PartID>? = nil) throws(Error) {
        try ensureUnlocked()

        switch content.cases {
        case let .keyboardBeat(parts, tempoMap, meterTable, keyTable):
            typealias PartType = Part<BeatTime, NoteNumber>

            let resolvedRange = pitchRange ?? Self.aggregatePitchRange(of: Self.selected(parts, partIDs: partIDs))

            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: resolvedRange)
            }

            var newKeyTable = keyTable

            if movesKeys,
               let resolvedRange {
                newKeyTable.invert(around: resolvedRange)
            }

            content = .keyboardBeat(newParts, tempoMap, meterTable, newKeyTable)

        case let .keyboardWall(parts):
            typealias PartType = Part<WallTime, NoteNumber>

            let resolvedRange = pitchRange ?? Self.aggregatePitchRange(of: Self.selected(parts, partIDs: partIDs))

            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: resolvedRange)
            }

            content = .keyboardWall(newParts)

        default:
            throw Error.pitchNotationMismatch(expected: .keyboard)
        }
    }

    /// Inverts note pitches around a pitch range across the parts in this work that `partIDs`
    /// names.
    ///
    /// In beat time, the work’s keys are inverted too, unless `movesKeys` is `false`, exactly; a
    /// diatonic key’s mode is mapped. If any key can’t be inverted, they’re all removed.
    ///
    /// - Parameter pitchRange:         The pitch range to invert pitches around. `nil`
    ///                                 resolves to the aggregate pitch range spanned by the
    ///                                 targeted parts.
    /// - Parameter movesKeys:          Whether to invert (or, in absolute pitch, remove) the
    ///                                 work’s keys too. Defaults to `true`.
    /// - Parameter partIDs:            The IDs of the parts to transform, or `nil` (the default)
    ///                                 for every part. IDs naming no part are ignored.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             standard (staff) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(kind:partID:detail:)`` naming the part that failed.
    public mutating func invert(around pitchRange: ClosedRange<Pitch>? = nil,
                                movesKeys: Bool = true,
                                partIDs: Set<PartID>? = nil) throws(Error) {
        try ensureUnlocked()

        switch content.cases {
        case let .standardBeat(parts, tempoMap, meterTable, keyTable):
            typealias PartType = Part<BeatTime, Pitch>

            let resolvedRange = pitchRange ?? Self.aggregatePitchRange(of: Self.selected(parts, partIDs: partIDs))

            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: resolvedRange)
            }

            var newKeyTable = keyTable

            if movesKeys,
               let resolvedRange {
                newKeyTable.invert(around: resolvedRange)
            }

            content = .standardBeat(newParts, tempoMap, meterTable, newKeyTable)

        case let .standardWall(parts):
            typealias PartType = Part<WallTime, Pitch>

            let resolvedRange = pitchRange ?? Self.aggregatePitchRange(of: Self.selected(parts, partIDs: partIDs))

            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: resolvedRange)
            }

            content = .standardWall(newParts)

        default:
            throw Error.pitchNotationMismatch(expected: .standard)
        }
    }
}

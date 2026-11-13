// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTuning

internal import IvorTiming

extension Work {

    // MARK: Public Instance Methods

    /// Transposes note pitches by a directed ratio across the parts in this work that `partIDs`
    /// names.
    ///
    /// - Parameter directedInterval:   The directed ratio by which to transpose the targeted parts’
    ///                                 pitches.
    /// - Parameter partIDs:            The IDs of the parts to transform, or `nil` (the default)
    ///                                 for every part. IDs naming no part are ignored.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             absolute (frequency) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(kind:partID:detail:)`` naming the part that failed.
    public mutating func transpose(by directedInterval: DirectedInterval<Ratio>,
                                   partIDs: Set<PartID>? = nil) throws(Error) {
        try ensureUnlocked()

        switch content {
        case let .absoluteBeat(parts, tempoMap, meterTable):
            typealias PartType = Part<BeatTime, Frequency>

            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .transpose) { (part: inout PartType) throws(PartType.Error) in
                try part.transpose(by: directedInterval)
            }

            content = .absoluteBeat(newParts, tempoMap, meterTable)

        case let .absoluteWall(parts):
            typealias PartType = Part<WallTime, Frequency>

            content = try .absoluteWall(Self.transformed(parts: parts,
                                                         partIDs: partIDs,
                                                         kind: .transpose) { (part: inout PartType) throws(PartType.Error) in
                try part.transpose(by: directedInterval)
            })

        default:
            throw Error.pitchNotationMismatch(expected: .absolute)
        }
    }

    /// Transposes note pitches by a directed note distance across the parts in this work that
    /// `partIDs` names.
    ///
    /// - Parameter directedInterval:   The directed note distance by which to transpose every
    ///                                 part’s pitches.
    /// - Parameter partIDs:            The IDs of the parts to transform, or `nil` (the default)
    ///                                 for every part. IDs naming no part are ignored.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             keyboard (MIDI note number) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(kind:partID:detail:)`` naming the part that failed.
    public mutating func transpose(by directedInterval: DirectedInterval<NoteDistance>,
                                   partIDs: Set<PartID>? = nil) throws(Error) {
        try ensureUnlocked()

        switch content {
        case let .keyboardBeat(parts, tempoMap, meterTable):
            typealias PartType = Part<BeatTime, NoteNumber>

            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .transpose) { (part: inout PartType) throws(PartType.Error) in
                try part.transpose(by: directedInterval)
            }

            content = .keyboardBeat(newParts, tempoMap, meterTable)

        case let .keyboardWall(parts):
            typealias PartType = Part<WallTime, NoteNumber>

            content = try .keyboardWall(Self.transformed(parts: parts,
                                                         partIDs: partIDs,
                                                         kind: .transpose) { (part: inout PartType) throws(PartType.Error) in
                try part.transpose(by: directedInterval)
            })

        default:
            throw Error.pitchNotationMismatch(expected: .keyboard)
        }
    }

    /// Transposes note pitches by a directed interval across the parts in this work that `partIDs`
    /// names.
    ///
    /// - Parameter directedInterval:   The directed interval by which to transpose the targeted
    ///                                 parts’ pitches.
    /// - Parameter partIDs:            The IDs of the parts to transform, or `nil` (the default)
    ///                                 for every part. IDs naming no part are ignored.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             standard (staff) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(kind:partID:detail:)`` naming the part that failed.
    public mutating func transpose(by directedInterval: DirectedInterval<Interval>,
                                   partIDs: Set<PartID>? = nil) throws(Error) {
        try ensureUnlocked()

        switch content {
        case let .standardBeat(parts, tempoMap, meterTable):
            typealias PartType = Part<BeatTime, Pitch>

            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .transpose) { (part: inout PartType) throws(PartType.Error) in
                try part.transpose(by: directedInterval)
            }

            content = .standardBeat(newParts, tempoMap, meterTable)

        case let .standardWall(parts):
            typealias PartType = Part<WallTime, Pitch>

            content = try .standardWall(Self.transformed(parts: parts,
                                                         partIDs: partIDs,
                                                         kind: .transpose) { (part: inout PartType) throws(PartType.Error) in
                try part.transpose(by: directedInterval)
            })

        default:
            throw Error.pitchNotationMismatch(expected: .standard)
        }
    }
}

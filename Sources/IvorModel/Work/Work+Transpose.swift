// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTuning

internal import IvorTiming

extension Work {

    // MARK: Public Instance Methods

    /// Transposes note pitches by a directed ratio for a single part in this work. No-ops if no
    /// part with `partID` is found.
    ///
    /// - Parameter partID:            The ID of the part to transpose.
    /// - Parameter directedInterval:  The directed ratio by which to transpose the part’s
    ///                                pitches.
    ///
    /// - Throws:   ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             absolute (frequency) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(_:partID:detail:)`` naming the part that failed.
    public mutating func transpose(_ partID: PartID,
                                   by directedInterval: DirectedInterval<Ratio>) throws(Error) {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            content = try .absoluteBeat(Self.transformed(parts: parts,
                                                         partID: partID,
                                                         kind: .transpose) { (part: inout PartType) throws(PartType.Error) in
                try part.transpose(by: directedInterval)
            }, tempoMap)

        case let .absoluteWall(parts):
            typealias PartType = Part<WallTime, Frequency>

            content = try .absoluteWall(Self.transformed(parts: parts,
                                                         partID: partID,
                                                         kind: .transpose) { (part: inout PartType) throws(PartType.Error) in
                try part.transpose(by: directedInterval)
            })

        default:
            throw Error.pitchNotationMismatch(expected: .absolute)
        }
    }

    /// Transposes note pitches by a directed note distance for a single part in this work.
    /// No-ops if no part with `partID` is found.
    ///
    /// - Parameter partID:            The ID of the part to transpose.
    /// - Parameter directedInterval:  The directed note distance by which to transpose the
    ///                                part’s pitches.
    ///
    /// - Throws:   ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             keyboard (MIDI note number) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(_:partID:detail:)`` naming the part that failed.
    public mutating func transpose(_ partID: PartID,
                                   by directedInterval: DirectedInterval<NoteDistance>) throws(Error) {
        switch content {
        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            content = try .keyboardBeat(Self.transformed(parts: parts,
                                                         partID: partID,
                                                         kind: .transpose) { (part: inout PartType) throws(PartType.Error) in
                try part.transpose(by: directedInterval)
            }, tempoMap)

        case let .keyboardWall(parts):
            typealias PartType = Part<WallTime, NoteNumber>

            content = try .keyboardWall(Self.transformed(parts: parts,
                                                         partID: partID,
                                                         kind: .transpose) { (part: inout PartType) throws(PartType.Error) in
                try part.transpose(by: directedInterval)
            })

        default:
            throw Error.pitchNotationMismatch(expected: .keyboard)
        }
    }

    /// Transposes note pitches by a directed interval for a single part in this work. No-ops if
    /// no part with `partID` is found.
    ///
    /// - Parameter partID:            The ID of the part to transpose.
    /// - Parameter directedInterval:  The directed interval by which to transpose the part’s
    ///                                pitches.
    ///
    /// - Throws:   ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             standard (staff) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(_:partID:detail:)`` naming the part that failed.
    public mutating func transpose(_ partID: PartID,
                                   by directedInterval: DirectedInterval<Interval>) throws(Error) {
        switch content {
        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            content = try .standardBeat(Self.transformed(parts: parts,
                                                         partID: partID,
                                                         kind: .transpose) { (part: inout PartType) throws(PartType.Error) in
                try part.transpose(by: directedInterval)
            }, tempoMap)

        case let .standardWall(parts):
            typealias PartType = Part<WallTime, Pitch>

            content = try .standardWall(Self.transformed(parts: parts,
                                                         partID: partID,
                                                         kind: .transpose) { (part: inout PartType) throws(PartType.Error) in
                try part.transpose(by: directedInterval)
            })

        default:
            throw Error.pitchNotationMismatch(expected: .standard)
        }
    }

    /// Transposes note pitches by a directed ratio for a set of parts in this work.
    /// All-or-nothing across just the targeted parts.
    ///
    /// - Parameter partIDs:           The IDs of the parts to transpose.
    /// - Parameter directedInterval:  The directed ratio by which to transpose the targeted
    ///                                parts’ pitches.
    ///
    /// - Throws:   ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             absolute (frequency) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(_:partID:detail:)`` naming the part that failed.
    public mutating func transpose(_ partIDs: Set<PartID>,
                                   by directedInterval: DirectedInterval<Ratio>) throws(Error) {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            content = try .absoluteBeat(Self.transformed(parts: parts,
                                                         partIDs: partIDs,
                                                         kind: .transpose) { (part: inout PartType) throws(PartType.Error) in
                try part.transpose(by: directedInterval)
            }, tempoMap)

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

    /// Transposes note pitches by a directed note distance for a set of parts in this work.
    /// All-or-nothing across just the targeted parts.
    ///
    /// - Parameter partIDs:           The IDs of the parts to transpose.
    /// - Parameter directedInterval:  The directed note distance by which to transpose the
    ///                                targeted parts’ pitches.
    ///
    /// - Throws:   ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             keyboard (MIDI note number) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(_:partID:detail:)`` naming the part that failed.
    public mutating func transpose(_ partIDs: Set<PartID>,
                                   by directedInterval: DirectedInterval<NoteDistance>) throws(Error) {
        switch content {
        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            content = try .keyboardBeat(Self.transformed(parts: parts,
                                                         partIDs: partIDs,
                                                         kind: .transpose) { (part: inout PartType) throws(PartType.Error) in
                try part.transpose(by: directedInterval)
            }, tempoMap)

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

    /// Transposes note pitches by a directed interval for a set of parts in this work.
    /// All-or-nothing across just the targeted parts.
    ///
    /// - Parameter partIDs:           The IDs of the parts to transpose.
    /// - Parameter directedInterval:  The directed interval by which to transpose the targeted
    ///                                parts’ pitches.
    ///
    /// - Throws:   ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             standard (staff) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(_:partID:detail:)`` naming the part that failed.
    public mutating func transpose(_ partIDs: Set<PartID>,
                                   by directedInterval: DirectedInterval<Interval>) throws(Error) {
        switch content {
        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            content = try .standardBeat(Self.transformed(parts: parts,
                                                         partIDs: partIDs,
                                                         kind: .transpose) { (part: inout PartType) throws(PartType.Error) in
                try part.transpose(by: directedInterval)
            }, tempoMap)

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

    /// Transposes note pitches by a directed ratio across every part in this work.
    ///
    /// - Parameter directedInterval:   The directed ratio by which to transpose every part’s
    ///                                 pitches.
    ///
    /// - Throws:   ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             absolute (frequency) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(_:partID:detail:)`` naming the part that failed.
    public mutating func transpose(by directedInterval: DirectedInterval<Ratio>) throws(Error) {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            content = try .absoluteBeat(Self.transformed(parts: parts,
                                                         kind: .transpose) { (part: inout PartType) throws(PartType.Error) in
                try part.transpose(by: directedInterval)
            }, tempoMap)

        case let .absoluteWall(parts):
            typealias PartType = Part<WallTime, Frequency>

            content = try .absoluteWall(Self.transformed(parts: parts,
                                                         kind: .transpose) { (part: inout PartType) throws(PartType.Error) in
                try part.transpose(by: directedInterval)
            })

        default:
            throw Error.pitchNotationMismatch(expected: .absolute)
        }
    }

    /// Transposes note pitches by a directed note distance across every part in this work.
    ///
    /// - Parameter directedInterval:   The directed note distance by which to transpose every
    ///                                 part’s pitches.
    ///
    /// - Throws:   ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             keyboard (MIDI note number) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(_:partID:detail:)`` naming the part that failed.
    public mutating func transpose(by directedInterval: DirectedInterval<NoteDistance>) throws(Error) {
        switch content {
        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            content = try .keyboardBeat(Self.transformed(parts: parts,
                                                         kind: .transpose) { (part: inout PartType) throws(PartType.Error) in
                try part.transpose(by: directedInterval)
            }, tempoMap)

        case let .keyboardWall(parts):
            typealias PartType = Part<WallTime, NoteNumber>

            content = try .keyboardWall(Self.transformed(parts: parts,
                                                         kind: .transpose) { (part: inout PartType) throws(PartType.Error) in
                try part.transpose(by: directedInterval)
            })

        default:
            throw Error.pitchNotationMismatch(expected: .keyboard)
        }
    }

    /// Transposes note pitches by a directed interval across every part in this work.
    ///
    /// - Parameter directedInterval:   The directed interval by which to transpose every part’s
    ///                                 pitches.
    ///
    /// - Throws:   ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             standard (staff) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(_:partID:detail:)`` naming the part that failed.
    public mutating func transpose(by directedInterval: DirectedInterval<Interval>) throws(Error) {
        switch content {
        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            content = try .standardBeat(Self.transformed(parts: parts,
                                                         kind: .transpose) { (part: inout PartType) throws(PartType.Error) in
                try part.transpose(by: directedInterval)
            }, tempoMap)

        case let .standardWall(parts):
            typealias PartType = Part<WallTime, Pitch>

            content = try .standardWall(Self.transformed(parts: parts,
                                                         kind: .transpose) { (part: inout PartType) throws(PartType.Error) in
                try part.transpose(by: directedInterval)
            })

        default:
            throw Error.pitchNotationMismatch(expected: .standard)
        }
    }
}

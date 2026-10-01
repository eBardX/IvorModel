// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTuning

internal import IvorTiming

extension Work {

    // MARK: Public Instance Methods

    /// Inverts note pitches around a frequency range across the parts in this work that `partIDs`
    /// names.
    ///
    /// - Parameter pitchRange:   The frequency range to invert pitches around. `nil` resolves to
    ///                           the aggregate frequency range spanned by the targeted parts.
    /// - Parameter partIDs:      The IDs of the parts to transform, or `nil` (the default) for
    ///                           every part. IDs naming no part are ignored.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             absolute (frequency) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(_:partID:detail:)`` naming the part that failed.
    public mutating func invert(around pitchRange: ClosedRange<Frequency>? = nil,
                                partIDs: Set<PartID>? = nil) throws(Error) {
        try ensureUnlocked()

        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            let resolvedRange = pitchRange ?? Self.aggregatePitchRange(of: Self.selected(parts, partIDs: partIDs))

            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: resolvedRange)
            }

            content = .absoluteBeat(newParts, tempoMap)

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
    /// - Parameter pitchRange:   The note number range to invert pitches around. `nil` resolves to
    ///                           the aggregate note number range spanned by the targeted parts.
    /// - Parameter partIDs:      The IDs of the parts to transform, or `nil` (the default) for
    ///                           every part. IDs naming no part are ignored.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             keyboard (MIDI note number) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(_:partID:detail:)`` naming the part that failed.
    public mutating func invert(around pitchRange: ClosedRange<NoteNumber>? = nil,
                                partIDs: Set<PartID>? = nil) throws(Error) {
        try ensureUnlocked()

        switch content {
        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            let resolvedRange = pitchRange ?? Self.aggregatePitchRange(of: Self.selected(parts, partIDs: partIDs))

            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: resolvedRange)
            }

            content = .keyboardBeat(newParts, tempoMap)

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
    /// - Parameter pitchRange:   The pitch range to invert pitches around. `nil` resolves to the
    ///                           aggregate pitch range spanned by the targeted parts.
    /// - Parameter partIDs:      The IDs of the parts to transform, or `nil` (the default) for
    ///                           every part. IDs naming no part are ignored.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             standard (staff) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(_:partID:detail:)`` naming the part that failed.
    public mutating func invert(around pitchRange: ClosedRange<Pitch>? = nil,
                                partIDs: Set<PartID>? = nil) throws(Error) {
        try ensureUnlocked()

        switch content {
        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            let resolvedRange = pitchRange ?? Self.aggregatePitchRange(of: Self.selected(parts, partIDs: partIDs))

            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: resolvedRange)
            }

            content = .standardBeat(newParts, tempoMap)

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

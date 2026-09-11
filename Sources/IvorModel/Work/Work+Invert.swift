// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTuning

internal import IvorTiming

extension Work {

    // MARK: Public Instance Methods

    /// Inverts note pitches around a frequency range for a single part in this work. No-ops if
    /// no part with `partID` is found.
    ///
    /// - Parameter partID:      The ID of the part to invert.
    /// - Parameter pitchRange:  The frequency range to invert pitches around. `nil` resolves to
    ///                          the part’s own frequency range.
    ///
    /// - Throws:   ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             absolute (frequency) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(_:partID:detail:)`` naming the part that failed.
    public mutating func invert(_ partID: PartID,
                                around pitchRange: ClosedRange<Frequency>? = nil) throws(Error) {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            content = try .absoluteBeat(Self.transformed(parts, partID: partID, kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: pitchRange)
            }, tempoMap)

        case let .absoluteWall(parts):
            typealias PartType = Part<WallTime, Frequency>

            content = try .absoluteWall(Self.transformed(parts, partID: partID, kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: pitchRange)
            })

        default:
            throw Error.pitchNotationMismatch(expected: .absolute)
        }
    }

    /// Inverts note pitches around a MIDI note number range for a single part in this work.
    /// No-ops if no part with `partID` is found.
    ///
    /// - Parameter partID:      The ID of the part to invert.
    /// - Parameter pitchRange:  The note number range to invert pitches around. `nil` resolves to
    ///                          the part’s own note number range.
    ///
    /// - Throws:   ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             keyboard (MIDI note number) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(_:partID:detail:)`` naming the part that failed.
    public mutating func invert(_ partID: PartID,
                                around pitchRange: ClosedRange<NoteNumber>? = nil) throws(Error) {
        switch content {
        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            content = try .keyboardBeat(Self.transformed(parts, partID: partID, kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: pitchRange)
            }, tempoMap)

        case let .keyboardWall(parts):
            typealias PartType = Part<WallTime, NoteNumber>

            content = try .keyboardWall(Self.transformed(parts, partID: partID, kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: pitchRange)
            })

        default:
            throw Error.pitchNotationMismatch(expected: .keyboard)
        }
    }

    /// Inverts note pitches around a pitch range for a single part in this work. No-ops if no
    /// part with `partID` is found.
    ///
    /// - Parameter partID:      The ID of the part to invert.
    /// - Parameter pitchRange:  The pitch range to invert pitches around. `nil` resolves to the
    ///                          part’s own pitch range.
    ///
    /// - Throws:   ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             standard (staff) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(_:partID:detail:)`` naming the part that failed.
    public mutating func invert(_ partID: PartID,
                                around pitchRange: ClosedRange<Pitch>? = nil) throws(Error) {
        switch content {
        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            content = try .standardBeat(Self.transformed(parts, partID: partID, kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: pitchRange)
            }, tempoMap)

        case let .standardWall(parts):
            typealias PartType = Part<WallTime, Pitch>

            content = try .standardWall(Self.transformed(parts, partID: partID, kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: pitchRange)
            })

        default:
            throw Error.pitchNotationMismatch(expected: .standard)
        }
    }

    /// Inverts note pitches around a frequency range for a set of parts in this work.
    /// All-or-nothing across just the targeted parts.
    ///
    /// - Parameter partIDs:     The IDs of the parts to invert.
    /// - Parameter pitchRange:  The frequency range to invert pitches around. `nil` resolves to
    ///                          the aggregate frequency range spanned by the targeted parts.
    ///
    /// - Throws:   ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             absolute (frequency) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(_:partID:detail:)`` naming the part that failed.
    public mutating func invert(_ partIDs: Set<PartID>,
                                around pitchRange: ClosedRange<Frequency>? = nil) throws(Error) {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            let resolvedRange = pitchRange ?? Self.aggregatePitchRange(of: parts.filter { partIDs.contains($0.partID) })
            let newParts = try Self.transformed(parts, partIDs: partIDs, kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: resolvedRange)
            }

            content = .absoluteBeat(newParts, tempoMap)

        case let .absoluteWall(parts):
            typealias PartType = Part<WallTime, Frequency>

            let resolvedRange = pitchRange ?? Self.aggregatePitchRange(of: parts.filter { partIDs.contains($0.partID) })
            let newParts = try Self.transformed(parts, partIDs: partIDs, kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: resolvedRange)
            }

            content = .absoluteWall(newParts)

        default:
            throw Error.pitchNotationMismatch(expected: .absolute)
        }
    }

    /// Inverts note pitches around a MIDI note number range for a set of parts in this work.
    /// All-or-nothing across just the targeted parts.
    ///
    /// - Parameter partIDs:     The IDs of the parts to invert.
    /// - Parameter pitchRange:  The note number range to invert pitches around. `nil` resolves to
    ///                          the aggregate note number range spanned by the targeted parts.
    ///
    /// - Throws:   ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             keyboard (MIDI note number) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(_:partID:detail:)`` naming the part that failed.
    public mutating func invert(_ partIDs: Set<PartID>,
                                around pitchRange: ClosedRange<NoteNumber>? = nil) throws(Error) {
        switch content {
        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            let resolvedRange = pitchRange ?? Self.aggregatePitchRange(of: parts.filter { partIDs.contains($0.partID) })
            let newParts = try Self.transformed(parts, partIDs: partIDs, kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: resolvedRange)
            }

            content = .keyboardBeat(newParts, tempoMap)

        case let .keyboardWall(parts):
            typealias PartType = Part<WallTime, NoteNumber>

            let resolvedRange = pitchRange ?? Self.aggregatePitchRange(of: parts.filter { partIDs.contains($0.partID) })
            let newParts = try Self.transformed(parts, partIDs: partIDs, kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: resolvedRange)
            }

            content = .keyboardWall(newParts)

        default:
            throw Error.pitchNotationMismatch(expected: .keyboard)
        }
    }

    /// Inverts note pitches around a pitch range for a set of parts in this work. All-or-nothing
    /// across just the targeted parts.
    ///
    /// - Parameter partIDs:     The IDs of the parts to invert.
    /// - Parameter pitchRange:  The pitch range to invert pitches around. `nil` resolves to the
    ///                          aggregate pitch range spanned by the targeted parts.
    ///
    /// - Throws:   ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             standard (staff) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(_:partID:detail:)`` naming the part that failed.
    public mutating func invert(_ partIDs: Set<PartID>,
                                around pitchRange: ClosedRange<Pitch>? = nil) throws(Error) {
        switch content {
        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            let resolvedRange = pitchRange ?? Self.aggregatePitchRange(of: parts.filter { partIDs.contains($0.partID) })
            let newParts = try Self.transformed(parts, partIDs: partIDs, kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: resolvedRange)
            }

            content = .standardBeat(newParts, tempoMap)

        case let .standardWall(parts):
            typealias PartType = Part<WallTime, Pitch>

            let resolvedRange = pitchRange ?? Self.aggregatePitchRange(of: parts.filter { partIDs.contains($0.partID) })
            let newParts = try Self.transformed(parts, partIDs: partIDs, kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: resolvedRange)
            }

            content = .standardWall(newParts)

        default:
            throw Error.pitchNotationMismatch(expected: .standard)
        }
    }

    /// Inverts note pitches around a frequency range across every part in this work.
    ///
    /// - Parameter pitchRange:   The frequency range to invert pitches around. `nil` resolves to
    ///                           the aggregate frequency range spanned by every part.
    ///
    /// - Throws:   ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             absolute (frequency) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(_:partID:detail:)`` naming the part that failed.
    public mutating func invert(around pitchRange: ClosedRange<Frequency>? = nil) throws(Error) {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            let resolvedRange = pitchRange ?? Self.aggregatePitchRange(of: parts)

            content = try .absoluteBeat(Self.transformed(parts, kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: resolvedRange)
            }, tempoMap)

        case let .absoluteWall(parts):
            typealias PartType = Part<WallTime, Frequency>

            let resolvedRange = pitchRange ?? Self.aggregatePitchRange(of: parts)

            content = try .absoluteWall(Self.transformed(parts, kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: resolvedRange)
            })

        default:
            throw Error.pitchNotationMismatch(expected: .absolute)
        }
    }

    /// Inverts note pitches around a MIDI note number range across every part in this work.
    ///
    /// - Parameter pitchRange:   The note number range to invert pitches around. `nil` resolves
    ///                           to the aggregate note number range spanned by every part.
    ///
    /// - Throws:   ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             keyboard (MIDI note number) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(_:partID:detail:)`` naming the part that failed.
    public mutating func invert(around pitchRange: ClosedRange<NoteNumber>? = nil) throws(Error) {
        switch content {
        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            let resolvedRange = pitchRange ?? Self.aggregatePitchRange(of: parts)

            content = try .keyboardBeat(Self.transformed(parts, kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: resolvedRange)
            }, tempoMap)

        case let .keyboardWall(parts):
            typealias PartType = Part<WallTime, NoteNumber>

            let resolvedRange = pitchRange ?? Self.aggregatePitchRange(of: parts)

            content = try .keyboardWall(Self.transformed(parts, kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: resolvedRange)
            })

        default:
            throw Error.pitchNotationMismatch(expected: .keyboard)
        }
    }

    /// Inverts note pitches around a pitch range across every part in this work.
    ///
    /// - Parameter pitchRange:   The pitch range to invert pitches around. `nil` resolves to the
    ///                           aggregate pitch range spanned by every part.
    ///
    /// - Throws:   ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             standard (staff) pitch notation; otherwise,
    ///             ``Work/Error/transformFailure(_:partID:detail:)`` naming the part that failed.
    public mutating func invert(around pitchRange: ClosedRange<Pitch>? = nil) throws(Error) {
        switch content {
        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            let resolvedRange = pitchRange ?? Self.aggregatePitchRange(of: parts)

            content = try .standardBeat(Self.transformed(parts, kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: resolvedRange)
            }, tempoMap)

        case let .standardWall(parts):
            typealias PartType = Part<WallTime, Pitch>

            let resolvedRange = pitchRange ?? Self.aggregatePitchRange(of: parts)

            content = try .standardWall(Self.transformed(parts, kind: .invert) { (part: inout PartType) throws(PartType.Error) in
                try part.invert(around: resolvedRange)
            })

        default:
            throw Error.pitchNotationMismatch(expected: .standard)
        }
    }
}

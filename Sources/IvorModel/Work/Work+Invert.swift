// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTuning

internal import IvorTiming

extension Work {

    // MARK: Public Instance Methods

    /// Inverts note pitches around a frequency range across the notes of this work that `scope`
    /// takes.
    ///
    /// In beat time, the work’s keys are removed, when they’re carried, unless `movesKeys` is
    /// `false`: inverting them would need an assignment of frequencies to pitch classes, which an
    /// absolute-pitch work doesn’t have.
    ///
    /// - Parameter pitchRange:         The frequency range to invert pitches around. `nil`
    ///                                 resolves to the scope’s notes’ own range.
    /// - Parameter movesKeys:          Whether to invert (or, in absolute pitch, remove) the
    ///                                 work’s keys too, when the transform carries them: with
    ///                                 the whole work, or when `alsoCarry` contains
    ///                                 ``TransformTargets/key``. Defaults to `true`.
    /// - Parameter alsoCarry:          The work tables to carry even though `scope` doesn’t
    ///                                 cover the whole work; only ``TransformTargets/key``
    ///                                 matters here. Defaults to none.
    /// - Parameter scope:              The notes to invert. Defaults to ``Work/Scope/all``.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             absolute (frequency) pitch notation; an unknown-ID case if `scope` names something not
    ///             in this work; otherwise, ``Work/Error/transformFailure(kind:partID:detail:)``
    ///             naming the part that failed.
    public mutating func invert(around pitchRange: ClosedRange<Frequency>? = nil,
                                movesKeys: Bool = true,
                                alsoCarry: TransformTargets = [],
                                scope: Scope = .all) throws(Error) {
        let (resolution, resolvedRange) = try _invert(around: pitchRange,
                                                      expected: .absolute,
                                                      scope: scope)

        guard movesKeys,
              resolution.workTargets(applyTo: .key, alsoCarry: alsoCarry).contains(.key),
              resolvedRange != nil
        else { return }

        //
        // Inverting keys needs an assignment of frequencies to pitch classes, which an
        // absolute-pitch work doesn't have, so they're removed instead.
        //
        _ = try modifyKeyTable { $0.removeAll() }
    }

    /// Inverts note pitches around a note number range across the notes of this work that `scope`
    /// takes.
    ///
    /// In beat time, the work’s keys are inverted too, when they’re carried, unless `movesKeys`
    /// is `false`, assuming 12 keys to the octave; a diatonic key’s mode is mapped. If any key
    /// can’t be inverted, they’re all removed.
    ///
    /// - Parameter pitchRange:         The note number range to invert pitches around. `nil`
    ///                                 resolves to the scope’s notes’ own range.
    /// - Parameter movesKeys:          Whether to invert (or, in absolute pitch, remove) the
    ///                                 work’s keys too, when the transform carries them: with
    ///                                 the whole work, or when `alsoCarry` contains
    ///                                 ``TransformTargets/key``. Defaults to `true`.
    /// - Parameter alsoCarry:          The work tables to carry even though `scope` doesn’t
    ///                                 cover the whole work; only ``TransformTargets/key``
    ///                                 matters here. Defaults to none.
    /// - Parameter scope:              The notes to invert. Defaults to ``Work/Scope/all``.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             keyboard (MIDI note number) pitch notation; an unknown-ID case if `scope` names something not
    ///             in this work; otherwise, ``Work/Error/transformFailure(kind:partID:detail:)``
    ///             naming the part that failed.
    public mutating func invert(around pitchRange: ClosedRange<NoteNumber>? = nil,
                                movesKeys: Bool = true,
                                alsoCarry: TransformTargets = [],
                                scope: Scope = .all) throws(Error) {
        let (resolution, resolvedRange) = try _invert(around: pitchRange,
                                                      expected: .keyboard,
                                                      scope: scope)

        guard movesKeys,
              resolution.workTargets(applyTo: .key, alsoCarry: alsoCarry).contains(.key),
              let resolvedRange
        else { return }

        _ = try modifyKeyTable { $0.invert(around: resolvedRange) }
    }

    /// Inverts note pitches around a pitch range across the notes of this work that `scope`
    /// takes.
    ///
    /// In beat time, the work’s keys are inverted too, when they’re carried, unless `movesKeys`
    /// is `false`.
    ///
    /// - Parameter pitchRange:         The pitch range to invert pitches around. `nil`
    ///                                 resolves to the scope’s notes’ own range.
    /// - Parameter movesKeys:          Whether to invert (or, in absolute pitch, remove) the
    ///                                 work’s keys too, when the transform carries them: with
    ///                                 the whole work, or when `alsoCarry` contains
    ///                                 ``TransformTargets/key``. Defaults to `true`.
    /// - Parameter alsoCarry:          The work tables to carry even though `scope` doesn’t
    ///                                 cover the whole work; only ``TransformTargets/key``
    ///                                 matters here. Defaults to none.
    /// - Parameter scope:              The notes to invert. Defaults to ``Work/Scope/all``.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             standard pitch notation; an unknown-ID case if `scope` names something not
    ///             in this work; otherwise, ``Work/Error/transformFailure(kind:partID:detail:)``
    ///             naming the part that failed.
    public mutating func invert(around pitchRange: ClosedRange<Pitch>? = nil,
                                movesKeys: Bool = true,
                                alsoCarry: TransformTargets = [],
                                scope: Scope = .all) throws(Error) {
        let (resolution, resolvedRange) = try _invert(around: pitchRange,
                                                      expected: .standard,
                                                      scope: scope)

        guard movesKeys,
              resolution.workTargets(applyTo: .key, alsoCarry: alsoCarry).contains(.key),
              let resolvedRange
        else { return }

        _ = try modifyKeyTable { $0.invert(around: resolvedRange) }
    }

    // MARK: Private Type Aliases

    //
    // What inverting the scope's notes returns: the resolved scope and the range used.
    //
    private typealias InvertResult<PitchType: PitchProtocol> = (ResolvedScope, ClosedRange<PitchType>?)

    // MARK: Private Type Methods

    //
    // The scope's notes inverted around `pitchRange`, of the body's own pitch type (its caller
    // has checked the pitch notation), or around the scope's notes' own range. Returns the
    // resolved scope and the range used.
    //
    private static func _invertParts<WorkBody: Body, PitchType: PitchProtocol>(_ body: inout WorkBody,
                                                                               around pitchRange: ClosedRange<PitchType>?,
                                                                               scope: Scope) throws(Error) -> InvertResult<PitchType> {
        typealias PartType = Part<WorkBody.TimeType, WorkBody.PitchType>

        let givenRange: ClosedRange<WorkBody.PitchType>?

        if let pitchRange {
            guard let range = pitchRange as? ClosedRange<WorkBody.PitchType>
            else { preconditionFailure("The range doesn’t match the work’s pitch notation") }

            givenRange = range
        } else {
            givenRange = nil
        }

        let resolution = try scope.resolved(in: body)
        let resolvedRange = givenRange ?? selectedPitchRange(of: body,
                                                             resolution: resolution)

        try transform(&body,
                      resolution: resolution,
                      kind: .invert) { (part: inout PartType, selection) throws(PartType.Error) in
            try part.invert(around: resolvedRange,
                            selection: selection)
        }

        return (resolution, resolvedRange.flatMap { $0 as? ClosedRange<PitchType> })
    }

    // MARK: Private Instance Methods

    //
    // Inverts the scope's notes, in a work of the `expected` pitch notation. Returns the
    // resolved scope and the range used, for the caller's keys.
    //
    private mutating func _invert<PitchType: PitchProtocol>(around pitchRange: ClosedRange<PitchType>?,
                                                            expected: PitchNotation,
                                                            scope: Scope) throws(Error) -> InvertResult<PitchType> {
        try ensureUnlocked()

        guard content.body.pitchNotation == expected
        else { throw Error.pitchNotationMismatch(expected: expected) }

        var body = content.body
        let result = try Self._invertParts(&body,
                                           around: pitchRange,
                                           scope: scope)

        content.body = body

        return result
    }
}

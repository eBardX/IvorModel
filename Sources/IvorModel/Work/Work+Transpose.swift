// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTuning

internal import IvorTiming

extension Work {

    // MARK: Public Instance Methods

    /// Transposes note pitches by a directed ratio across the notes of this work that `scope`
    /// takes.
    ///
    /// In beat time, the work’s keys move too, when they’re carried, unless `movesKeys` is
    /// `false`: a ratio within 25 cents of a whole number of semitones moves them by that many
    /// key steps, assuming 12 to the octave. Any other ratio leaves the music between keys, so
    /// they’re all removed, as they are if any key can’t be transposed.
    ///
    /// - Parameter directedInterval:   The directed ratio by which to transpose the pitches.
    /// - Parameter movesKeys:          Whether to transpose the work’s keys too, when the
    ///                                 transform carries them: with the whole work, or when
    ///                                 `alsoCarry` contains ``TransformTargets/key``. Defaults to
    ///                                 `true`.
    /// - Parameter alsoCarry:          The work tables to carry even though `scope` doesn’t
    ///                                 cover the whole work; only ``TransformTargets/key``
    ///                                 matters here. Defaults to none.
    /// - Parameter scope:              The notes to transpose. Defaults to ``Work/Scope/all``.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             absolute (frequency) pitch notation; an unknown-ID case if `scope` names something not
    ///             in this work; otherwise, ``Work/Error/transformFailure(kind:partID:detail:)``
    ///             naming the part that failed.
    public mutating func transpose(by directedInterval: DirectedInterval<Ratio>,
                                   movesKeys: Bool = true,
                                   alsoCarry: TransformTargets = [],
                                   scope: Scope = .all) throws(Error) {
        try _transpose(by: directedInterval,
                       expected: .absolute,
                       movesKeys: movesKeys,
                       alsoCarry: alsoCarry,
                       scope: scope) { $0.transpose(by: directedInterval) }
    }

    /// Transposes note pitches by a directed note distance across the notes of this work that `scope`
    /// takes.
    ///
    /// In beat time, the work’s keys move too, when they’re carried, unless `movesKeys` is
    /// `false`.
    ///
    /// - Parameter directedInterval:   The directed note distance by which to transpose the pitches.
    /// - Parameter movesKeys:          Whether to transpose the work’s keys too, when the
    ///                                 transform carries them: with the whole work, or when
    ///                                 `alsoCarry` contains ``TransformTargets/key``. Defaults to
    ///                                 `true`.
    /// - Parameter alsoCarry:          The work tables to carry even though `scope` doesn’t
    ///                                 cover the whole work; only ``TransformTargets/key``
    ///                                 matters here. Defaults to none.
    /// - Parameter scope:              The notes to transpose. Defaults to ``Work/Scope/all``.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             keyboard (MIDI note number) pitch notation; an unknown-ID case if `scope` names something not
    ///             in this work; otherwise, ``Work/Error/transformFailure(kind:partID:detail:)``
    ///             naming the part that failed.
    public mutating func transpose(by directedInterval: DirectedInterval<NoteDistance>,
                                   movesKeys: Bool = true,
                                   alsoCarry: TransformTargets = [],
                                   scope: Scope = .all) throws(Error) {
        try _transpose(by: directedInterval,
                       expected: .keyboard,
                       movesKeys: movesKeys,
                       alsoCarry: alsoCarry,
                       scope: scope) { $0.transpose(by: directedInterval) }
    }

    /// Transposes note pitches by a directed interval across the notes of this work that `scope`
    /// takes.
    ///
    /// In beat time, the work’s keys move too, when they’re carried, unless `movesKeys` is
    /// `false`.
    ///
    /// - Parameter directedInterval:   The directed interval by which to transpose the pitches.
    /// - Parameter movesKeys:          Whether to transpose the work’s keys too, when the
    ///                                 transform carries them: with the whole work, or when
    ///                                 `alsoCarry` contains ``TransformTargets/key``. Defaults to
    ///                                 `true`.
    /// - Parameter alsoCarry:          The work tables to carry even though `scope` doesn’t
    ///                                 cover the whole work; only ``TransformTargets/key``
    ///                                 matters here. Defaults to none.
    /// - Parameter scope:              The notes to transpose. Defaults to ``Work/Scope/all``.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/pitchNotationMismatch(expected:)`` if this work does not use
    ///             standard pitch notation; an unknown-ID case if `scope` names something not
    ///             in this work; otherwise, ``Work/Error/transformFailure(kind:partID:detail:)``
    ///             naming the part that failed.
    public mutating func transpose(by directedInterval: DirectedInterval<Interval>,
                                   movesKeys: Bool = true,
                                   alsoCarry: TransformTargets = [],
                                   scope: Scope = .all) throws(Error) {
        try _transpose(by: directedInterval,
                       expected: .standard,
                       movesKeys: movesKeys,
                       alsoCarry: alsoCarry,
                       scope: scope) { $0.transpose(by: directedInterval) }
    }

    // MARK: Private Type Methods

    //
    // The scope's notes transposed. `directedInterval` is of the body's own interval type:
    // its caller has checked the pitch notation.
    //
    private static func _transposeParts<WorkBody: Body>(_ body: inout WorkBody,
                                                        by directedInterval: DirectedInterval<some IntervalProtocol>,
                                                        scope: Scope) throws(Error) -> ResolvedScope {
        typealias PartType = Part<WorkBody.TimeType, WorkBody.PitchType>

        guard let directedInterval = directedInterval as? DirectedInterval<WorkBody.PitchType.IntervalType>
        else { preconditionFailure("The interval doesn’t match the work’s pitch notation") }

        let resolution = try scope.resolved(in: body)

        try transform(&body,
                      resolution: resolution,
                      kind: .transpose) { (part: inout PartType, selection) throws(PartType.Error) in
            try part.transpose(by: directedInterval,
                               selection: selection)
        }

        return resolution
    }

    // MARK: Private Instance Methods

    //
    // Transposes the scope's notes, in a work of the `expected` pitch notation, then the keys
    // with `keys`, when they're carried and `movesKeys` is set (only a beat-time work has keys).
    //
    private mutating func _transpose(by directedInterval: DirectedInterval<some IntervalProtocol>,
                                     expected: PitchNotation,
                                     movesKeys: Bool,
                                     alsoCarry: TransformTargets,
                                     scope: Scope,
                                     keys: (inout KeyTable) -> Void) throws(Error) {
        try ensureUnlocked()

        guard content.body.pitchNotation == expected
        else { throw Error.pitchNotationMismatch(expected: expected) }

        var body = content.body
        let resolution = try Self._transposeParts(&body,
                                                  by: directedInterval,
                                                  scope: scope)

        content.body = body

        if movesKeys,
           resolution.workTargets(applyTo: .key, alsoCarry: alsoCarry).contains(.key) {
            _ = try modifyKeyTable(keys)
        }
    }
}

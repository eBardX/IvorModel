// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning
public import XestiNumbers

extension Part {

    // MARK: Public Instance Methods

    /// Augments note attack times and durations by a rational factor, along with the tables it
    /// carries.
    ///
    /// A table is carried only when the notes cover everything that shares it. With `noteIDs`
    /// `nil` (the whole part), every table `applyTo` names is carried. With some notes, only the
    /// entries within their time range of the own dynamic maps and instrument tables of the
    /// strands that hold them are; the part’s pedals, pan, marks, dynamic map and instrument
    /// table stay, unless `alsoCarry` opts them in.
    ///
    /// - Parameter factor:     A rational number ≥ 1 by which to stretch the note timings.
    /// - Parameter anchor:     The low time bound to stretch attack times relative to. `nil`
    ///                         resolves to the start of everything being augmented: the chosen
    ///                         notes and every table carried whole.
    /// - Parameter noteIDs:    The identities of the notes to augment, wherever they are in
    ///                         the part, or `nil` (the default) for the whole part.
    /// - Parameter applyTo:    The kinds of table to augment along with the notes. Defaults to
    ///                         every kind.
    /// - Parameter alsoCarry:  The kinds of shared table to carry even though `noteIDs` doesn’t
    ///                         cover everything that shares them. Their entries within the
    ///                         chosen notes’ time range are carried. Defaults to none.
    ///
    /// - Throws:   ``Part/Error/noteTableFailure(_:)`` if the notes cannot be augmented, or the
    ///             corresponding table-failure case if a carried table cannot be augmented.
    public mutating func augment(by factor: Number,
                                 anchor: TimeType? = nil,
                                 noteIDs: Set<NoteID>? = nil,
                                 applyTo: TransformTargets = .all,
                                 alsoCarry: TransformTargets = []) throws(Error) {
        try augment(by: factor,
                    anchor: anchor,
                    selection: selection(for: noteIDs),
                    applyTo: applyTo,
                    alsoCarry: alsoCarry)
    }

    /// Diminishes note attack times and durations by a rational factor, along with the tables
    /// it carries.
    ///
    /// A table is carried only when the notes cover everything that shares it. With `noteIDs`
    /// `nil` (the whole part), every table `applyTo` names is carried. With some notes, only the
    /// entries within their time range of the own dynamic maps and instrument tables of the
    /// strands that hold them are; the part’s pedals, pan, marks, dynamic map and instrument
    /// table stay, unless `alsoCarry` opts them in.
    ///
    /// - Parameter factor:     A rational number ≥ 1 by which to compress the note timings.
    /// - Parameter anchor:     The low time bound to compress attack times relative to. `nil`
    ///                         resolves to the start of everything being diminished: the chosen
    ///                         notes and every table carried whole.
    /// - Parameter noteIDs:    The identities of the notes to diminish, wherever they are in
    ///                         the part, or `nil` (the default) for the whole part.
    /// - Parameter applyTo:    The kinds of table to diminish along with the notes. Defaults to
    ///                         every kind.
    /// - Parameter alsoCarry:  The kinds of shared table to carry even though `noteIDs` doesn’t
    ///                         cover everything that shares them. Their entries within the
    ///                         chosen notes’ time range are carried. Defaults to none.
    ///
    /// - Throws:   ``Part/Error/noteTableFailure(_:)`` if the notes cannot be diminished, or the
    ///             corresponding table-failure case if a carried table cannot be diminished.
    public mutating func diminish(by factor: Number,
                                  anchor: TimeType? = nil,
                                  noteIDs: Set<NoteID>? = nil,
                                  applyTo: TransformTargets = .all,
                                  alsoCarry: TransformTargets = []) throws(Error) {
        try diminish(by: factor,
                     anchor: anchor,
                     selection: selection(for: noteIDs),
                     applyTo: applyTo,
                     alsoCarry: alsoCarry)
    }

    /// Inverts note pitches around a pitch range.
    ///
    /// - Parameter pitchRange: The pitch range to invert pitches around. `nil` resolves to the
    ///                         chosen notes’ own pitch range, across every strand.
    /// - Parameter noteIDs:    The identities of the notes to invert, wherever they are in the
    ///                         part, or `nil` (the default) for the whole part.
    ///
    /// - Throws:   ``Part/Error/noteTableFailure(_:)`` if the notes cannot be inverted.
    ///
    /// - Note: No table has a pitch axis, so — unlike the time transforms — this one never
    ///         carries any table along.
    public mutating func invert(around pitchRange: ClosedRange<PitchType>? = nil,
                                noteIDs: Set<NoteID>? = nil) throws(Error) {
        try invert(around: pitchRange,
                   selection: selection(for: noteIDs))
    }

    /// Moves note attack times by a directed duration, along with the tables it carries.
    ///
    /// A table is carried only when the notes cover everything that shares it. With `noteIDs`
    /// `nil` (the whole part), every table `applyTo` names is carried. With some notes, only the
    /// entries within their time range of the own dynamic maps and instrument tables of the
    /// strands that hold them are; the part’s pedals, pan, marks, dynamic map and instrument
    /// table stay, unless `alsoCarry` opts them in.
    ///
    /// - Parameter directedDuration:   The directed duration by which to move the attack
    ///                                 times.
    /// - Parameter noteIDs:            The identities of the notes to move, wherever they are
    ///                                 in the part, or `nil` (the default) for the whole part.
    /// - Parameter applyTo:            The kinds of table to move along with the notes.
    ///                                 Defaults to every kind.
    /// - Parameter alsoCarry:          The kinds of shared table to carry even though `noteIDs`
    ///                                 doesn’t cover everything that shares them. Their entries
    ///                                 within the chosen notes’ time range are carried. Defaults
    ///                                 to none.
    ///
    /// - Throws:   ``Part/Error/noteTableFailure(_:)`` if the notes cannot be moved, or the
    ///             corresponding table-failure case if a carried table cannot be moved.
    public mutating func move(by directedDuration: DirectedDuration<DurationType>,
                              noteIDs: Set<NoteID>? = nil,
                              applyTo: TransformTargets = .all,
                              alsoCarry: TransformTargets = []) throws(Error) {
        try move(by: directedDuration,
                 selection: selection(for: noteIDs),
                 applyTo: applyTo,
                 alsoCarry: alsoCarry)
    }

    /// Reverses the order of notes within a time range, along with the tables it carries.
    ///
    /// A table is carried only when the notes cover everything that shares it. With `noteIDs`
    /// `nil` (the whole part), every table `applyTo` names is carried. With some notes, only the
    /// entries within their time range of the own dynamic maps and instrument tables of the
    /// strands that hold them are; the part’s pedals, pan, marks, dynamic map and instrument
    /// table stay, unless `alsoCarry` opts them in.
    ///
    /// - Parameter timeRange:  The time range to mirror attack times around. `nil` resolves to
    ///                         the span of everything being reversed: the chosen notes and every
    ///                         table carried whole.
    /// - Parameter noteIDs:    The identities of the notes to reverse, wherever they are in
    ///                         the part, or `nil` (the default) for the whole part.
    /// - Parameter applyTo:    The kinds of table to reverse along with the notes. Defaults to
    ///                         every kind.
    /// - Parameter alsoCarry:  The kinds of shared table to carry even though `noteIDs` doesn’t
    ///                         cover everything that shares them. Their entries within the
    ///                         chosen notes’ time range are carried. Defaults to none.
    ///
    /// - Throws:   ``Part/Error/noteTableFailure(_:)`` if the notes cannot be reversed, or the
    ///             corresponding table-failure case if a carried table cannot be reversed.
    public mutating func reverse(within timeRange: ClosedRange<TimeType>? = nil,
                                 noteIDs: Set<NoteID>? = nil,
                                 applyTo: TransformTargets = .all,
                                 alsoCarry: TransformTargets = []) throws(Error) {
        try reverse(within: timeRange,
                    selection: selection(for: noteIDs),
                    applyTo: applyTo,
                    alsoCarry: alsoCarry)
    }

    /// Transposes note pitches by a directed interval.
    ///
    /// - Parameter directedInterval:   The directed interval by which to transpose the pitches.
    /// - Parameter noteIDs:            The identities of the notes to transpose, wherever they
    ///                                 are in the part, or `nil` (the default) for the whole
    ///                                 part.
    ///
    /// - Throws:   ``Part/Error/noteTableFailure(_:)`` if the notes cannot be transposed.
    ///
    /// - Note: No table has a pitch axis, so — unlike the time transforms — this one never
    ///         carries any table along.
    public mutating func transpose(by directedInterval: DirectedInterval<IntervalType>,
                                   noteIDs: Set<NoteID>? = nil) throws(Error) {
        try transpose(by: directedInterval,
                      selection: selection(for: noteIDs))
    }
}

// MARK: -

extension Part where TimeType == BeatTime {

    // MARK: Public Instance Methods

    /// Quantizes note attack and release times to the nearest subdivision given by `factors`,
    /// along with the tables it carries.
    ///
    /// A table is carried only when the notes cover everything that shares it. With `noteIDs`
    /// `nil` (the whole part), every table `applyTo` names is carried. With some notes, only the
    /// entries within their time range of the own dynamic maps and instrument tables of the
    /// strands that hold them are; the part’s pedals, pan, marks, dynamic map and instrument
    /// table stay, unless `alsoCarry` opts them in.
    ///
    /// - Parameter factors:    An array of positive integer subdivision factors.
    /// - Parameter noteIDs:    The identities of the notes to quantize, wherever they are in
    ///                         the part, or `nil` (the default) for the whole part.
    /// - Parameter applyTo:    The kinds of table to quantize along with the notes. Defaults to
    ///                         every kind.
    /// - Parameter alsoCarry:  The kinds of shared table to carry even though `noteIDs` doesn’t
    ///                         cover everything that shares them. Their entries within the
    ///                         chosen notes’ time range are carried. Defaults to none.
    ///
    /// - Throws:   ``Part/Error/noteTableFailure(_:)`` wrapping
    ///             ``NoteTable/Error/emptyQuantizationFactors`` or
    ///             ``NoteTable/Error/invalidQuantizationFactor(_:)`` if `factors` is invalid.
    public mutating func quantize(to factors: [Int],
                                  noteIDs: Set<NoteID>? = nil,
                                  applyTo: TransformTargets = .all,
                                  alsoCarry: TransformTargets = []) throws(Error) {
        let quantizer: BeatQuantizer

        do {
            quantizer = try BeatQuantizer(factors: factors)
        } catch {
            switch error {
            case .emptyFactors:
                throw Error.noteTableFailure(.emptyQuantizationFactors)

            case let .invalidFactor(factor):
                throw Error.noteTableFailure(.invalidQuantizationFactor(factor))
            }
        }

        quantize(to: quantizer,
                 noteIDs: noteIDs,
                 applyTo: applyTo,
                 alsoCarry: alsoCarry)
    }

    /// Quantizes note attack and release times to the nearest grid point defined by `quantizer`,
    /// along with the tables it carries.
    ///
    /// Unlike ``quantize(to:noteIDs:applyTo:alsoCarry:)-(_,_,_,_)``, this never throws: a
    /// ``BeatQuantizer`` has already had its factors validated, so nothing is left to fail.
    ///
    /// - Parameter quantizer:  The quantizer whose grid to snap attack and release times to.
    /// - Parameter noteIDs:    The identities of the notes to quantize, wherever they are in
    ///                         the part, or `nil` (the default) for the whole part.
    /// - Parameter applyTo:    The kinds of table to quantize along with the notes. Defaults to
    ///                         every kind.
    /// - Parameter alsoCarry:  The kinds of shared table to carry even though `noteIDs` doesn’t
    ///                         cover everything that shares them. Their entries within the
    ///                         chosen notes’ time range are carried. Defaults to none.
    public mutating func quantize(to quantizer: BeatQuantizer,
                                  noteIDs: Set<NoteID>? = nil,
                                  applyTo: TransformTargets = .all,
                                  alsoCarry: TransformTargets = []) {
        quantize(to: quantizer,
                 selection: selection(for: noteIDs),
                 applyTo: applyTo,
                 alsoCarry: alsoCarry)
    }
}

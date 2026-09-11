// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning
public import XestiNumbers

private import XestiTools

extension NoteTable {

    // MARK: Public Instance Methods

    /// Augments note attack times and durations by a rational factor.
    ///
    /// - Parameter factor:     A rational number ≥ 1 by which to stretch the selected note timings.
    /// - Parameter anchor:     The low time bound to stretch attack times relative to. `nil`
    ///                         resolves to the table’s own range, or — when `noteIDs` is non-`nil`
    ///                         — the selected notes’ own range.
    /// - Parameter noteIDs:    The identities of the notes to augment, or `nil` to augment every
    ///                         note in the table.
    ///
    /// - Throws:   ``NoteTable/Error/invalidAugmentationFactor(_:)`` if `factor` is not a rational
    ///             number ≥ 1; ``NoteTable/Error/invalidAnchor`` if `anchor` is later than the low
    ///             bound of the notes being augmented; otherwise,
    ///             ``NoteTable/Error/augmentFailure(_:_:_:_:)`` if a note cannot be augmented.
    public mutating func augment(by factor: Number,
                                 anchor: TimeType? = nil,
                                 noteIDs: Set<NoteID>? = nil) throws(Error) {
        guard factor.isRational,
              factor >= 1
        else { throw Error.invalidAugmentationFactor(factor) }

        guard !notes.isEmpty,
              factor > 1
        else { return }

        guard let selectedRange = selectedTimeRange(noteIDs: noteIDs)
        else { return }

        let loAttack = try _resolvedLowerBound(anchor, containing: selectedRange)

        for (idx, note) in notes.enumerated() {
            guard noteIDs?.contains(note.noteID) ?? true
            else { continue }

            guard let result = loAttack.duration(to: note.attack),
                  let duration = result.duration.multiplied(by: factor),
                  let newAttack = loAttack.moved(by: DirectedDuration(duration: duration,
                                                                      direction: result.direction)),
                  let newDuration = note.duration.multiplied(by: factor)
            else { throw Error.augmentFailure(note.attack, note.duration, note.startPitch, note.endPitch) }

            notes[idx] = Note(noteID: note.noteID,
                              attack: newAttack,
                              duration: newDuration,
                              startPitch: note.startPitch,
                              endPitch: note.endPitch,
                              extras: note.extras)
        }

        timeRange = Self.timeRange(in: notes)
    }

    /// Diminishes note attack times and durations by a rational factor.
    ///
    /// - Parameter factor:     A rational number ≥ 1 by which to compress the selected note
    ///                         timings.
    /// - Parameter anchor:     The low time bound to compress attack times relative to. `nil`
    ///                         resolves to the table’s own range, or — when `noteIDs` is non-`nil`
    ///                         — the selected notes’ own range.
    /// - Parameter noteIDs:    The identities of the notes to diminish, or `nil` to diminish every
    ///                         note in the table.
    ///
    /// - Throws:   ``NoteTable/Error/invalidDiminutionFactor(_:)`` if `factor` is not a rational
    ///             number ≥ 1; ``NoteTable/Error/invalidAnchor`` if `anchor` is later than the low
    ///             bound of the notes being diminished; otherwise,
    ///             ``NoteTable/Error/diminishFailure(_:_:_:_:)`` if a note cannot be diminished.
    public mutating func diminish(by factor: Number,
                                  anchor: TimeType? = nil,
                                  noteIDs: Set<NoteID>? = nil) throws(Error) {
        guard factor.isRational,
              factor >= 1
        else { throw Error.invalidDiminutionFactor(factor) }

        guard !notes.isEmpty,
              factor > 1
        else { return }

        guard let selectedRange = selectedTimeRange(noteIDs: noteIDs)
        else { return }

        let loAttack = try _resolvedLowerBound(anchor, containing: selectedRange)

        for (idx, note) in notes.enumerated() {
            guard noteIDs?.contains(note.noteID) ?? true
            else { continue }

            guard let result = loAttack.duration(to: note.attack),
                  let duration = result.duration.divided(by: factor),
                  let newAttack = loAttack.moved(by: DirectedDuration(duration: duration,
                                                                      direction: result.direction)),
                  let newDuration = note.duration.divided(by: factor)
            else { throw Error.diminishFailure(note.attack, note.duration, note.startPitch, note.endPitch) }

            notes[idx] = Note(noteID: note.noteID,
                              attack: newAttack,
                              duration: newDuration,
                              startPitch: note.startPitch,
                              endPitch: note.endPitch,
                              extras: note.extras)
        }

        timeRange = Self.timeRange(in: notes)
    }

    /// Inverts note pitches around a pitch range.
    ///
    /// - Parameter pitchRange:   The pitch range to invert pitches around. `nil` resolves to the
    ///                           table’s own pitch range, or — when `noteIDs` is non-`nil` — the
    ///                           selected notes’ own pitch range.
    /// - Parameter noteIDs:      The identities of the notes to invert, or `nil` to invert every
    ///                           note in the table.
    ///
    /// - Throws:   ``NoteTable/Error/invalidAnchor`` if `pitchRange` does not contain the pitch
    ///             range of the notes being inverted; otherwise,
    ///             ``NoteTable/Error/invertFailure(_:_:_:_:)`` if a note cannot be inverted.
    public mutating func invert(around pitchRange: ClosedRange<PitchType>? = nil,
                                noteIDs: Set<NoteID>? = nil) throws(Error) {
        guard !notes.isEmpty
        else { return }

        guard let selectedRange = selectedPitchRange(noteIDs: noteIDs)
        else { return }

        let anchorRange = try _resolvedRange(pitchRange, containing: selectedRange)
        let hiPitch = anchorRange.upperBound
        let loPitch = anchorRange.lowerBound

        for (idx, note) in notes.enumerated() {
            guard noteIDs?.contains(note.noteID) ?? true
            else { continue }

            guard let dirInt1 = loPitch.interval(to: note.startPitch),
                  let dirInt2 = loPitch.interval(to: note.endPitch),
                  let newStartPitch = hiPitch.transposed(by: dirInt1),
                  let newEndPitch = hiPitch.transposed(by: dirInt2)
            else { throw Error.invertFailure(note.attack, note.duration, note.startPitch, note.endPitch) }

            notes[idx] = Note(noteID: note.noteID,
                              attack: note.attack,
                              duration: note.duration,
                              startPitch: newStartPitch,
                              endPitch: newEndPitch,
                              extras: note.extras)
        }

        notes.sort()
    }

    /// Moves note attack times by a directed duration.
    ///
    /// - Parameter directedDuration:   The directed duration by which to move the selected note
    ///                                 attack times.
    /// - Parameter noteIDs:            The identities of the notes to move, or `nil` to move every
    ///                                 note in the table.
    ///
    /// - Throws:   ``NoteTable/Error/moveFailure(_:_:_:_:)`` if a note cannot be moved.
    public mutating func move(by directedDuration: DirectedDuration<DurationType>,
                              noteIDs: Set<NoteID>? = nil) throws(Error) {
        guard !notes.isEmpty,
              !directedDuration.duration.isZero
        else { return }

        for (idx, note) in notes.enumerated() {
            guard noteIDs?.contains(note.noteID) ?? true
            else { continue }

            guard let newAttack = note.attack.moved(by: directedDuration)
            else { throw Error.moveFailure(note.attack, note.duration, note.startPitch, note.endPitch) }

            notes[idx] = Note(noteID: note.noteID,
                              attack: newAttack,
                              duration: note.duration,
                              startPitch: note.startPitch,
                              endPitch: note.endPitch,
                              extras: note.extras)
        }

        timeRange = Self.timeRange(in: notes)
    }

    /// Reverses the order of notes within a time range.
    ///
    /// - Parameter timeRange:   The time range to mirror attack times around. `nil` resolves to
    ///                          the table’s own time range, or — when `noteIDs` is non-`nil` — the
    ///                          selected notes’ own time range.
    /// - Parameter noteIDs:     The identities of the notes to reverse, or `nil` to reverse every
    ///                          note in the table.
    ///
    /// - Throws:   ``NoteTable/Error/invalidAnchor`` if `timeRange` does not contain the time range
    ///             of the notes being reversed; otherwise,
    ///             ``NoteTable/Error/reverseFailure(_:_:_:_:)`` if a note cannot be reversed.
    public mutating func reverse(within timeRange: ClosedRange<TimeType>? = nil,
                                 noteIDs: Set<NoteID>? = nil) throws(Error) {
        guard !notes.isEmpty
        else { return }

        guard let selectedRange = selectedTimeRange(noteIDs: noteIDs)
        else { return }

        let anchorRange = try _resolvedRange(timeRange, containing: selectedRange)
        let hiTime = anchorRange.upperBound
        let loTime = anchorRange.lowerBound

        for (idx, note) in notes.enumerated() {
            guard noteIDs?.contains(note.noteID) ?? true
            else { continue }

            guard let dirDur = note.release.duration(to: hiTime),
                  let newAttack = loTime.moved(by: dirDur)
            else { throw Error.reverseFailure(note.attack, note.duration, note.startPitch, note.endPitch) }

            notes[idx] = Note(noteID: note.noteID,
                              attack: newAttack,
                              duration: note.duration,
                              startPitch: note.endPitch,
                              endPitch: note.startPitch,
                              extras: note.extras)
        }

        notes.sort()
    }

    /// Transposes note pitches by a directed interval.
    ///
    /// - Parameter directedInterval:   The directed interval by which to transpose the selected
    ///                                 pitches.
    /// - Parameter noteIDs:            The identities of the notes to transpose, or `nil` to
    ///                                 transpose every note in the table.
    ///
    /// - Throws:   ``NoteTable/Error/transposeFailure(_:_:_:_:)`` if a note cannot be transposed.
    public mutating func transpose(by directedInterval: DirectedInterval<IntervalType>,
                                   noteIDs: Set<NoteID>? = nil) throws(Error) {
        guard !notes.isEmpty,
              !directedInterval.interval.isUnison
        else { return }

        for (idx, note) in notes.enumerated() {
            guard noteIDs?.contains(note.noteID) ?? true
            else { continue }

            guard let newStartPitch = note.startPitch.transposed(by: directedInterval),
                  let newEndPitch = note.endPitch.transposed(by: directedInterval)
            else { throw Error.transposeFailure(note.attack, note.duration, note.startPitch, note.endPitch) }

            notes[idx] = Note(noteID: note.noteID,
                              attack: note.attack,
                              duration: note.duration,
                              startPitch: newStartPitch,
                              endPitch: newEndPitch,
                              extras: note.extras)
        }

        pitchRange = Self.pitchRange(in: notes)
    }

    // MARK: Internal Instance Methods

    //
    // Exposed beyond this file (module-internal, not file-private) so `Part`'s wrapper (Phase 3)
    // can derive a carried map's `entryIDs` from the same selected-notes range these methods
    // resolve their own anchor against, rather than recomputing it independently.
    //
    internal func selectedPitchRange(noteIDs: Set<NoteID>?) -> ClosedRange<PitchType>? {
        guard let noteIDs
        else { return pitchRange }

        return Self.pitchRange(in: notes.filter { noteIDs.contains($0.noteID) })
    }

    internal func selectedTimeRange(noteIDs: Set<NoteID>?) -> ClosedRange<TimeType>? {
        guard let noteIDs
        else { return timeRange }

        return Self.timeRange(in: notes.filter { noteIDs.contains($0.noteID) })
    }

    // MARK: Private Instance Methods

    //
    // `nil` resolves to `containing` (the selected notes' own range) — safe by construction, since
    // it's derived from the very notes being operated on. A caller-supplied anchor must be no later
    // than that range's low bound, or the stretch it pivots would be applied against notes it
    // doesn't actually bound.
    //
    private func _resolvedLowerBound(_ anchor: TimeType?,
                                     containing selectedRange: ClosedRange<TimeType>) throws(Error) -> TimeType {
        guard let anchor
        else { return selectedRange.lowerBound }

        guard anchor <= selectedRange.lowerBound
        else { throw Error.invalidAnchor }

        return anchor
    }

    //
    // `nil` resolves to `selectedRange` — safe by construction, since it's derived from the very
    // notes/pitches being operated on. A caller-supplied range must fully contain `selectedRange`,
    // or the mirror it pivots around would reflect notes it doesn't actually bound.
    //
    private func _resolvedRange<BoundType: Comparable>(_ anchorRange: ClosedRange<BoundType>?,
                                                       containing selectedRange: ClosedRange<BoundType>) throws(Error) -> ClosedRange<BoundType> {
        guard let anchorRange
        else { return selectedRange }

        guard anchorRange.lowerBound <= selectedRange.lowerBound,
              anchorRange.upperBound >= selectedRange.upperBound
        else { throw Error.invalidAnchor }

        return anchorRange
    }
}

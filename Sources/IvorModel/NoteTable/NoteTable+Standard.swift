// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning
public import XestiNumbers

private import XestiTools

extension NoteTable {

    // MARK: Public Instance Methods

    /// Augments all note attack times and durations by a rational factor.
    ///
    /// - Parameter factor:     A rational number ≥ 1 by which to stretch all note timings.
    ///
    /// - Throws:   ``NoteTable/Error/invalidAugmentationFactor(_:)`` if `factor` is not a rational
    ///             number ≥ 1; otherwise, ``NoteTable/Error/augmentFailure(_:_:_:_:)`` if a note
    ///             cannot be augmented.
    public mutating func augment(by factor: Number) throws {
        guard factor.isRational,
              factor >= 1
        else { throw Error.invalidAugmentationFactor(factor) }

        guard !notes.isEmpty,
              factor > 1
        else { return }

        let loAttack = timeRange.require().lowerBound

        for (idx, note) in notes.enumerated() {
            guard let result = loAttack.duration(to: note.attack),
                  let duration = result.duration.multiplied(by: factor),
                  let newAttack = loAttack.moved(by: DirectedDuration(duration: duration,
                                                                      direction: result.direction)),
                  let newDuration = note.duration.multiplied(by: factor)
            else { throw Error.augmentFailure(note.attack, note.duration, note.startPitch, note.endPitch) }

            notes[idx] = Note(attack: newAttack,
                              duration: newDuration,
                              startPitch: note.startPitch,
                              endPitch: note.endPitch,
                              extras: note.extras)
        }

        timeRange = Self.timeRange(in: notes)
    }

    /// Returns a copy of the table with all note timings augmented by a rational factor.
    ///
    /// - Parameter factor:     A rational number ≥ 1 by which to stretch all note timings.
    ///
    /// - Returns:  A new ``NoteTable`` with augmented note timings.
    ///
    /// - Throws:   ``NoteTable/Error/invalidAugmentationFactor(_:)`` if `factor` is not a rational
    ///             number ≥ 1; otherwise, ``NoteTable/Error/augmentFailure(_:_:_:_:)`` if a note
    ///             cannot be augmented.
    public func augmented(by factor: Number) throws -> Self {
        var new = self

        try new.augment(by: factor)

        return new
    }

    /// Diminishes all note attack times and durations by a rational factor.
    ///
    /// - Parameter factor:     A rational number ≥ 1 by which to compress all note timings.
    ///
    /// - Throws:   ``NoteTable/Error/invalidDiminutionFactor(_:)`` if `factor` is not a rational
    ///             number ≥ 1; otherwise, ``NoteTable/Error/diminishFailure(_:_:_:_:)`` if a note
    ///             cannot be diminished.
    public mutating func diminish(by factor: Number) throws {
        guard factor.isRational,
              factor >= 1
        else { throw Error.invalidDiminutionFactor(factor) }

        guard !notes.isEmpty,
              factor > 1
        else { return }

        let loAttack = timeRange.require().lowerBound

        for (idx, note) in notes.enumerated() {
            guard let result = loAttack.duration(to: note.attack),
                  let duration = result.duration.divided(by: factor),
                  let newAttack = loAttack.moved(by: DirectedDuration(duration: duration,
                                                                      direction: result.direction)),
                  let newDuration = note.duration.multiplied(by: factor)
            else { throw Error.diminishFailure(note.attack, note.duration, note.startPitch, note.endPitch) }

            notes[idx] = Note(attack: newAttack,
                              duration: newDuration,
                              startPitch: note.startPitch,
                              endPitch: note.endPitch,
                              extras: note.extras)
        }

        timeRange = Self.timeRange(in: notes)
    }

    /// Returns a copy of the table with all note timings diminished by a rational factor.
    ///
    /// - Parameter factor:     A rational number ≥ 1 by which to compress all note timings.
    ///
    /// - Returns:  A new ``NoteTable`` with diminished note timings.
    ///
    /// - Throws:   ``NoteTable/Error/invalidDiminutionFactor(_:)`` if `factor` is not a rational
    ///             number ≥ 1; otherwise, ``NoteTable/Error/diminishFailure(_:_:_:_:)`` if a note
    ///             cannot be diminished.
    public func diminished(by factor: Number) throws -> Self {
        var new = self

        try new.diminish(by: factor)

        return new
    }

    /// Inverts all note pitches around the pitch range of the table.
    ///
    /// - Throws:   ``NoteTable/Error/invertFailure(_:_:_:_:)`` if a note cannot be inverted.
    public mutating func invert() throws {
        guard !notes.isEmpty,
              let pitchRange
        else { return }

        let hiPitch = pitchRange.upperBound
        let loPitch = pitchRange.lowerBound

        for (idx, note) in notes.enumerated() {
            guard let dirInt1 = loPitch.interval(to: note.startPitch),
                  let dirInt2 = loPitch.interval(to: note.endPitch),
                  let newStartPitch = hiPitch.transposed(by: dirInt1),
                  let newEndPitch = hiPitch.transposed(by: dirInt2)
            else { throw Error.invertFailure(note.attack, note.duration, note.startPitch, note.endPitch) }

            notes[idx] = Note(attack: note.attack,
                              duration: note.duration,
                              startPitch: newStartPitch,
                              endPitch: newEndPitch,
                              extras: note.extras)
        }

        notes.sort()
    }

    /// Returns a copy of the table with all note pitches inverted.
    ///
    /// - Returns:  A new ``NoteTable`` with inverted pitches.
    ///
    /// - Throws:   ``NoteTable/Error/invertFailure(_:_:_:_:)`` if a note cannot be inverted.
    public func inverted() throws -> Self {
        var new = self

        try new.invert()

        return new
    }

    /// Moves all note attack times by a directed duration.
    ///
    /// - Parameter directedDuration:   The directed duration by which to move all note attack times.
    ///
    /// - Throws:   ``NoteTable/Error/moveFailure(_:_:_:_:)`` if a note cannot be moved.
    public mutating func move(by directedDuration: DirectedDuration<DurationType>) throws {
        guard !notes.isEmpty,
              !directedDuration.duration.isZero
        else { return }

        for (idx, note) in notes.enumerated() {
            guard let newAttack = note.attack.moved(by: directedDuration)
            else { throw Error.moveFailure(note.attack, note.duration, note.startPitch, note.endPitch) }

            notes[idx] = Note(attack: newAttack,
                              duration: note.duration,
                              startPitch: note.startPitch,
                              endPitch: note.endPitch,
                              extras: note.extras)
        }

        timeRange = Self.timeRange(in: notes)
    }

    /// Returns a copy of the table with all note attack times moved by a directed duration.
    ///
    /// - Parameter directedDuration:   The directed duration by which to move all note attack times.
    ///
    /// - Returns:  A new ``NoteTable`` with moved note attack times.
    ///
    /// - Throws:   ``NoteTable/Error/moveFailure(_:_:_:_:)`` if a note cannot be moved.
    public func moved(by directedDuration: DirectedDuration<DurationType>) throws -> Self {
        var new = self

        try new.move(by: directedDuration)

        return new
    }

    /// Reverses the order of notes in the table within the current time range.
    ///
    /// - Throws:   ``NoteTable/Error/reverseFailure(_:_:_:_:)`` if a note cannot be reversed.
    public mutating func reverse() throws {
        guard !notes.isEmpty,
              let timeRange
        else { return }

        let hiTime = timeRange.upperBound
        let loTime = timeRange.lowerBound

        for (idx, note) in notes.enumerated() {
            guard let dirDur = note.release.duration(to: hiTime),
                  let newAttack = loTime.moved(by: dirDur)
            else { throw Error.reverseFailure(note.attack, note.duration, note.startPitch, note.endPitch) }

            notes[idx] = Note(attack: newAttack,
                              duration: note.duration,
                              startPitch: note.endPitch,
                              endPitch: note.startPitch,
                              extras: note.extras)
        }

        notes.sort()
    }

    /// Returns a copy of the table with the order of notes reversed.
    ///
    /// - Returns:  A new ``NoteTable`` with notes in reversed order.
    ///
    /// - Throws:   ``NoteTable/Error/reverseFailure(_:_:_:_:)`` if a note cannot be reversed.
    public func reversed() throws -> Self {
        var new = self

        try new.reverse()

        return new
    }

    /// Transposes all note pitches by a directed interval.
    ///
    /// - Parameter directedInterval:   The directed interval by which to transpose all pitches.
    ///
    /// - Throws:   ``NoteTable/Error/transposeFailure(_:_:_:_:)`` if a note cannot be transposed.
    public mutating func transpose(by directedInterval: DirectedInterval<IntervalType>) throws {
        guard !notes.isEmpty,
              directedInterval.interval.isUnison
        else { return }

        for (idx, note) in notes.enumerated() {
            guard let newStartPitch = note.startPitch.transposed(by: directedInterval),
                  let newEndPitch = note.endPitch.transposed(by: directedInterval)
            else { throw Error.transposeFailure(note.attack, note.duration, note.startPitch, note.endPitch) }

            notes[idx] = Note(attack: note.attack,
                              duration: note.duration,
                              startPitch: newStartPitch,
                              endPitch: newEndPitch,
                              extras: note.extras)
        }

        pitchRange = Self.pitchRange(in: notes)
    }

    /// Returns a copy of the table with all note pitches transposed by a directed interval.
    ///
    /// - Parameter directedInterval:   The directed interval by which to transpose all pitches.
    ///
    /// - Returns:  A new ``NoteTable`` with transposed pitches.
    ///
    /// - Throws:   ``NoteTable/Error/transposeFailure(_:_:_:_:)`` if a note cannot be transposed.
    public func transposed(by directedInterval: DirectedInterval<IntervalType>) throws -> Self {
        var new = self

        try new.transpose(by: directedInterval)

        return new
    }
}

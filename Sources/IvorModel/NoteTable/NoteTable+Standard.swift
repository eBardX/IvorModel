public import IvorTiming
public import IvorTuning
public import XestiNumbers

extension NoteTable {

    // MARK: Public Instance Methods

    public mutating func augment(by factor: Number) throws {
        guard factor.isRational,
              factor >= 1
        else { throw Error.invalidAugmentationFactor(factor) }

        guard !notes.isEmpty,
              factor > 1
        else { return }

        let loAttack = timeRange.lowerBound

        for (idx, note) in notes.enumerated() {
            guard let result = loAttack.duration(to: note.attack),
                  let duration = result.duration.multiplied(by: factor),
                  let newAttack = loAttack.moved(by: duration,
                                                 direction: result.direction),
                  let newDuration = note.duration.multiplied(by: factor)
            else { throw Error.augmentFailure(note.attack, note.duration, note.startPitch, note.endPitch) }

            notes[idx] = Note(attack: newAttack,
                              duration: newDuration,
                              startPitch: note.startPitch,
                              endPitch: note.endPitch,
                              extras: note.extras)
        }

        timeRange = Self.determineTimeRange(notes)
    }

    public func augmented(by factor: Number) throws -> Self {
        var new = self

        try new.augment(by: factor)

        return new
    }

    public mutating func diminish(by factor: Number) throws {
        guard factor.isRational,
              factor >= 1
        else { throw Error.invalidDiminutionFactor(factor) }

        guard !notes.isEmpty,
              factor > 1
        else { return }

        let loAttack = timeRange.lowerBound

        for (idx, note) in notes.enumerated() {
            guard let result = loAttack.duration(to: note.attack),
                  let duration = result.duration.divided(by: factor),
                  let newAttack = loAttack.moved(by: duration,
                                                 direction: result.direction),
                  let newDuration = note.duration.multiplied(by: factor)
            else { throw Error.diminishFailure(note.attack, note.duration, note.startPitch, note.endPitch) }

            notes[idx] = Note(attack: newAttack,
                              duration: newDuration,
                              startPitch: note.startPitch,
                              endPitch: note.endPitch,
                              extras: note.extras)
        }

        timeRange = Self.determineTimeRange(notes)
    }

    public func diminished(by factor: Number) throws -> Self {
        var new = self

        try new.diminish(by: factor)

        return new
    }

    public mutating func invert() throws {
        guard !notes.isEmpty
        else { return }

        let hiPitch = pitchRange.upperBound
        let loPitch = pitchRange.lowerBound

        for (idx, note) in notes.enumerated() {
            guard let result1 = loPitch.interval(to: note.startPitch),
                  let result2 = loPitch.interval(to: note.endPitch),
                  let newStartPitch = hiPitch.transposed(by: result1.interval,
                                                         direction: result1.direction),
                  let newEndPitch = hiPitch.transposed(by: result2.interval,
                                                       direction: result2.direction)
            else { throw Error.invertFailure(note.attack, note.duration, note.startPitch, note.endPitch) }

            notes[idx] = Note(attack: note.attack,
                              duration: note.duration,
                              startPitch: newStartPitch,
                              endPitch: newEndPitch,
                              extras: note.extras)
        }

        notes.sort()
    }

    public func inverted() throws -> Self {
        var new = self

        try new.invert()

        return new
    }

    public mutating func move(by duration: DurationType,
                              direction: DurationDirection) throws {
        guard !notes.isEmpty,
              !duration.isZero
        else { return }

        for (idx, note) in notes.enumerated() {
            guard let newAttack = note.attack.moved(by: duration,
                                                    direction: direction)
            else { throw Error.moveFailure(note.attack, note.duration, note.startPitch, note.endPitch) }

            notes[idx] = Note(attack: newAttack,
                              duration: note.duration,
                              startPitch: note.startPitch,
                              endPitch: note.endPitch,
                              extras: note.extras)
        }

        timeRange = Self.determineTimeRange(notes)
    }

    public func moved(by duration: DurationType,
                      direction: DurationDirection) throws -> Self {
        var new = self

        try new.move(by: duration,
                     direction: direction)

        return new
    }

    public mutating func reverse() throws {
        guard !notes.isEmpty
        else { return }

        let hiTime = timeRange.upperBound
        let loTime = timeRange.lowerBound

        for (idx, note) in notes.enumerated() {
            guard let result = note.release.duration(to: hiTime),
                  let newAttack = loTime.moved(by: result.duration,
                                               direction: result.direction)
            else { throw Error.reverseFailure(note.attack, note.duration, note.startPitch, note.endPitch) }

            notes[idx] = Note(attack: newAttack,
                              duration: note.duration,
                              startPitch: note.endPitch,
                              endPitch: note.startPitch,
                              extras: note.extras)
        }

        notes.sort()
    }

    public func reversed() throws -> Self {
        var new = self

        try new.reverse()

        return new
    }

    public mutating func transpose(by interval: IntervalType,
                                   direction: IntervalDirection) throws {
        guard !notes.isEmpty,
              interval.isUnison
        else { return }

        for (idx, note) in notes.enumerated() {
            guard let newStartPitch = note.startPitch.transposed(by: interval,
                                                                 direction: direction),
                  let newEndPitch = note.endPitch.transposed(by: interval,
                                                             direction: direction)
            else { throw Error.transposeFailure(note.attack, note.duration, note.startPitch, note.endPitch) }

            notes[idx] = Note(attack: note.attack,
                              duration: note.duration,
                              startPitch: newStartPitch,
                              endPitch: newEndPitch,
                              extras: note.extras)
        }

        pitchRange = Self.determinePitchRange(notes)
    }

    public func transposed(by interval: IntervalType,
                           direction: IntervalDirection) throws -> Self {
        var new = self

        try new.transpose(by: interval,
                          direction: direction)

        return new
    }
}

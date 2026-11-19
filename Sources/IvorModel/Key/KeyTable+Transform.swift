// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning
public import XestiNumbers

private import XestiTools

extension KeyTable {

    // MARK: Public Instance Methods

    /// Augments this key table by a rational factor, so that each key change
    /// stays with the music.
    ///
    /// Entries before `anchor` don’t change. Every entry at or after `anchor` moves to
    /// `anchor + (time − anchor) × factor`.
    ///
    /// - Parameter factor: A rational number ≥ 1 by which to stretch the key table.
    /// - Parameter anchor: The beat time to stretch relative to. Defaults to 0.
    ///
    /// - Throws:   ``KeyTable/Error/invalidAugmentationFactor(_:)`` if `factor` is not a
    ///             rational number ≥ 1.
    public mutating func augment(by factor: Number,
                                 anchor: BeatTime = .zero) throws(Error) {
        guard factor.isRational,
              factor >= 1
        else { throw Error.invalidAugmentationFactor(factor) }

        _scale(by: factor,
               anchor: anchor)
    }

    /// Diminishes this key table by a rational factor, so that each key
    /// change stays with the music.
    ///
    /// This is the same as augmenting by the reciprocal of `factor`; see
    /// ``augment(by:anchor:)``.
    ///
    /// - Parameter factor: A rational number ≥ 1 by which to compress the key table.
    /// - Parameter anchor: The beat time to compress relative to. Defaults to 0.
    ///
    /// - Throws:   ``KeyTable/Error/invalidDiminutionFactor(_:)`` if `factor` is not a
    ///             rational number ≥ 1.
    public mutating func diminish(by factor: Number,
                                  anchor: BeatTime = .zero) throws(Error) {
        guard factor.isRational,
              factor >= 1
        else { throw Error.invalidDiminutionFactor(factor) }

        _scale(by: 1 / factor,
               anchor: anchor)
    }

    /// Inverts every key in this key table around a range of pitches, as
    /// `Key.inverted(around:)` does, keeping each entry’s extras. A diatonic key’s mode is
    /// mapped (C major inverted around C is C phrygian).
    ///
    /// If any entry’s key can’t be inverted, the whole table is emptied, since dropping
    /// one entry would let the key before it run on.
    ///
    /// - Parameter pitchRange: The range of pitches to invert around.
    ///
    /// - Returns:  `true` if the table was emptied because an entry couldn’t be inverted;
    ///             otherwise, `false`.
    @discardableResult
    public mutating func invert(around pitchRange: ClosedRange<Pitch>) -> Bool {
        _mapKeys { $0.inverted(around: pitchRange) }
    }

    /// Inverts every key in this key table around a range of MIDI note numbers, as
    /// `Key.inverted(around:)` does, keeping each entry’s extras. A diatonic key’s mode is
    /// mapped. This assumes 12 keys to the octave.
    ///
    /// If any entry’s key can’t be inverted, the whole table is emptied, since dropping
    /// one entry would let the key before it run on.
    ///
    /// - Parameter noteRange:  The range of note numbers to invert around.
    ///
    /// - Returns:  `true` if the table was emptied because an entry couldn’t be inverted;
    ///             otherwise, `false`.
    @discardableResult
    public mutating func invert(around noteRange: ClosedRange<NoteNumber>) -> Bool {
        _mapKeys { $0.inverted(around: noteRange) }
    }

    /// Moves every entry of this key table by a directed duration.
    ///
    /// Moving earlier, of the entries that would land before time 0, only the last is kept,
    /// placed at 0, since its key is the one in effect there; the others, and their
    /// extras, are dropped. If an entry lands exactly on 0, it wins, and those before it are all
    /// dropped. Unlike the part tables’ moves, this never fails.
    ///
    /// - Parameter directedDuration:   The directed duration by which to move the entries.
    public mutating func move(by directedDuration: DirectedDuration<BeatDuration>) {
        guard !entries.isEmpty
        else { return }

        let distance = directedDuration.duration

        switch directedDuration.direction {
        case .backward:
            let shift = distance.numberValue
            let landsBefore = entries.indices.filter { entries[$0].beatTime.numberValue < shift }
            let rest = entries[(landsBefore.last.map { $0 + 1 } ?? 0)...].map { $0.moved(to: $0.beatTime - distance) }

            if let kept = landsBefore.last,
               rest.first?.beatTime != .zero {
                entries = [entries[kept].moved(to: .zero)] + rest
            } else {
                entries = rest
            }

        case .forward:
            entries = entries.map { $0.moved(to: $0.beatTime + distance) }

        case .same:
            return
        }

        hasExtras = Self.hasExtras(in: entries)
    }

    /// Reverses the keys of this key table within a beat-time range,
    /// mirroring them as the music in that range is mirrored.
    ///
    /// Each entry is a step: its key holds until the next entry. So reversing mirrors
    /// the stretch each entry in the range governs — up to the next entry, or to the range’s
    /// upper bound — and moves the entry to that stretch’s new start. The stretch before the first
    /// entry in the range, which holds the key in effect before the range, moves to the
    /// end of the range, and a new entry with that key and its extras begins it there.
    /// (When no key is in effect before the range, there’s nothing to begin it with, so
    /// the last mirrored key runs on over it.) Finally, the key in effect
    /// after the range is restated at its upper bound, unless it’s already in effect there.
    ///
    /// For example, D major at 0 and B♭ major at 4, reversed within 0…8, gives B♭ major at 0 and
    /// D major at 4, then B♭ major again at 8, since it was in effect after the range.
    ///
    /// - Parameter beatTimeRange:  The beat-time range to mirror the keys within.
    public mutating func reverse(within beatTimeRange: ClosedRange<BeatTime>) {
        let lower = beatTimeRange.lowerBound
        let upper = beatTimeRange.upperBound
        let inside = entries.indices.filter { lower <= entries[$0].beatTime && entries[$0].beatTime < upper }

        guard let firstInside = inside.first
        else { return }

        let original = self
        var newEntries = entries.filter { $0.beatTime < lower || $0.beatTime >= upper }

        for (position, index) in inside.enumerated() {
            let stretchEnd = position + 1 < inside.count ? entries[inside[position + 1]].beatTime : upper

            newEntries.append(entries[index].moved(to: Self._mirrored(stretchEnd,
                                                                      within: beatTimeRange)))
        }

        let firstTime = entries[firstInside].beatTime

        if firstTime > lower,
           firstInside > 0 {
            let leading = entries[firstInside - 1]

            newEntries.append(StoredEntry(beatTime: Self._mirrored(firstTime,
                                                                   within: beatTimeRange),
                                          key: leading.key,
                                          extras: leading.extras))
        }

        newEntries.sort { $0.beatTime < $1.beatTime }

        var result = Self(entries: newEntries)

        if original.entryIndex(at: upper) == nil,
           let afterIndex = original.governingIndex(at: upper) {
            let after = original.entries[afterIndex]
            let current = result.governingIndex(at: upper).map { result.entries[$0] }

            if current?.key != after.key || current?.extras != after.extras {
                result.entries.insert(StoredEntry(beatTime: upper,
                                                  key: after.key,
                                                  extras: after.extras),
                                      at: result.insertionIndex(for: upper))
            }
        }

        result.hasExtras = Self.hasExtras(in: result.entries)

        self = result
    }

    /// Transposes every key in this key table by a directed frequency ratio,
    /// as `Key.transposed(by:)` does, keeping each entry’s extras.
    ///
    /// If the ratio is more than 25 cents from a whole number of semitones, or any entry’s key
    /// can’t be transposed, the whole table is emptied, since the music then sits
    /// between keys, and dropping one entry would let the key before it run on.
    ///
    /// - Parameter directedInterval:   The directed ratio to transpose by.
    ///
    /// - Returns:  `true` if the table was emptied; otherwise, `false`.
    @discardableResult
    public mutating func transpose(by directedInterval: DirectedInterval<Ratio>) -> Bool {
        _mapKeys { $0.transposed(by: directedInterval) }
    }

    /// Transposes every key in this key table by a directed distance in key
    /// steps, as `Key.transposed(by:)` does, keeping each entry’s extras. This assumes 12
    /// keys to the octave.
    ///
    /// If any entry’s key can’t be transposed, the whole table is emptied, since
    /// dropping one entry would let the key before it run on.
    ///
    /// - Parameter directedInterval:   The directed distance to transpose by.
    ///
    /// - Returns:  `true` if the table was emptied because an entry couldn’t be transposed;
    ///             otherwise, `false`.
    @discardableResult
    public mutating func transpose(by directedInterval: DirectedInterval<NoteDistance>) -> Bool {
        _mapKeys { $0.transposed(by: directedInterval) }
    }

    /// Transposes every key in this key table by a directed interval, as
    /// `Key.transposed(by:)` does, keeping each entry’s extras.
    ///
    /// If any entry’s key can’t be transposed, the whole table is emptied, since
    /// dropping one entry would let the key before it run on.
    ///
    /// - Parameter directedInterval:   The directed interval to transpose by.
    ///
    /// - Returns:  `true` if the table was emptied because an entry couldn’t be transposed;
    ///             otherwise, `false`.
    @discardableResult
    public mutating func transpose(by directedInterval: DirectedInterval<Interval>) -> Bool {
        _mapKeys { $0.transposed(by: directedInterval) }
    }

    // MARK: Private Type Methods

    //
    // `beatTime` mirrored within `range`: as far after its lower bound as it was before its upper
    // bound.
    //
    private static func _mirrored(_ beatTime: BeatTime,
                                  within range: ClosedRange<BeatTime>) -> BeatTime {
        range.lowerBound + (range.upperBound - beatTime)
    }

    // MARK: Private Instance Methods

    //
    // Replaces every entry's key with `transform`'s result, or empties the table if any
    // result is `nil`. Returns whether the table was emptied.
    //
    private mutating func _mapKeys(_ transform: (Key) -> Key?) -> Bool {
        var newEntries: [StoredEntry] = []

        for entry in entries {
            guard let key = transform(entry.key)
            else {
                removeAll()
                return true
            }

            newEntries.append(entry.with(key))
        }

        entries = newEntries
        hasExtras = Self.hasExtras(in: entries)

        return false
    }

    //
    // Augments (factor > 1) or diminishes (factor < 1) about `anchor`; see `augment(by:anchor:)`.
    //
    private mutating func _scale(by factor: Number,
                                 anchor: BeatTime) {
        guard factor != 1
        else { return }

        entries = entries.map { entry in
            guard entry.beatTime >= anchor
            else { return entry }

            return entry.moved(to: anchor + (entry.beatTime - anchor) * factor)
        }
    }
}

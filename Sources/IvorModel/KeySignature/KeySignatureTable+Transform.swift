// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning
public import XestiNumbers

private import XestiTools

extension KeySignatureTable {

    // MARK: Public Instance Methods

    /// Augments this key signature table by a rational factor, so that each key signature change
    /// stays with the music.
    ///
    /// Entries before `anchor` don’t change. Every entry at or after `anchor` moves to
    /// `anchor + (time − anchor) × factor`.
    ///
    /// - Parameter factor: A rational number ≥ 1 by which to stretch the key signature table.
    /// - Parameter anchor: The beat time to stretch relative to. Defaults to 0.
    ///
    /// - Throws:   ``KeySignatureTable/Error/invalidAugmentationFactor(_:)`` if `factor` is not a
    ///             rational number ≥ 1.
    public mutating func augment(by factor: Number,
                                 anchor: BeatTime = .zero) throws(Error) {
        guard factor.isRational,
              factor >= 1
        else { throw Error.invalidAugmentationFactor(factor) }

        _scale(by: factor,
               anchor: anchor)
    }

    /// Diminishes this key signature table by a rational factor, so that each key signature
    /// change stays with the music.
    ///
    /// This is the same as augmenting by the reciprocal of `factor`; see
    /// ``augment(by:anchor:)``.
    ///
    /// - Parameter factor: A rational number ≥ 1 by which to compress the key signature table.
    /// - Parameter anchor: The beat time to compress relative to. Defaults to 0.
    ///
    /// - Throws:   ``KeySignatureTable/Error/invalidDiminutionFactor(_:)`` if `factor` is not a
    ///             rational number ≥ 1.
    public mutating func diminish(by factor: Number,
                                  anchor: BeatTime = .zero) throws(Error) {
        guard factor.isRational,
              factor >= 1
        else { throw Error.invalidDiminutionFactor(factor) }

        _scale(by: 1 / factor,
               anchor: anchor)
    }

    /// Inverts every key signature in this key signature table around a range of pitches, as
    /// `KeySignature.inverted(around:)` does, dropping each entry’s ``Extra/keySignatureMode``,
    /// which no longer fits.
    ///
    /// If any entry’s key signature can’t be inverted, the whole table is emptied, since dropping
    /// one entry would let the key signature before it run on.
    ///
    /// - Parameter pitchRange: The range of pitches to invert around.
    ///
    /// - Returns:  `true` if the table was emptied because an entry couldn’t be inverted;
    ///             otherwise, `false`.
    @discardableResult
    public mutating func invert(around pitchRange: ClosedRange<Pitch>) -> Bool {
        _mapKeySignatures(droppingMode: true) { $0.inverted(around: pitchRange) }
    }

    /// Inverts every key signature in this key signature table around a range of MIDI note
    /// numbers, as `KeySignature.inverted(around:)` does, dropping each entry’s
    /// ``Extra/keySignatureMode``, which no longer fits. This assumes 12 keys to the octave.
    ///
    /// If any entry’s key signature can’t be inverted, the whole table is emptied, since dropping
    /// one entry would let the key signature before it run on.
    ///
    /// - Parameter noteRange:  The range of note numbers to invert around.
    ///
    /// - Returns:  `true` if the table was emptied because an entry couldn’t be inverted;
    ///             otherwise, `false`.
    @discardableResult
    public mutating func invert(around noteRange: ClosedRange<NoteNumber>) -> Bool {
        _mapKeySignatures(droppingMode: true) { $0.inverted(around: noteRange) }
    }

    /// Moves every entry of this key signature table by a directed duration.
    ///
    /// Moving earlier, of the entries that would land before time 0, only the last is kept,
    /// placed at 0, since its key signature is the one in effect there; the others, and their
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

    /// Reverses the key signatures of this key signature table within a beat-time range,
    /// mirroring them as the music in that range is mirrored.
    ///
    /// Each entry is a step: its key signature holds until the next entry. So reversing mirrors
    /// the stretch each entry in the range governs — up to the next entry, or to the range’s
    /// upper bound — and moves the entry to that stretch’s new start. The stretch before the first
    /// entry in the range, which holds the key signature in effect before the range, moves to the
    /// end of the range, and a new entry with that key signature and its extras begins it there.
    /// (When no key signature is in effect before the range, there’s nothing to begin it with, so
    /// the last mirrored key signature runs on over it.) Finally, the key signature in effect
    /// after the range is restated at its upper bound, unless it’s already in effect there.
    ///
    /// For example, D major at 0 and B♭ major at 4, reversed within 0…8, gives B♭ major at 0 and
    /// D major at 4, then B♭ major again at 8, since it was in effect after the range.
    ///
    /// - Parameter beatTimeRange:  The beat-time range to mirror the key signatures within.
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
                                          keySignature: leading.keySignature,
                                          extras: leading.extras))
        }

        newEntries.sort { $0.beatTime < $1.beatTime }

        var result = Self(entries: newEntries)

        if original.entryIndex(at: upper) == nil,
           let afterIndex = original.governingIndex(at: upper) {
            let after = original.entries[afterIndex]
            let current = result.governingIndex(at: upper).map { result.entries[$0] }

            if current?.keySignature != after.keySignature || current?.extras != after.extras {
                result.entries.insert(StoredEntry(beatTime: upper,
                                                  keySignature: after.keySignature,
                                                  extras: after.extras),
                                      at: result.insertionIndex(for: upper))
            }
        }

        result.hasExtras = Self.hasExtras(in: result.entries)

        self = result
    }

    /// Transposes every key signature in this key signature table by a directed frequency ratio,
    /// as `KeySignature.transposed(by:)` does, keeping each entry’s extras.
    ///
    /// If the ratio is more than 25 cents from a whole number of semitones, or any entry’s key
    /// signature can’t be transposed, the whole table is emptied, since the music then sits
    /// between keys, and dropping one entry would let the key signature before it run on.
    ///
    /// - Parameter directedInterval:   The directed ratio to transpose by.
    ///
    /// - Returns:  `true` if the table was emptied; otherwise, `false`.
    @discardableResult
    public mutating func transpose(by directedInterval: DirectedInterval<Ratio>) -> Bool {
        _mapKeySignatures(droppingMode: false) { $0.transposed(by: directedInterval) }
    }

    /// Transposes every key signature in this key signature table by a directed distance in key
    /// steps, as `KeySignature.transposed(by:)` does, keeping each entry’s extras. This assumes 12
    /// keys to the octave.
    ///
    /// If any entry’s key signature can’t be transposed, the whole table is emptied, since
    /// dropping one entry would let the key signature before it run on.
    ///
    /// - Parameter directedInterval:   The directed distance to transpose by.
    ///
    /// - Returns:  `true` if the table was emptied because an entry couldn’t be transposed;
    ///             otherwise, `false`.
    @discardableResult
    public mutating func transpose(by directedInterval: DirectedInterval<NoteDistance>) -> Bool {
        _mapKeySignatures(droppingMode: false) { $0.transposed(by: directedInterval) }
    }

    /// Transposes every key signature in this key signature table by a directed interval, as
    /// `KeySignature.transposed(by:)` does, keeping each entry’s extras.
    ///
    /// If any entry’s key signature can’t be transposed, the whole table is emptied, since
    /// dropping one entry would let the key signature before it run on.
    ///
    /// - Parameter directedInterval:   The directed interval to transpose by.
    ///
    /// - Returns:  `true` if the table was emptied because an entry couldn’t be transposed;
    ///             otherwise, `false`.
    @discardableResult
    public mutating func transpose(by directedInterval: DirectedInterval<Interval>) -> Bool {
        _mapKeySignatures(droppingMode: false) { $0.transposed(by: directedInterval) }
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
    // Replaces every entry's key signature with `transform`'s result, or empties the table if any
    // result is `nil`. Returns whether the table was emptied.
    //
    private mutating func _mapKeySignatures(droppingMode: Bool,
                                            _ transform: (KeySignature) -> KeySignature?) -> Bool {
        var newEntries: [StoredEntry] = []

        for entry in entries {
            guard let keySignature = transform(entry.keySignature)
            else {
                removeAll()
                return true
            }

            newEntries.append(entry.with(keySignature,
                                         droppingMode: droppingMode))
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

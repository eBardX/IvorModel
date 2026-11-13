// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiNumbers

private import XestiTools

extension MeterTable {

    // MARK: Public Instance Methods

    /// Augments this meter table by a rational factor, so that the meter scales with the music
    /// and every note keeps its `bar:beat`.
    ///
    /// Entries before `anchor` don’t change. If `anchor` falls inside the grid and no entry sits
    /// there, one is first inserted there with the meter in effect, splitting the bar that
    /// contains `anchor` if it’s mid-bar (and shortening the pickup to end there if it falls
    /// inside the pickup bar). Then every entry at or after `anchor` moves to
    /// `anchor + (time − anchor) × factor` and its meter is re-notated with
    /// ``Meter/scaled(by:)``. With an anchor of 0, the pickup scales too.
    ///
    /// - Parameter factor: A rational number ≥ 1 by which to stretch the meter table.
    /// - Parameter anchor: The beat time to stretch relative to. Defaults to 0.
    ///
    /// - Throws:   ``MeterTable/Error/invalidAugmentationFactor(_:)`` if `factor` is not a
    ///             rational number ≥ 1.
    public mutating func augment(by factor: Number,
                                 anchor: BeatTime = .zero) throws(Error) {
        guard factor.isRational,
              factor >= 1
        else { throw Error.invalidAugmentationFactor(factor) }

        _scale(by: factor,
               anchor: anchor)
    }

    /// Diminishes this meter table by a rational factor, so that the meter scales with the music
    /// and every note keeps its `bar:beat`.
    ///
    /// This is the same as augmenting by the reciprocal of `factor`; see
    /// ``augment(by:anchor:)``.
    ///
    /// - Parameter factor: A rational number ≥ 1 by which to compress the meter table.
    /// - Parameter anchor: The beat time to compress relative to. Defaults to 0.
    ///
    /// - Throws:   ``MeterTable/Error/invalidDiminutionFactor(_:)`` if `factor` is not a rational
    ///             number ≥ 1.
    public mutating func diminish(by factor: Number,
                                  anchor: BeatTime = .zero) throws(Error) {
        guard factor.isRational,
              factor >= 1
        else { throw Error.invalidDiminutionFactor(factor) }

        _scale(by: 1 / factor,
               anchor: anchor)
    }

    /// Moves every entry of this meter table by a directed duration, keeping every barline where
    /// the music takes it.
    ///
    /// - **Later:** an entry at time 0 stays there instead, and the pickup grows by the duration,
    ///   wrapped to that entry’s bar length (a free meter keeps no pickup), so its grid still
    ///   lines up with the music.
    /// - **Earlier:** of the entries that would land before time 0, only the last is kept,
    ///   placed at 0, with the pickup set so that its grid still lines up with the music (capped
    ///   at the next entry). The others, and their extras, are dropped. If an entry lands exactly
    ///   on 0, it wins, and those before it are all dropped.
    ///
    /// Unlike the other tables’ moves, this never fails.
    ///
    /// - Parameter directedDuration:   The directed duration by which to move the entries.
    public mutating func move(by directedDuration: DirectedDuration<BeatDuration>) {
        guard let first = entries.first
        else { return }

        let distance = directedDuration.duration

        switch directedDuration.direction {
        case .same:
            return

        case .forward:
            let firstStays = first.beatTime == .zero

            entries = entries.enumerated().map { index, entry in
                index == 0 && firstStays ? entry : entry.moved(to: entry.beatTime + distance)
            }

            if firstStays {
                if let barLength = first.meter.barLength {
                    pickup = Meter.remainder(pickup + distance,
                                             barLength)
                } else {
                    pickup = .zero
                }
            }

        case .backward:
            _moveEarlier(by: distance)
        }

        normalizePickup()
        hasExtras = Self.hasExtras(in: entries)
    }

    /// Reverses the grid of this meter table within a beat-time range, mirroring its bars as the
    /// music in that range is mirrored.
    ///
    /// The grid within the range — clipped to start no earlier than the first entry — is cut into
    /// pieces, one per bar (clipped to the range), each with its meter and the extras of the entry
    /// that governs it. The pieces are mirrored within the range, and the entries in it are
    /// replaced by one at the start of each mirrored piece, leaving out any that would be
    /// redundant. Then:
    ///
    /// - **Leftover → pickup:** if the range starts at time 0 and the first mirrored piece is
    ///   shorter than its bar, it becomes the pickup.
    /// - **The grid after the range is kept:** if the range’s upper bound wasn’t a barline, an
    ///   entry with the meter in effect there is inserted at it, and a restart at the first
    ///   barline after it, so that every later barline stays where it was. If it was a barline,
    ///   an entry with the meter in effect there is inserted at it, unless the reversed grid
    ///   already has a barline there with that meter.
    ///
    /// For example, bars of 3/4 then 2/4, reversed within 0…1 (the range ending 1/4 into the 2/4
    /// bar), give 2/4 at 0 with a pickup of 1/4, then 3/4 from 1/4.
    ///
    /// - Parameter beatTimeRange:  The beat-time range to mirror the grid within.
    public mutating func reverse(within beatTimeRange: ClosedRange<BeatTime>) {
        let upper = beatTimeRange.upperBound

        guard let first = entries.first,
              upper > first.beatTime
        else { return }

        let lower = Swift.max(beatTimeRange.lowerBound, first.beatTime)
        let original = self

        //
        // Each piece of the grid, mirrored: an entry at its new start (with the meter and extras of
        // the entry that governed it), and its new end.
        //
        let pieces: [(entry: StoredEntry, end: BeatTime)] = original
            .barsWithEntryIndex(overlapping: lower..<upper)
            .reversed()
            .map { bar, index in
                let start = Swift.max(bar.range.lowerBound, lower)
                let end = Swift.min(bar.range.upperBound, upper)

                return (StoredEntry(beatTime: Self._mirrored(end, within: lower...upper),
                                    meter: bar.meter,
                                    extras: original.entries[index].extras),
                        Self._mirrored(start, within: lower...upper))
            }

        var result = Self(entries: entries.filter { $0.beatTime < lower || $0.beatTime >= upper },
                          pickup: lower == .zero ? .zero : pickup)

        for (offset, piece) in pieces.enumerated() {
            let entry = piece.entry
            let length = piece.end - entry.beatTime

            if offset == 0,
               entry.beatTime == .zero,
               let barLength = entry.meter.barLength,
               length < barLength {
                result.entries.insert(entry,
                                      at: 0)
                result.pickup = length
                continue
            }

            guard !result._isRedundant(at: entry.beatTime,
                                       meter: entry.meter,
                                       extras: entry.extras)
            else { continue }

            result.entries.insert(entry,
                                  at: result.insertionIndex(for: entry.beatTime))
        }

        let meterAfter = original.meter(at: upper)

        if original.isBarline(upper) {
            //
            // The entry that governed the bars after `upper` may have been inside the range, and
            // so removed: restate its meter at `upper`, unless the reversed grid already draws a
            // barline there with the same meter.
            //
            if result.meter(at: upper) != meterAfter || !result.isBarline(upper) {
                result._insertIfVacant(at: upper,
                                       meter: meterAfter)
            }
        } else {
            result._insertIfVacant(at: upper,
                                   meter: meterAfter)

            if let barline = original.nextBarline(after: upper) {
                result._insertIfVacant(at: barline,
                                       meter: original.meter(at: barline))
            }
        }

        result.normalizePickup()
        result.hasExtras = Self.hasExtras(in: result.entries)

        self = result
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

    private mutating func _insertIfVacant(at beatTime: BeatTime,
                                          meter: Meter?) {
        guard let meter,
              entryIndex(at: beatTime) == nil
        else { return }

        entries.insert(StoredEntry(beatTime: beatTime,
                                   meter: meter,
                                   extras: nil),
                       at: insertionIndex(for: beatTime))
    }

    //
    // Whether an entry at `beatTime` would change nothing: the entry in effect there has the same
    // meter and extras, and its grid draws a barline there anyway.
    //
    private func _isRedundant(at beatTime: BeatTime,
                              meter: Meter,
                              extras: Extras?) -> Bool {
        guard let index = governingIndex(at: beatTime),
              entries[index].meter == meter,
              entries[index].extras == extras
        else { return false }

        let span = spans()[index]

        return beatTime >= span.start && span.isOnBarline(beatTime)
    }

    private mutating func _moveEarlier(by distance: BeatDuration) {
        let shift = distance.numberValue
        let landsBefore = entries.indices.filter { entries[$0].beatTime.numberValue < shift }

        guard let kept = landsBefore.last
        else {
            entries = entries.map { $0.moved(to: $0.beatTime - distance) }
            return
        }

        let spans = spans()
        let rest = entries[(kept + 1)...].map { $0.moved(to: $0.beatTime - distance) }

        if rest.first?.beatTime == .zero {
            entries = rest
            pickup = .zero
            return
        }

        let keptEntry = entries[kept]
        var newPickup = BeatDuration.zero

        if let barLength = keptEntry.meter.barLength {
            //
            // The kept entry's grid, moved: its bars start at `spans[kept].start - distance`,
            // which is before 0 or at it. The pickup runs from 0 to the first of those barlines
            // at or after 0.
            //
            let gridStart = spans[kept].start.numberValue - shift
            let length = barLength.numberValue
            let wrapped = gridStart - floor(gridStart / length) * length

            newPickup = BeatDuration(wrapped)

            if let next = rest.first,
               next.beatTime < .zero + newPickup {
                newPickup = next.beatTime - .zero
            }
        }

        entries = [keptEntry.moved(to: .zero)] + rest
        pickup = newPickup
    }

    //
    // Augments (factor > 1) or diminishes (factor < 1) about `anchor`; see `augment(by:anchor:)`.
    //
    private mutating func _scale(by factor: Number,
                                 anchor: BeatTime) {
        guard let first = entries.first,
              factor != 1
        else { return }

        if anchor >= first.beatTime,
           entryIndex(at: anchor) == nil,
           let meter = meter(at: anchor) {
            entries.insert(StoredEntry(beatTime: anchor,
                                       meter: meter,
                                       extras: nil),
                           at: insertionIndex(for: anchor))
        }

        entries = entries.map { entry in
            guard entry.beatTime >= anchor
            else { return entry }

            return StoredEntry(entryID: entry.entryID,
                               beatTime: anchor + (entry.beatTime - anchor) * factor,
                               meter: entry.meter.scaled(by: factor),
                               extras: entry.extras)
        }

        if anchor == .zero {
            pickup *= factor
        }

        normalizePickup()
        hasExtras = Self.hasExtras(in: entries)
    }
}

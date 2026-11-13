// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

extension MeterTable {

    // MARK: Public Instance Methods

    /// Returns the bars of the grid that overlap the given beat-time range, in order.
    ///
    /// The bars returned are whole bars, not clipped to `range`, except that a free bar that runs
    /// on for ever, after the last entry, ends at `range.upperBound`. Nothing before the first
    /// entry is a bar.
    ///
    /// - Parameter range:  The beat-time range to find the bars in.
    ///
    /// - Returns:  The bars that overlap `range`, or an empty array if there are none or `range`
    ///             is empty.
    public func bars(overlapping range: Range<BeatTime>) -> [Bar] {
        barsWithEntryIndex(overlapping: range).map(\.bar)
    }

    /// Returns the beat time of a position given as a bar, a beat within it, and an offset from
    /// that beat — the inverse of ``position(at:)``.
    ///
    /// - Parameter bar:    The bar number: 0 for the pickup bar, and counting from 1 after it.
    /// - Parameter beat:   The beat number within the bar, counting from 1, or `nil` for a free
    ///                     bar.
    /// - Parameter offset: The distance from the start of the beat (from the start of the bar, in
    ///                     a free bar).
    ///
    /// - Returns:  The beat time, or `nil` unless the bar exists, the beat exists in it (in the
    ///             pickup bar, only the tail beats that reach into it), `offset` is shorter than
    ///             the beat, and the result lies inside the bar. `beat` must be `nil` exactly when
    ///             the bar is free.
    public func beatTime(bar: Int,
                         beat: Int?,
                         offset: BeatDuration) -> BeatTime? {
        if bar == 0 {
            guard let meter = pickupMeter,
                  let barLength = meter.barLength,
                  let beat,
                  let fullBarOffset = Self._fullBarOffset(of: meter,
                                                          beat: beat,
                                                          offset: offset)
            else { return nil }

            let shift = barLength - pickup

            guard fullBarOffset >= shift
            else { return nil }

            return .zero + (fullBarOffset - shift)
        }

        guard let span = spans().first(where: { $0.contains(barNumber: bar) })
        else { return nil }

        let barStart = span.barStart(bar)
        let result: BeatTime

        if span.meter.isFree {
            guard beat == nil
            else { return nil }

            result = barStart + offset
        } else {
            guard let beat,
                  let fullBarOffset = Self._fullBarOffset(of: span.meter,
                                                          beat: beat,
                                                          offset: offset)
            else { return nil }

            result = barStart + fullBarOffset
        }

        if let barEnd = span.barEnd(bar), result >= barEnd {
            return nil
        }

        return result
    }

    /// Returns the beat time a given distance after the start of a bar.
    ///
    /// - Parameter bar:    The bar number: 0 for the pickup bar, and counting from 1 after it.
    /// - Parameter plus:   The distance from the start of the bar.
    ///
    /// - Returns:  The beat time, or `nil` unless the bar exists and the result lies inside it.
    public func beatTime(bar: Int,
                         plus: BeatDuration) -> BeatTime? {
        if bar == 0 {
            guard pickupMeter != nil,
                  plus < pickup
            else { return nil }

            return .zero + plus
        }

        guard let span = spans().first(where: { $0.contains(barNumber: bar) })
        else { return nil }

        let result = span.barStart(bar) + plus

        if let barEnd = span.barEnd(bar), result >= barEnd {
            return nil
        }

        return result
    }

    /// Returns a Boolean value indicating whether the entry with the given identity is a
    /// *restart*: an entry with the same meter as the one before it, which doesn’t fall on a
    /// barline the earlier entry’s grid would have drawn anyway, and so exists to make the bar
    /// before it short.
    ///
    /// An entry with the same meter that does fall on such a barline is *redundant*: harmless,
    /// but not a restart.
    ///
    /// - Parameter entryID:    The identity of the entry.
    ///
    /// - Returns:  `true` if the entry is a restart; `false` if it isn’t, or if `entryID` names no
    ///             entry.
    public func isRestart(entryID: EntryID) -> Bool {
        guard let index = firstIndex(entryID: entryID),
              index > 0,
              entries[index].meter == entries[index - 1].meter
        else { return false }

        return !spans()[index - 1].isOnBarline(entries[index].beatTime)
    }

    /// Returns the meter in effect at the given beat time.
    ///
    /// - Parameter beatTime:   The beat time at which to query the meter.
    ///
    /// - Returns:  The meter of the last entry at or before `beatTime`, or `nil` if there’s none.
    public func meter(at beatTime: BeatTime) -> Meter? {
        governingIndex(at: beatTime).map { entries[$0].meter }
    }

    /// Returns the position of the given beat time as a bar, a beat within it, and an offset
    /// from that beat — the `bar:beat` a composer reads.
    ///
    /// - Parameter beatTime:   The beat time to locate.
    ///
    /// - Returns:  The position, or `nil` if `beatTime` comes before the first entry (where there
    ///             are no bars).
    public func position(at beatTime: BeatTime) -> Position? {
        guard let index = governingIndex(at: beatTime)
        else { return nil }

        if index == 0,
           let meter = pickupMeter,
           let barLength = meter.barLength,
           beatTime < .zero + pickup {
            return Self._position(in: meter,
                                  bar: 0,
                                  fullBarOffset: barLength - pickup + (beatTime - .zero))
        }

        let span = spans()[index]
        let bar = span.barNumber(containing: beatTime)
        let barOffset = beatTime - span.barStart(bar)

        guard !span.meter.isFree
        else { return Position(bar: bar,
                               beat: nil,
                               offset: barOffset,
                               beatLength: nil) }

        return Self._position(in: span.meter,
                              bar: bar,
                              fullBarOffset: barOffset)
    }

    /// Returns the actual and full lengths of the short bar that the entry with the given
    /// identity cuts off, if it cuts one off.
    ///
    /// For example, a 4/4 restart 3/4 into a bar of 4/4 cuts it off at 3/4 of its full length of
    /// 1.
    ///
    /// - Parameter entryID:    The identity of the entry.
    ///
    /// - Returns:  The actual and full lengths of the bar just before the entry, or `nil` if that
    ///             bar isn’t short, if it’s free, or if `entryID` names no entry or the first.
    public func shortBar(before entryID: EntryID) -> (actual: BeatDuration, full: BeatDuration)? {
        guard let index = firstIndex(entryID: entryID),
              index > 0
        else { return nil }

        let span = spans()[index - 1]

        guard let barLength = span.meter.barLength
        else { return nil }

        let actual = Meter.remainder(entries[index].beatTime - span.start,
                                     barLength)

        guard !actual.isZero
        else { return nil }

        return (actual, barLength)
    }

    // MARK: Private Type Methods

    //
    // The distance from the start of a full bar of `meter` to `offset` into beat `beat`, or `nil`
    // if there's no such beat or `offset` isn't shorter than it.
    //
    private static func _fullBarOffset(of meter: Meter,
                                       beat: Int,
                                       offset: BeatDuration) -> BeatDuration? {
        let pulse = meter.pulse

        guard pulse.indices.contains(beat - 1),
              offset < pulse[beat - 1]
        else { return nil }

        return meter.beatOffsets[beat - 1] + offset
    }

    private static func _position(in meter: Meter,
                                  bar: Int,
                                  fullBarOffset: BeatDuration) -> Position? {
        guard let beat = meter.beat(at: fullBarOffset)
        else { return nil }

        return Position(bar: bar,
                        beat: beat.index + 1,
                        offset: fullBarOffset - beat.start,
                        beatLength: beat.length)
    }
}

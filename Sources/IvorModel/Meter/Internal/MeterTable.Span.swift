// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import XestiNumbers

extension MeterTable {

    // MARK: Internal Nested Types

    //
    // The stretch of the grid one entry governs: from its first full bar (the entry's own beat
    // time, or the end of the pickup bar for an entry at 0 with a pickup) up to the next entry, or
    // for ever after the last. It holds `barCount` bars, numbered from `firstBarNumber`; a free
    // span is one bar. A span can hold no bars at all, when a pickup ends exactly on the second
    // entry.
    //
    internal struct Span {

        // MARK: Internal Instance Properties

        internal let barCount: Int?          // nil when the span runs on for ever
        internal let end: BeatTime?          // nil when the span runs on for ever
        internal let entryIndex: Int
        internal let firstBarNumber: Int
        internal let meter: Meter
        internal let start: BeatTime
    }
}

// MARK: -

extension MeterTable.Span {

    // MARK: Internal Instance Methods

    //
    // The end of bar `number`: the next bar's start, cut off at the span's end; for a free span,
    // the span's end (`nil` for ever).
    //
    internal func barEnd(_ number: Int) -> BeatTime? {
        guard let barLength = meter.barLength
        else { return end }

        let fullEnd = barStart(number) + barLength

        if let end, end < fullEnd {
            return end
        }

        return fullEnd
    }

    //
    // The number of the bar that contains `beatTime`, which must lie in this span.
    //
    internal func barNumber(containing beatTime: BeatTime) -> Int {
        guard let barLength = meter.barLength
        else { return firstBarNumber }

        return firstBarNumber + Meter.floorQuotient(beatTime - start,
                                                    barLength)
    }

    internal func barStart(_ number: Int) -> BeatTime {
        guard let barLength = meter.barLength
        else { return start }

        return start + barLength * Number(number - firstBarNumber)
    }

    internal func contains(barNumber number: Int) -> Bool {
        guard number >= firstBarNumber
        else { return false }

        guard let barCount
        else { return true }

        return number < firstBarNumber + barCount
    }

    //
    // Whether this span's grid draws a barline at `beatTime`, which must not come before `start`.
    // A free span draws one only at its start.
    //
    internal func isOnBarline(_ beatTime: BeatTime) -> Bool {
        guard let barLength = meter.barLength
        else { return beatTime == start }

        return Meter.remainder(beatTime - start,
                               barLength).isZero
    }
}

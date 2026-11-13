// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import XestiNumbers
internal import XestiTools

extension MeterTable {

    // MARK: Internal Type Methods

    internal static func hasExtras(in entries: [StoredEntry]) -> Bool {
        entries.contains { $0.extras != nil }
    }

    //
    // Invariants 2 and 3: a non-zero pickup needs a metered entry at 0, must be shorter than its
    // bar, and must end no later than the second entry.
    //
    internal static func isValid(pickup: BeatDuration,
                                 for entries: [StoredEntry]) -> Bool {
        guard !pickup.isZero
        else { return true }

        guard let first = entries.first,
              first.beatTime == .zero,
              let barLength = first.meter.barLength,
              pickup < barLength
        else { return false }

        guard entries.count > 1
        else { return true }

        return BeatTime.zero + pickup <= entries[1].beatTime
    }

    // MARK: Internal Instance Properties

    //
    // The meter of the pickup bar, bar 0, if there is one.
    //
    internal var pickupMeter: Meter? {
        guard !pickup.isZero
        else { return nil }

        return entries.first?.meter
    }

    // MARK: Internal Instance Methods

    //
    // The meter in effect at `beatTime` and the distance from the start of the bar that contains
    // it, or `nil` before the first entry. The pickup bar counts as the tail of a full bar, so a
    // time in it is as far from the bar's start as it would be in a full bar. A free bar gives 0.
    //
    internal func barOffset(at beatTime: BeatTime) -> (meter: Meter, offset: BeatDuration)? {
        guard let index = governingIndex(at: beatTime)
        else { return nil }

        let meter = entries[index].meter

        guard let barLength = meter.barLength
        else { return (meter, .zero) }

        if index == 0,
           pickupMeter != nil,
           beatTime < .zero + pickup {
            return (meter, barLength - pickup + (beatTime - .zero))
        }

        let span = spans()[index]

        return (meter, beatTime - span.barStart(span.barNumber(containing: beatTime)))
    }

    //
    // Every bar overlapping `range`, each with the index of the entry that governs it.
    //
    internal func barsWithEntryIndex(overlapping range: Range<BeatTime>) -> [(bar: Bar, entryIndex: Int)] {
        guard !range.isEmpty
        else { return [] }

        var result: [(bar: Bar, entryIndex: Int)] = []

        if let meter = pickupMeter,
           let barLength = meter.barLength,
           range.lowerBound < .zero + pickup {
            let shift = barLength - pickup
            let beatStarts = meter.beatOffsets
                .filter { $0 >= shift }
                .map { BeatTime.zero + ($0 - shift) }

            result.append((Bar(number: 0,
                               range: .zero..<(.zero + pickup),
                               meter: meter,
                               isPickup: true,
                               isShort: false,
                               beatStarts: beatStarts), 0))
        }

        for span in spans() {
            if let end = span.end, end <= range.lowerBound {
                continue
            }

            if span.start >= range.upperBound {
                break
            }

            if span.barCount == 0 {
                continue
            }

            guard let barLength = span.meter.barLength
            else {
                result.append((Bar(number: span.firstBarNumber,
                                   range: span.start..<(span.end ?? range.upperBound),
                                   meter: span.meter,
                                   isPickup: false,
                                   isShort: false,
                                   beatStarts: []), span.entryIndex))
                continue
            }

            var number = span.barNumber(containing: Swift.max(range.lowerBound, span.start))

            while span.contains(barNumber: number) {
                let barStart = span.barStart(number)

                guard barStart < range.upperBound,
                      let barEnd = span.barEnd(number)
                else { break }

                let beatStarts = span.meter.beatOffsets
                    .map { barStart + $0 }
                    .filter { $0 < barEnd }

                result.append((Bar(number: number,
                                   range: barStart..<barEnd,
                                   meter: span.meter,
                                   isPickup: false,
                                   isShort: barEnd - barStart < barLength,
                                   beatStarts: beatStarts), span.entryIndex))

                number += 1
            }
        }

        return result
    }

    internal func entryIndex(at beatTime: BeatTime) -> Int? {
        entries.firstIndex { $0.beatTime == beatTime }
    }

    internal func firstIndex(entryID: EntryID) -> Int? {
        entries.firstIndex { $0.entryID == entryID }
    }

    //
    // The index of the entry in effect at `beatTime`: the last at or before it.
    //
    internal func governingIndex(at beatTime: BeatTime) -> Int? {
        entries.lastIndex { $0.beatTime <= beatTime }
    }

    internal func insertionIndex(for beatTime: BeatTime) -> Int {
        entries.firstIndex { beatTime < $0.beatTime } ?? entries.endIndex
    }

    //
    // Whether the grid draws a barline at `beatTime`: an entry, the end of the pickup bar, or a
    // bar start within a span. Nothing before the first entry is a barline.
    //
    internal func isBarline(_ beatTime: BeatTime) -> Bool {
        guard let index = governingIndex(at: beatTime)
        else { return false }

        if entries[index].beatTime == beatTime {
            return true
        }

        let span = spans()[index]

        guard beatTime >= span.start
        else { return false }

       // inside the pickup bar

        return span.isOnBarline(beatTime)
    }

    //
    // The first barline the grid draws after `beatTime`, or `nil` if there's none (inside the
    // free bar that runs on for ever, or before the first entry).
    //
    internal func nextBarline(after beatTime: BeatTime) -> BeatTime? {
        guard let index = governingIndex(at: beatTime)
        else { return entries.first?.beatTime }

        let span = spans()[index]

        guard beatTime >= span.start
        else { return span.start }

  // inside the pickup bar

        return span.barEnd(span.barNumber(containing: beatTime))
    }

    //
    // Restores invariants 2 and 3 after a transform: a pickup that the entry at 0 can no longer
    // hold is dropped (or wrapped to its bar length), and one that runs past the second entry is
    // shortened to end there.
    //
    internal mutating func normalizePickup() {
        guard !pickup.isZero
        else { return }

        guard let first = entries.first,
              first.beatTime == .zero,
              let barLength = first.meter.barLength
        else { pickup = .zero; return }

        if pickup >= barLength {
            pickup = Meter.remainder(pickup, barLength)
        }

        if entries.count > 1,
           entries[1].beatTime < .zero + pickup {
            pickup = entries[1].beatTime - .zero
        }
    }

    //
    // The span of each entry, in order, with their bars numbered.
    //
    internal func spans() -> [Span] {
        var result: [Span] = []
        var number = 1

        for (index, entry) in entries.enumerated() {
            let end = index + 1 < entries.count ? entries[index + 1].beatTime : nil
            let start = index == 0 && entry.beatTime == .zero ? .zero + pickup : entry.beatTime
            let barCount: Int? = if let end {
                if let barLength = entry.meter.barLength {
                    ceiling((end - start).numberValue / barLength.numberValue).exact.intValue
                } else {
                    1
                }
            } else {
                nil
            }

            result.append(Span(barCount: barCount,
                               end: end,
                               entryIndex: index,
                               firstBarNumber: number,
                               meter: entry.meter,
                               start: start))

            number += barCount ?? 0
        }

        return result
    }
}

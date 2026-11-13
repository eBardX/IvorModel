// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import XestiNumbers

extension Meter {

    // MARK: Internal Type Methods

    //
    // The number of whole `length`s in `duration`, rounded down. `length` must be non-zero. Made
    // exact before converting, as `intValue` traps on an inexact number, even a whole one.
    //
    internal static func floorQuotient(_ duration: BeatDuration,
                                       _ length: BeatDuration) -> Int {
        floor(duration.numberValue / length.numberValue).exact.intValue
    }

    //
    // What's left of `duration` after taking out as many whole `length`s as fit. `length` must be
    // non-zero.
    //
    internal static func remainder(_ duration: BeatDuration,
                                   _ length: BeatDuration) -> BeatDuration {
        let quotient = floor(duration.numberValue / length.numberValue)

        return BeatDuration(duration.numberValue - quotient * length.numberValue)
    }

    // MARK: Internal Instance Methods

    //
    // The beat that a point `offset` into a full bar of this meter falls in: its index (from 0),
    // its start and its length, all measured from the start of the full bar. `nil` if this meter
    // is free, or if `offset` isn't inside one bar.
    //
    internal func beat(at offset: BeatDuration) -> (index: Int, start: BeatDuration, length: BeatDuration)? {
        var start = BeatDuration.zero

        for (index, length) in pulse.enumerated() {
            if offset < start + length {
                return (index, start, length)
            }

            start += length
        }

        return nil
    }

    //
    // The start of each beat of a full bar of this meter, measured from the start of the bar.
    // Empty if this meter is free.
    //
    internal var beatOffsets: [BeatDuration] {
        var start = BeatDuration.zero

        return pulse.map { length in
            defer { start += length }

            return start
        }
    }
}

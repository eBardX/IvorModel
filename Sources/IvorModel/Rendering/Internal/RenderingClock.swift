// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning
internal import XestiNumbers
internal import XestiTools

//
// What rendering needs to know about a work's time at a given position (in the work's own
// numbers: whole notes or seconds): how long a number of seconds lasts there, the meter and
// key in effect, and the built-in note values. A beat work answers from its tempo map, meter
// table and key table; a wall work has none of them, so seconds are its own units and it has
// no meter, no key and no written note values.
//
internal struct RenderingClock {

    // MARK: Internal Initializers

    internal init() {
        self.defaultGracePerNote = RenderingDefaults.gracePerNoteWall.duration.numberValue
        self.eighth = nil
        self.isCompound = { _ in false }
        self.key = { _ in nil }
        self.length = { seconds, _ in seconds }
        self.seconds = { from, to in to - from }
        self.subdivision = { _ in nil }
    }

    internal init(tempoMap: TempoMap,
                  meterTable: MeterTable,
                  keyTable: KeyTable) {
        let converter = TimeConverter(tempoMap: tempoMap)

        self.defaultGracePerNote = RenderingDefaults.gracePerNoteBeat.duration.numberValue
        self.eighth = Number(numerator: 1,
                             denominator: 8)
        self.isCompound = { position in
            guard let time = BeatTime(numberValue: max(position, 0)),
                  let meter = meterTable.meter(at: time),
                  meter.numerators.count == 1
            else { return false }

            let numerator = meter.numerators[0]

            return numerator > 3 && numerator.isMultiple(of: 3)
        }
        self.key = { position in
            BeatTime(numberValue: max(position, 0)).flatMap(keyTable.key(at:))
        }
        self.length = { seconds, position in
            guard let time = BeatTime(numberValue: max(position, 0))
            else { return seconds }

            let start = converter.wallTime(at: time)

            guard let end = WallTime(numberValue: start.numberValue + seconds)
            else { return seconds }

            return converter.beatTime(at: end).numberValue - time.numberValue
        }
        self.seconds = { from, to in
            guard let start = BeatTime(numberValue: max(from, 0)),
                  let end = BeatTime(numberValue: max(to, 0))
            else { return to - from }

            return converter.wallTime(at: end).numberValue - converter.wallTime(at: start).numberValue
        }
        self.subdivision = { strokes in
            Number(numerator: 1,
                   denominator: 1 << Int(strokes.uintValue + 2))
        }
    }

    // MARK: Internal Instance Properties

    //
    // How long each grace note is when nothing else says: a sixty-fourth, or 40 milliseconds.
    //
    internal let defaultGracePerNote: Number

    //
    // An eighth note, for the compound-meter appoggiatura rule; `nil` in a wall work, which has
    // no compound meter.
    //
    internal let eighth: Number?

    //
    // Whether the meter at a position is compound (6/8, 9/8, 12/8 and the like).
    //
    internal let isCompound: (Number) -> Bool

    //
    // The key at a position, for a diatonic step partner.
    //
    internal let key: (Number) -> Key?

    //
    // How long `seconds` lasts from a position, in the work's own units.
    //
    internal let length: (Number, Number) -> Number

    //
    // How many seconds pass from one position to another.
    //
    internal let seconds: (Number, Number) -> Number

    //
    // A measured tremolo's subdivision, in the work's own units; `nil` in a wall work, where
    // strokes have no tempo to follow.
    //
    internal let subdivision: (TremoloStrokes) -> Number?
}

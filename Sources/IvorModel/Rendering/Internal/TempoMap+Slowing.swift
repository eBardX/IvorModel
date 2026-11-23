// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import XestiNumbers

extension TempoMap {

    // MARK: Internal Instance Methods

    //
    // This tempo map with its speed multiplied by `factor` (less than 1 to slow down) from `start`
    // up to `end`, and as before elsewhere: a step down at `start` and a step back at `end` (two
    // entries at one time are a step). Entries between are scaled; entries at the two ends keep
    // their extras, unscaled, on the outer side of the step.
    //
    // Between two entries the speed follows an ease-in curve, so an entry added where a ramp
    // crosses `start` or `end` reshapes that ramp slightly. Where tempos change by steps, as
    // they usually do, the result is exact.
    //
    internal func slowed(from start: BeatTime,
                         to end: BeatTime,
                         by factor: Number) -> TempoMap {
        let entries = Array(self)
        var result = TempoMap(defaultTempo: defaultTempo)

        func scaled(_ tempo: Tempo) -> Tempo {
            Tempo(rate: tempo.rate * factor, unit: tempo.unit) ?? tempo
        }

        for entry in entries where entry.beatTime < start {
            result.insert(beatTime: entry.beatTime, tempo: entry.tempo, extras: entry.extras)
        }

        let atStart = entries.filter { $0.beatTime == start }

        if atStart.isEmpty {
            result.insert(beatTime: start, tempo: self[start])
        }

        for entry in atStart {
            result.insert(beatTime: start, tempo: entry.tempo, extras: entry.extras)
        }

        result.insert(beatTime: start, tempo: scaled(self[start]))

        for entry in entries where entry.beatTime > start && entry.beatTime < end {
            result.insert(beatTime: entry.beatTime, tempo: scaled(entry.tempo), extras: entry.extras)
        }

        let arrival = _tempo(approaching: end, in: entries)
        let atEnd = entries.filter { $0.beatTime == end }

        result.insert(beatTime: end, tempo: scaled(arrival))

        if atEnd.isEmpty {
            result.insert(beatTime: end, tempo: arrival)
        }

        for entry in atEnd {
            result.insert(beatTime: end, tempo: entry.tempo, extras: entry.extras)
        }

        for entry in entries where entry.beatTime > end {
            result.insert(beatTime: entry.beatTime, tempo: entry.tempo, extras: entry.extras)
        }

        return result
    }

    // MARK: Private Instance Methods

    //
    // The tempo just before `time`: the curve from the last entry before it toward the first at
    // or after it (see the tempo map's subscript), evaluated at `time`.
    //
    private func _tempo(approaching time: BeatTime,
                        in entries: [Entry]) -> Tempo {
        guard let before = entries.last(where: { $0.beatTime < time })
        else { return entries.first?.tempo ?? defaultTempo }

        guard let after = entries.first(where: { $0.beatTime >= time })
        else { return before.tempo }

        let fraction = (time - before.beatTime).numberValue / (after.beatTime - before.beatTime).numberValue
        let startSpeed = before.tempo.numberValue
        let speed = startSpeed + (after.tempo.numberValue - startSpeed) * fraction * fraction
        let unit = before.tempo.unit

        return Tempo(rate: speed / unit.numberValue, unit: unit) ?? before.tempo
    }
}

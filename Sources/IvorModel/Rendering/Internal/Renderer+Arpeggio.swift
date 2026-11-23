// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import XestiNumbers

extension Renderer {

    // MARK: Internal Instance Methods

    //
    // Rolls each arpeggio: the tones anywhere in the work that share an attack and a group
    // (resolution 13 of the grace-notes plan). They're ordered up, or down, by pitch, and each
    // next one starts a spread later — after the first, which stays on the beat, or before the
    // last, which does, for `.lastOnBeat`; notes ending at the attack then end where the roll
    // begins. Every tone is held to its end. A group whose tones disagree takes its direction
    // and execution from its first tone (lowest part, then lowest pitch).
    //
    internal mutating func rollArpeggios() {
        var rolls: [RollKey: [Int]] = [:]

        for (index, source) in sources.enumerated() {
            guard let arpeggio = source.ornamentation?.arpeggio
            else { continue }

            rolls[RollKey(group: arpeggio.group, time: source.attack), default: []].append(index)
        }

        for (key, tones) in rolls where tones.count > 1 {
            _roll(tones, at: key.time)
        }
    }

    // MARK: Private Instance Methods

    private mutating func _roll(_ tones: [Int],
                                at attack: Number) {
        guard let first = tones.min(by: { (sources[$0].part, sources[$0].startPitch) < (sources[$1].part, sources[$1].startPitch) }),
              let arpeggio = sources[first].ornamentation?.arpeggio
        else { return }

        let arpeggioRules = rules[sources[first].part].arpeggio
        let direction = arpeggio.direction ?? arpeggioRules?.direction ?? RenderingDefaults.arpeggioDirection
        let anchor = arpeggio.execution?.anchor ?? arpeggioRules?.anchor ?? RenderingDefaults.arpeggioAnchor
        let perTone = _spread(tones,
                              of: arpeggio,
                              rules: arpeggioRules,
                              at: attack)
        var ordered = tones.sorted { (sources[$0].startPitch, sources[$0].part) < (sources[$1].startPitch, sources[$1].part) }

        if direction == .down {
            ordered.reverse()
        }

        let count = ordered.count

        for (position, tone) in ordered.enumerated() {
            let steps = anchor == .firstOnBeat ? Number(position) : -Number(count - 1 - position)

            starts[tone] += steps * perTone
        }

        guard anchor == .lastOnBeat,
              let rollStart = ordered.map({ starts[$0] }).min()
        else { return }

        for part in Set(tones.map { sources[$0].part }) {
            for predecessor in releases[Moment(part: part, time: attack)] ?? [] {
                ends[predecessor] = min(ends[predecessor], rollStart)
            }
        }
    }

    //
    // How far apart a roll's tones start: its execution's spread, else the rules', else the
    // chord's shortest tone divided by its number of tones, at most 60 milliseconds. A total
    // spread is shared among the gaps between tones (resolution 9 of the grace-notes plan).
    //
    private func _spread(_ tones: [Int],
                         of arpeggio: NoteTable<TimeType, PitchType>.Arpeggio,
                         rules: ArpeggioRules?,
                         at attack: Number) -> Number {
        let shortest = tones.map { sources[$0].duration }.min() ?? 0
        let gaps = Number(tones.count - 1)

        switch arpeggio.execution?.spread {
        case let .perTone(length):
            return TimeType.number(of: length.duration)

        case let .total(share):
            return share.numberValue * shortest / gaps

        case nil:
            break
        }

        switch rules?.spread {
        case let .perTone(seconds):
            return clock.length(seconds.duration.numberValue, attack)

        case let .total(share):
            return share.numberValue * shortest / gaps

        case nil:
            return min(shortest / Number(tones.count),
                       clock.length(RenderingDefaults.arpeggioMaximumPerTone.duration.numberValue, attack))
        }
    }
}

// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning

private import Foundation
private import XestiNumbers

//
// The tolerances' functions, shared by analysis, by adding a part, and by learning a phrase to
// continue in generation (see `PhraseLearner`).
//
extension Template {

    // MARK: Internal Type Methods

    internal static func beatGrouping(_ durations: AnalysisOptions.DurationTolerance?) throws(Error)
        -> ([BeatDuration]) -> [BeatDuration: BeatDuration] {
        switch durations {
        case let .proportional(fraction):
            return { _proportionalGroups(of: $0, within: fraction) }

        case .step:
            throw .incompatibleOptions

        case nil:
            return { _ in [:] }
        }
    }

    internal static func exactRounding<P>(_ pitches: AnalysisOptions.PitchTolerance?) throws(Error) -> (P) -> P {
        guard pitches == nil
        else { throw .incompatibleOptions }

        return { $0 }
    }

    //
    // Each frequency moves to the nearest whole number of `cents` steps from A4 = 440 Hz.
    //
    internal static func frequencyRounding(_ pitches: AnalysisOptions.PitchTolerance?) -> (Frequency) -> Frequency {
        switch pitches {
        case let .cents(cents):
            { frequency in
                let steps = (1_200 * log2(frequency.doubleValue / 440) / cents).rounded()
                let rounded = 440 * pow(2, steps * cents / 1_200)

                return Frequency(numberValue: Number(floatLiteral: rounded)) ?? frequency
            }

        case nil:
            { $0 }
        }
    }

    //
    // Pitches that round to the same pitch become one; the first, in the event's order, keeps
    // its ties.
    //
    internal static func roundedPitches<T, P>(_ tiedPitches: [NoteEvent<T, P>.TiedPitch],
                                              with rounding: (P) -> P) -> [NoteEvent<T, P>.TiedPitch] {
        var seen: Set<P> = []

        return tiedPitches.compactMap { tiedPitch in
            let pitch = rounding(tiedPitch.pitch)

            guard seen.insert(pitch).inserted
            else { return nil }

            return NoteEvent<T, P>.TiedPitch(pitch: pitch,
                                             startsTie: tiedPitch.startsTie,
                                             endsTie: tiedPitch.endsTie)
        }
    }

    //
    // A step rounds each duration to the nearest whole number of steps, but never below one.
    //
    internal static func wallGrouping(_ durations: AnalysisOptions.DurationTolerance?) -> ([WallDuration]) -> [WallDuration: WallDuration] {
        switch durations {
        case let .proportional(fraction):
            { _proportionalGroups(of: $0, within: fraction) }

        case let .step(step):
            { durations in
                var representatives: [WallDuration: WallDuration] = [:]

                for duration in Set(durations) {
                    let steps = max(1, (duration.uintValue + step.uintValue / 2) / step.uintValue)

                    representatives[duration] = WallDuration(uintValue: steps * step.uintValue) ?? duration
                }

                return representatives
            }

        case nil:
            { _ in [:] }
        }
    }

    // MARK: Private Type Methods

    //
    // Groups the distinct durations, shortest first, so that the longest in each group is at most
    // `1 + fraction` times the shortest, and maps each to its group's most common duration — the
    // shortest of those, on a tie.
    //
    private static func _proportionalGroups<D: DurationProtocol>(of durations: [D],
                                                                 within fraction: Double) -> [D: D] {
        var counts: [D: Int] = [:]

        for duration in durations {
            counts[duration, default: 0] += 1
        }

        let ratio = Number(floatLiteral: 1 + fraction)
        var groups: [[D]] = []

        for duration in counts.keys.sorted() {
            if let shortest = groups.last?.first,
               let limit = shortest.multiplied(by: ratio),
               duration <= limit {
                groups[groups.count - 1].append(duration)
            } else {
                groups.append([duration])
            }
        }

        var representatives: [D: D] = [:]

        for group in groups {
            var best = group[0]

            for duration in group where counts[duration, default: 0] > counts[best, default: 0] {
                best = duration
            }

            for duration in group {
                representatives[duration] = best
            }
        }

        return representatives
    }
}

// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

private import IvorTiming
private import IvorTuning

extension NoteTable {

    // MARK: Internal Type Methods

    internal static func hasExtras(in notes: [Note]) -> Bool {
        notes.contains { $0.extras != nil }
    }

    internal static func hasPortamento(in notes: [Note]) -> Bool {
        notes.contains { $0.startPitch != $0.endPitch }
    }

    internal static func isMonophonic(in notes: [Note]) -> Bool {
        guard !notes.isEmpty
        else { return true }

        var prevRelease = TimeType.zero

        for note in notes {
            if note.attack < prevRelease {
                return false
            }

            prevRelease = note.release
        }

        return true
    }

    internal static func pitchRange(in notes: [Note]) -> ClosedRange<PitchType>? {
        guard !notes.isEmpty
        else { return nil }

        var maxPitch = notes[0].maximumPitch
        var minPitch = notes[0].minimumPitch

        for note in notes {
            if minPitch > note.minimumPitch {
                minPitch = note.minimumPitch
            }

            if maxPitch < note.maximumPitch {
                maxPitch = note.maximumPitch
            }
        }

        return minPitch...maxPitch
    }

    internal static func timeRange(in notes: [Note]) -> ClosedRange<TimeType>? {
        guard !notes.isEmpty
        else { return nil }

        var maxTime = notes[0].release
        var minTime = notes[0].attack

        for note in notes {
            if minTime > note.attack {
                minTime = note.attack
            }

            if maxTime < note.release {
                maxTime = note.release
            }
        }

        return minTime...maxTime
    }

    internal static func mergePitchRanges(_ range1: ClosedRange<PitchType>,
                                          _ range2: ClosedRange<PitchType>) -> ClosedRange<PitchType> {
        min(range1.lowerBound, range2.lowerBound)...max(range1.upperBound, range2.upperBound)
    }

    internal static func mergeTimeRanges(_ range1: ClosedRange<TimeType>,
                                         _ range2: ClosedRange<TimeType>) -> ClosedRange<TimeType> {
        min(range1.lowerBound, range2.lowerBound)...max(range1.upperBound, range2.upperBound)
    }

    // MARK: Internal Instance Methods

    internal func firstIndex(attack: TimeType,
                             duration: DurationType,
                             startPitch: PitchType,
                             endPitch: PitchType,
                             extras: Extras?) -> Int? {
        notes.firstIndex {
            (attack, duration, startPitch, endPitch, extras) == ($0.attack, $0.duration, $0.startPitch, $0.endPitch, $0.extras)
        }
    }

    internal func insertionIndex(for attack: TimeType,
                                 duration: DurationType,
                                 startPitch: PitchType,
                                 endPitch: PitchType) -> Int {
        notes.firstIndex {
            (attack, duration, $0.startPitch, $0.endPitch) < ($0.attack, $0.duration, startPitch, endPitch)
        } ?? notes.endIndex
    }
}

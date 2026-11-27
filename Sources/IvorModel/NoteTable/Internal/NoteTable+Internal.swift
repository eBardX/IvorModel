// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

private import IvorTiming
private import IvorTuning

extension NoteTable {

    // MARK: Internal Type Methods

    internal static func hasExtras(in notes: [StoredNote]) -> Bool {
        notes.contains { $0.extras != nil }
    }

    internal static func hasOrnamentation(in notes: [StoredNote]) -> Bool {
        notes.contains { $0.ornamentation != nil }
    }

    //
    // A step partner’s written pitch must lie strictly on its side of the note’s start pitch
    // (resolution 19 of the grace-notes plan): a contradiction is an error, never silently
    // reinterpreted.
    //
    internal static func hasPartnerOnWrongSide(_ ornamentation: Ornamentation?,
                                               startPitch: PitchType) -> Bool {
        guard case let .step(side, written?) = ornamentation?.ornament?.partner
        else { return false }

        switch side {
        case .above:
            return written <= startPitch

        case .below:
            return written >= startPitch
        }
    }

    internal static func hasPortamento(in notes: [StoredNote]) -> Bool {
        notes.contains { $0.startPitch != $0.endPitch }
    }

    internal static func isMonophonic(in notes: [StoredNote]) -> Bool {
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

    internal static func mergePitchRanges(_ range1: ClosedRange<PitchType>,
                                          _ range2: ClosedRange<PitchType>) -> ClosedRange<PitchType> {
        Swift.min(range1.lowerBound, range2.lowerBound)...Swift.max(range1.upperBound, range2.upperBound)
    }

    internal static func mergeTimeRanges(_ range1: ClosedRange<TimeType>,
                                         _ range2: ClosedRange<TimeType>) -> ClosedRange<TimeType> {
        Swift.min(range1.lowerBound, range2.lowerBound)...Swift.max(range1.upperBound, range2.upperBound)
    }

    internal static func pitchRange(in notes: [StoredNote]) -> ClosedRange<PitchType>? {
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

    internal static func timeRange(in notes: [StoredNote]) -> ClosedRange<TimeType>? {
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

    // MARK: Internal Instance Methods

    internal func firstIndex(noteID: NoteID) -> Int? {
        notes.firstIndex { $0.noteID == noteID }
    }

    internal func insertionIndex(for attack: TimeType,
                                 duration: DurationType,
                                 startPitch: PitchType,
                                 endPitch: PitchType) -> Int {
        notes.partitioningIndex {
            (attack, duration, $0.startPitch, $0.endPitch) < ($0.attack, $0.duration, startPitch, endPitch)
        }
    }

    //
    // This table with every note under a fresh identity, and otherwise unchanged. Note order
    // doesn't depend on identity, so the notes stay in order.
    //
    internal func renewingNoteIDs() -> Self {
        var table = self

        table.notes = notes.map { $0.renewingNoteID() }

        return table
    }
}

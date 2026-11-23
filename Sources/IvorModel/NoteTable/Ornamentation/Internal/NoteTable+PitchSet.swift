// © 2026 John Gary Pusey (see LICENSE.md)

extension NoteTable {

    // MARK: Internal Type Methods

    // Whether `pitches` is a valid pitch list for a grace event or a partner:
    // non-empty, sorted ascending, with no duplicates.
    internal static func isPitchSet(_ pitches: [PitchType]) -> Bool {
        !pitches.isEmpty && zip(pitches, pitches.dropFirst()).allSatisfy { $0 < $1 }
    }

    // `pitches` as a valid pitch list: sorted ascending, with duplicates
    // removed. A mapping can reorder pitches (an inversion) or make two equal
    // (an enharmonic collapse), so every `mapPitches(_:)` ends here.
    internal static func pitchSet(_ pitches: [PitchType]) -> [PitchType] {
        Array(Set(pitches)).sorted()
    }
}

// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import XestiTools

extension KeyTable {

    // MARK: Internal Type Methods

    internal static func hasExtras(in entries: [StoredEntry]) -> Bool {
        entries.contains { $0.extras != nil }
    }

    // MARK: Internal Instance Methods

    internal func entryIndex(at beatTime: BeatTime) -> Int? {
        let index = entries.partitioningIndex { beatTime <= $0.beatTime }

        return index < entries.endIndex && entries[index].beatTime == beatTime ? index : nil
    }

    internal func firstIndex(entryID: EntryID) -> Int? {
        entries.firstIndex { $0.entryID == entryID }
    }

    //
    // The index of the entry in effect at `beatTime`: the last at or before it.
    //
    internal func governingIndex(at beatTime: BeatTime) -> Int? {
        let index = entries.partitioningIndex { beatTime < $0.beatTime }

        return index > entries.startIndex ? index - 1 : nil
    }

    internal func insertionIndex(for beatTime: BeatTime) -> Int {
        entries.partitioningIndex { beatTime < $0.beatTime }
    }
}

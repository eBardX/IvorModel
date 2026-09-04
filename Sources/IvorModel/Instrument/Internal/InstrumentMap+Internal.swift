// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

extension InstrumentMap {

    // MARK: Internal Type Methods

    //
    // Keeps the first occurrence of each exact duplicate (same time, instrument,
    // and extras — `Entry`'s own `==` already excludes identity) and drops the
    // rest, matching the rule `insert(time:instrument:extras:)` applies to a live
    // instrument map.
    //
    internal static func deduplicated(_ entries: [Entry]) -> [Entry] {
        var result: [Entry] = []

        for entry in entries where !result.contains(entry) {
            result.append(entry)
        }

        return result
    }

    internal static func hasExtras(in entries: [Entry]) -> Bool {
        entries.contains { $0.extras != nil }
    }

    // MARK: Internal Instance Methods

    internal func firstIndex(time: TimeType,
                             instrument: Instrument,
                             extras: Extras?) -> Int? {
        entries.firstIndex {
            (time, instrument, extras) == ($0.time, $0.instrument, $0.extras)
        }
    }

    internal func firstIndex(entryID: EntryID) -> Int? {
        entries.firstIndex { $0.entryID == entryID }
    }

    internal func insertionIndex(for time: TimeType) -> Int {
        entries.firstIndex { time < $0.time } ?? entries.endIndex
    }
}

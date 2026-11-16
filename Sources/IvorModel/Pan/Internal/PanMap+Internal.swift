// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

extension PanMap {

    // MARK: Internal Type Methods

    //
    // Keeps the first occurrence of each exact duplicate (same time, pan position,
    // and extras — `StoredEntry`'s own `==` already excludes identity) and drops the
    // rest, matching the rule `insert(time:pan:extras:)` applies to a live pan map.
    //
    internal static func deduplicated(_ entries: [StoredEntry]) -> [StoredEntry] {
        var result: [StoredEntry] = []

        for entry in entries where !result.contains(entry) {
            result.append(entry)
        }

        return result
    }

    internal static func hasExtras(in entries: [StoredEntry]) -> Bool {
        entries.contains { $0.extras != nil }
    }

    // MARK: Internal Instance Methods

    internal func firstIndex(entryID: EntryID) -> Int? {
        entries.firstIndex { $0.entryID == entryID }
    }

    //
    // Entries are sorted by time, so only the run of entries at `time` can match.
    //
    internal func firstIndex(time: TimeType,
                             pan: Pan,
                             extras: Extras?) -> Int? {
        let start = entries.partitioningIndex { time <= $0.time }

        return entries[start...].prefix { $0.time == time }.firstIndex {
            (pan, extras) == ($0.pan, $0.extras)
        }
    }

    internal func insertionIndex(for time: TimeType) -> Int {
        entries.partitioningIndex { time < $0.time }
    }
}

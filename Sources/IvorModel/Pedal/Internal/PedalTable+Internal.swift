// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import XestiTools

extension PedalTable {

    // MARK: Internal Type Methods

    //
    // Drops each entry identical to the one just before it (same time, level, and extras —
    // `StoredEntry`'s own `==` already excludes identity), matching the rule
    // `insert(time:level:extras:)` applies to a live pedal table. Only neighbors fold: in On, Off,
    // On at one time, the second On is what puts the pedal back down.
    //
    internal static func deduplicated(_ entries: [StoredEntry]) -> [StoredEntry] {
        var result: [StoredEntry] = []

        for entry in entries where result.last != entry {
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

    internal func insertionIndex(for time: TimeType) -> Int {
        entries.firstIndex { time < $0.time } ?? entries.endIndex
    }

    //
    // This table with every entry's time converted, as between beat and wall time. The entries
    // keep their order, levels and extras, so a re-pedal survives; `transform` must not reorder
    // times.
    //
    internal func mapTimes<NewTimeType: TimeProtocol>(_ transform: (TimeType) -> NewTimeType) -> PedalTable<NewTimeType> {
        PedalTable<NewTimeType>(entries: entries.map { entry in
            PedalTable<NewTimeType>.StoredEntry(time: transform(entry.time),
                                                level: entry.level,
                                                extras: entry.extras)
        })
    }
}

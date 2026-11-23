// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import XestiTools

extension PartMarkTable {

    // MARK: Internal Type Methods

    //
    // Drops each entry identical to the one just before it (same time and mark — `StoredEntry`'s
    // own `==` already excludes identity), matching the rule `insert(time:mark:)` applies to a
    // live table.
    //
    internal static func deduplicated(_ entries: [StoredEntry]) -> [StoredEntry] {
        var result: [StoredEntry] = []

        for entry in entries where result.last != entry {
            result.append(entry)
        }

        return result
    }

    // MARK: Internal Instance Methods

    //
    // This table with every entry's time converted, as between beat and wall time, and each
    // mark's lengths in the work's own time — a fermata's span, an added hold or pause —
    // converted as starting at the mark (see `FermataConverter.init(at:times:)`). The entries
    // keep their order; `times` must not reorder them. A mark whose length converts to zero,
    // which a positive tempo never gives, is dropped.
    //
    internal func convertedTimes<NewTimeType: TimeProtocol>(_ times: @escaping (TimeType) -> NewTimeType) -> PartMarkTable<NewTimeType> {
        PartMarkTable<NewTimeType>(entries: entries.compactMap { entry in
            guard let mark = try? FermataConverter(at: entry.time,
                                                   times: times).partMark(entry.mark)
            else { return nil }

            return PartMarkTable<NewTimeType>.StoredEntry(time: times(entry.time),
                                                          mark: mark)
        })
    }

    internal func firstIndex(entryID: EntryID) -> Int? {
        entries.firstIndex { $0.entryID == entryID }
    }

    internal func insertionIndex(for time: TimeType) -> Int {
        entries.partitioningIndex { time < $0.time }
    }
}

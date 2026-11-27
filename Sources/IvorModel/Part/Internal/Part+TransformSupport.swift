// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning

//
// What `Part`'s transforms share for carrying a transform across the part's strands: each
// strand's notes, and the part's dynamic map and instrument table together with every strand's
// own.
//
extension Part {

    // MARK: Internal Type Aliases

    internal typealias DynamicFailure = DynamicMap<TimeType>.Error

    internal typealias DynamicsAndStrands = (DynamicMap<TimeType>, [Strand<TimeType, PitchType>])

    internal typealias DynamicTransform = (inout DynamicMap<TimeType>, Set<EntryID>?) throws(DynamicMap<TimeType>.Error) -> Void

    internal typealias InstrumentFailure = InstrumentTable<TimeType>.Error

    internal typealias InstrumentsAndStrands = (InstrumentTable<TimeType>, [Strand<TimeType, PitchType>])

    internal typealias InstrumentTransform = (inout InstrumentTable<TimeType>, Set<EntryID>?) throws(InstrumentTable<TimeType>.Error) -> Void

    internal typealias NoteFailure = NoteTable<TimeType, PitchType>.Error

    internal typealias NoteTransform = (inout NoteTable<TimeType, PitchType>) throws(NoteTable<TimeType, PitchType>.Error) -> Void

    // MARK: Internal Type Methods

    //
    // The entries of `map` a transform of the chosen notes carries: every entry when no notes are
    // chosen (`nil`), else those inside the chosen notes' time range (none when it's `nil`).
    //
    internal static func entryIDs(of map: DynamicMap<TimeType>,
                                  noteIDs: Set<NoteID>?,
                                  in range: ClosedRange<TimeType>?) -> Set<EntryID>? {
        guard noteIDs != nil
        else { return nil }

        guard let range
        else { return [] }

        return Set(map.filter { range.contains($0.time) }.map(\.entryID))
    }

    //
    // The entries of `table` a transform of the chosen notes carries, as for a dynamic map.
    //
    internal static func entryIDs(of table: InstrumentTable<TimeType>,
                                  noteIDs: Set<NoteID>?,
                                  in range: ClosedRange<TimeType>?) -> Set<EntryID>? {
        guard noteIDs != nil
        else { return nil }

        guard let range
        else { return [] }

        return Set(table.filter { range.contains($0.time) }.map(\.entryID))
    }

    // MARK: Internal Instance Methods

    //
    // The first and last entry times of the dynamic maps and instrument tables, the part's and
    // its strands' own, that `applyTo` selects.
    //
    internal func ownTableBounds(applyTo: TransformTargets) -> [TimeType] {
        var bounds: [TimeType] = []

        if applyTo.contains(.dynamic) {
            for map in [dynamicMap] + strands.compactMap(\.dynamicMap) {
                if let first = map.first,
                   let last = map.last {
                    bounds += [first.time, last.time]
                }
            }
        }

        if applyTo.contains(.instrument) {
            for table in [instrumentTable] + strands.compactMap(\.instrumentTable) {
                if let first = table.first,
                   let last = table.last {
                    bounds += [first.time, last.time]
                }
            }
        }

        return bounds
    }

    //
    // The time range of the chosen notes, across every strand, or of all notes when none are
    // chosen (`nil`).
    //
    internal func selectedTimeRange(noteIDs: Set<NoteID>?) -> ClosedRange<TimeType>? {
        strands.compactMap { $0.noteTable.selectedTimeRange(noteIDs: noteIDs) }.reduce(nil) { acc, range in
            acc.map { NoteTable<TimeType, PitchType>.mergeTimeRanges($0, range) } ?? range
        }
    }

    //
    // The part's dynamic map, and every strand's own, transformed by `transform` with the
    // entries each carries for the chosen notes. A failure in any of them is the part's.
    //
    internal func transformingDynamicMaps(of strands: [Strand<TimeType, PitchType>],
                                          noteIDs: Set<NoteID>?,
                                          _ transform: DynamicTransform) throws(Error) -> DynamicsAndStrands {
        let range = selectedTimeRange(noteIDs: noteIDs)
        var partMap = dynamicMap
        var newStrands = strands

        do {
            try transform(&partMap, Self.entryIDs(of: dynamicMap, noteIDs: noteIDs, in: range))

            for index in newStrands.indices {
                guard var map = newStrands[index].dynamicMap
                else { continue }

                try transform(&map, Self.entryIDs(of: map, noteIDs: noteIDs, in: range))

                newStrands[index].dynamicMap = map
            }
        } catch {
            throw Error.dynamicMapFailure(error)
        }

        return (partMap, newStrands)
    }

    //
    // The part's instrument table, and every strand's own, transformed by `transform` with the
    // entries each carries for the chosen notes. A failure in any of them is the part's.
    //
    internal func transformingInstrumentTables(of strands: [Strand<TimeType, PitchType>],
                                               noteIDs: Set<NoteID>?,
                                               _ transform: InstrumentTransform) throws(Error) -> InstrumentsAndStrands {
        let range = selectedTimeRange(noteIDs: noteIDs)
        var partTable = instrumentTable
        var newStrands = strands

        do {
            try transform(&partTable, Self.entryIDs(of: instrumentTable, noteIDs: noteIDs, in: range))

            for index in newStrands.indices {
                guard var table = newStrands[index].instrumentTable
                else { continue }

                try transform(&table, Self.entryIDs(of: table, noteIDs: noteIDs, in: range))

                newStrands[index].instrumentTable = table
            }
        } catch {
            throw Error.instrumentTableFailure(error)
        }

        return (partTable, newStrands)
    }

    //
    // Every strand with its notes transformed by `transform`, each with every chosen note it
    // holds (a strand without any is left as it is, since the note tables ignore IDs they don't
    // have). Nothing is assigned until every strand has succeeded.
    //
    internal func transformingNotes(_ transform: NoteTransform) throws(Error) -> [Strand<TimeType, PitchType>] {
        var newStrands = strands

        for index in newStrands.indices {
            do {
                try transform(&newStrands[index].noteTable)
            } catch {
                throw Error.noteTableFailure(error)
            }
        }

        return newStrands
    }
}

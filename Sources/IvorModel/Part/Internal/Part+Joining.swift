// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning
internal import XestiTools

//
// What `Work`'s extract and join operations ask of a part.
//
extension Part {

    // MARK: Internal Instance Methods

    //
    // This part with the strand at `index` taken out, and a new part holding it: a copy of this
    // part's tables, rules and extras, with the strand's own instrument table and dynamic map,
    // if any, as its own. The strand keeps its ID, and its notes theirs; its arpeggio groups
    // are renumbered from 1. The new part takes the strand's name, or this part's when the
    // strand has none.
    //
    internal func extractingStrand(at index: Int) -> (remaining: Self, extracted: Self) {
        var remaining = self
        let strand = remaining.strands.remove(at: index)
        let extracted = Self(partID: PartID(),
                             name: strand.name.isEmpty ? name : strand.name,
                             strands: [Strand(strandID: strand.strandID,
                                              name: strand.name,
                                              noteTable: strand.noteTable,
                                              instrumentTable: nil,
                                              dynamicMap: nil,
                                              extras: strand.extras)],
                             dynamicMap: strand.dynamicMap ?? dynamicMap,
                             instrumentTable: strand.instrumentTable ?? instrumentTable,
                             panMap: panMap,
                             pedals: pedals,
                             markTable: markTable,
                             interpretationRules: interpretationRules,
                             extras: extras)

        return (remaining, extracted.regroupingArpeggios(from: ArpeggioGroup(uintValue: 1).require()))
    }

    //
    // This part with `other`'s strands appended, in order, and the kinds of `other`'s tables
    // that were dropped. This part keeps its name, tables, rules and extras.
    //
    // - `other`'s dynamic map and instrument table become the own tables of its strands that
    //   have none, unless they're the same as this part's.
    // - `other`'s pan map, mark table and each pedal table are dropped if they're the same as
    //   this part's, or adopted if this part's is empty; otherwise this part's win, and the
    //   kind is reported as dropped.
    // - `other`'s arpeggio groups are renumbered above this part's, so rolls from the two never
    //   meet.
    //
    internal func joining(_ other: Self) -> (part: Self, dropped: TransformTargets) {
        let other = other.regroupingArpeggios(from: unusedArpeggioGroup)
        let otherDynamics = Self._sameEntries(dynamicMap, other.dynamicMap) ? nil : other.dynamicMap
        let otherInstruments = Self._sameEntries(instrumentTable, other.instrumentTable) ? nil : other.instrumentTable
        var part = self
        var dropped: TransformTargets = []

        for var strand in other.strands {
            strand.dynamicMap = strand.dynamicMap ?? otherDynamics
            strand.instrumentTable = strand.instrumentTable ?? otherInstruments

            part.strands.append(strand)
        }

        if !Self._sameEntries(panMap, other.panMap) {
            if panMap.isEmpty {
                part.panMap = other.panMap
            } else if !other.panMap.isEmpty {
                dropped.insert(.pan)
            }
        }

        if !Self._sameEntries(markTable, other.markTable) {
            if markTable.isEmpty {
                part.markTable = other.markTable
            } else if !other.markTable.isEmpty {
                dropped.insert(.mark)
            }
        }

        for (pedal, table) in other.pedals {
            if let mine = pedals[pedal] {
                if !Self._sameEntries(mine, table) {
                    dropped.insert(.pedal)
                }
            } else {
                part.pedals[pedal] = table
            }
        }

        return (part, dropped)
    }

    // MARK: Private Type Methods

    //
    // Whether two tables have the same entries, apart from their entry IDs.
    //
    private static func _sameEntries(_ lhs: DynamicMap<TimeType>,
                                     _ rhs: DynamicMap<TimeType>) -> Bool {
        lhs.map(\.time) == rhs.map(\.time) && lhs.map(\.dynamic) == rhs.map(\.dynamic) && lhs.map(\.extras) == rhs.map(\.extras)
    }

    private static func _sameEntries(_ lhs: InstrumentTable<TimeType>,
                                     _ rhs: InstrumentTable<TimeType>) -> Bool {
        lhs.map(\.time) == rhs.map(\.time) && lhs.map(\.instrument) == rhs.map(\.instrument) && lhs.map(\.extras) == rhs.map(\.extras)
    }

    private static func _sameEntries(_ lhs: PanMap<TimeType>,
                                     _ rhs: PanMap<TimeType>) -> Bool {
        lhs.map(\.time) == rhs.map(\.time) && lhs.map(\.pan) == rhs.map(\.pan) && lhs.map(\.extras) == rhs.map(\.extras)
    }

    private static func _sameEntries(_ lhs: PartMarkTable<TimeType>,
                                     _ rhs: PartMarkTable<TimeType>) -> Bool {
        lhs.map(\.time) == rhs.map(\.time) && lhs.map(\.mark) == rhs.map(\.mark)
    }

    private static func _sameEntries(_ lhs: PedalTable<TimeType>,
                                     _ rhs: PedalTable<TimeType>) -> Bool {
        lhs.map(\.time) == rhs.map(\.time) && lhs.map(\.level) == rhs.map(\.level) && lhs.map(\.extras) == rhs.map(\.extras)
    }
}

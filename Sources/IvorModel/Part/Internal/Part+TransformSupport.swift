// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning

//
// What `Part`'s transforms share: the table rule, which decides how much of each table a
// transform carries (`carryPlan(for:applyTo:alsoCarry:)`), and the one place that applies a
// transform to the chosen notes and the tables the plan carries (`applying(_:notes:...)`).
//
extension Part {

    // MARK: Internal Type Aliases

    internal typealias DynamicFailure = DynamicMap<TimeType>.Error

    internal typealias DynamicTransform = (inout DynamicMap<TimeType>, Set<EntryID>?) throws(DynamicMap<TimeType>.Error) -> Void

    internal typealias InstrumentFailure = InstrumentTable<TimeType>.Error

    internal typealias InstrumentTransform = (inout InstrumentTable<TimeType>, Set<EntryID>?) throws(InstrumentTable<TimeType>.Error) -> Void

    internal typealias MarkFailure = PartMarkTable<TimeType>.Error

    internal typealias MarkTransform = (inout PartMarkTable<TimeType>, Set<EntryID>?) throws(PartMarkTable<TimeType>.Error) -> Void

    internal typealias NoteFailure = NoteTable<TimeType, PitchType>.Error

    internal typealias NoteTransform = (inout NoteTable<TimeType, PitchType>, Set<NoteID>?) throws(NoteTable<TimeType, PitchType>.Error) -> Void

    internal typealias PanFailure = PanMap<TimeType>.Error

    internal typealias PanTransform = (inout PanMap<TimeType>, Set<EntryID>?) throws(PanMap<TimeType>.Error) -> Void

    internal typealias PedalFailure = PedalTable<TimeType>.Error

    internal typealias PedalTransform = (inout PedalTable<TimeType>, Set<EntryID>?) throws(PedalTable<TimeType>.Error) -> Void

    // MARK: Internal Instance Methods

    //
    // Applies `notes` to every chosen note of `plan`, strand by strand, and each table transform
    // to the tables `plan` carries, with the entries it carries of each. All or nothing: nothing
    // is assigned until every strand and table has succeeded. A table transform left out does
    // nothing (the pitch transforms carry no table).
    //
    internal mutating func applying(_ plan: CarryPlan,
                                    notes: NoteTransform,
                                    dynamics: DynamicTransform = { _, _ in },
                                    instruments: InstrumentTransform = { _, _ in },
                                    pan: PanTransform = { _, _ in },
                                    pedals pedalTransform: PedalTransform = { _, _ in },
                                    marks: MarkTransform = { _, _ in }) throws(Error) {
        var newStrands = strands

        for index in newStrands.indices {
            guard let selection = plan.strandSelections[index]
            else { continue }

            do {
                try notes(&newStrands[index].noteTable, selection.noteIDs)
            } catch {
                throw Error.noteTableFailure(error)
            }
        }

        var newDynamicMap = dynamicMap
        var newInstrumentTable = instrumentTable
        var newPanMap = panMap
        var newPedals = pedals
        var newMarkTable = markTable

        do {
            try Work.TableCarry.apply(plan.dynamics, to: &newDynamicMap, dynamics)
            try Self._applying(plan.strandDynamics, to: &newStrands, at: \.dynamicMap, dynamics)
        } catch {
            throw Error.dynamicMapFailure(error)
        }

        do {
            try Work.TableCarry.apply(plan.instruments, to: &newInstrumentTable, instruments)
            try Self._applying(plan.strandInstruments, to: &newStrands, at: \.instrumentTable, instruments)
        } catch {
            throw Error.instrumentTableFailure(error)
        }

        do {
            try Work.TableCarry.apply(plan.pan, to: &newPanMap, pan)
        } catch {
            throw Error.panMapFailure(error)
        }

        for (pedal, table) in pedals {
            var newTable = table

            do {
                try Work.TableCarry.apply(plan.pedals[pedal] ?? .none, to: &newTable, pedalTransform)
            } catch {
                throw Error.pedalTableFailure(pedal, error)
            }

            newPedals[pedal] = newTable
        }

        do {
            try Work.TableCarry.apply(plan.marks, to: &newMarkTable, marks)
        } catch {
            throw Error.markTableFailure(error)
        }

        strands = newStrands
        dynamicMap = newDynamicMap
        instrumentTable = newInstrumentTable
        panMap = newPanMap
        pedals = newPedals
        markTable = newMarkTable
    }

    //
    // The table rule: a transform carries a table only when `selection` covers everything that
    // shares it, and `applyTo` names its kind.
    //
    // - Pedals, pan and marks are shared by every strand, so they need the whole part.
    // - The part's dynamic map and instrument table are shared by the strands without their own,
    //   so they need every one of those strands whole (or the whole part).
    // - A strand's own dynamic map or instrument table is that strand's alone: a whole strand
    //   carries all of it, some of its notes the entries within their time range.
    //
    // A shared table `selection` doesn't cover is carried anyway when `alsoCarry` names its kind
    // (and so does `applyTo`): all of it when the selection takes only whole strands, else the
    // entries within the chosen notes' time range. A pedal table also gives up the entry that
    // ends a press under way at the end of that range (see `PedalTable.pressEnd(after:)`), so a
    // moved press keeps its release.
    //
    internal func carryPlan(for selection: Work.PartSelection,
                            applyTo: TransformTargets,
                            alsoCarry: TransformTargets) -> CarryPlan {
        let strandSelections = strands.map { strand -> Work.StrandSelection? in
            switch selection {
            case let .strands(strandSelections):
                strandSelections[strand.strandID]

            case .whole:
                .whole
            }
        }
        let strandRanges = zip(strands, strandSelections).map { strand, strandSelection in
            strandSelection.flatMap { strand.noteTable.selectedTimeRange(noteIDs: $0.noteIDs) }
        }
        let rule = TableRule(applyTo: applyTo,
                             alsoCarry: alsoCarry,
                             noteTimeRange: Self._merged(strandRanges),
                             strandRanges: strandRanges,
                             strandSelections: strandSelections)
        let isWhole = selection == .whole

        //
        // The part's own tables are covered by the whole part, or by every strand that uses
        // them (there must be one) taken whole.
        //
        func coversUsers(of hasOwn: (Strand<TimeType, PitchType>) -> Bool) -> Bool {
            let users = strands.indices.filter { !hasOwn(strands[$0]) }

            return isWhole || (!users.isEmpty && users.allSatisfy { strandSelections[$0] == .whole })
        }

        let dynamics = rule.shared(.dynamic, covered: coversUsers { $0.dynamicMap != nil }) {
            Self._entryIDs(dynamicMap.map { ($0.entryID, $0.time) }, in: $0)
        }
        let instruments = rule.shared(.instrument, covered: coversUsers { $0.instrumentTable != nil }) {
            Self._entryIDs(instrumentTable.map { ($0.entryID, $0.time) }, in: $0)
        }
        let marks = rule.shared(.mark, covered: isWhole) {
            Self._entryIDs(markTable.map { ($0.entryID, $0.time) }, in: $0)
        }
        let pan = rule.shared(.pan, covered: isWhole) {
            Self._entryIDs(panMap.map { ($0.entryID, $0.time) }, in: $0)
        }

        return CarryPlan(dynamics: dynamics,
                         instruments: instruments,
                         marks: marks,
                         noteTimeRange: rule.noteTimeRange,
                         pan: pan,
                         pedals: pedals.mapValues { table in
                             rule.shared(.pedal, covered: isWhole) { range in
                                 var entryIDs = Self._entryIDs(table.map { ($0.entryID, $0.time) }, in: range)

                                 if let pressEnd = table.pressEnd(after: range) {
                                     entryIDs.insert(pressEnd)
                                 }

                                 return entryIDs
                             }
                         },
                         strandDynamics: strands.indices.map { index in
                             guard let map = strands[index].dynamicMap
                             else { return .none }

                             return rule.own(.dynamic, at: index) { Self._entryIDs(map.map { ($0.entryID, $0.time) }, in: $0) }
                         },
                         strandInstruments: strands.indices.map { index in
                             guard let table = strands[index].instrumentTable
                             else { return .none }

                             return rule.own(.instrument, at: index) { Self._entryIDs(table.map { ($0.entryID, $0.time) }, in: $0) }
                         },
                         strandSelections: strandSelections)
    }

    //
    // What a `noteIDs:` argument to one of `Part`'s public transforms takes: the whole part for
    // `nil`, else just those notes, in whichever strands hold them.
    //
    internal func selection(for noteIDs: Set<NoteID>?) -> Work.PartSelection {
        guard let noteIDs
        else { return .whole }

        var strandSelections: [StrandID: Work.StrandSelection] = [:]

        for strand in strands {
            let held = Set(strand.noteTable.map(\.noteID)).intersection(noteIDs)

            if !held.isEmpty {
                strandSelections[strand.strandID] = .notes(held)
            }
        }

        return .strands(strandSelections)
    }

    //
    // The pitch range of the notes `selection` takes, across every strand.
    //
    internal func selectedPitchRange(for selection: Work.PartSelection) -> ClosedRange<PitchType>? {
        let plan = carryPlan(for: selection, applyTo: [], alsoCarry: [])
        let ranges = zip(strands, plan.strandSelections).compactMap { strand, strandSelection in
            strandSelection.flatMap { strand.noteTable.selectedPitchRange(noteIDs: $0.noteIDs) }
        }

        guard let lowerBound = ranges.map(\.lowerBound).min(),
              let upperBound = ranges.map(\.upperBound).max()
        else { return nil }

        return lowerBound...upperBound
    }

    //
    // The one range a time transform's default resolves from, so the notes and every table it
    // carries scale or mirror about the same point: the chosen notes' range, widened by every
    // table `plan` carries all of. (A table carried only in part carries entries within the
    // notes' range, give or take a pedal release.)
    //
    internal func transformTimeRange(_ plan: CarryPlan) -> ClosedRange<TimeType>? {
        var ranges: [ClosedRange<TimeType>?] = [plan.noteTimeRange]

        func add(_ carry: Work.TableCarry, _ times: [TimeType]) {
            guard carry == .all,
                  let first = times.min(),
                  let last = times.max()
            else { return }

            ranges.append(first...last)
        }

        add(plan.dynamics, dynamicMap.map(\.time))
        add(plan.instruments, instrumentTable.map(\.time))

        for index in strands.indices {
            add(plan.strandDynamics[index], strands[index].dynamicMap?.map(\.time) ?? [])
            add(plan.strandInstruments[index], strands[index].instrumentTable?.map(\.time) ?? [])
        }

        add(plan.pan, panMap.map(\.time))

        for (pedal, table) in pedals {
            add(plan.pedals[pedal] ?? .none, table.map(\.time))
        }

        add(plan.marks, markTable.timeRange.map { [$0.lowerBound, $0.upperBound] } ?? [])

        return Self._merged(ranges)
    }

    // MARK: Private Type Methods

    //
    // Applies `transform` to each strand's own table at `keyPath`, with what `carries` (by
    // strand index) carries of it. A strand without one is left alone.
    //
    private static func _applying<Table, Failure: Swift.Error>(_ carries: [Work.TableCarry],
                                                               to strands: inout [Strand<TimeType, PitchType>],
                                                               at keyPath: WritableKeyPath<Strand<TimeType, PitchType>, Table?>,
                                                               _ transform: (inout Table, Set<EntryID>?) throws(Failure) -> Void) throws(Failure) {
        for index in strands.indices {
            guard var table = strands[index][keyPath: keyPath]
            else { continue }

            try Work.TableCarry.apply(carries[index], to: &table, transform)

            strands[index][keyPath: keyPath] = table
        }
    }

    private static func _entryIDs(_ entries: [(EntryID, TimeType)],
                                  in range: ClosedRange<TimeType>) -> Set<EntryID> {
        Set(entries.filter { range.contains($0.1) }.map(\.0))
    }

    private static func _merged(_ ranges: [ClosedRange<TimeType>?]) -> ClosedRange<TimeType>? {
        ranges.compactMap(\.self).reduce(nil) { acc, range in
            acc.map { NoteTable<TimeType, PitchType>.mergeTimeRanges($0, range) } ?? range
        }
    }
}

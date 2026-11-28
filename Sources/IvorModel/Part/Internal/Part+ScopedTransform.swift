// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning
internal import XestiNumbers

//
// `Part`'s transforms over a resolved selection: what `Work`'s scoped transforms call for each
// part their scope touches, and what `Part`'s public transforms call with the selection their
// `noteIDs:` makes. Each one carries the tables its selection covers (see
// `carryPlan(for:applyTo:alsoCarry:)`).
//
extension Part {

    // MARK: Internal Instance Methods

    internal mutating func augment(by factor: Number,
                                   anchor: TimeType?,
                                   selection: Work.PartSelection,
                                   applyTo: TransformTargets,
                                   alsoCarry: TransformTargets) throws(Error) {
        let plan = carryPlan(for: selection, applyTo: applyTo, alsoCarry: alsoCarry)

        //
        // Resolve the default once, so the notes and every table scale about the same anchor.
        //
        let anchor = anchor ?? transformTimeRange(plan)?.lowerBound

        try applying(plan,
                     notes: { table, noteIDs throws(NoteFailure) in try table.augment(by: factor, anchor: anchor, noteIDs: noteIDs) },
                     dynamics: { table, entryIDs throws(DynamicFailure) in try table.augment(by: factor, anchor: anchor, entryIDs: entryIDs) },
                     instruments: { table, entryIDs throws(InstrumentFailure) in try table.augment(by: factor, anchor: anchor, entryIDs: entryIDs) },
                     pan: { table, entryIDs throws(PanFailure) in try table.augment(by: factor, anchor: anchor, entryIDs: entryIDs) },
                     pedals: { table, entryIDs throws(PedalFailure) in try table.augment(by: factor, anchor: anchor, entryIDs: entryIDs) },
                     marks: { table, entryIDs throws(MarkFailure) in try table.augment(by: factor, anchor: anchor, entryIDs: entryIDs) })
    }

    internal mutating func diminish(by factor: Number,
                                    anchor: TimeType?,
                                    selection: Work.PartSelection,
                                    applyTo: TransformTargets,
                                    alsoCarry: TransformTargets) throws(Error) {
        let plan = carryPlan(for: selection, applyTo: applyTo, alsoCarry: alsoCarry)
        let anchor = anchor ?? transformTimeRange(plan)?.lowerBound

        try applying(plan,
                     notes: { table, noteIDs throws(NoteFailure) in try table.diminish(by: factor, anchor: anchor, noteIDs: noteIDs) },
                     dynamics: { table, entryIDs throws(DynamicFailure) in try table.diminish(by: factor, anchor: anchor, entryIDs: entryIDs) },
                     instruments: { table, entryIDs throws(InstrumentFailure) in try table.diminish(by: factor, anchor: anchor, entryIDs: entryIDs) },
                     pan: { table, entryIDs throws(PanFailure) in try table.diminish(by: factor, anchor: anchor, entryIDs: entryIDs) },
                     pedals: { table, entryIDs throws(PedalFailure) in try table.diminish(by: factor, anchor: anchor, entryIDs: entryIDs) },
                     marks: { table, entryIDs throws(MarkFailure) in try table.diminish(by: factor, anchor: anchor, entryIDs: entryIDs) })
    }

    //
    // `pitchRange` `nil` resolves to the chosen notes' own pitch range, across every strand, so
    // a part's strands invert about the same axis.
    //
    internal mutating func invert(around pitchRange: ClosedRange<PitchType>?,
                                  selection: Work.PartSelection) throws(Error) {
        let pitchRange = pitchRange ?? selectedPitchRange(for: selection)

        try applying(carryPlan(for: selection, applyTo: [], alsoCarry: [])) { table, noteIDs throws(NoteFailure) in
            try table.invert(around: pitchRange, noteIDs: noteIDs)
        }
    }

    internal mutating func move(by directedDuration: DirectedDuration<DurationType>,
                                selection: Work.PartSelection,
                                applyTo: TransformTargets,
                                alsoCarry: TransformTargets) throws(Error) {
        try applying(carryPlan(for: selection, applyTo: applyTo, alsoCarry: alsoCarry),
                     notes: { table, noteIDs throws(NoteFailure) in try table.move(by: directedDuration, noteIDs: noteIDs) },
                     dynamics: { table, entryIDs throws(DynamicFailure) in try table.move(by: directedDuration, entryIDs: entryIDs) },
                     instruments: { table, entryIDs throws(InstrumentFailure) in try table.move(by: directedDuration, entryIDs: entryIDs) },
                     pan: { table, entryIDs throws(PanFailure) in try table.move(by: directedDuration, entryIDs: entryIDs) },
                     pedals: { table, entryIDs throws(PedalFailure) in try table.move(by: directedDuration, entryIDs: entryIDs) },
                     marks: { table, entryIDs throws(MarkFailure) in try table.move(by: directedDuration, entryIDs: entryIDs) })
    }

    internal mutating func reverse(within timeRange: ClosedRange<TimeType>?,
                                   selection: Work.PartSelection,
                                   applyTo: TransformTargets,
                                   alsoCarry: TransformTargets) throws(Error) {
        let plan = carryPlan(for: selection, applyTo: applyTo, alsoCarry: alsoCarry)

        //
        // Resolve the default once, so the notes and every table mirror about the same axis.
        //
        let timeRange = timeRange ?? transformTimeRange(plan)

        try applying(plan,
                     notes: { table, noteIDs throws(NoteFailure) in try table.reverse(within: timeRange, noteIDs: noteIDs) },
                     dynamics: { table, entryIDs throws(DynamicFailure) in try table.reverse(within: timeRange, entryIDs: entryIDs) },
                     instruments: { table, entryIDs throws(InstrumentFailure) in try table.reverse(within: timeRange, entryIDs: entryIDs) },
                     pan: { table, entryIDs throws(PanFailure) in try table.reverse(within: timeRange, entryIDs: entryIDs) },
                     pedals: { table, entryIDs throws(PedalFailure) in try table.reverse(within: timeRange, entryIDs: entryIDs) },
                     marks: { table, entryIDs throws(MarkFailure) in try table.reverse(within: timeRange, entryIDs: entryIDs) })
    }

    internal mutating func transpose(by directedInterval: DirectedInterval<IntervalType>,
                                     selection: Work.PartSelection) throws(Error) {
        try applying(carryPlan(for: selection, applyTo: [], alsoCarry: [])) { table, noteIDs throws(NoteFailure) in
            try table.transpose(by: directedInterval, noteIDs: noteIDs)
        }
    }
}

// MARK: -

extension Part where TimeType == BeatTime {

    // MARK: Internal Instance Methods

    internal mutating func quantize(to quantizer: BeatQuantizer,
                                    selection: Work.PartSelection,
                                    applyTo: TransformTargets,
                                    alsoCarry: TransformTargets) {
        do {
            try applying(carryPlan(for: selection, applyTo: applyTo, alsoCarry: alsoCarry),
                         notes: { table, noteIDs throws(NoteFailure) in table.quantize(using: quantizer, noteIDs: noteIDs) },
                         dynamics: { table, entryIDs throws(DynamicFailure) in table.quantize(using: quantizer, entryIDs: entryIDs) },
                         instruments: { table, entryIDs throws(InstrumentFailure) in table.quantize(using: quantizer, entryIDs: entryIDs) },
                         pan: { table, entryIDs throws(PanFailure) in table.quantize(using: quantizer, entryIDs: entryIDs) },
                         pedals: { table, entryIDs throws(PedalFailure) in table.quantize(using: quantizer, entryIDs: entryIDs) },
                         marks: { table, entryIDs throws(MarkFailure) in table.quantize(using: quantizer, entryIDs: entryIDs) })
        } catch {
            preconditionFailure("Quantizing never fails: \(error.message)")
        }
    }
}

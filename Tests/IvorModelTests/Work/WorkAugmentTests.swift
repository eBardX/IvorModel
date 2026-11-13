// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct WorkAugmentTests {
}

// MARK: -

extension WorkAugmentTests {
    @Test
    func augment_allPartIDs_matchesWholeWork() throws {
        var violin = Part<BeatTime, Pitch>(name: "Violin")
        var cello = Part<BeatTime, Pitch>(name: "Cello")

        violin.noteTable.insert(attack: 1, duration: 1, pitch: .c4)
        cello.noteTable.insert(attack: 2, duration: 1, pitch: .e4)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 3, tempo: .default)

        var selected = Work(content: .standardBeat([violin, cello], tempoMap, MeterTable()))
        var whole = selected

        try selected.augment(by: Number(2),
                             anchor: nil as BeatTime?,
                             partIDs: [violin.partID, cello.partID])
        try whole.augment(by: Number(2),
                          anchor: nil as BeatTime?)

        #expect(selected.beatTimeRange == whole.beatTimeRange)
        #expect(selected.tempoMap?.map(\.beatTime) == whole.tempoMap?.map(\.beatTime))
    }

    @Test
    func augment_defaultAnchor_includesMeterEntries() throws {
        //
        // The meter starts at 0 and the only note at 1. With the meter table carried, the default
        // anchor is 0 and the rest before the note scales; without it, the anchor is the note.
        //
        let work = try makeMeterWork(meterTable: makeMeterTable([(0, "4/4")]),
                                     notes: [1])
        var carried = work
        var notCarried = work

        try carried.augment(by: 2, anchor: nil as BeatTime?)
        try notCarried.augment(by: 2, anchor: nil as BeatTime?, applyTo: [])

        #expect(carried.beatTimeRange?.lowerBound == 2)
        #expect(notCarried.beatTimeRange?.lowerBound == 1)
    }

    @Test
    func augment_keepingSound_preservesWallTimes() throws {
        //
        // 3/8 at ♪ = 240 augmented by 2 is 3/4 at ♩ = 240, and sounds the same, ramp and all.
        //
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: .zero, tempo: Tempo(240, unit: .eighth))
        tempoMap.insert(beatTime: beatTime(frac(3, 2)), tempo: Tempo(180, unit: .eighth))

        let work = try makeMeterWork(meterTable: makeMeterTable([(0, "3/8")]),
                                     tempoMap: tempoMap,
                                     notes: [0, frac(1, 8), frac(3, 8), frac(3, 4), frac(9, 8), 2])
        var augmented = work

        try augmented.augment(by: 2, anchor: nil as BeatTime?, keepingSound: true)

        try expectSameWallTimes(augmented, work)
        #expect(augmented.meterTable?.map(\.meter) == [meter("3/4")])
        #expect(augmented.tempoMap?.first?.tempo == Tempo(240, unit: .quarter))
    }

    @Test
    func augment_keepingSound_withoutTempo_doesNothing() throws {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: .zero, tempo: Tempo(240, unit: .eighth))

        let work = try makeMeterWork(meterTable: makeMeterTable([(0, "3/8")]),
                                     tempoMap: tempoMap,
                                     notes: [0, frac(3, 8)])
        let applyTo = TransformTargets.all.subtracting(.tempo)
        var keeping = work
        var plain = work

        try keeping.augment(by: 2, anchor: nil as BeatTime?, applyTo: applyTo, keepingSound: true)
        try plain.augment(by: 2, anchor: nil as BeatTime?, applyTo: applyTo)

        #expect(keeping.tempoMap == work.tempoMap)
        #expect(keeping.tempoMap == plain.tempoMap)
        #expect(keeping.meterTable == plain.meterTable)
        #expect(keeping.beatTimeRange == plain.beatTimeRange)
    }

    @Test
    func augment_leadingRestScales() throws {
        //
        // The tempo and dynamic are set at 0 and the first note attacks at 1. The default anchor
        // covers every layer that moves, so it's 0, and the beat of rest scales with the notes.
        //
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 1, duration: 1, pitch: .c4)
        part.dynamicMap.insert(time: 0, dynamic: .mf)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)

        var work = Work(content: .standardBeat([part], tempoMap, MeterTable()))

        try work.augment(by: Number(2), anchor: nil as BeatTime?)

        let augmented = try #require(work.part(part.partID, as: Part<BeatTime, Pitch>.self))

        #expect(augmented.noteTable.map(\.attack) == [2])
        #expect(augmented.dynamicMap.map(\.time) == [0])
        #expect(work.tempoMap?.map(\.beatTime) == [0])
    }

    @Test
    func augment_lockedWork_throwsAndLeavesWorkUnchanged() {
        var (work, partID) = makeLockedWorkSB()
        let beatTimeRange = work.beatTimeRange

        #expect(throws: Work.Error.workIsLocked) {
            try work.augment(by: Number(2), anchor: nil as BeatTime?, partIDs: [partID])
        }

        #expect(throws: Work.Error.workIsLocked) {
            try work.augment(by: Number(2), anchor: nil as BeatTime?)
        }

        #expect(work.beatTimeRange == beatTimeRange)
        #expect(work.pitchRange?.lowerBound as? Pitch == .c4)
    }

    @Test
    func augment_mapEntryBeforeFirstNote_doesNotThrow() throws {
        //
        // The work opens with a beat of rest: the tempo and the part's dynamic are set at 0,
        // the first note attacks at 1. With no explicit anchor, the work resolves one from the
        // notes alone (1), which every map then rejects as later than its own first entry (0).
        //
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 1, duration: 1, pitch: .c4)
        part.noteTable.insert(attack: 2, duration: 1, pitch: .e4)
        part.dynamicMap.insert(time: 0, dynamic: .mf)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)

        var work = Work(content: .standardBeat([part], tempoMap, MeterTable()))

        try work.augment(by: Number(2), anchor: nil as BeatTime?)
    }

    @Test
    func augment_onePartOfTwo_withoutMeter_keepsTable() throws {
        var violin = Part<BeatTime, Pitch>(name: "Violin")
        var cello = Part<BeatTime, Pitch>(name: "Cello")

        violin.noteTable.insert(attack: 0, duration: .quarter, pitch: .c4)
        cello.noteTable.insert(attack: 0, duration: .quarter, pitch: .c3)

        let meterTable = try makeMeterTable([(0, "3/4"), (frac(3, 2), "2/4")])
        var work = Work(content: .standardBeat([violin, cello], TempoMap(), meterTable))

        try work.augment(by: 2,
                         anchor: nil as BeatTime?,
                         applyTo: TransformTargets.all.subtracting([.tempo, .meter]),
                         partIDs: [violin.partID])

        #expect(work.meterTable == meterTable)
        #expect(work.part(violin.partID, as: Part<BeatTime, Pitch>.self)?.noteTable.first?.duration == .half)
    }

    @Test
    func augment_partIDs_allOrNothingLeavesWorkUnchangedOnFailure() {
        var goodPart = Part<BeatTime, Pitch>(name: "Violin")
        var badPart = Part<BeatTime, Pitch>(name: "Cello")

        goodPart.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        badPart.noteTable.insert(attack: 5, duration: 1, pitch: .e4)

        let partIDs: Set<PartID> = [goodPart.partID, badPart.partID]
        var work = Work(content: .standardBeat([goodPart, badPart], TempoMap(), MeterTable()))

        //
        // An explicit anchor of 3 is later than `goodPart`'s own range (0...1), so its
        // containment check fails, even though it's a valid anchor for `badPart` (5...6):
        //
        #expect(throws: Work.Error.self) {
            try work.augment(by: Number(2), anchor: BeatTime(3), partIDs: partIDs)
        }

        #expect(work.partName(at: 0) == "Violin")
        #expect(work.beatTimeRange == BeatTime(0)...BeatTime(6))
    }

    @Test
    func augment_scalesRampDuration() throws {
        //
        // `rampDuration` is in beats. Augmenting a 4-beat ramp by 2 makes it 8 beats long.
        //
        let t60 = Tempo(60)
        let t120 = Tempo(120)
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 4, pitch: .c4)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0,
                        tempo: t60,
                        extras: Extras(elements: [Extra(name: Extra.rampStartTempo.name, values: [.double(60)]),
                                                  Extra(name: Extra.rampEndTempo.name, values: [.double(120)]),
                                                  Extra(name: Extra.rampDuration.name, values: [.double(4)])]))
        tempoMap.insert(beatTime: 4, tempo: t120)

        var work = Work(content: .standardBeat([part], tempoMap, MeterTable()))

        try work.augment(by: Number(2), anchor: nil as BeatTime?)

        let entries = Array(work.tempoMap ?? TempoMap())

        #expect(entries.map(\.beatTime) == [0, 8])

        #expect(extraValues(.rampDuration, in: entries.first?.extras) == [.double(8)])
    }

    @Test
    func augment_singlePart_missingID_isNoOp() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable()))

        try work.augment(by: Number(2), anchor: nil as BeatTime?, partIDs: [PartID()])

        #expect(work.partCount == 1)
    }

    @Test
    func augment_singlePart_scalesOnlyThatPart() throws {
        var part1 = Part<BeatTime, Pitch>(name: "Violin")
        var part2 = Part<BeatTime, Pitch>(name: "Cello")

        part1.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        part2.noteTable.insert(attack: 0, duration: 1, pitch: .e4)

        let targetID = part1.partID
        var work = Work(content: .standardBeat([part1, part2], TempoMap(), MeterTable()))

        try work.augment(by: Number(2), anchor: nil as BeatTime?, partIDs: [targetID])

        #expect(work.partName(at: 0) == "Violin")
        #expect(work.partName(at: 1) == "Cello")
    }

    @Test
    func augment_wholeWorkBeat_applyToAll_scalesEveryLayerConsistently() throws {
        var part1 = Part<BeatTime, Pitch>(name: "Violin")
        var part2 = Part<BeatTime, Pitch>(name: "Cello")

        part1.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        part1.dynamicMap.insert(time: 0, dynamic: .mp)
        part1.instrumentTable.insert(time: 0, instrument: .vanilla)
        part1.panMap.insert(time: 0, pan: .center)

        part2.noteTable.insert(attack: 2, duration: 1, pitch: .e4)
        part2.dynamicMap.insert(time: 2, dynamic: .mf)
        part2.instrumentTable.insert(time: 2, instrument: .vanilla)
        part2.panMap.insert(time: 2, pan: .left)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)
        tempoMap.insert(beatTime: 2, tempo: .default)

        var work = Work(content: .standardBeat([part1, part2], tempoMap, MeterTable()))

        try work.augment(by: Number(2), anchor: nil as BeatTime?, applyTo: .all)

        //
        // Every part's note table, dynamic map, instrument table, and pan map, and the work's
        // tempo map, all scaled consistently relative to the same anchor (the aggregate
        // beat-time range's lower bound, 0).
        //
        guard case let .standardBeat(parts, newTempoMap, _) = work.content
        else { Issue.record("Expected .standardBeat content."); return }

        #expect(parts.count == 2)

        var attacksAndDurations: [(BeatTime, BeatTime.DurationType)] = []
        var dynamicTimes: [BeatTime] = []
        var instrumentTimes: [BeatTime] = []
        var panTimes: [BeatTime] = []

        for part in parts {
            for note in part.noteTable {
                attacksAndDurations.append((note.attack, note.duration))
            }

            for entry in part.dynamicMap {
                dynamicTimes.append(entry.time)
            }

            for entry in part.instrumentTable {
                instrumentTimes.append(entry.time)
            }

            for entry in part.panMap {
                panTimes.append(entry.time)
            }
        }

        var tempoTimes: [BeatTime] = []

        for entry in newTempoMap {
            tempoTimes.append(entry.beatTime)
        }

        #expect(attacksAndDurations.map(\.0).sorted() == [0, 4])
        #expect(attacksAndDurations.map(\.1).sorted() == [2, 2])
        #expect(dynamicTimes.sorted() == [0, 4])
        #expect(instrumentTimes.sorted() == [0, 4])
        #expect(panTimes.sorted() == [0, 4])
        #expect(tempoTimes.sorted() == [0, 4])
    }

    @Test
    func augment_wholeWorkBeat_applyToEmpty_leavesTempoMapUntouched() throws {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)
        tempoMap.insert(beatTime: 2, tempo: .default)

        var work = Work(content: .standardBeat([], tempoMap, MeterTable()))

        try work.augment(by: Number(2), anchor: nil as BeatTime?, applyTo: [])

        let tempoTimes = work.tempoMap?.map(\.beatTime) ?? []

        #expect(tempoTimes.sorted() == [0, 2])
    }

    @Test
    func augment_wholeWorkBeat_applyToWithoutTempo_leavesTempoMapUntouched() throws {
        //
        // Only `.tempo` carries the tempo map, however many other maps `applyTo` names. Its
        // entries then don't widen the default anchor either: the notes start at 1, so they
        // scale from there.
        //
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 1, duration: 1, pitch: .c4)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)
        tempoMap.insert(beatTime: 2, tempo: .default)

        var work = Work(content: .standardBeat([part], tempoMap, MeterTable()))

        try work.augment(by: Number(2),
                         anchor: nil as BeatTime?,
                         applyTo: [.dynamic, .instrument, .pan])

        let augmented = try #require(work.part(part.partID, as: Part<BeatTime, Pitch>.self))

        #expect(work.tempoMap?.map(\.beatTime) == [0, 2])
        #expect(augmented.noteTable.map(\.attack) == [1])
        #expect(augmented.timeRange == 1...3)
    }

    @Test
    func augment_wholeWorkBeat_scalesEveryPartAndTempoMap() throws {
        var part1 = Part<BeatTime, Pitch>(name: "Violin")
        var part2 = Part<BeatTime, Pitch>(name: "Cello")

        part1.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        part2.noteTable.insert(attack: 2, duration: 1, pitch: .e4)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)
        tempoMap.insert(beatTime: 2, tempo: .default)

        var work = Work(content: .standardBeat([part1, part2], tempoMap, MeterTable()))

        try work.augment(by: Number(2), anchor: nil as BeatTime?)

        #expect(work.beatTimeRange?.upperBound == 6)

        let tempoTimes = work.tempoMap?.map(\.beatTime) ?? []

        #expect(tempoTimes.sorted() == [0, 4])
    }

    @Test
    func augment_wholeWorkBeat_wrongTimeBasisThrows() {
        var work = Work(content: .standardWall([]))

        #expect(throws: Work.Error.timeBasisMismatch(expected: .beat)) {
            try work.augment(by: Number(2), anchor: nil as BeatTime?)
        }
    }

    @Test
    func augment_withMeter_invalidFactor_throwsMeterTableTransformFailure() throws {
        var work = try makeMeterWork(meterTable: makeMeterTable([(0, "3/4")]),
                                     notes: [])

        #expect(throws: Work.Error.meterTableTransformFailure(kind: .augment,
                                                              detail: MeterTable.Error.invalidAugmentationFactor(frac(1, 2)).message)) {
            try work.augment(by: frac(1, 2), anchor: nil as BeatTime?, applyTo: [.meter], partIDs: [])
        }
    }

    @Test
    func augment_withMeter_renotatesTable() throws {
        let meterTable = try makeMeterTable([(0, "3/4"), (frac(3, 2), "2+2+3/8")],
                                            pickup: frac(1, 4))
        var work = try makeMeterWork(meterTable: meterTable,
                                     notes: [0, frac(1, 4), 1, 2])
        var expected = meterTable

        try expected.augment(by: frac(3, 2))
        try work.augment(by: frac(3, 2), anchor: nil as BeatTime?)

        #expect(work.meterTable == expected)
        #expect(work.meterTable?.map(\.meter) == [meter("9/8"), meter("6+6+9/16")])
        #expect(work.meterTable?.pickup == beats(frac(3, 8)))
    }

    @Test
    func augment_withoutMeter_keepsTable() throws {
        let meterTable = try makeMeterTable([(0, "3/4")])
        var work = try makeMeterWork(meterTable: meterTable,
                                     notes: [0, frac(3, 4)])

        try work.augment(by: 2, anchor: nil as BeatTime?, applyTo: TransformTargets.all.subtracting(.meter))

        #expect(work.meterTable == meterTable)
        #expect(work.beatTimeRange?.lowerBound == .zero)
        #expect(work.beatTimeRange?.upperBound == beatTime(frac(7, 4)))
    }

    @Test
    func mapTransformFailure_wrapsUnderlyingDynamicMapError() {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 5, duration: 1, pitch: .c4)
        part.dynamicMap.insert(time: 0, dynamic: .mp)

        let partID = part.partID
        let detail = "Invalid anchor: does not contain the range of entries it is being applied to"
        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable()))

        #expect(throws: Work.Error.dynamicMapTransformFailure(kind: .augment,
                                                              partID: partID,
                                                              detail: detail)) {
            try work.augment(by: Number(2), anchor: BeatTime(5))
        }

        #expect(work.beatTimeRange == BeatTime(5)...BeatTime(6))
    }

    @Test
    func mapTransformFailure_wrapsUnderlyingInstrumentTableError() {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 5, duration: 1, pitch: .c4)
        part.instrumentTable.insert(time: 0, instrument: .vanilla)

        let partID = part.partID
        let detail = "Invalid anchor: does not contain the range of entries it is being applied to"
        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable()))

        #expect(throws: Work.Error.instrumentTableTransformFailure(kind: .augment,
                                                                   partID: partID,
                                                                   detail: detail)) {
            try work.augment(by: Number(2), anchor: BeatTime(5))
        }

        #expect(work.beatTimeRange == BeatTime(5)...BeatTime(6))
    }

    @Test
    func mapTransformFailure_wrapsUnderlyingPanMapError() {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 5, duration: 1, pitch: .c4)
        part.panMap.insert(time: 0, pan: .center)

        let partID = part.partID
        let detail = "Invalid anchor: does not contain the range of entries it is being applied to"
        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable()))

        #expect(throws: Work.Error.panMapTransformFailure(kind: .augment,
                                                          partID: partID,
                                                          detail: detail)) {
            try work.augment(by: Number(2), anchor: BeatTime(5))
        }

        #expect(work.beatTimeRange == BeatTime(5)...BeatTime(6))
    }
}

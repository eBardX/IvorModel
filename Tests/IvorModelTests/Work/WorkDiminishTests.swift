// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct WorkDiminishTests {
}

// MARK: -

extension WorkDiminishTests {
    @Test
    func diminish_keepingSound_preservesWallTimes() throws {
        //
        // 3/4 at ♩ = 240 diminished by 2 is 3/8 at ♪ = 240.
        //
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: .zero, tempo: Tempo(240))

        let work = try makeMeterWork(meterTable: makeMeterTable([(0, "3/4")]),
                                     tempoMap: tempoMap,
                                     notes: [0, frac(1, 4), frac(3, 4), frac(7, 4)])
        var diminished = work

        try diminished.diminish(by: 2, anchor: nil as BeatTime?, keepingSound: true)

        try expectSameWallTimes(diminished, work)
        #expect(diminished.meterTable?.map(\.meter) == [meter("3/8")])
        #expect(diminished.tempoMap?.first?.tempo == Tempo(240, unit: .eighth))
    }

    @Test
    func diminish_lockedWork_throwsAndLeavesWorkUnchanged() {
        var (work, partID) = makeLockedWorkSB()
        let beatTimeRange = work.beatTimeRange

        #expect(throws: Work.Error.workIsLocked) {
            try work.diminish(by: Number(2), anchor: nil as BeatTime?, partIDs: [partID])
        }

        #expect(throws: Work.Error.workIsLocked) {
            try work.diminish(by: Number(2), anchor: nil as BeatTime?)
        }

        #expect(work.beatTimeRange == beatTimeRange)
        #expect(work.pitchRange?.lowerBound as? Pitch == .c4)
    }

    @Test
    func diminish_mapEntryBeforeFirstNote_doesNotThrow() throws {
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

        try work.diminish(by: Number(2), anchor: nil as BeatTime?)
    }

    @Test
    func diminish_scalesRampDuration() throws {
        //
        // `rampDuration` is in beats. Diminishing a 4-beat ramp by 2 makes it 2 beats long.
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

        try work.diminish(by: Number(2), anchor: nil as BeatTime?)

        let entries = Array(work.tempoMap ?? TempoMap())

        #expect(entries.map(\.beatTime) == [0, 2])

        #expect(extraValues(.rampDuration, in: entries.first?.extras) == [.double(2)])
    }

    @Test
    func diminish_withMeter_renotatesTable() throws {
        let meterTable = try makeMeterTable([(0, "6/8"), (frac(3, 2), "3/4")])
        var work = try makeMeterWork(meterTable: meterTable,
                                     notes: [0, frac(3, 8), 2])
        var expected = meterTable

        try expected.diminish(by: 3)
        try work.diminish(by: 3, anchor: nil as BeatTime?)

        #expect(work.meterTable == expected)
        #expect(work.meterTable?.map(\.meter) == [meter("6/24"), meter("3/12")])
    }

    @Test
    func diminish_withoutMeter_keepsTable() throws {
        let meterTable = try makeMeterTable([(0, "3/4")])
        var work = try makeMeterWork(meterTable: meterTable,
                                     notes: [0, frac(3, 4)])

        try work.diminish(by: 2, anchor: nil as BeatTime?, applyTo: [.tempo])

        #expect(work.meterTable == meterTable)
    }

    @Test
    func diminish_wrongTimeBasisThrows() {
        var work = Work(content: .standardWall([]))

        #expect(throws: Work.Error.timeBasisMismatch(expected: .beat)) {
            try work.diminish(by: Number(2), anchor: nil as BeatTime?)
        }
    }
}

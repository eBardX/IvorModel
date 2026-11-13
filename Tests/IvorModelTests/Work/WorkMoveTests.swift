// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct WorkMoveTests {
}

// MARK: -

extension WorkMoveTests {
    @Test
    func move_lockedWork_throwsAndLeavesWorkUnchanged() throws {
        var (work, partID) = makeLockedWorkSB()
        let directedDuration = try #require(BeatTime(0).duration(to: 2))
        let beatTimeRange = work.beatTimeRange

        #expect(throws: Work.Error.workIsLocked) {
            try work.move(by: directedDuration, partIDs: [partID])
        }

        #expect(throws: Work.Error.workIsLocked) {
            try work.move(by: directedDuration)
        }

        #expect(work.beatTimeRange == beatTimeRange)
        #expect(work.pitchRange?.lowerBound as? Pitch == .c4)
    }

    @Test
    func move_wholeWorkBeat_shiftsEveryPartAndTempoMap() throws {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)

        var work = Work(content: .standardBeat([part], tempoMap, MeterTable()))

        let directedDuration = try #require(BeatTime(0).duration(to: 2))

        try work.move(by: directedDuration)

        #expect(work.beatTimeRange?.lowerBound == 2)

        let tempoTimes = work.tempoMap?.map(\.beatTime) ?? []

        #expect(tempoTimes == [2])
    }

    @Test
    func move_withMeter_movesTable() throws {
        let meterTable = try makeMeterTable([(0, "3/4"), (frac(3, 2), "2/4")])
        var work = try makeMeterWork(meterTable: meterTable,
                                     notes: [0, frac(3, 4)])
        let shift = DirectedDuration(duration: BeatDuration.quarter, direction: .forward)
        var expected = meterTable

        expected.move(by: shift)

        try work.move(by: shift)

        #expect(work.meterTable == expected)
        #expect(work.meterTable?.first?.beatTime == .zero)
        #expect(work.meterTable?.pickup == .quarter)
        #expect(work.meterTable?.position(at: beatTime(frac(1, 4)))?.bar == 1)
        #expect(work.meterTable?.position(at: beatTime(frac(1, 4)))?.beat == 1)
    }

    @Test
    func move_withoutMeter_keepsTable() throws {
        let meterTable = try makeMeterTable([(0, "3/4")])
        var work = try makeMeterWork(meterTable: meterTable,
                                     notes: [0])

        try work.move(by: DirectedDuration(duration: BeatDuration.quarter, direction: .forward),
                      applyTo: [.tempo])

        #expect(work.meterTable == meterTable)
        #expect(work.beatTimeRange?.lowerBound == beatTime(frac(1, 4)))
    }
}

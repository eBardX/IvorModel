// © 2025–2026 John Gary Pusey (see LICENSE.md)

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

        var work = Work(content: .standardBeat([part], tempoMap))

        let directedDuration = try #require(BeatTime(0).duration(to: 2))

        try work.move(by: directedDuration)

        #expect(work.beatTimeRange?.lowerBound == 2)

        let tempoTimes = work.tempoMap?.map(\.beatTime) ?? []

        #expect(tempoTimes == [2])
    }
}

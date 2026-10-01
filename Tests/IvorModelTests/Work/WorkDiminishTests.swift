// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct WorkDiminishTests {
}

// MARK: -

extension WorkDiminishTests {
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
    func diminish_wrongTimeBasisThrows() {
        var work = Work(content: .standardWall([]))

        #expect(throws: Work.Error.timeBasisMismatch(expected: .beat)) {
            try work.diminish(by: Number(2), anchor: nil as BeatTime?)
        }
    }
}

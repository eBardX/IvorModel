// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct WorkReverseTests {
}

// MARK: -

extension WorkReverseTests {
    @Test
    func reverse_lockedWork_throwsAndLeavesWorkUnchanged() {
        var (work, partID) = makeLockedWorkSB()
        let beatTimeRange = work.beatTimeRange

        #expect(throws: Work.Error.workIsLocked) {
            try work.reverse(within: nil as ClosedRange<BeatTime>?, partIDs: [partID])
        }

        #expect(throws: Work.Error.workIsLocked) {
            try work.reverse(within: nil as ClosedRange<BeatTime>?)
        }

        #expect(work.beatTimeRange == beatTimeRange)
        #expect(work.pitchRange?.lowerBound as? Pitch == .c4)
    }

    @Test
    func reverse_partialSelection_carriesTempoMap() throws {
        var violin = Part<BeatTime, Pitch>(name: "Violin")
        var cello = Part<BeatTime, Pitch>(name: "Cello")

        violin.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        violin.noteTable.insert(attack: 2, duration: 1, pitch: .e4)
        cello.noteTable.insert(attack: 5, duration: 1, pitch: .g4)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)
        tempoMap.insert(beatTime: 2, tempo: .default)

        var work = Work(content: .standardBeat([violin, cello], tempoMap))

        try work.reverse(within: nil as ClosedRange<BeatTime>?,
                         partIDs: [violin.partID])

        //
        // The tempo map is work-wide, so it is reversed within the targeted part’s range (0...3)
        // even though only one part was targeted; the untargeted part is left alone.
        //
        #expect(work.tempoMap?.map(\.beatTime) == [1, 3])
        #expect(work.part(cello.partID, as: Part<BeatTime, Pitch>.self)?.timeRange == 5...6)
    }

    @Test
    func reverse_wholeWorkBeat_mirrorsEveryPartAndTempoMap() throws {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        part.noteTable.insert(attack: 2, duration: 1, pitch: .e4)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)
        tempoMap.insert(beatTime: 2, tempo: .default)

        var work = Work(content: .standardBeat([part], tempoMap))

        try work.reverse(within: nil as ClosedRange<BeatTime>?)

        let tempoTimes = work.tempoMap?.map(\.beatTime) ?? []

        //
        // The part spans 0...3 (a note at 0 of duration 1, and one at 2 of duration 1), so the
        // aggregate beat-time range the tempo map is reversed within is 0...3, not 0...2 — the
        // tempo entries at 0 and 2 mirror to 3 and 1 respectively:
        //
        #expect(tempoTimes.sorted() == [1, 3])
    }
}

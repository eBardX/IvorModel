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
    func move_wholeWorkBeat_shiftsEveryPartAndTempoMap() throws {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)

        var work = Work(content: .standardBeat([part], tempoMap))

        let directedDuration = try #require(BeatTime(0).duration(to: 2))

        try work.move(by: directedDuration)

        #expect(work.beatTimeRange?.lowerBound == 2)

        var tempoTimes: [BeatTime] = []

        work.tempoMap?.forEach { _, beatTime, _, _ in
            tempoTimes.append(beatTime)
        }

        #expect(tempoTimes == [2])
    }
}

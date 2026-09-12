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
    func reverse_wholeWorkBeat_mirrorsEveryPartAndTempoMap() throws {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        part.noteTable.insert(attack: 2, duration: 1, pitch: .e4)

        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0, tempo: .default)
        tempoMap.insert(beatTime: 2, tempo: .default)

        var work = Work(content: .standardBeat([part], tempoMap))

        try work.reverse(within: nil as ClosedRange<BeatTime>?)

        var tempoTimes: [BeatTime] = []

        work.tempoMap?.forEach { _, beatTime, _, _ in
            tempoTimes.append(beatTime)
        }

        //
        // The part spans 0...3 (a note at 0 of duration 1, and one at 2 of duration 1), so the
        // aggregate beat-time range the tempo map is reversed within is 0...3, not 0...2 — the
        // tempo entries at 0 and 2 mirror to 3 and 1 respectively:
        //
        #expect(tempoTimes.sorted() == [1, 3])
    }
}

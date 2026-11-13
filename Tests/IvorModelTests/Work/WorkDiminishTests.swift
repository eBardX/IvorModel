// © 2025–2026 John Gary Pusey (see LICENSE.md)

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
    func diminish_wrongTimeBasisThrows() {
        var work = Work(content: .standardWall([]))

        #expect(throws: Work.Error.timeBasisMismatch(expected: .beat)) {
            try work.diminish(by: Number(2), anchor: nil as BeatTime?)
        }
    }
}

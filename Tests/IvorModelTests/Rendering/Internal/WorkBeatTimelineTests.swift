// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct WorkBeatTimelineTests {
}

// MARK: -

extension WorkBeatTimelineTests {
    @Test
    func init_storesEveryField() throws {
        let keyTable = try makeKeyTable([(0, 2)])
        let meterTable = try makeMeterTable([(0, "3/4")])
        let part = try twoNotePart()
        let tempoMap = TempoMap(defaultTempo: Tempo(90))
        let timeline = Work.BeatTimeline(keyTable: keyTable,
                                         meterTable: meterTable,
                                         parts: [part],
                                         tempoMap: tempoMap,
                                         times: [0, frac(1, 2)])

        #expect(timeline.keyTable == keyTable)
        #expect(timeline.meterTable == meterTable)
        #expect(timeline.parts.map(\.partID) == [part.partID])
        #expect(timeline.tempoMap == tempoMap)
        #expect(timeline.times == [0, frac(1, 2)])
    }
}

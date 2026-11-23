// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct TempoMapSlowingTests {
}

// MARK: -

extension TempoMapSlowingTests {
    @Test
    func slowed_keepsEntriesAfterTheEnd() {
        var tempoMap = TempoMap(defaultTempo: Tempo(60))

        tempoMap.insert(beatTime: 3, tempo: Tempo(90))

        let slowed = tempoMap.slowed(from: 1, to: 2, by: frac(1, 2))

        #expect(slowed.map(\.beatTime).last == 3)
        #expect(slowed.map(\.tempo).last == Tempo(90))
        #expect(slowed[beatTime(4)] == Tempo(90))
    }

    @Test
    func slowed_scalesEntriesInsideTheSpan() {
        var tempoMap = TempoMap(defaultTempo: Tempo(60))

        tempoMap.insert(beatTime: 0, tempo: Tempo(60))
        tempoMap.insert(beatTime: beatTime(frac(3, 2)), tempo: Tempo(120))
        tempoMap.insert(beatTime: beatTime(frac(3, 2)), tempo: Tempo(120))

        let slowed = tempoMap.slowed(from: 1, to: 2, by: frac(1, 2))

        #expect(slowed[beatTime(frac(7, 4))].numberValue == Tempo(60).numberValue)
        #expect(slowed[beatTime(3)] == Tempo(120))
    }

    @Test
    func slowed_stepsDownAtTheStartAndBackAtTheEnd() {
        let slowed = TempoMap(defaultTempo: Tempo(60)).slowed(from: 1, to: 2, by: frac(1, 2))

        #expect(slowed.map(\.tempo) == [Tempo(60), Tempo(30), Tempo(30), Tempo(60)])
        #expect(slowed.map(\.beatTime) == [1, 1, 2, 2])
        #expect(slowed[beatTime(frac(1, 2))] == Tempo(60))
        #expect(slowed[beatTime(frac(3, 2))] == Tempo(30))
        #expect(slowed[beatTime(3)] == Tempo(60))
    }
}

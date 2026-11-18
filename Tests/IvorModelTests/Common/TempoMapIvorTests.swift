// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct TempoMapIvorTests {
}

// MARK: -

extension TempoMapIvorTests {
    @Test
    func normalizingExtraNames_empty_isUnchanged() {
        let tempoMap = TempoMap()

        #expect(tempoMap.normalizingExtraNames() == tempoMap)
    }

    @Test
    func normalizingExtraNames_keepsEntryIdentityAndTime() throws {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 2,
                        tempo: .default,
                        extras: Extras(elements: [Extra(name: "TempoText", values: [.string("Lento")])]))

        let original = try #require(tempoMap.first)
        let normalized = try #require(tempoMap.normalizingExtraNames().first)

        #expect(normalized.beatTime == original.beatTime)
        #expect(normalized.entryID == original.entryID)
        #expect(normalized.tempo == original.tempo)
    }

    @Test
    func normalizingExtraNames_leavesNormalizedAndBareEntriesAlone() {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0,
                        tempo: .default)
        tempoMap.insert(beatTime: 1,
                        tempo: .default,
                        extras: Extras(elements: [Extra(name: Extra.tempoText.name, values: [.string("Allegro")])]))

        #expect(tempoMap.normalizingExtraNames() == tempoMap)
    }

    @Test
    func normalizingExtraNames_normalizesEveryEntry() {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 0,
                        tempo: .default,
                        extras: Extras(elements: [Extra(name: "TempoText", values: [.string("Lento")])]))
        tempoMap.insert(beatTime: 4,
                        tempo: .default,
                        extras: Extras(elements: [Extra(name: "RampDuration", values: [.double(2)])]))

        let normalized = tempoMap.normalizingExtraNames()
        let names = normalized.map { $0.extras?.elements.map(\.name) }
        let values = normalized.map { $0.extras?.elements.first?.values }

        #expect(names == [[Extra.tempoText.name], [Extra.rampDuration.name]])
        #expect(values == [[.string("Lento")], [.double(2)]])
    }
}

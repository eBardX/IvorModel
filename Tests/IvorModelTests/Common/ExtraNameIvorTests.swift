// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiTools

struct ExtraNameIvorTests {
}

// MARK: -

extension ExtraNameIvorTests {
    @Test
    func decodedWork_normalizesExtraNamesEverywhere() throws {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: .zero,
                        tempo: .default,
                        extras: Extras(elements: [Extra(name: "TempoText", values: [.string("Lento")])]))

        var meterTable = MeterTable()

        try meterTable.insert(beatTime: .zero,
                              meter: #require(Meter(plain: "4/4")),
                              extras: Extras(elements: [Extra(name: "MeterSymbol", values: [.string("common")])]))

        let work = Work(name: "Tune",
                        content: .standardBeat([Part<BeatTime, Pitch>(name: "Part 1")],
                                               tempoMap,
                                               meterTable,
                                               KeyTable()),
                        extras: Extras(elements: [Extra(name: "SMPTENote")]))
        let decoded = try JSONDecoder().decode(Work.self, from: JSONEncoder().encode(work))

        #expect(decoded.extras?.elements.map(\.name) == ["smpteNote"])
        #expect(decoded.tempoMap?.first?.extras?.elements.map(\.name) == [Extra.tempoText.name])
        #expect(decoded.meterTable?.first?.extras?.elements.map(\.name) == [Extra.meterSymbol.name])
    }

    @Test(arguments: [("Accent", "accent"),
                      ("SMPTETimeCode", "smpteTimeCode"),
                      ("URL", "url"),
                      ("MIDI2Value", "midi2Value"),
                      ("A", "a"),
                      ("ABc", "aBc"),
                      ("METERSYMBOL", "meterSymbol"),
                      ("MeterSymbol", "meterSymbol"),
                      ("customTag", "customTag"),
                      ("x1", "x1")])
    func normalized(name: String, expected: String) {
        #expect(Extra.Name.normalized(Extra.Name(name)) == Extra.Name(expected))
    }
}

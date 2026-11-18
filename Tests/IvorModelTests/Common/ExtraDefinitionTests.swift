// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiTools

struct ExtraDefinitionTests {
}

// MARK: -

extension ExtraDefinitionTests {
    @Test
    func accepts_checksCountTypesAndRanges() throws {
        let channel = try #require(Extra.definition(named: Extra.midiChannel.name))

        #expect(channel.accepts([.int(16)]))
        #expect(!channel.accepts([.int(17)]))
        #expect(!channel.accepts([.string("16")]))
        #expect(!channel.accepts([]))
        #expect(!channel.accepts([.int(1), .int(2)]))
    }

    @Test
    func accepts_choices() throws {
        let symbol = try #require(Extra.definition(named: Extra.meterSymbol.name))

        #expect(symbol.accepts([.string("cut")]))
        #expect(!symbol.accepts([.string("Cut")]))
    }

    @Test
    func accepts_optionalTrailingValue() throws {
        let slurStart = try #require(Extra.definition(named: Extra.slurStart.name))

        #expect(slurStart.accepts([]))
        #expect(slurStart.accepts([.string("1")]))
        #expect(!slurStart.accepts([.int(1)]))
    }

    @Test
    func accepts_positiveRampValues() throws {
        let startTempo = try #require(Extra.definition(named: Extra.rampStartTempo.name))

        #expect(startTempo.accepts([.double(0.5)]))
        #expect(!startTempo.accepts([.double(0)]))
        #expect(!startTempo.accepts([.double(-60)]))
        #expect(!startTempo.accepts([.double(.infinity)]))

        let duration = try #require(Extra.definition(named: Extra.rampDuration.name))

        #expect(duration.accepts([.double(2)]))
        #expect(!duration.accepts([.double(0)]))
    }

    @Test
    func init_defaults_isBareFlag() {
        let definition = Extra.Definition(name: "flag",
                                          targets: [.note])

        #expect(definition.minimumValueCount == 0)
        #expect(definition.name == "flag")
        #expect(definition.targets == [.note])
        #expect(definition.values.isEmpty)
        #expect(definition.accepts([]))
        #expect(!definition.accepts([.bool(true)]))
    }

    @Test
    func init_minimumValueCount_clampsToValueCount() {
        let slot = Extra.ValueSlot(.text, .string(nil))

        #expect(Extra.Definition(name: "a", targets: [.note], values: [slot]).minimumValueCount == 1)
        #expect(Extra.Definition(name: "b", targets: [.note], values: [slot], minimumValueCount: 0).minimumValueCount == 0)
        #expect(Extra.Definition(name: "c", targets: [.note], values: [slot], minimumValueCount: 5).minimumValueCount == 1)
    }
}

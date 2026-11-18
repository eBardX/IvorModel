// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing
import XestiTools

struct ExtraDefinitionsTests {
}

// MARK: -

extension ExtraDefinitionsTests {
    @Test
    func definition_named() throws {
        let definition = try #require(Extra.definition(named: Extra.midiChannel.name))

        #expect(definition.name == Extra.midiChannel.name)
        #expect(definition.targets == [.part])
        #expect(Extra.definition(named: "unknownExtra") == nil)
        #expect(Extra.definition(named: "MidiChannel") == nil)
    }

    @Test
    func definitions_areSortedUniqueAndNormalized() {
        let names = Extra.definitions.map(\.name)

        #expect(names == names.sorted())
        #expect(Set(names).count == names.count)
        #expect(names.allSatisfy { Extra.Name.normalized($0) == $0 })
        #expect(names.allSatisfy { $0.stringValue.first?.isLowercase == true })
    }

    @Test
    func definitions_coverEveryIvorExtra() {
        let ivorExtras: [Extra] = [.accent,
                                   .articulation,
                                   .attackVelocity,
                                   .breathMark,
                                   .downBow,
                                   .dynamicMark,
                                   .expressionValue,
                                   .fermata,
                                   .fingering,
                                   .harmonic,
                                   .instrumentAbbreviation,
                                   .instrumentName,
                                   .keySignatureMode,
                                   .marcato,
                                   .meterSymbol,
                                   .midiBank,
                                   .midiChannel,
                                   .midiKeyPressure,
                                   .midiPan,
                                   .midiProgram,
                                   .midiTimeCode,
                                   .midiTimeSignature,
                                   .midiUnpitched,
                                   .midiVolume,
                                   .mordent,
                                   .pizzicato,
                                   .rampDuration,
                                   .rampEndTempo,
                                   .rampStartTempo,
                                   .releaseVelocity,
                                   .slurEnd,
                                   .slurStart,
                                   .staccato,
                                   .tempoText,
                                   .tenuto,
                                   .trill,
                                   .turn,
                                   .upBow]

        #expect(Extra.definitions.map(\.name) == ivorExtras.map(\.name).sorted())
    }

    @Test
    func definitions_flagsTakeNoValues() throws {
        for flag in [Extra.accent, .fermata, .staccato, .upBow] {
            let definition = try #require(Extra.definition(named: flag.name))

            #expect(definition.targets == [.note])
            #expect(definition.values.isEmpty)
            #expect(definition.accepts([]))
        }
    }

    @Test
    func definitions_forTarget() {
        #expect(Extra.definitions(for: .meterEntry).map(\.name) == [Extra.meterSymbol.name,
                                                                    Extra.midiTimeSignature.name])
        #expect(Extra.definitions(for: .pedalEntry).isEmpty)
        #expect(Extra.definitions(for: .note).contains { $0.name == Extra.accent.name })
    }

    @Test
    func keySignatureMode_acceptsModeNames() throws {
        let mode = try #require(Extra.definition(named: Extra.keySignatureMode.name))

        #expect(mode.accepts([.string("dorian")]))
        #expect(mode.accepts([.string("none")]))
        #expect(!mode.accepts([.string("Dorian")]))
        #expect(!mode.accepts([]))
    }

    @Test
    func midiTimeCode_takesAFrameRateAndTicks() throws {
        let timeCode = try #require(Extra.definition(named: Extra.midiTimeCode.name))

        #expect(timeCode.accepts([.string("29.97DF"), .int(40)]))
        #expect(!timeCode.accepts([.string("31"), .int(40)]))
    }

    @Test
    func midiTimeSignature_labelsItsValues() throws {
        let timeSignature = try #require(Extra.definition(named: Extra.midiTimeSignature.name))

        #expect(timeSignature.values.map(\.role) == [.clocksPerClick, .thirtySecondsPerQuarter])
        #expect(timeSignature.values.map(\.spec) == [.int(1...255), .int(1...255)])
    }
}

// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct ExtraIvorTests {
}

// MARK: -

extension ExtraIvorTests {
    private typealias NoteTableSB = NoteTable<BeatTime, Pitch>

    @Test
    func accent() {
        #expect(Extra.accent.name == "accent")
        #expect(Extra.accent.values.isEmpty)
    }

    @Test
    func accentAndSlurStart_roundTripThroughNoteTableEntry() {
        var table = NoteTableSB()

        table.insert(attack: 0,
                     duration: 1,
                     pitch: .c4,
                     extras: Extras(elements: [Extra(name: Extra.accent.name, values: []),
                                               Extra(name: Extra.slurStart.name,
                                                     values: [.string("1")])]))

        var foundAccent = false
        var foundSlurID: String?

        table.forEach { _, _, _, _, _, extras in
            for extra in extras?.elements ?? [] {
                if extra.name == Extra.accent.name {
                    foundAccent = true
                } else if extra.name == Extra.slurStart.name,
                          case let .string(value)? = extra.values.first {
                    foundSlurID = value
                }
            }
        }

        #expect(foundAccent)
        #expect(foundSlurID == "1")
    }

    @Test
    func articulation() {
        #expect(Extra.articulation.name == "articulation")
        #expect(Extra.articulation.values.isEmpty)
    }

    @Test
    func breathMark() {
        #expect(Extra.breathMark.name == "breathMark")
        #expect(Extra.breathMark.values.isEmpty)
    }

    @Test
    func downBow() {
        #expect(Extra.downBow.name == "downBow")
        #expect(Extra.downBow.values.isEmpty)
    }

    @Test
    func dynamicMark() {
        #expect(Extra.dynamicMark.name == "dynamicMark")
        #expect(Extra.dynamicMark.values.isEmpty)
    }

    @Test
    func dynamicMark_roundTripsThroughDynamicMapEntry() {
        var dynamicMap = DynamicMap<BeatTime>()

        dynamicMap.insert(time: 1,
                          dynamic: .mf,
                          extras: Extras(elements: [Extra(name: Extra.dynamicMark.name,
                                                          values: [.string("sfz")])]))

        var found = false

        dynamicMap.forEach { _, _, _, extras in
            if let mark = extras?.elements.first(where: { $0.name == Extra.dynamicMark.name }),
               case let .string(text)? = mark.values.first {
                found = true

                #expect(text == "sfz")
            }
        }

        #expect(found)
    }

    @Test
    func expressionValue() {
        #expect(Extra.expressionValue.name == "expressionValue")
        #expect(Extra.expressionValue.values.isEmpty)
    }

    @Test
    func fermata() {
        #expect(Extra.fermata.name == "fermata")
        #expect(Extra.fermata.values.isEmpty)
    }

    @Test
    func fingering() {
        #expect(Extra.fingering.name == "fingering")
        #expect(Extra.fingering.values.isEmpty)
    }

    @Test
    func harmonic() {
        #expect(Extra.harmonic.name == "harmonic")
        #expect(Extra.harmonic.values.isEmpty)
    }

    @Test
    func marcato() {
        #expect(Extra.marcato.name == "marcato")
        #expect(Extra.marcato.values.isEmpty)
    }

    @Test
    func midiBank() {
        #expect(Extra.midiBank.name == "midiBank")
        #expect(Extra.midiBank.values.isEmpty)
    }

    @Test
    func midiChannel() {
        #expect(Extra.midiChannel.name == "midiChannel")
        #expect(Extra.midiChannel.values.isEmpty)
    }

    @Test
    func midiChannelAndMidiBank_roundTripThroughInstrumentMapEntry() {
        var instrumentMap = InstrumentMap<BeatTime>()

        instrumentMap.insert(time: 1,
                             instrument: .vanilla,
                             extras: Extras(elements: [Extra(name: Extra.midiChannel.name,
                                                             values: [.int(3)]),
                                                       Extra(name: Extra.midiBank.name,
                                                             values: [.int(129)])]))

        var foundChannel: Int?
        var foundBank: Int?

        instrumentMap.forEach { _, _, _, extras in
            for extra in extras?.elements ?? [] {
                if extra.name == Extra.midiChannel.name,
                   case let .int(value)? = extra.values.first {
                    foundChannel = value
                } else if extra.name == Extra.midiBank.name,
                          case let .int(value)? = extra.values.first {
                    foundBank = value
                }
            }
        }

        #expect(foundChannel == 3)
        #expect(foundBank == 129)
    }

    @Test
    func midiKeyPressure() {
        #expect(Extra.midiKeyPressure.name == "midiKeyPressure")
        #expect(Extra.midiKeyPressure.values.isEmpty)
    }

    @Test
    func midiPan() {
        #expect(Extra.midiPan.name == "midiPan")
        #expect(Extra.midiPan.values.isEmpty)
    }

    @Test
    func midiProgram() {
        #expect(Extra.midiProgram.name == "midiProgram")
        #expect(Extra.midiProgram.values.isEmpty)
    }

    @Test
    func midiProgramAndMidiVolume_roundTripThroughInstrumentMapEntry() {
        var instrumentMap = InstrumentMap<BeatTime>()

        instrumentMap.insert(time: 1,
                             instrument: .vanilla,
                             extras: Extras(elements: [Extra(name: Extra.midiProgram.name,
                                                             values: [.int(41)]),
                                                       Extra(name: Extra.midiVolume.name,
                                                             values: [.double(80)])]))

        var foundProgram: Int?
        var foundVolume: Double?

        instrumentMap.forEach { _, _, _, extras in
            for extra in extras?.elements ?? [] {
                if extra.name == Extra.midiProgram.name,
                   case let .int(value)? = extra.values.first {
                    foundProgram = value
                } else if extra.name == Extra.midiVolume.name,
                          case let .double(value)? = extra.values.first {
                    foundVolume = value
                }
            }
        }

        #expect(foundProgram == 41)
        #expect(foundVolume == 80)
    }

    @Test
    func midiTempo() {
        #expect(Extra.midiTempo.name == "midiTempo")
        #expect(Extra.midiTempo.values.isEmpty)
    }

    @Test
    func midiTimeCode() {
        #expect(Extra.midiTimeCode.name == "midiTimeCode")
        #expect(Extra.midiTimeCode.values.isEmpty)
    }

    @Test
    func midiUnpitched() {
        #expect(Extra.midiUnpitched.name == "midiUnpitched")
        #expect(Extra.midiUnpitched.values.isEmpty)
    }

    @Test
    func midiVolume() {
        #expect(Extra.midiVolume.name == "midiVolume")
        #expect(Extra.midiVolume.values.isEmpty)
    }

    @Test
    func mordent() {
        #expect(Extra.mordent.name == "mordent")
        #expect(Extra.mordent.values.isEmpty)
    }

    @Test
    func pizzicato() {
        #expect(Extra.pizzicato.name == "pizzicato")
        #expect(Extra.pizzicato.values.isEmpty)
    }

    @Test
    func rampDuration() {
        #expect(Extra.rampDuration.name == "rampDuration")
        #expect(Extra.rampDuration.values.isEmpty)
    }

    @Test
    func rampEndTempo() {
        #expect(Extra.rampEndTempo.name == "rampEndTempo")
        #expect(Extra.rampEndTempo.values.isEmpty)
    }

    @Test
    func rampStartTempo() {
        #expect(Extra.rampStartTempo.name == "rampStartTempo")
        #expect(Extra.rampStartTempo.values.isEmpty)
    }

    @Test
    func slurEnd() {
        #expect(Extra.slurEnd.name == "slurEnd")
        #expect(Extra.slurEnd.values.isEmpty)
    }

    @Test
    func slurStart() {
        #expect(Extra.slurStart.name == "slurStart")
        #expect(Extra.slurStart.values.isEmpty)
    }

    @Test
    func smpteOffset() {
        #expect(Extra.smpteOffset.name == "smpteOffset")
        #expect(Extra.smpteOffset.values.isEmpty)
    }

    @Test
    func staccato() {
        #expect(Extra.staccato.name == "staccato")
        #expect(Extra.staccato.values.isEmpty)
    }

    @Test
    func tempoText() {
        #expect(Extra.tempoText.name == "tempoText")
        #expect(Extra.tempoText.values.isEmpty)
    }

    @Test
    func tempoText_roundTripsThroughTempoMapEntry() {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: 1,
                        tempo: 120,
                        extras: Extras(elements: [Extra(name: Extra.tempoText.name,
                                                        values: [.string("Allegro")])]))

        var found = false

        tempoMap.forEach { _, _, _, extras in
            if let mark = extras?.elements.first(where: { $0.name == Extra.tempoText.name }),
               case let .string(text)? = mark.values.first {
                found = true

                #expect(text == "Allegro")
            }
        }

        #expect(found)
    }

    @Test
    func tenuto() {
        #expect(Extra.tenuto.name == "tenuto")
        #expect(Extra.tenuto.values.isEmpty)
    }

    @Test
    func trill() {
        #expect(Extra.trill.name == "trill")
        #expect(Extra.trill.values.isEmpty)
    }

    @Test
    func turn() {
        #expect(Extra.turn.name == "turn")
        #expect(Extra.turn.values.isEmpty)
    }

    @Test
    func upBow() {
        #expect(Extra.upBow.name == "upBow")
        #expect(Extra.upBow.values.isEmpty)
    }

    @Test
    func velocity() {
        #expect(Extra.velocity.name == "velocity")
        #expect(Extra.velocity.values.isEmpty)
    }

    @Test
    func velocityAndExpressionValue_roundTripThroughDynamicMapEntry() {
        var dynamicMap = DynamicMap<BeatTime>()

        dynamicMap.insert(time: 1,
                          dynamic: .mf,
                          extras: Extras(elements: [Extra(name: Extra.velocity.name,
                                                          values: [.int(84)]),
                                                    Extra(name: Extra.expressionValue.name,
                                                          values: [.int(100)])]))

        var foundVelocity: Int?
        var foundExpression: Int?

        dynamicMap.forEach { _, _, _, extras in
            for extra in extras?.elements ?? [] {
                if extra.name == Extra.velocity.name,
                   case let .int(value)? = extra.values.first {
                    foundVelocity = value
                } else if extra.name == Extra.expressionValue.name,
                          case let .int(value)? = extra.values.first {
                    foundExpression = value
                }
            }
        }

        #expect(foundVelocity == 84)
        #expect(foundExpression == 100)
    }
}

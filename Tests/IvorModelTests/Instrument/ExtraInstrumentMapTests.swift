// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct ExtraInstrumentMapTests {
}

// MARK: -

extension ExtraInstrumentMapTests {
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
    func midiElevation() {
        #expect(Extra.midiElevation.name == "midiElevation")
        #expect(Extra.midiElevation.values.isEmpty)
    }

    @Test
    func midiProgram() {
        #expect(Extra.midiProgram.name == "midiProgram")
        #expect(Extra.midiProgram.values.isEmpty)
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
}

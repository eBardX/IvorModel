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

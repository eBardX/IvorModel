// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct ExtraPanMapTests {
}

// MARK: -

extension ExtraPanMapTests {
    @Test
    func midiPan() {
        #expect(Extra.midiPan.name == "midiPan")
        #expect(Extra.midiPan.values.isEmpty)
    }

    @Test
    func panHorizontal() {
        #expect(Extra.panHorizontal.name == "panHorizontal")
        #expect(Extra.panHorizontal.values.isEmpty)
    }

    @Test
    func panHorizontal_roundTripsThroughPanMapEntry() {
        var panMap = PanMap<BeatTime>()

        panMap.insert(time: 1,
                      pan: .center,
                      extras: Extras(elements: [Extra(name: Extra.panHorizontal.name,
                                                      values: [.double(135)])]))

        var found = false

        panMap.forEach { _, _, _, extras in
            if let mark = extras?.elements.first(where: { $0.name == Extra.panHorizontal.name }),
               case let .double(degree)? = mark.values.first {
                found = true

                #expect(degree == 135)
            }
        }

        #expect(found)
    }

    @Test
    func panVertical() {
        #expect(Extra.panVertical.name == "panVertical")
        #expect(Extra.panVertical.values.isEmpty)
    }

    @Test
    func panVertical_roundTripsThroughPanMapEntry() {
        var panMap = PanMap<BeatTime>()

        panMap.insert(time: 1,
                      pan: .center,
                      extras: Extras(elements: [Extra(name: Extra.panVertical.name,
                                                      values: [.double(45)])]))

        var found = false

        panMap.forEach { _, _, _, extras in
            if let mark = extras?.elements.first(where: { $0.name == Extra.panVertical.name }),
               case let .double(elevation)? = mark.values.first {
                found = true

                #expect(elevation == 45)
            }
        }

        #expect(found)
    }
}

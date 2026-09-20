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
    func panDegree() {
        #expect(Extra.panDegree.name == "panDegree")
        #expect(Extra.panDegree.values.isEmpty)
    }

    @Test
    func panDegree_roundTripsThroughPanMapEntry() {
        var panMap = PanMap<BeatTime>()

        panMap.insert(time: 1,
                      pan: .center,
                      extras: Extras(elements: [Extra(name: Extra.panDegree.name,
                                                      values: [.double(135)])]))

        var found = false

        panMap.forEach { _, _, _, extras in
            if let mark = extras?.elements.first(where: { $0.name == Extra.panDegree.name }),
               case let .double(degree)? = mark.values.first {
                found = true

                #expect(degree == 135)
            }
        }

        #expect(found)
    }
}

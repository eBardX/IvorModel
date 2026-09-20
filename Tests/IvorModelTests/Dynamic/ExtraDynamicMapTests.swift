// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct ExtraDynamicMapTests {
}

// MARK: -

extension ExtraDynamicMapTests {
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
}

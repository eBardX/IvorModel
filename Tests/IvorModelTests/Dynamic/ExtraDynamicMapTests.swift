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

    @Test
    func expressionValue() {
        #expect(Extra.expressionValue.name == "expressionValue")
        #expect(Extra.expressionValue.values.isEmpty)
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

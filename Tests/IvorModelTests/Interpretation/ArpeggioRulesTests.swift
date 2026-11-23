// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing
import XestiNumbers

struct ArpeggioRulesTests {
}

// MARK: -

extension ArpeggioRulesTests {
    @Test
    func codable_roundTripAndRejects() throws {
        let rules = ArpeggioRules(direction: .down, anchor: .lastOnBeat, spread: .total(proportion(1, 3)))

        #expect(try codingRoundTrip(rules) == rules)
        #expect(try encodedJSON(ArpeggioRules()) == "{}")
        #expect(throws: DecodingError.self) {
            try decodeJSON(ArpeggioRules.self, #"{"direction":"sideways"}"#)
        }
    }

    @Test
    func overridden() {
        let base = ArpeggioRules(direction: .down, spread: .perTone(positiveSeconds(1, 20)))
        let other = ArpeggioRules(anchor: .lastOnBeat, spread: .total(proportion(1, 2)))

        #expect(base.overridden(by: other) == ArpeggioRules(direction: .down, anchor: .lastOnBeat, spread: .total(proportion(1, 2))))
        #expect(base.overridden(by: nil) == base)
        #expect(ArpeggioRules().isEmpty)
        #expect(!base.isEmpty)
    }
}

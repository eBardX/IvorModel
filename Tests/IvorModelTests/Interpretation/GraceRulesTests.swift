// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing
import XestiNumbers

struct GraceRulesTests {
}

// MARK: -

extension GraceRulesTests {
    @Test
    func codable_roundTripAndRejects() throws {
        let rules = GraceRules(slashedPlacement: .beforeBeat, perNote: positiveSeconds(1, 25))

        #expect(try codingRoundTrip(rules) == rules)
        #expect(try encodedJSON(GraceRules()) == "{}")
        #expect(throws: DecodingError.self) {
            try decodeJSON(GraceRules.self, #"{"maximumShare":2}"#)
        }
    }

    @Test
    func overridden() {
        let base = GraceRules(slashedPlacement: .beforeBeat, maximumShare: proportion(1, 2))
        let other = GraceRules(unslashedPlacement: .onBeat, maximumShare: proportion(1, 4))

        #expect(base.overridden(by: other) == GraceRules(slashedPlacement: .beforeBeat,
                                                         unslashedPlacement: .onBeat,
                                                         maximumShare: proportion(1, 4)))
        #expect(base.overridden(by: nil) == base)
        #expect(GraceRules().isEmpty)
        #expect(!base.isEmpty)
    }
}

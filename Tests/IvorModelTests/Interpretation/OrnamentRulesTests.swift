// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing
import XestiNumbers
import XestiTools

struct OrnamentRulesTests {
}

// MARK: -

extension OrnamentRulesTests {
    @Test
    func codable_roundTripAndRejects() throws {
        let rules = OrnamentRules(startNote: .main, partnerRule: .wholeStep, extent: .count(AlternationCount(3)))

        #expect(try codingRoundTrip(rules) == rules)
        #expect(try encodedJSON(OrnamentRules()) == "{}")
        #expect(throws: DecodingError.self) {
            try decodeJSON(OrnamentRules.self, #"{"rate":0}"#)
        }
    }

    @Test
    func overridden() {
        let base = OrnamentRules(startNote: .partner, partnerRule: .diatonic)
        let other = OrnamentRules(partnerRule: .halfStep, extent: .span(proportion(1, 2)))

        #expect(base.overridden(by: other) == OrnamentRules(startNote: .partner, partnerRule: .halfStep, extent: .span(proportion(1, 2))))
        #expect(base.overridden(by: nil) == base)
        #expect(OrnamentRules().isEmpty)
        #expect(!base.isEmpty)
    }
}

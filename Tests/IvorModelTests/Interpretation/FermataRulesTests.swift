// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct FermataRulesTests {
}

// MARK: -

extension FermataRulesTests {
    @Test
    func codable_holdsAreKeyedByShape() throws {
        let rules = FermataRules(holds: [.long: .stretch(fermataStretch(3))])

        #expect(try encodedJSON(rules) == "{\"holds\":{\"long\":{\"stretch\":" + encodedJSON(fermataStretch(3)) + "}}}")
        #expect(try encodedJSON(FermataRules()) == "{}")
        #expect(try decodeJSON(FermataRules.self, "{}") == FermataRules())
    }

    @Test
    func codable_rejects() {
        for json in [#"{"holds":{"inverted":{"stretch":3}}}"#,
                     #"{"holds":{"long":{"stretch":0}}}"#,
                     #"{"holds":{"long":{"added":1}}}"#] {
            #expect(throws: DecodingError.self) {
                try decodeJSON(FermataRules.self, json)
            }
        }
    }

    @Test
    func codable_roundTrip() throws {
        let rules = FermataRules(holds: [.short: .stretch(fermataStretch(frac(3, 2))), .veryLong: .seconds(positiveSeconds(4))],
                                 pauseAfter: positiveSeconds(1, 2))

        #expect(try codingRoundTrip(rules) == rules)
    }

    @Test
    func isEmpty() {
        #expect(FermataRules().isEmpty)
        #expect(!FermataRules(pauseAfter: positiveSeconds(1)).isEmpty)
        #expect(!FermataRules(holds: [.long: .stretch(fermataStretch(3))]).isEmpty)
    }

    @Test
    func overridden_combinesHoldsShapeByShape() {
        let base = FermataRules(holds: [.short: .stretch(fermataStretch(2)), .long: .stretch(fermataStretch(3))],
                                pauseAfter: positiveSeconds(1))
        let other = FermataRules(holds: [.long: .seconds(positiveSeconds(5))])

        #expect(base.overridden(by: other) == FermataRules(holds: [.short: .stretch(fermataStretch(2)), .long: .seconds(positiveSeconds(5))],
                                                           pauseAfter: positiveSeconds(1)))
        #expect(base.overridden(by: nil) == base)
    }
}

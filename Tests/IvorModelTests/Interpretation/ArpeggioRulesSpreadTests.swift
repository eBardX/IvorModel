// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct ArpeggioRulesSpreadTests {
}

// MARK: -

extension ArpeggioRulesSpreadTests {
    private typealias Spread = ArpeggioRules.Spread

    @Test
    func codable() throws {
        #expect(try encodedJSON(Spread.total(proportion(1, 2))) == "{\"total\":" + encodedJSON(proportion(1, 2)) + "}")

        for spread in [Spread.total(proportion(1, 2)), .perTone(positiveSeconds(1, 20))] {
            #expect(try codingRoundTrip(spread) == spread)
        }

        for json in [#"{"perTone":0}"#, #"{"total":2}"#, #"{"tone":1}"#, #"{}"#] {
            #expect(throws: DecodingError.self) {
                try decodeJSON(Spread.self, json)
            }
        }
    }
}

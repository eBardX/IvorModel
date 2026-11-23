// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct FermataRulesHoldTests {
}

// MARK: -

extension FermataRulesHoldTests {
    private typealias Hold = FermataRules.Hold

    @Test
    func codable() throws {
        // swiftlint:disable:next force_unwrapping
        let stretch = Hold.stretch(FermataStretch(numberValue: 2)!)

        // swiftlint:disable:next force_unwrapping
        #expect(try encodedJSON(stretch) == "{\"stretch\":" + encodedJSON(FermataStretch(numberValue: 2)!) + "}")

        for hold in [stretch, .seconds(positiveSeconds(3))] {
            #expect(try codingRoundTrip(hold) == hold)
        }

        for json in [#"{"stretch":0.5}"#, #"{"seconds":0}"#, #"{"added":1}"#, #"{}"#] {
            #expect(throws: DecodingError.self) {
                try decodeJSON(Hold.self, json)
            }
        }
    }
}

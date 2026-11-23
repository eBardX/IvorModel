// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct FermataExecutionHoldTests {
}

// MARK: -

extension FermataExecutionHoldTests {
    typealias Hold = FermataExecution<BeatTime>.Hold

    @Test(arguments: [#"{}"#, #"{"stretch":1,"added":1}"#, #"{"longer":1}"#])
    func codable_rejectsInvalid(_ json: String) {
        #expect(throws: DecodingError.self) {
            try decodeJSON(Hold.self, json)
        }
    }

    @Test
    func codable_rejectsShrinkingStretch() throws {
        let json = try #"{"stretch":"# + encodedJSON(frac(1, 2)) + "}"

        #expect(throws: DecodingError.self) {
            try decodeJSON(Hold.self, json)
        }
    }

    @Test
    func codable_roundTrip() throws {
        for hold in [Hold.added(positiveBeats(1, 2)), .seconds(positiveSeconds(3, 2)), .stretch(FermataStretch(2))] {
            #expect(try codingRoundTrip(hold) == hold)
        }

        #expect(try encodedJSON(Hold.stretch(FermataStretch(2))).hasPrefix(#"{"stretch":"#))
    }

    @Test
    func hashable() {
        #expect(Set([Hold.stretch(FermataStretch(2)), .stretch(FermataStretch(2)), .seconds(positiveSeconds(1))]).count == 2)
    }

    @Test
    func scaled_scalesOnlyTheWorksOwnTime() {
        #expect(Hold.added(positiveBeats(1, 4)).scaled(by: 2) == .added(positiveBeats(1, 2)))
        #expect(Hold.seconds(positiveSeconds(1)).scaled(by: 2) == .seconds(positiveSeconds(1)))
        #expect(Hold.stretch(FermataStretch(2)).scaled(by: 2) == .stretch(FermataStretch(2)))
        #expect(Hold.added(positiveBeats(1, 4)).scaled(by: 0) == nil)
    }
}

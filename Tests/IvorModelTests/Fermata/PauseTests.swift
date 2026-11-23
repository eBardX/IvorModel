// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct PauseTests {
}

// MARK: -

extension PauseTests {
    @Test
    func codable_encodesOneCase() throws {
        let pause = Pause<BeatTime>.seconds(positiveSeconds(2))

        #expect(try encodedJSON(pause).hasPrefix(#"{"seconds":"#))
        #expect(try codingRoundTrip(pause) == pause)
        #expect(try codingRoundTrip(Pause<BeatTime>.added(positiveBeats(1, 4))) == .added(positiveBeats(1, 4)))
    }

    @Test(arguments: [#"{}"#, #"{"rest":1}"#])
    func codable_rejectsInvalid(_ json: String) {
        #expect(throws: DecodingError.self) {
            try decodeJSON(Pause<BeatTime>.self, json)
        }
    }

    @Test
    func codable_rejectsZeroLength() throws {
        let json = try #"{"added":"# + encodedJSON(BeatDuration.zero) + "}"

        #expect(throws: DecodingError.self) {
            try decodeJSON(Pause<BeatTime>.self, json)
        }
    }

    @Test
    func hashable() {
        #expect(Set([Pause<BeatTime>.seconds(positiveSeconds(2)), .seconds(positiveSeconds(2)), .added(positiveBeats(1))]).count == 2)
    }

    @Test
    func scaled_scalesOnlyTheWorksOwnTime() {
        #expect(Pause<BeatTime>.added(positiveBeats(1, 4)).scaled(by: 2) == .added(positiveBeats(1, 2)))
        #expect(Pause<BeatTime>.seconds(positiveSeconds(2)).scaled(by: 2) == .seconds(positiveSeconds(2)))
        #expect(Pause<BeatTime>.added(positiveBeats(1, 4)).scaled(by: 0) == nil)
    }
}

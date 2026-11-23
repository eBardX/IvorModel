// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing
import XestiTools

struct OrnamentExtentTests {
}

// MARK: -

extension OrnamentExtentTests {
    @Test
    func codable_encodesOneCase() throws {
        let count = OrnamentExtent.count(AlternationCount(3))

        #expect(try encodedJSON(count) == #"{"count":3}"#)
        #expect(try codingRoundTrip(count) == count)
        #expect(try codingRoundTrip(OrnamentExtent.span(proportion(1, 2))) == .span(proportion(1, 2)))
    }

    @Test(arguments: [#"{}"#, #"{"count":3,"span":1}"#, #"{"length":3}"#, #"{"count":0}"#])
    func codable_rejectsInvalid(_ json: String) {
        #expect(throws: DecodingError.self) {
            try decodeJSON(OrnamentExtent.self, json)
        }
    }

    @Test
    func hashable() {
        #expect(Set([OrnamentExtent.count(1), .count(1), .span(proportion(1, 2))]).count == 2)
    }
}

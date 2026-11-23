// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct GracePlacementTests {
}

// MARK: -

extension GracePlacementTests {
    @Test(arguments: [GracePlacement.beforeBeat, .onBeat])
    func codable_encodesRawValue(_ value: GracePlacement) throws {
        #expect(try encodedJSON(value) == "\"\(value.rawValue)\"")
        #expect(try codingRoundTrip(value) == value)
    }

    @Test
    func codable_rejectsUnknownValue() {
        #expect(throws: DecodingError.self) {
            try decodeJSON(GracePlacement.self, "\"sideways\"")
        }
    }
}

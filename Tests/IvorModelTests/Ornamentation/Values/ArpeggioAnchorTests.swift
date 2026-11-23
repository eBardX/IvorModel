// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct ArpeggioAnchorTests {
}

// MARK: -

extension ArpeggioAnchorTests {
    @Test(arguments: [ArpeggioAnchor.firstOnBeat, .lastOnBeat])
    func codable_encodesRawValue(_ value: ArpeggioAnchor) throws {
        #expect(try encodedJSON(value) == "\"\(value.rawValue)\"")
        #expect(try codingRoundTrip(value) == value)
    }

    @Test
    func codable_rejectsUnknownValue() {
        #expect(throws: DecodingError.self) {
            try decodeJSON(ArpeggioAnchor.self, "\"sideways\"")
        }
    }
}

// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct OrnamentStartTests {
}

// MARK: -

extension OrnamentStartTests {
    @Test(arguments: [OrnamentStart.main, .partner])
    func codable_encodesRawValue(_ value: OrnamentStart) throws {
        #expect(try encodedJSON(value) == "\"\(value.rawValue)\"")
        #expect(try codingRoundTrip(value) == value)
    }

    @Test
    func codable_rejectsUnknownValue() {
        #expect(throws: DecodingError.self) {
            try decodeJSON(OrnamentStart.self, "\"sideways\"")
        }
    }
}

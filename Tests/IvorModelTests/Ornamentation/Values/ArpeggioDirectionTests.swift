// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct ArpeggioDirectionTests {
}

// MARK: -

extension ArpeggioDirectionTests {
    @Test(arguments: [ArpeggioDirection.down, .up])
    func codable_encodesRawValue(_ value: ArpeggioDirection) throws {
        #expect(try encodedJSON(value) == "\"\(value.rawValue)\"")
        #expect(try codingRoundTrip(value) == value)
    }

    @Test
    func codable_rejectsUnknownValue() {
        #expect(throws: DecodingError.self) {
            try decodeJSON(ArpeggioDirection.self, "\"sideways\"")
        }
    }
}

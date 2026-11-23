// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct PartnerSideTests {
}

// MARK: -

extension PartnerSideTests {
    @Test(arguments: [PartnerSide.above, .below])
    func codable_encodesRawValue(_ value: PartnerSide) throws {
        #expect(try encodedJSON(value) == "\"\(value.rawValue)\"")
        #expect(try codingRoundTrip(value) == value)
    }

    @Test
    func codable_rejectsUnknownValue() {
        #expect(throws: DecodingError.self) {
            try decodeJSON(PartnerSide.self, "\"sideways\"")
        }
    }
}

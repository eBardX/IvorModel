// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct PartnerRuleTests {
}

// MARK: -

extension PartnerRuleTests {
    @Test(arguments: [PartnerRule.diatonic, .halfStep, .wholeStep])
    func codable_encodesRawValue(_ value: PartnerRule) throws {
        #expect(try encodedJSON(value) == "\"\(value.rawValue)\"")
        #expect(try codingRoundTrip(value) == value)
    }

    @Test
    func codable_rejectsUnknownValue() {
        #expect(throws: DecodingError.self) {
            try decodeJSON(PartnerRule.self, "\"sideways\"")
        }
    }
}

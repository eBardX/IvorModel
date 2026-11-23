// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct FermataShapeTests {
}

// MARK: -

extension FermataShapeTests {
    @Test(arguments: [FermataShape.long, .normal, .short, .veryLong, .veryShort])
    func codable_encodesRawValue(_ value: FermataShape) throws {
        #expect(try encodedJSON(value) == "\"\(value.rawValue)\"")
        #expect(try codingRoundTrip(value) == value)
    }

    @Test
    func codable_rejectsUnknownValue() {
        #expect(throws: DecodingError.self) {
            try decodeJSON(FermataShape.self, "\"sideways\"")
        }
    }
}

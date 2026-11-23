// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct TremoloStrokesTests {
}

// MARK: -

extension TremoloStrokesTests {
    @Test
    func codable_rejectsInvalidValue() throws {
        let data = try JSONEncoder().encode(UInt(9))

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(TremoloStrokes.self, from: data)
        }
    }

    @Test
    func codable_roundTrip() throws {
        let value = try #require(TremoloStrokes(uintValue: 3))

        #expect(try codingRoundTrip(value) == value)
    }

    @Test
    func hashable() throws {
        let value = try #require(TremoloStrokes(uintValue: 3))

        #expect(Set([value, value]).count == 1)
    }

    @Test
    func init_bounds() {
        #expect((TremoloStrokes(uintValue: 0) != nil) == false)
        #expect((TremoloStrokes(uintValue: 1) != nil) == true)
        #expect((TremoloStrokes(uintValue: 8) != nil) == true)
        #expect((TremoloStrokes(uintValue: 9) != nil) == false)
    }
}

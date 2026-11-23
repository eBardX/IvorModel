// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct AlternationCountTests {
}

// MARK: -

extension AlternationCountTests {
    @Test
    func codable_rejectsInvalidValue() throws {
        let data = try JSONEncoder().encode(UInt(0))

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(AlternationCount.self, from: data)
        }
    }

    @Test
    func codable_roundTrip() throws {
        let value = try #require(AlternationCount(uintValue: 3))

        #expect(try codingRoundTrip(value) == value)
    }

    @Test
    func hashable() throws {
        let value = try #require(AlternationCount(uintValue: 3))

        #expect(Set([value, value]).count == 1)
    }

    @Test
    func init_bounds() {
        #expect((AlternationCount(uintValue: 0) != nil) == false)
        #expect((AlternationCount(uintValue: 1) != nil) == true)
        #expect((AlternationCount(uintValue: 100) != nil) == true)
    }
}

// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing

struct ArpeggioGroupTests {
}

// MARK: -

extension ArpeggioGroupTests {
    @Test
    func codable_rejectsInvalidValue() throws {
        let data = try JSONEncoder().encode(UInt(0))

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(ArpeggioGroup.self, from: data)
        }
    }

    @Test
    func codable_roundTrip() throws {
        let value = try #require(ArpeggioGroup(uintValue: 2))

        #expect(try codingRoundTrip(value) == value)
    }

    @Test
    func hashable() throws {
        let value = try #require(ArpeggioGroup(uintValue: 2))

        #expect(Set([value, value]).count == 1)
    }

    @Test
    func init_bounds() {
        #expect((ArpeggioGroup(uintValue: 0) != nil) == false)
        #expect((ArpeggioGroup(uintValue: 1) != nil) == true)
        #expect((ArpeggioGroup(uintValue: 1_000) != nil) == true)
    }
}

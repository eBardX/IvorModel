// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing
import XestiNumbers

struct NotesPerSecondTests {
}

// MARK: -

extension NotesPerSecondTests {
    @Test
    func codable_rejectsInvalidValue() throws {
        let data = try JSONEncoder().encode(Number(0))

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(NotesPerSecond.self, from: data)
        }
    }

    @Test
    func codable_roundTrip() throws {
        let value = try #require(NotesPerSecond(numberValue: 12))

        #expect(try codingRoundTrip(value) == value)
    }

    @Test
    func hashable() throws {
        let value = try #require(NotesPerSecond(numberValue: 12))

        #expect(Set([value, value]).count == 1)
    }

    @Test
    func init_bounds() {
        #expect((NotesPerSecond(numberValue: 0) != nil) == false)
        #expect((NotesPerSecond(numberValue: -1) != nil) == false)
        #expect((NotesPerSecond(numberValue: frac(1, 2)) != nil) == true)
        #expect((NotesPerSecond(numberValue: 12) != nil) == true)
    }

    @Test
    func isValid_rejectsIrrational() {
        #expect(!NotesPerSecond.isValid(Number(floatLiteral: .infinity)))
    }
}

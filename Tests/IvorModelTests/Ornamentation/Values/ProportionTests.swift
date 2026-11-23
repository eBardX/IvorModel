// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing
import XestiNumbers

struct ProportionTests {
}

// MARK: -

extension ProportionTests {
    @Test
    func codable_rejectsInvalidValue() throws {
        let data = try JSONEncoder().encode(frac(3, 2))

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Proportion.self, from: data)
        }
    }

    @Test
    func codable_roundTrip() throws {
        let value = try #require(Proportion(numberValue: frac(1, 2)))

        #expect(try codingRoundTrip(value) == value)
    }

    @Test
    func hashable() throws {
        let value = try #require(Proportion(numberValue: frac(1, 2)))

        #expect(Set([value, value]).count == 1)
    }

    @Test
    func init_bounds() {
        #expect((Proportion(numberValue: 0) != nil) == false)
        #expect((Proportion(numberValue: frac(1, 1_000)) != nil) == true)
        #expect((Proportion(numberValue: frac(1, 2)) != nil) == true)
        #expect((Proportion(numberValue: 1) != nil) == true)
        #expect((Proportion(numberValue: frac(1_001, 1_000)) != nil) == false)
        #expect((Proportion(numberValue: -1) != nil) == false)
    }

    @Test
    func isValid_rejectsIrrational() {
        #expect(!Proportion.isValid(Number(floatLiteral: .infinity)))
    }
}

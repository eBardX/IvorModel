// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing
import XestiNumbers

struct FermataStretchTests {
}

// MARK: -

extension FermataStretchTests {
    @Test
    func codable_rejectsInvalidValue() throws {
        let data = try JSONEncoder().encode(frac(1, 2))

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(FermataStretch.self, from: data)
        }
    }

    @Test
    func codable_roundTrip() throws {
        let value = try #require(FermataStretch(numberValue: 2))

        #expect(try codingRoundTrip(value) == value)
    }

    @Test
    func hashable() throws {
        let value = try #require(FermataStretch(numberValue: 2))

        #expect(Set([value, value]).count == 1)
    }

    @Test
    func init_bounds() {
        #expect((FermataStretch(numberValue: frac(999, 1_000)) != nil) == false)
        #expect((FermataStretch(numberValue: 1) != nil) == true)
        #expect((FermataStretch(numberValue: frac(3, 2)) != nil) == true)
        #expect((FermataStretch(numberValue: 0) != nil) == false)
    }

    @Test
    func isValid_rejectsIrrational() {
        #expect(!FermataStretch.isValid(Number(floatLiteral: .infinity)))
    }
}

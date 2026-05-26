// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing
import XestiNumbers

struct DynamicTests {
}

// MARK: -

extension DynamicTests {
    @Test
    func comparable() {
        #expect(Dynamic.pppp < Dynamic.ppp)
        #expect(Dynamic.ppp < Dynamic.pp)
        #expect(Dynamic.pp < Dynamic.p)
        #expect(Dynamic.p < Dynamic.mp)
        #expect(Dynamic.mp < Dynamic.mf)
        #expect(Dynamic.mf < Dynamic.f)
        #expect(Dynamic.f < Dynamic.ff)
        #expect(Dynamic.ff < Dynamic.fff)
        #expect(Dynamic.fff < Dynamic.ffff)
    }

    @Test
    func formatted() {
        let result = Dynamic.mf.formatted()

        #expect(!result.characters.isEmpty)
    }

    @Test
    func init_invalid() {
        #expect(Dynamic(numberValue: -1) == nil)
        #expect(Dynamic(numberValue: 2) == nil)
    }

    @Test
    func init_valid() {
        #expect(Dynamic(numberValue: 0) != nil)
        #expect(Dynamic(numberValue: 1) != nil)
    }

    @Test
    func isValid() {
        #expect(Dynamic.isValid(0))
        #expect(Dynamic.isValid(1))
        #expect(!Dynamic.isValid(-1))
        #expect(!Dynamic.isValid(2))
    }

    @Test
    func standardMarkings() {
        #expect(Dynamic.ffff.numberValue == 1)
        #expect(Dynamic.pppp.numberValue > 0)
        #expect(Dynamic.pppp.numberValue < Dynamic.ppp.numberValue)
    }
}

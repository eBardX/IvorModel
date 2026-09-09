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
    func description() {
        #expect(Dynamic.mf.description == "3/5")
        #expect(Dynamic.ffff.description == "1/1")
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
    func plain() {
        #expect(Dynamic.mf.plain == "3/5")
        #expect(Dynamic.ffff.plain == "1")
    }

    @Test
    func plain_roundTrip() {
        #expect(Dynamic(plain: "1/2") == Dynamic(numberValue: Number(numerator: 1, denominator: 2)))
        #expect(Dynamic(plain: "0.5") == Dynamic(numberValue: Number(numerator: 1, denominator: 2)))
        #expect(Dynamic(plain: "0") == Dynamic(numberValue: 0))
        #expect(Dynamic(plain: "1") == Dynamic.ffff)
        #expect(Dynamic(plain: "-1") == nil)
        #expect(Dynamic(plain: "2") == nil)
        #expect(Dynamic(plain: "") == nil)
        #expect(Dynamic(plain: "not a number") == nil)
        #expect(Dynamic(plain: "#b101") == nil)
    }

    @Test
    func standardMarkings() {
        #expect(Dynamic.ffff.numberValue == 1)
        #expect(Dynamic.pppp.numberValue > 0)
        #expect(Dynamic.pppp.numberValue < Dynamic.ppp.numberValue)
    }
}

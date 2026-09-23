// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing
import XestiNumbers

struct PanAngleTests {
}

// MARK: -

extension PanAngleTests {
    private typealias Angle = Pan.Angle

    @Test
    func add_wraps() {
        #expect(Angle(90) + Angle(100) == Angle(-170))
        #expect(Angle(-90) + Angle(-100) == Angle(170))
        #expect(Angle(90) + Angle(90) == Angle(180))
    }

    @Test
    func codable_roundTrip() throws {
        let original = Angle(Number(numerator: 45, denominator: 2))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Angle.self, from: data)

        #expect(decoded == original)
    }

    @Test
    func codable_wrapsOnDecode() throws {
        let data = Data(#""190""#.utf8)
        let decoded = try JSONDecoder().decode(Angle.self, from: data)

        #expect(decoded == Angle(-170))
    }

    @Test
    func init_exactStaysExact() {
        let angle = Angle(Number(numerator: 721, denominator: 2))

        #expect(angle.numberValue == Number(numerator: 1, denominator: 2))
        #expect(angle.numberValue.isExact)
    }

    @Test
    func init_inexact() {
        let angle = Angle(Number(190.5))

        #expect(abs(angle.doubleValue - -169.5) < 1e-9)
    }

    @Test
    func init_invalid() {
        #expect(Angle(numberValue: Number(Double.nan)) == nil)
        #expect(Angle(numberValue: Number(Double.infinity)) == nil)
    }

    @Test
    func init_wraps() {
        #expect(Angle(180).numberValue == 180)
        #expect(Angle(-180).numberValue == 180)
        #expect(Angle(190).numberValue == -170)
        #expect(Angle(-190).numberValue == 170)
        #expect(Angle(360).numberValue == 0)
        #expect(Angle(540).numberValue == 180)
        #expect(Angle(-720).numberValue == 0)
        #expect(Angle(45).numberValue == 45)
    }

    @Test
    func isValid() {
        #expect(Angle.isValid(0))
        #expect(Angle.isValid(1_000))
        #expect(Angle.isValid(Number(12.5)))
        #expect(!Angle.isValid(Number(Double.nan)))
    }

    @Test
    func negate() {
        #expect(-Angle(45) == Angle(-45))
        #expect(-Angle(180) == Angle(180))
    }

    @Test
    func plain_roundTrip() {
        #expect(Angle(-45).plain == "-45")
        #expect(Angle(plain: "-45") == Angle(-45))
        #expect(Angle(plain: "22.5") == Angle(Number(numerator: 45, denominator: 2)))
        #expect(Angle(plain: "270") == Angle(-90))
        #expect(Angle(plain: "") == nil)
        #expect(Angle(plain: "north") == nil)
    }

    @Test
    func subtract_isShortestRotation() {
        #expect(Angle(-170) - Angle(170) == Angle(20))
        #expect(Angle(170) - Angle(-170) == Angle(-20))
        #expect(Angle(180) - Angle(0) == Angle(180))
        #expect(Angle(0) - Angle(180) == Angle(180))
    }
}

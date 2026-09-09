// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing
import XestiNumbers

struct PanTests {
}

// MARK: -

extension PanTests {
    @Test
    func center() {
        #expect(Pan.center.numberValue == 0)
    }

    @Test
    func comparable() {
        #expect(Pan.left < Pan.center)
        #expect(Pan.center < Pan.right)
        #expect(Pan.left == Pan.left) // swiftlint:disable:this identical_operands
    }

    @Test
    func description() {
        #expect(Pan.center.description == "0")
        #expect(Pan.left.description == "-1")
        #expect(Pan.right.description == "1")
    }

    @Test
    func init_invalid() {
        #expect(Pan(numberValue: -2) == nil)
        #expect(Pan(numberValue: 2) == nil)
    }

    @Test
    func init_valid() {
        #expect(Pan(numberValue: -1) != nil)
        #expect(Pan(numberValue: 0) != nil)
        #expect(Pan(numberValue: 1) != nil)
    }

    @Test
    func isValid() {
        #expect(Pan.isValid(-1))
        #expect(Pan.isValid(0))
        #expect(Pan.isValid(1))
        #expect(!Pan.isValid(-2))
        #expect(!Pan.isValid(2))
    }

    @Test
    func left() {
        #expect(Pan.left.numberValue == -1)
    }

    @Test
    func plain() {
        #expect(Pan.center.plain == "0")
        #expect(Pan.left.plain == "-1")
    }

    @Test
    func plain_roundTrip() {
        #expect(Pan(plain: "0") == Pan.center)
        #expect(Pan(plain: "-1") == Pan.left)
        #expect(Pan(plain: "1") == Pan.right)
        #expect(Pan(plain: "-0.5") == Pan(numberValue: Number(numerator: -1, denominator: 2)))
        #expect(Pan(plain: "-2") == nil)
        #expect(Pan(plain: "2") == nil)
        #expect(Pan(plain: "") == nil)
        #expect(Pan(plain: "not a number") == nil)
        #expect(Pan(plain: "#b101") == nil)
    }

    @Test
    func right() {
        #expect(Pan.right.numberValue == 1)
    }
}

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
    func right() {
        #expect(Pan.right.numberValue == 1)
    }
}

@testable import IvorModel
import Testing
import XestiNumbers

struct PositionTests {
}

// MARK: -

extension PositionTests {
    @Test
    func center() {
        #expect(Position.center.numberValue == 0)
    }

    @Test
    func comparable() {
        #expect(Position.left < Position.center)
        #expect(Position.center < Position.right)
        #expect(Position.left == Position.left) // swiftlint:disable:this identical_operands
    }

    @Test
    func init_invalid() {
        #expect(Position(numberValue: -2) == nil)
        #expect(Position(numberValue: 2) == nil)
    }

    @Test
    func init_valid() {
        #expect(Position(numberValue: -1) != nil)
        #expect(Position(numberValue: 0) != nil)
        #expect(Position(numberValue: 1) != nil)
    }

    @Test
    func isValid() {
        #expect(Position.isValid(-1))
        #expect(Position.isValid(0))
        #expect(Position.isValid(1))
        #expect(!Position.isValid(-2))
        #expect(!Position.isValid(2))
    }

    @Test
    func left() {
        #expect(Position.left.numberValue == -1)
    }

    @Test
    func right() {
        #expect(Position.right.numberValue == 1)
    }
}

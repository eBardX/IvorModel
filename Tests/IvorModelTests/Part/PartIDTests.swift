@testable import IvorModel
import Testing

struct PartIDTests {
}

// MARK: -

extension PartIDTests {
    @Test
    func comparable() throws {
        let id1 = try #require(PartID(intValue: 1))
        let id2 = try #require(PartID(intValue: 2))

        #expect(id1 < id2)
        #expect(id1 == id1) // swiftlint:disable:this identical_operands
    }

    @Test
    func index() throws {
        let id = try #require(PartID(intValue: 3))

        #expect(id.index == 2)
    }

    @Test
    func init_byIndex() throws {
        let id = try #require(PartID(index: 0))

        #expect(id.intValue == 1)
        #expect(id.index == 0)
    }

    @Test
    func init_invalid() {
        #expect(PartID(intValue: 0) == nil)
        #expect(PartID(intValue: -1) == nil)
        #expect(PartID(index: -1) == nil)
    }

    @Test
    func init_valid() {
        #expect(PartID(intValue: 1) != nil)
        #expect(PartID(intValue: 100) != nil)
    }

    @Test
    func isValid() {
        #expect(PartID.isValid(1))
        #expect(!PartID.isValid(0))
        #expect(!PartID.isValid(-1))
    }
}

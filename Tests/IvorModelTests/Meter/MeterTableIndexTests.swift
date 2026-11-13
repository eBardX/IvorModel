// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct MeterTableIndexTests {
}

// MARK: -

extension MeterTableIndexTests {
    @Test
    func comparable() {
        #expect(MeterTable.Index(0) < MeterTable.Index(1))
        #expect(!(MeterTable.Index(1) < MeterTable.Index(0)))
    }

    @Test
    func comparable_notLessThanSelf() {
        #expect(!(MeterTable.Index(2) < MeterTable.Index(2))) // swiftlint:disable:this identical_operands
    }

    @Test
    func equality() {
        #expect(MeterTable.Index(3) == MeterTable.Index(3)) // swiftlint:disable:this identical_operands
    }

    @Test
    func hashable() {
        let indices: Set = [MeterTable.Index(0),
                            MeterTable.Index(0),
                            MeterTable.Index(1)]

        #expect(indices.count == 2)
    }

    @Test
    func inequality() {
        #expect(MeterTable.Index(3) != MeterTable.Index(4))
    }

    @Test
    func init_storesOffset() {
        #expect(MeterTable.Index(5).offset == 5)
    }
}

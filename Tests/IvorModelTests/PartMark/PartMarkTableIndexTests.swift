// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct PartMarkTableIndexTests {
}

// MARK: -

extension PartMarkTableIndexTests {
    @Test
    func comparable() {
        #expect(PartMarkTable<BeatTime>.Index(0) < PartMarkTable<BeatTime>.Index(1))
        #expect(!(PartMarkTable<BeatTime>.Index(1) < PartMarkTable<BeatTime>.Index(0)))
    }

    @Test
    func comparable_notLessThanSelf() {
        #expect(!(PartMarkTable<BeatTime>.Index(2) < PartMarkTable<BeatTime>.Index(2))) // swiftlint:disable:this identical_operands
    }

    @Test
    func equality() {
        #expect(PartMarkTable<BeatTime>.Index(3) == PartMarkTable<BeatTime>.Index(3)) // swiftlint:disable:this identical_operands
    }

    @Test
    func hashable() {
        let indices: Set = [PartMarkTable<BeatTime>.Index(0),
                            PartMarkTable<BeatTime>.Index(0),
                            PartMarkTable<BeatTime>.Index(1)]

        #expect(indices.count == 2)
    }

    @Test
    func inequality() {
        #expect(PartMarkTable<BeatTime>.Index(3) != PartMarkTable<BeatTime>.Index(4))
    }

    @Test
    func init_storesOffset() {
        #expect(PartMarkTable<BeatTime>.Index(5).offset == 5)
    }
}

// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing

struct PedalTableIndexTests {
}

// MARK: -

extension PedalTableIndexTests {
    @Test
    func comparable() {
        #expect(PedalTable<BeatTime>.Index(0) < PedalTable<BeatTime>.Index(1))
        #expect(!(PedalTable<BeatTime>.Index(1) < PedalTable<BeatTime>.Index(0)))
    }

    @Test
    func comparable_notLessThanSelf() {
        #expect(!(PedalTable<BeatTime>.Index(2) < PedalTable<BeatTime>.Index(2))) // swiftlint:disable:this identical_operands
    }

    @Test
    func equality() {
        #expect(PedalTable<BeatTime>.Index(3) == PedalTable<BeatTime>.Index(3)) // swiftlint:disable:this identical_operands
    }

    @Test
    func hashable() {
        let indices: Set = [PedalTable<BeatTime>.Index(0),
                            PedalTable<BeatTime>.Index(0),
                            PedalTable<BeatTime>.Index(1)]

        #expect(indices.count == 2)
    }

    @Test
    func inequality() {
        #expect(PedalTable<BeatTime>.Index(3) != PedalTable<BeatTime>.Index(4))
    }

    @Test
    func init_storesOffset() {
        #expect(PedalTable<BeatTime>.Index(5).offset == 5)
    }
}

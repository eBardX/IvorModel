// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing

struct PanMapIndexTests {
}

// MARK: -

extension PanMapIndexTests {
    @Test
    func comparable() {
        #expect(PanMap<BeatTime>.Index(0) < PanMap<BeatTime>.Index(1))
        #expect(!(PanMap<BeatTime>.Index(1) < PanMap<BeatTime>.Index(0)))
    }

    @Test
    func comparable_notLessThanSelf() {
        #expect(!(PanMap<BeatTime>.Index(2) < PanMap<BeatTime>.Index(2))) // swiftlint:disable:this identical_operands
    }

    @Test
    func equality() {
        #expect(PanMap<BeatTime>.Index(3) == PanMap<BeatTime>.Index(3)) // swiftlint:disable:this identical_operands
    }

    @Test
    func hashable() {
        let indices: Set = [PanMap<BeatTime>.Index(0),
                            PanMap<BeatTime>.Index(0),
                            PanMap<BeatTime>.Index(1)]

        #expect(indices.count == 2)
    }

    @Test
    func inequality() {
        #expect(PanMap<BeatTime>.Index(3) != PanMap<BeatTime>.Index(4))
    }

    @Test
    func init_storesOffset() {
        #expect(PanMap<BeatTime>.Index(5).offset == 5)
    }
}

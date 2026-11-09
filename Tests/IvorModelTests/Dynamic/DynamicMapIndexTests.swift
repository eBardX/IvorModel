// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing

struct DynamicMapIndexTests {
}

// MARK: -

extension DynamicMapIndexTests {
    @Test
    func comparable() {
        #expect(DynamicMap<BeatTime>.Index(0) < DynamicMap<BeatTime>.Index(1))
        #expect(!(DynamicMap<BeatTime>.Index(1) < DynamicMap<BeatTime>.Index(0)))
    }

    @Test
    func comparable_notLessThanSelf() {
        #expect(!(DynamicMap<BeatTime>.Index(2) < DynamicMap<BeatTime>.Index(2))) // swiftlint:disable:this identical_operands
    }

    @Test
    func equality() {
        #expect(DynamicMap<BeatTime>.Index(3) == DynamicMap<BeatTime>.Index(3)) // swiftlint:disable:this identical_operands
    }

    @Test
    func hashable() {
        let indices: Set = [DynamicMap<BeatTime>.Index(0),
                            DynamicMap<BeatTime>.Index(0),
                            DynamicMap<BeatTime>.Index(1)]

        #expect(indices.count == 2)
    }

    @Test
    func inequality() {
        #expect(DynamicMap<BeatTime>.Index(3) != DynamicMap<BeatTime>.Index(4))
    }

    @Test
    func init_storesOffset() {
        #expect(DynamicMap<BeatTime>.Index(5).offset == 5)
    }
}

// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing

struct InstrumentTableIndexTests {
}

// MARK: -

extension InstrumentTableIndexTests {
    @Test
    func comparable() {
        #expect(InstrumentTable<BeatTime>.Index(0) < InstrumentTable<BeatTime>.Index(1))
        #expect(!(InstrumentTable<BeatTime>.Index(1) < InstrumentTable<BeatTime>.Index(0)))
    }

    @Test
    func comparable_notLessThanSelf() {
        #expect(!(InstrumentTable<BeatTime>.Index(2) < InstrumentTable<BeatTime>.Index(2))) // swiftlint:disable:this identical_operands
    }

    @Test
    func equality() {
        #expect(InstrumentTable<BeatTime>.Index(3) == InstrumentTable<BeatTime>.Index(3)) // swiftlint:disable:this identical_operands
    }

    @Test
    func hashable() {
        let indices: Set = [InstrumentTable<BeatTime>.Index(0),
                            InstrumentTable<BeatTime>.Index(0),
                            InstrumentTable<BeatTime>.Index(1)]

        #expect(indices.count == 2)
    }

    @Test
    func inequality() {
        #expect(InstrumentTable<BeatTime>.Index(3) != InstrumentTable<BeatTime>.Index(4))
    }

    @Test
    func init_storesOffset() {
        #expect(InstrumentTable<BeatTime>.Index(5).offset == 5)
    }
}

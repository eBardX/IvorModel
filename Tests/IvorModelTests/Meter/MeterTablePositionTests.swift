// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct MeterTablePositionTests {
}

// MARK: -

extension MeterTablePositionTests {
    @Test
    func equality() {
        #expect(makePosition(beat: 2) == makePosition(beat: 2)) // swiftlint:disable:this identical_operands
    }

    @Test
    func hashable() {
        let positions: Set = [makePosition(beat: 1),
                              makePosition(beat: 1),
                              makePosition(beat: nil)]

        #expect(positions.count == 2)
    }

    @Test
    func inequality_differentBeat() {
        #expect(makePosition(beat: 1) != makePosition(beat: 2))
    }

    @Test
    func init_freeBar_hasNoBeat() {
        let position = MeterTable.Position(bar: 1,
                                           beat: nil,
                                           offset: 2,
                                           beatLength: nil)

        #expect(position.beat == nil)
        #expect(position.beatLength == nil)
    }

    @Test
    func init_storesValues() {
        let position = MeterTable.Position(bar: 4,
                                           beat: 2,
                                           offset: beats(frac(1, 8)),
                                           beatLength: beats(frac(3, 8)))

        #expect(position.bar == 4)
        #expect(position.beat == 2)
        #expect(position.beatLength == beats(frac(3, 8)))
        #expect(position.offset == beats(frac(1, 8)))
    }
}

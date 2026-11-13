// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct MeterTableBarTests {
}

// MARK: -

extension MeterTableBarTests {
    @Test
    func equality() {
        #expect(makeBar(number: 1) == makeBar(number: 1)) // swiftlint:disable:this identical_operands
    }

    @Test
    func hashable() {
        let bars: Set = [makeBar(number: 1),
                         makeBar(number: 1),
                         makeBar(number: 2)]

        #expect(bars.count == 2)
    }

    @Test
    func inequality_differentNumber() {
        #expect(makeBar(number: 1) != makeBar(number: 2))
    }

    @Test
    func init_storesValues() {
        let bar = MeterTable.Bar(number: 3,
                                 range: 1..<beatTime(frac(7, 4)),
                                 meter: meter("3/4"),
                                 isPickup: false,
                                 isShort: true,
                                 beatStarts: [1, beatTime(frac(5, 4))])

        #expect(bar.beatStarts == [1, beatTime(frac(5, 4))])
        #expect(!bar.isPickup)
        #expect(bar.isShort)
        #expect(bar.meter == meter("3/4"))
        #expect(bar.number == 3)
        #expect(bar.range == 1..<beatTime(frac(7, 4)))
    }
}

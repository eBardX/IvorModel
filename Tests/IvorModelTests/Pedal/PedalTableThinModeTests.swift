// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct PedalTableThinModeTests {
}

// MARK: -

extension PedalTableThinModeTests {
    private typealias ThinModeSB = PedalTable<BeatTime>.ThinMode

    @Test
    func equatable_mergeComparesTolerance() {
        let half = Pedal.Level(Number(numerator: 1, denominator: 2))

        #expect(ThinModeSB.merge(tolerance: half) == .merge(tolerance: half))
        #expect(ThinModeSB.merge(tolerance: half) != .merge(tolerance: .on))
    }

    @Test
    func equatable_snapDiffersFromMerge() {
        #expect(ThinModeSB.snap == .snap)
        #expect(ThinModeSB.snap != .merge(tolerance: .on))
    }
}

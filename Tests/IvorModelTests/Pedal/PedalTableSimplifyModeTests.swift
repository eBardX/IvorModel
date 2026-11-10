// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct PedalTableSimplifyModeTests {
}

// MARK: -

extension PedalTableSimplifyModeTests {
    private typealias SimplifyModeSB = PedalTable<BeatTime>.SimplifyMode

    @Test
    func equatable_mergeComparesTolerance() {
        let half = Pedal.Level(Number(numerator: 1, denominator: 2))

        #expect(SimplifyModeSB.merge(tolerance: half) == .merge(tolerance: half))
        #expect(SimplifyModeSB.merge(tolerance: half) != .merge(tolerance: .on))
    }

    @Test
    func equatable_snapDiffersFromMerge() {
        #expect(SimplifyModeSB.snap == .snap)
        #expect(SimplifyModeSB.snap != .merge(tolerance: .on))
    }
}

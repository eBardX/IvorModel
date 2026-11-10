// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing
import XestiNumbers

struct PedalSimplifyModeTests {
}

// MARK: -

extension PedalSimplifyModeTests {
    @Test
    func equatable_mergeComparesTolerance() {
        let half = Pedal.Level(Number(numerator: 1, denominator: 2))

        #expect(Pedal.SimplifyMode.merge(tolerance: half) == .merge(tolerance: half))
        #expect(Pedal.SimplifyMode.merge(tolerance: half) != .merge(tolerance: .down))
    }

    @Test
    func equatable_snapDiffersFromMerge() {
        #expect(Pedal.SimplifyMode.snap == .snap)
        #expect(Pedal.SimplifyMode.snap != .merge(tolerance: .down))
    }
}

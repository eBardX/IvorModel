// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct TransformTargetsTests {
}

// MARK: -

extension TransformTargetsTests {
    @Test
    func all_containsEveryMap() {
        #expect(TransformTargets.all == [.dynamic, .instrument, .meter, .pan, .pedal, .tempo])
        #expect(TransformTargets.all.contains(.meter))
        #expect(TransformTargets.all.contains(.pedal))
    }

    @Test
    func init_rawValue() {
        #expect(TransformTargets(rawValue: 0).isEmpty)
        #expect(TransformTargets(rawValue: 1 << 0) == .dynamic)
        #expect(TransformTargets(rawValue: 1 << 1) == .instrument)
        #expect(TransformTargets(rawValue: 1 << 2) == .pan)
        #expect(TransformTargets(rawValue: 1 << 3) == .tempo)
        #expect(TransformTargets(rawValue: 1 << 4) == .pedal)
        #expect(TransformTargets(rawValue: 1 << 5) == .meter)
    }

    @Test
    func union_combinesTargets() {
        let combined: TransformTargets = [.dynamic, .pan]

        #expect(combined.contains(.dynamic))
        #expect(!combined.contains(.instrument))
        #expect(combined.contains(.pan))
    }
}

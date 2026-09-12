// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing

struct MapTargetsTests {
}

// MARK: -

extension MapTargetsTests {
    @Test
    func all_containsEveryMap() {
        #expect(MapTargets.all == [.dynamic, .instrument, .pan])
    }

    @Test
    func init_rawValue() {
        #expect(MapTargets(rawValue: 0).isEmpty)
        #expect(MapTargets(rawValue: 1 << 0) == .dynamic)
        #expect(MapTargets(rawValue: 1 << 1) == .instrument)
        #expect(MapTargets(rawValue: 1 << 2) == .pan)
    }

    @Test
    func union_combinesTargets() {
        let combined: MapTargets = [.dynamic, .pan]

        #expect(combined.contains(.dynamic))
        #expect(!combined.contains(.instrument))
        #expect(combined.contains(.pan))
    }
}

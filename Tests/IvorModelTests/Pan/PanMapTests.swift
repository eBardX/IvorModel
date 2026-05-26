// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct PanMapTests {
}

// MARK: -

extension PanMapTests {
    @Test
    func defaultPan() {
        let map = PanMap<BeatTime>()

        #expect(map.defaultPan == .center)
    }

    @Test
    func defaultPan_override() {
        let map = PanMap<BeatTime>(defaultPan: .right)

        #expect(map.defaultPan == .right)
    }

    @Test
    func inserting() {
        let map = PanMap<BeatTime>().inserting(time: 1,
                                               pan: .left)

        #expect(!map.isEmpty)
    }

    @Test
    func isEmpty_afterInsert() {
        var map = PanMap<BeatTime>()

        map.insert(time: 1,
                   pan: .right)

        #expect(!map.isEmpty)
    }

    @Test
    func isEmpty_initial() {
        let map = PanMap<BeatTime>()

        #expect(map.isEmpty)
    }

    @Test
    func merge() {
        var map1 = PanMap<BeatTime>()
        var map2 = PanMap<BeatTime>()

        map1.insert(time: 1,
                    pan: .left)
        map2.insert(time: 3,
                    pan: .right)
        map1.merge(with: map2)

        #expect(!map1.isEmpty)
    }

    @Test
    func remove() {
        var map = PanMap<BeatTime>()

        map.insert(time: 1,
                   pan: .left)
        map.remove(time: 1,
                   pan: .left)

        #expect(map.isEmpty)
    }

    @Test
    func subscript_empty() {
        let map = PanMap<BeatTime>()

        #expect(map[BeatTime(1)] == .center)
    }
}

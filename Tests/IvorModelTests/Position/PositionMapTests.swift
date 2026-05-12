@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct PositionMapTests {
}

// MARK: -

extension PositionMapTests {
    @Test
    func defaultPosition() {
        let map = PositionMap<BeatTime>()

        #expect(map.defaultPosition == .center)
    }

    @Test
    func defaultPosition_override() {
        let map = PositionMap<BeatTime>(defaultPosition: .right)

        #expect(map.defaultPosition == .right)
    }

    @Test
    func inserting() {
        let map = PositionMap<BeatTime>().inserting(time: 1,
                                                    position: .left)

        #expect(!map.isEmpty)
    }

    @Test
    func isEmpty_afterInsert() {
        var map = PositionMap<BeatTime>()

        map.insert(time: 1,
                   position: .right)

        #expect(!map.isEmpty)
    }

    @Test
    func isEmpty_initial() {
        let map = PositionMap<BeatTime>()

        #expect(map.isEmpty)
    }

    @Test
    func merge() {
        var map1 = PositionMap<BeatTime>()
        var map2 = PositionMap<BeatTime>()

        map1.insert(time: 1,
                    position: .left)
        map2.insert(time: 3,
                    position: .right)
        map1.merge(with: map2)

        #expect(!map1.isEmpty)
    }

    @Test
    func remove() {
        var map = PositionMap<BeatTime>()

        map.insert(time: 1,
                   position: .left)
        map.remove(time: 1,
                   position: .left)

        #expect(map.isEmpty)
    }

    @Test
    func subscript_empty() {
        let map = PositionMap<BeatTime>()

        #expect(map[BeatTime(1)] == .center)
    }
}

// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct DynamicMapTests {
}

// MARK: -

extension DynamicMapTests {
    @Test
    func defaultDynamic() {
        let map = DynamicMap<BeatTime>()

        #expect(map.defaultDynamic == .mp)
    }

    @Test
    func defaultDynamic_override() {
        let map = DynamicMap<BeatTime>(defaultDynamic: .ff)

        #expect(map.defaultDynamic == .ff)
    }

    @Test
    func forEach() {
        var map = DynamicMap<BeatTime>()

        map.insert(time: 1,
                   dynamic: .f)
        map.insert(time: 3,
                   dynamic: .p)

        var keys: [BeatTime] = []

        map.forEach { time, _, _ in
            keys.append(time)
        }

        #expect(keys.count == 2)
        #expect(keys[0] == 1)
        #expect(keys[1] == 3)
    }

    @Test
    func inserting() {
        let map = DynamicMap<BeatTime>().inserting(time: 2,
                                                   dynamic: .f)

        #expect(!map.isEmpty)
    }

    @Test
    func isEmpty_afterInsert() {
        var map = DynamicMap<BeatTime>()

        map.insert(time: 1,
                   dynamic: .mf)

        #expect(!map.isEmpty)
    }

    @Test
    func isEmpty_initial() {
        let map = DynamicMap<BeatTime>()

        #expect(map.isEmpty)
    }

    @Test
    func merge() {
        var map1 = DynamicMap<BeatTime>()
        var map2 = DynamicMap<BeatTime>()

        map1.insert(time: 1,
                    dynamic: .f)
        map2.insert(time: 3,
                    dynamic: .p)
        map1.merge(with: map2)

        #expect(!map1.isEmpty)
    }

    @Test
    func merging() {
        let map1 = DynamicMap<BeatTime>().inserting(time: 1,
                                                    dynamic: .f)
        let map2 = DynamicMap<BeatTime>().inserting(time: 3,
                                                    dynamic: .p)
        let merged = map1.merging(with: map2)

        #expect(!merged.isEmpty)
    }

    @Test
    func remove() {
        var map = DynamicMap<BeatTime>()

        map.insert(time: 1,
                   dynamic: .mf)
        map.remove(time: 1,
                   dynamic: .mf)

        #expect(map.isEmpty)
    }

    @Test
    func removing() {
        let map = DynamicMap<BeatTime>()
            .inserting(time: 1,
                       dynamic: .mf)
            .removing(time: 1,
                      dynamic: .mf)

        #expect(map.isEmpty)
    }

    @Test
    func subscript_empty() {
        let map = DynamicMap<BeatTime>()

        #expect(map[BeatTime(1)] == .mp)
    }
}

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct LoudnessMapTests {
}

// MARK: -

extension LoudnessMapTests {
    @Test
    func defaultLoudness() {
        let map = LoudnessMap<BeatTime>()

        #expect(map.defaultLoudness == .mp)
    }

    @Test
    func defaultLoudness_override() {
        let map = LoudnessMap<BeatTime>(defaultLoudness: .ff)

        #expect(map.defaultLoudness == .ff)
    }

    @Test
    func forEach() {
        var map = LoudnessMap<BeatTime>()

        map.insert(time: 1,
                   loudness: .f)
        map.insert(time: 3,
                   loudness: .p)

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
        let map = LoudnessMap<BeatTime>().inserting(time: 2,
                                                    loudness: .f)

        #expect(!map.isEmpty)
    }

    @Test
    func isEmpty_afterInsert() {
        var map = LoudnessMap<BeatTime>()

        map.insert(time: 1,
                   loudness: .mf)

        #expect(!map.isEmpty)
    }

    @Test
    func isEmpty_initial() {
        let map = LoudnessMap<BeatTime>()

        #expect(map.isEmpty)
    }

    @Test
    func merge() {
        var map1 = LoudnessMap<BeatTime>()
        var map2 = LoudnessMap<BeatTime>()

        map1.insert(time: 1,
                    loudness: .f)
        map2.insert(time: 3,
                    loudness: .p)
        map1.merge(with: map2)

        #expect(!map1.isEmpty)
    }

    @Test
    func merging() {
        let map1 = LoudnessMap<BeatTime>().inserting(time: 1,
                                                     loudness: .f)
        let map2 = LoudnessMap<BeatTime>().inserting(time: 3,
                                                     loudness: .p)
        let merged = map1.merging(with: map2)

        #expect(!merged.isEmpty)
    }

    @Test
    func remove() {
        var map = LoudnessMap<BeatTime>()

        map.insert(time: 1,
                   loudness: .mf)
        map.remove(time: 1,
                   loudness: .mf)

        #expect(map.isEmpty)
    }

    @Test
    func removing() {
        let map = LoudnessMap<BeatTime>()
            .inserting(time: 1,
                       loudness: .mf)
            .removing(time: 1,
                      loudness: .mf)

        #expect(map.isEmpty)
    }

    @Test
    func subscript_empty() {
        let map = LoudnessMap<BeatTime>()

        #expect(map[BeatTime(1)] == .mp)
    }
}

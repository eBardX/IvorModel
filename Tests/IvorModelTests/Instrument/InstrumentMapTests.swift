// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct InstrumentMapTests {
    private let guitar: Instrument
    private let piano: Instrument

    init() throws {
        self.guitar = try #require(Instrument(stringValue: "Guitar"))
        self.piano = try #require(Instrument(stringValue: "Piano"))
    }
}

// MARK: -

extension InstrumentMapTests {
    @Test
    func defaultInstrument() {
        let map = InstrumentMap<BeatTime>()

        #expect(map.defaultInstrument == .vanilla)
    }

    @Test
    func defaultInstrument_override() {
        let map = InstrumentMap<BeatTime>(defaultInstrument: piano)

        #expect(map.defaultInstrument == piano)
    }

    @Test
    func forEach() {
        var map = InstrumentMap<BeatTime>()

        map.insert(time: 1,
                   instrument: guitar)
        map.insert(time: 3,
                   instrument: piano)

        var visited: [(BeatTime, Instrument)] = []

        map.forEach { time, instrument, _ in
            visited.append((time, instrument))
        }

        #expect(visited.count == 2)
        #expect(visited[0] == (1, guitar))
        #expect(visited[1] == (3, piano))
    }

    @Test
    func hasExtras_initial() {
        let map = InstrumentMap<BeatTime>()

        #expect(!map.hasExtras)
    }

    @Test
    func inserting() {
        let map = InstrumentMap<BeatTime>().inserting(time: 2,
                                                      instrument: guitar)

        #expect(!map.isEmpty)
        #expect(map[2] == guitar)
    }

    @Test
    func isEmpty_afterInsert() {
        var map = InstrumentMap<BeatTime>()

        map.insert(time: 1,
                   instrument: guitar)

        #expect(!map.isEmpty)
    }

    @Test
    func isEmpty_initial() {
        let map = InstrumentMap<BeatTime>()

        #expect(map.isEmpty)
    }

    @Test
    func merge() {
        var map1 = InstrumentMap<BeatTime>()
        var map2 = InstrumentMap<BeatTime>()

        map1.insert(time: 1,
                    instrument: guitar)
        map2.insert(time: 3,
                    instrument: piano)
        map1.merge(with: map2)

        #expect(map1[1] == guitar)
        #expect(map1[3] == piano)
    }

    @Test
    func merging() {
        let map1 = InstrumentMap<BeatTime>().inserting(time: 1,
                                                       instrument: guitar)
        let map2 = InstrumentMap<BeatTime>().inserting(time: 3,
                                                       instrument: piano)
        let merged = map1.merging(with: map2)

        #expect(merged[1] == guitar)
        #expect(merged[3] == piano)
    }

    @Test
    func remove() {
        var map = InstrumentMap<BeatTime>()

        map.insert(time: 1,
                   instrument: guitar)
        map.remove(time: 1,
                   instrument: guitar)

        #expect(map.isEmpty)
    }

    @Test
    func removing() {
        let map = InstrumentMap<BeatTime>()
            .inserting(time: 1,
                       instrument: guitar)
            .removing(time: 1,
                      instrument: guitar)

        #expect(map.isEmpty)
    }

    @Test
    func subscript_afterInsert() {
        var map = InstrumentMap<BeatTime>()

        map.insert(time: 2,
                   instrument: guitar)
        map.insert(time: 5,
                   instrument: piano)

        #expect(map[BeatTime(1)] == guitar)
        #expect(map[BeatTime(2)] == guitar)
        #expect(map[BeatTime(3)] == guitar)
        #expect(map[BeatTime(5)] == piano)
        #expect(map[BeatTime(7)] == piano)
    }

    @Test
    func subscript_empty() {
        let map = InstrumentMap<BeatTime>()

        #expect(map[BeatTime(1)] == Instrument.vanilla)
    }
}

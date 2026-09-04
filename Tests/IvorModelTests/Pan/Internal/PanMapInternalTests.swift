// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct PanMapInternalTests {
}

// MARK: -

extension PanMapInternalTests {
    @Test
    func deduplicated_keepsFirstOccurrence() {
        let first = PanMap<BeatTime>.Entry(time: 1, pan: .left, extras: nil)
        let duplicate = PanMap<BeatTime>.Entry(time: 1, pan: .left, extras: nil)
        let distinct = PanMap<BeatTime>.Entry(time: 2, pan: .right, extras: nil)
        let result = PanMap<BeatTime>.deduplicated([first, duplicate, distinct])

        #expect(result.count == 2)
        #expect(result[0].entryID == first.entryID)
        #expect(result[1].entryID == distinct.entryID)
    }

    @Test
    func deduplicated_empty() {
        #expect(PanMap<BeatTime>.deduplicated([]).isEmpty)
    }

    @Test
    func firstIndex_found() {
        var map = PanMap<BeatTime>()

        map.insert(time: 1, pan: .left)
        map.insert(time: 2, pan: .right)

        #expect(map.firstIndex(time: 2, pan: .right, extras: nil) == 1)
    }

    @Test
    func firstIndex_entryID_found() throws {
        var map = PanMap<BeatTime>()
        var foundEntryID: PanMap<BeatTime>.EntryID?

        map.insert(time: 1, pan: .left)

        map.forEach { entryID, _, _, _ in foundEntryID = entryID }

        #expect(try map.firstIndex(entryID: #require(foundEntryID)) == 0)
    }

    @Test
    func firstIndex_entryID_notFound() {
        let map = PanMap<BeatTime>()
        let position = map.firstIndex(entryID: PanMap<BeatTime>.EntryID())

        #expect(position == nil)
    }

    @Test
    func firstIndex_notFound() {
        var map = PanMap<BeatTime>()

        map.insert(time: 1, pan: .left)

        let index = map.firstIndex(time: 2, pan: .right, extras: nil)

        #expect(index == nil)
    }

    @Test
    func hasExtras_withExtras() {
        let entries = [PanMap<BeatTime>.Entry(time: 1,
                                              pan: .left,
                                              extras: Extras(elements: [Extra(name: "auto")]))]

        #expect(PanMap<BeatTime>.hasExtras(in: entries))
    }

    @Test
    func hasExtras_withoutExtras() {
        let entries = [PanMap<BeatTime>.Entry(time: 1, pan: .left, extras: nil)]

        #expect(!PanMap<BeatTime>.hasExtras(in: entries))
    }

    @Test
    func insertionIndex_empty() {
        let map = PanMap<BeatTime>()

        #expect(map.insertionIndex(for: 1) == 0)
    }

    @Test
    func insertionIndex_middle() {
        var map = PanMap<BeatTime>()

        map.insert(time: 1, pan: .left)
        map.insert(time: 3, pan: .right)

        #expect(map.insertionIndex(for: 2) == 1)
    }
}

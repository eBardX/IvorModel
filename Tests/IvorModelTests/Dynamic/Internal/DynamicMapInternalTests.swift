// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct DynamicMapInternalTests {
}

// MARK: -

extension DynamicMapInternalTests {
    @Test
    func deduplicated_keepsFirstOccurrence() {
        let first = DynamicMap<BeatTime>.Entry(time: 1, dynamic: .f, extras: nil)
        let duplicate = DynamicMap<BeatTime>.Entry(time: 1, dynamic: .f, extras: nil)
        let distinct = DynamicMap<BeatTime>.Entry(time: 2, dynamic: .p, extras: nil)
        let result = DynamicMap<BeatTime>.deduplicated([first, duplicate, distinct])

        #expect(result.count == 2)
        #expect(result[0].entryID == first.entryID)
        #expect(result[1].entryID == distinct.entryID)
    }

    @Test
    func deduplicated_empty() {
        #expect(DynamicMap<BeatTime>.deduplicated([]).isEmpty)
    }

    @Test
    func firstIndex_found() {
        var map = DynamicMap<BeatTime>()

        map.insert(time: 1, dynamic: .f)
        map.insert(time: 2, dynamic: .p)

        #expect(map.firstIndex(time: 2, dynamic: .p, extras: nil) == 1)
    }

    @Test
    func firstIndex_entryID_found() throws {
        var map = DynamicMap<BeatTime>()
        var foundEntryID: DynamicMap<BeatTime>.EntryID?

        map.insert(time: 1, dynamic: .f)

        map.forEach { entryID, _, _, _ in foundEntryID = entryID }

        #expect(try map.firstIndex(entryID: #require(foundEntryID)) == 0)
    }

    @Test
    func firstIndex_entryID_notFound() {
        let map = DynamicMap<BeatTime>()
        let position = map.firstIndex(entryID: DynamicMap<BeatTime>.EntryID())

        #expect(position == nil)
    }

    @Test
    func firstIndex_notFound() {
        var map = DynamicMap<BeatTime>()

        map.insert(time: 1, dynamic: .f)

        let index = map.firstIndex(time: 2, dynamic: .p, extras: nil)

        #expect(index == nil)
    }

    @Test
    func hasExtras_withExtras() {
        let entries = [DynamicMap<BeatTime>.Entry(time: 1,
                                                  dynamic: .f,
                                                  extras: Extras(elements: [Extra(name: "accent")]))]

        #expect(DynamicMap<BeatTime>.hasExtras(in: entries))
    }

    @Test
    func hasExtras_withoutExtras() {
        let entries = [DynamicMap<BeatTime>.Entry(time: 1, dynamic: .f, extras: nil)]

        #expect(!DynamicMap<BeatTime>.hasExtras(in: entries))
    }

    @Test
    func insertionIndex_empty() {
        let map = DynamicMap<BeatTime>()

        #expect(map.insertionIndex(for: 1) == 0)
    }

    @Test
    func insertionIndex_middle() {
        var map = DynamicMap<BeatTime>()

        map.insert(time: 1, dynamic: .f)
        map.insert(time: 3, dynamic: .p)

        #expect(map.insertionIndex(for: 2) == 1)
    }
}

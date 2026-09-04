// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct InstrumentMapInternalTests {
    private let guitar: Instrument
    private let piano: Instrument

    init() throws {
        self.guitar = try #require(Instrument(stringValue: "Guitar"))
        self.piano = try #require(Instrument(stringValue: "Piano"))
    }
}

// MARK: -

extension InstrumentMapInternalTests {
    @Test
    func deduplicated_keepsFirstOccurrence() {
        let first = InstrumentMap<BeatTime>.Entry(time: 1, instrument: guitar, extras: nil)
        let duplicate = InstrumentMap<BeatTime>.Entry(time: 1, instrument: guitar, extras: nil)
        let distinct = InstrumentMap<BeatTime>.Entry(time: 2, instrument: piano, extras: nil)
        let result = InstrumentMap<BeatTime>.deduplicated([first, duplicate, distinct])

        #expect(result.count == 2)
        #expect(result[0].entryID == first.entryID)
        #expect(result[1].entryID == distinct.entryID)
    }

    @Test
    func deduplicated_empty() {
        #expect(InstrumentMap<BeatTime>.deduplicated([]).isEmpty)
    }

    @Test
    func firstIndex_found() {
        var map = InstrumentMap<BeatTime>()

        map.insert(time: 1, instrument: guitar)
        map.insert(time: 2, instrument: piano)

        #expect(map.firstIndex(time: 2, instrument: piano, extras: nil) == 1)
    }

    @Test
    func firstIndex_entryID_found() throws {
        var map = InstrumentMap<BeatTime>()
        var foundEntryID: InstrumentMap<BeatTime>.EntryID?

        map.insert(time: 1, instrument: guitar)

        map.forEach { entryID, _, _, _ in foundEntryID = entryID }

        #expect(try map.firstIndex(entryID: #require(foundEntryID)) == 0)
    }

    @Test
    func firstIndex_entryID_notFound() {
        let map = InstrumentMap<BeatTime>()
        let position = map.firstIndex(entryID: InstrumentMap<BeatTime>.EntryID())

        #expect(position == nil)
    }

    @Test
    func firstIndex_notFound() {
        var map = InstrumentMap<BeatTime>()

        map.insert(time: 1, instrument: guitar)

        let index = map.firstIndex(time: 2, instrument: piano, extras: nil)

        #expect(index == nil)
    }

    @Test
    func hasExtras_withExtras() {
        let entries = [InstrumentMap<BeatTime>.Entry(time: 1,
                                                     instrument: guitar,
                                                     extras: Extras(elements: [Extra(name: "muted")]))]

        #expect(InstrumentMap<BeatTime>.hasExtras(in: entries))
    }

    @Test
    func hasExtras_withoutExtras() {
        let entries = [InstrumentMap<BeatTime>.Entry(time: 1, instrument: guitar, extras: nil)]

        #expect(!InstrumentMap<BeatTime>.hasExtras(in: entries))
    }

    @Test
    func insertionIndex_empty() {
        let map = InstrumentMap<BeatTime>()

        #expect(map.insertionIndex(for: 1) == 0)
    }

    @Test
    func insertionIndex_middle() {
        var map = InstrumentMap<BeatTime>()

        map.insert(time: 1, instrument: guitar)
        map.insert(time: 3, instrument: piano)

        #expect(map.insertionIndex(for: 2) == 1)
    }
}

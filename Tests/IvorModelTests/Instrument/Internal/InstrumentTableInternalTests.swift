// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct InstrumentTableInternalTests {
    private let guitar: Instrument
    private let piano: Instrument

    init() throws {
        self.guitar = try #require(Instrument(stringValue: "Guitar"))
        self.piano = try #require(Instrument(stringValue: "Piano"))
    }
}

// MARK: -

extension InstrumentTableInternalTests {
    @Test
    func deduplicated_empty() {
        #expect(InstrumentTable<BeatTime>.deduplicated([]).isEmpty)
    }

    @Test
    func deduplicated_keepsFirstOccurrence() {
        let first = InstrumentTable<BeatTime>.StoredEntry(time: 1, instrument: guitar, extras: nil)
        let duplicate = InstrumentTable<BeatTime>.StoredEntry(time: 1, instrument: guitar, extras: nil)
        let distinct = InstrumentTable<BeatTime>.StoredEntry(time: 2, instrument: piano, extras: nil)
        let result = InstrumentTable<BeatTime>.deduplicated([first, duplicate, distinct])

        #expect(result.count == 2)
        #expect(result[0].entryID == first.entryID)
        #expect(result[1].entryID == distinct.entryID)
    }

    @Test
    func firstIndex_entryID_found() throws {
        var table = InstrumentTable<BeatTime>()
        var foundEntryID: EntryID?

        table.insert(time: 1, instrument: guitar)

        for entry in table {
            foundEntryID = entry.entryID
        }

        #expect(try table.firstIndex(entryID: #require(foundEntryID)) == 0)
    }

    @Test
    func firstIndex_entryID_notFound() {
        let table = InstrumentTable<BeatTime>()
        let position = table.firstIndex(entryID: EntryID())

        #expect(position == nil)
    }

    @Test
    func firstIndex_found() {
        var table = InstrumentTable<BeatTime>()

        table.insert(time: 1, instrument: guitar)
        table.insert(time: 2, instrument: piano)

        #expect(table.firstIndex(time: 2, instrument: piano, extras: nil) == 1)
    }

    @Test
    func firstIndex_notFound() {
        var table = InstrumentTable<BeatTime>()

        table.insert(time: 1, instrument: guitar)

        let index = table.firstIndex(time: 2, instrument: piano, extras: nil)

        #expect(index == nil)
    }

    @Test
    func hasExtras_withExtras() {
        let entries = [InstrumentTable<BeatTime>.StoredEntry(time: 1,
                                                             instrument: guitar,
                                                             extras: Extras(elements: [Extra(name: "muted")]))]

        #expect(InstrumentTable<BeatTime>.hasExtras(in: entries))
    }

    @Test
    func hasExtras_withoutExtras() {
        let entries = [InstrumentTable<BeatTime>.StoredEntry(time: 1, instrument: guitar, extras: nil)]

        #expect(!InstrumentTable<BeatTime>.hasExtras(in: entries))
    }

    @Test
    func insertionIndex_empty() {
        let table = InstrumentTable<BeatTime>()

        #expect(table.insertionIndex(for: 1) == 0)
    }

    @Test
    func insertionIndex_middle() {
        var table = InstrumentTable<BeatTime>()

        table.insert(time: 1, instrument: guitar)
        table.insert(time: 3, instrument: piano)

        #expect(table.insertionIndex(for: 2) == 1)
    }
}

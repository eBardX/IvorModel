// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct InstrumentTableTests {
    private let guitar: Instrument
    private let piano: Instrument

    init() throws {
        self.guitar = try #require(Instrument(stringValue: "Guitar"))
        self.piano = try #require(Instrument(stringValue: "Piano"))
    }
}

// MARK: -

extension InstrumentTableTests {
    @Test
    func codable_decodeDeduplicatesLegacyDuplicates() throws {
        var table = InstrumentTable<BeatTime>()

        // Simulates a document saved before `insert`'s dedup rule existed: nothing
        // about `Codable` itself enforces uniqueness, so two exact-duplicate entries
        // can land in `entries` directly, bypassing `insert`'s own guard.
        table.entries = [InstrumentTable<BeatTime>.StoredEntry(time: 1, instrument: guitar, extras: nil),
                         InstrumentTable<BeatTime>.StoredEntry(time: 1, instrument: guitar, extras: nil)]

        let data = try JSONEncoder().encode(table)
        let decoded = try JSONDecoder().decode(InstrumentTable<BeatTime>.self, from: data)
        var count = 0

        for _ in decoded {
            count += 1
        }

        #expect(count == 1)
    }

    @Test
    func collection_empty() {
        let table = InstrumentTable<BeatTime>()

        #expect(table.isEmpty)
        #expect(table.startIndex == table.endIndex)
        #expect(table.first == nil)
        #expect(table.last == nil)
    }

    @Test
    func collection_iteratesEntriesInTimeOrder() {
        var table = InstrumentTable<BeatTime>()

        let later = table.insert(time: 2,
                                 instrument: guitar)
        let earlier = table.insert(time: 1,
                                   instrument: piano)

        #expect(table.count == 2)
        #expect(table.map(\.entryID) == [earlier.entryID, later.entryID])
        #expect(table.map(\.time) == [1, 2])
        #expect(table.first?.instrument == piano)
        #expect(table[table.index(after: table.startIndex)].instrument == guitar)
        #expect(table.index(table.startIndex, offsetBy: 2) == table.endIndex)
        #expect(table.distance(from: table.endIndex, to: table.startIndex) == -2)
        #expect(table.index(before: table.endIndex) == table.index(after: table.startIndex))
    }

    @Test
    func defaultInstrument() {
        let table = InstrumentTable<BeatTime>()

        #expect(table.defaultInstrument == .vanilla)
    }

    @Test
    func defaultInstrument_override() {
        let table = InstrumentTable<BeatTime>(defaultInstrument: piano)

        #expect(table.defaultInstrument == piano)
    }

    @Test
    func forEach() {
        var table = InstrumentTable<BeatTime>()

        table.insert(time: 1,
                     instrument: guitar)
        table.insert(time: 3,
                     instrument: piano)

        var visited: [(BeatTime, Instrument)] = []

        for entry in table {
            visited.append((entry.time, entry.instrument))
        }

        #expect(visited.count == 2)
        #expect(visited[0] == (1, guitar))
        #expect(visited[1] == (3, piano))
    }

    @Test
    func forEach_yieldsDistinctIdentities() {
        var table = InstrumentTable<BeatTime>()
        var ids: [EntryID] = []

        table.insert(time: 1, instrument: guitar)
        table.insert(time: 2, instrument: piano)

        for entry in table {
            ids.append(entry.entryID)
        }

        #expect(Set(ids).count == 2)
    }

    @Test
    func hasExtras_initial() {
        let table = InstrumentTable<BeatTime>()

        #expect(!table.hasExtras)
    }

    @Test
    func insert_duplicate() {
        var table = InstrumentTable<BeatTime>()

        let first = table.insert(time: 1, instrument: guitar)
        let second = table.insert(time: 1, instrument: guitar)

        #expect(first.inserted)
        #expect(!second.inserted)
        #expect(second.entryID == first.entryID)
    }

    @Test
    func insert_new() {
        var table = InstrumentTable<BeatTime>()

        let first = table.insert(time: 1, instrument: guitar)
        let second = table.insert(time: 2, instrument: piano)

        #expect(first.inserted)
        #expect(second.inserted)
        #expect(second.entryID != first.entryID)
    }

    @Test
    func instruments_eachOnceInOrderOfFirstUse() {
        var table = InstrumentTable<BeatTime>(defaultInstrument: .vanilla)

        table.insert(time: 4,
                     instrument: guitar)
        table.insert(time: 1,
                     instrument: piano)
        table.insert(time: 8,
                     instrument: piano)
        table.insert(time: 12,
                     instrument: guitar)

        //
        // The first entry is at 1, so the default instrument is in effect before it:
        //
        #expect(table.instruments == [.vanilla, piano, guitar])
    }

    @Test
    func instruments_empty_isDefaultInstrument() {
        #expect(InstrumentTable<BeatTime>(defaultInstrument: piano).instruments == [piano])
    }

    @Test
    func instruments_firstEntryAtZero_omitsDefaultInstrument() {
        var table = InstrumentTable<BeatTime>(defaultInstrument: .vanilla)

        table.insert(time: 0,
                     instrument: piano)
        table.insert(time: 4,
                     instrument: guitar)

        #expect(table.instruments == [piano, guitar])
    }

    @Test
    func isEmpty_afterInsert() {
        var table = InstrumentTable<BeatTime>()

        table.insert(time: 1,
                     instrument: guitar)

        #expect(!table.isEmpty)
    }

    @Test
    func isEmpty_initial() {
        let table = InstrumentTable<BeatTime>()

        #expect(table.isEmpty)
    }

    @Test
    func last_empty() {
        #expect(InstrumentTable<BeatTime>().last == nil)
    }

    @Test
    func last_returnsLastEntryInTimeOrder() throws {
        let extras = Extras(elements: [Extra(name: "tag")])
        var table = InstrumentTable<BeatTime>()

        let later = table.insert(time: 2,
                                 instrument: guitar,
                                 extras: extras)

        table.insert(time: 1,
                     instrument: piano)

        let last = try #require(table.last)

        #expect(last.entryID == later.entryID)
        #expect(last.time == 2)
        #expect(last.instrument == guitar)
        #expect(last.extras == extras)
    }

    @Test
    func merge() {
        var map1 = InstrumentTable<BeatTime>()
        var map2 = InstrumentTable<BeatTime>()

        map1.insert(time: 1,
                    instrument: guitar)
        map2.insert(time: 3,
                    instrument: piano)
        map1.merge(with: map2)

        #expect(map1[1] == guitar)
        #expect(map1[3] == piano)
    }

    @Test
    func move_found() throws {
        var table = InstrumentTable<BeatTime>()
        var movedID: EntryID?

        table.insert(time: 1, instrument: guitar)

        for entry in table {
            movedID = entry.entryID
        }

        let entryID = try #require(movedID)
        let newID = table.move(entryID: entryID, to: 5)

        #expect(newID == entryID)
        #expect(table[BeatTime(5)] == guitar)
    }

    @Test
    func move_notFound() {
        var table = InstrumentTable<BeatTime>()

        #expect(table.move(entryID: EntryID(), to: 1) == nil)
    }

    @Test
    func remove_entryID_found() throws {
        var table = InstrumentTable<BeatTime>()
        var removedID: EntryID?

        table.insert(time: 1, instrument: guitar)

        for entry in table {
            removedID = entry.entryID
        }

        let entryID = try #require(removedID)
        let removed = table.remove(entryID: entryID)

        #expect(removed)
        #expect(table.isEmpty)
    }

    @Test
    func remove_entryID_notFound() {
        var table = InstrumentTable<BeatTime>()

        table.insert(time: 1, instrument: guitar)

        let removed = table.remove(entryID: EntryID())

        #expect(!removed)
        #expect(!table.isEmpty)
    }

    @Test
    func subscript_afterInsert() {
        var table = InstrumentTable<BeatTime>()

        table.insert(time: 2,
                     instrument: guitar)
        table.insert(time: 5,
                     instrument: piano)

        #expect(table[BeatTime(1)] == .vanilla)
        #expect(table[BeatTime(2)] == guitar)
        #expect(table[BeatTime(3)] == guitar)
        #expect(table[BeatTime(5)] == piano)
        #expect(table[BeatTime(7)] == piano)
    }

    @Test
    func subscript_beforeFirstEntry_isDefaultInstrument() {
        var table = InstrumentTable<BeatTime>(defaultInstrument: piano)

        table.insert(time: 2,
                     instrument: guitar)

        #expect(table[BeatTime(0)] == piano)
        #expect(table[BeatTime(1)] == piano)
        #expect(table[BeatTime(2)] == guitar)
    }

    @Test
    func subscript_empty() {
        let table = InstrumentTable<BeatTime>()

        #expect(table[BeatTime(1)] == Instrument.vanilla)
    }

    @Test
    func subscript_integerLiteral_isTime() {
        var table = InstrumentTable<BeatTime>()

        table.insert(time: 0,
                     instrument: piano)
        table.insert(time: 1,
                     instrument: guitar)

        //
        // `1` must resolve to the time subscript, not a position — positions are an opaque
        // `Index` precisely so an integer literal can’t select them:
        //
        let value = table[1]

        #expect(value == guitar)
    }

    @Test
    func update_collapsesIntoDuplicate() throws {
        var table = InstrumentTable<BeatTime>()
        var ids: [EntryID] = []

        table.insert(time: 1, instrument: guitar)
        table.insert(time: 1, instrument: piano)

        for entry in table {
            ids.append(entry.entryID)
        }

        // Editing the second entry back to `guitar` makes it an exact duplicate
        // of the first, so it should be dropped rather than left in place.
        let result = try table.update(entryID: #require(ids.last), instrument: guitar)

        #expect(result.updated)
        #expect(result.removedEntryID == ids.first)

        var remaining: [EntryID] = []

        for entry in table {
            remaining.append(entry.entryID)
        }

        #expect(remaining == [ids.last])
    }

    @Test
    func update_found() throws {
        var table = InstrumentTable<BeatTime>()
        var foundEntryID: EntryID?

        table.insert(time: 1, instrument: guitar)

        for entry in table {
            foundEntryID = entry.entryID
        }

        let result = try table.update(entryID: #require(foundEntryID), instrument: piano)

        #expect(result.updated)
        #expect(result.removedEntryID == nil)
        #expect(table[BeatTime(1)] == piano)
    }

    @Test
    func update_notFound() {
        var table = InstrumentTable<BeatTime>()

        let result = table.update(entryID: EntryID(), instrument: piano)

        #expect(!result.updated)
        #expect(result.removedEntryID == nil)
        #expect(table.isEmpty)
    }
}

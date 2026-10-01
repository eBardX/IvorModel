// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

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
    func codable_decodeDeduplicatesLegacyDuplicates() throws {
        var map = InstrumentMap<BeatTime>()

        // Simulates a document saved before `insert`'s dedup rule existed: nothing
        // about `Codable` itself enforces uniqueness, so two exact-duplicate entries
        // can land in `entries` directly, bypassing `insert`'s own guard.
        map.entries = [InstrumentMap<BeatTime>.StoredEntry(time: 1, instrument: guitar, extras: nil),
                       InstrumentMap<BeatTime>.StoredEntry(time: 1, instrument: guitar, extras: nil)]

        let data = try JSONEncoder().encode(map)
        let decoded = try JSONDecoder().decode(InstrumentMap<BeatTime>.self, from: data)
        var count = 0

        for _ in decoded {
            count += 1
        }

        #expect(count == 1)
    }

    @Test
    func collection_empty() {
        let map = InstrumentMap<BeatTime>()

        #expect(map.isEmpty)
        #expect(map.startIndex == map.endIndex)
        #expect(map.first == nil)
        #expect(map.last == nil)
    }

    @Test
    func collection_iteratesEntriesInTimeOrder() {
        var map = InstrumentMap<BeatTime>()

        let later = map.insert(time: 2,
                               instrument: guitar)
        let earlier = map.insert(time: 1,
                                 instrument: piano)

        #expect(map.count == 2)
        #expect(map.map(\.entryID) == [earlier.entryID, later.entryID])
        #expect(map.map(\.time) == [1, 2])
        #expect(map.first?.instrument == piano)
        #expect(map[map.index(after: map.startIndex)].instrument == guitar)
        #expect(map.index(map.startIndex, offsetBy: 2) == map.endIndex)
        #expect(map.distance(from: map.endIndex, to: map.startIndex) == -2)
        #expect(map.index(before: map.endIndex) == map.index(after: map.startIndex))
    }

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

        for entry in map {
            visited.append((entry.time, entry.instrument))
        }

        #expect(visited.count == 2)
        #expect(visited[0] == (1, guitar))
        #expect(visited[1] == (3, piano))
    }

    @Test
    func forEach_yieldsDistinctIdentities() {
        var map = InstrumentMap<BeatTime>()
        var ids: [EntryID] = []

        map.insert(time: 1, instrument: guitar)
        map.insert(time: 2, instrument: piano)

        for entry in map {
            ids.append(entry.entryID)
        }

        #expect(Set(ids).count == 2)
    }

    @Test
    func hasExtras_initial() {
        let map = InstrumentMap<BeatTime>()

        #expect(!map.hasExtras)
    }

    @Test
    func insert_duplicate() {
        var map = InstrumentMap<BeatTime>()

        let first = map.insert(time: 1, instrument: guitar)
        let second = map.insert(time: 1, instrument: guitar)

        #expect(first.inserted)
        #expect(!second.inserted)
        #expect(second.entryID == first.entryID)
    }

    @Test
    func insert_new() {
        var map = InstrumentMap<BeatTime>()

        let first = map.insert(time: 1, instrument: guitar)
        let second = map.insert(time: 2, instrument: piano)

        #expect(first.inserted)
        #expect(second.inserted)
        #expect(second.entryID != first.entryID)
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
    func last_empty() {
        #expect(InstrumentMap<BeatTime>().last == nil)
    }

    @Test
    func last_returnsLastEntryInTimeOrder() throws {
        let extras = Extras(elements: [Extra(name: "tag")])
        var map = InstrumentMap<BeatTime>()

        let later = map.insert(time: 2,
                               instrument: guitar,
                               extras: extras)

        map.insert(time: 1,
                   instrument: piano)

        let last = try #require(map.last)

        #expect(last.entryID == later.entryID)
        #expect(last.time == 2)
        #expect(last.instrument == guitar)
        #expect(last.extras == extras)
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
    func move_found() throws {
        var map = InstrumentMap<BeatTime>()
        var movedID: EntryID?

        map.insert(time: 1, instrument: guitar)

        for entry in map {
            movedID = entry.entryID
        }

        let entryID = try #require(movedID)
        let newID = map.move(entryID: entryID, to: 5)

        #expect(newID == entryID)
        #expect(map[BeatTime(5)] == guitar)
    }

    @Test
    func move_notFound() {
        var map = InstrumentMap<BeatTime>()

        #expect(map.move(entryID: EntryID(), to: 1) == nil)
    }

    @Test
    func remove_entryID_found() throws {
        var map = InstrumentMap<BeatTime>()
        var removedID: EntryID?

        map.insert(time: 1, instrument: guitar)

        for entry in map {
            removedID = entry.entryID
        }

        let entryID = try #require(removedID)
        let removed = map.remove(entryID: entryID)

        #expect(removed)
        #expect(map.isEmpty)
    }

    @Test
    func remove_entryID_notFound() {
        var map = InstrumentMap<BeatTime>()

        map.insert(time: 1, instrument: guitar)

        let removed = map.remove(entryID: EntryID())

        #expect(!removed)
        #expect(!map.isEmpty)
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

    @Test
    func subscript_integerLiteral_isTime() {
        var map = InstrumentMap<BeatTime>()

        map.insert(time: 0,
                   instrument: piano)
        map.insert(time: 1,
                   instrument: guitar)

        //
        // `1` must resolve to the time subscript, not a position — positions are an opaque
        // `Index` precisely so an integer literal can’t select them:
        //
        let value = map[1]

        #expect(value == guitar)
    }

    @Test
    func update_collapsesIntoDuplicate() throws {
        var map = InstrumentMap<BeatTime>()
        var ids: [EntryID] = []

        map.insert(time: 1, instrument: guitar)
        map.insert(time: 1, instrument: piano)

        for entry in map {
            ids.append(entry.entryID)
        }

        // Editing the second entry back to `guitar` makes it an exact duplicate
        // of the first, so it should be dropped rather than left in place.
        let result = try map.update(entryID: #require(ids.last), instrument: guitar)

        #expect(result.updated)
        #expect(result.removedEntryID == ids.first)

        var remaining: [EntryID] = []

        for entry in map {
            remaining.append(entry.entryID)
        }

        #expect(remaining == [ids.last])
    }

    @Test
    func update_found() throws {
        var map = InstrumentMap<BeatTime>()
        var foundEntryID: EntryID?

        map.insert(time: 1, instrument: guitar)

        for entry in map {
            foundEntryID = entry.entryID
        }

        let result = try map.update(entryID: #require(foundEntryID), instrument: piano)

        #expect(result.updated)
        #expect(result.removedEntryID == nil)
        #expect(map[BeatTime(1)] == piano)
    }

    @Test
    func update_notFound() {
        var map = InstrumentMap<BeatTime>()

        let result = map.update(entryID: EntryID(), instrument: piano)

        #expect(!result.updated)
        #expect(result.removedEntryID == nil)
        #expect(map.isEmpty)
    }
}

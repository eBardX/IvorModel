// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct DynamicMapTests {
}

// MARK: -

extension DynamicMapTests {
    @Test
    func codable_decodeDeduplicatesLegacyDuplicates() throws {
        var map = DynamicMap<BeatTime>()

        // Simulates a document saved before `insert`'s dedup rule existed: nothing
        // about `Codable` itself enforces uniqueness, so two exact-duplicate entries
        // can land in `entries` directly, bypassing `insert`'s own guard.
        map.entries = [DynamicMap<BeatTime>.StoredEntry(time: 1, dynamic: .f, extras: nil),
                       DynamicMap<BeatTime>.StoredEntry(time: 1, dynamic: .f, extras: nil)]

        let data = try JSONEncoder().encode(map)
        let decoded = try JSONDecoder().decode(DynamicMap<BeatTime>.self, from: data)
        var count = 0

        for entry in decoded {
            count += 1
        }

        #expect(count == 1)
    }

    @Test
    func collection_empty() {
        let map = DynamicMap<BeatTime>()

        #expect(map.isEmpty)
        #expect(map.startIndex == map.endIndex)
        #expect(map.first == nil)
        #expect(map.last == nil)
    }

    @Test
    func collection_iteratesEntriesInTimeOrder() {
        var map = DynamicMap<BeatTime>()

        let later = map.insert(time: 2,
                               dynamic: .ff)
        let earlier = map.insert(time: 1,
                                 dynamic: .p)

        #expect(map.count == 2)
        #expect(map.map(\.entryID) == [earlier.entryID, later.entryID])
        #expect(map.map(\.time) == [1, 2])
        #expect(map.first?.dynamic == .p)
        #expect(map[map.index(after: map.startIndex)].dynamic == .ff)
        #expect(map.index(map.startIndex, offsetBy: 2) == map.endIndex)
        #expect(map.distance(from: map.endIndex, to: map.startIndex) == -2)
        #expect(map.index(before: map.endIndex) == map.index(after: map.startIndex))
    }

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

        for entry in map {
            keys.append(entry.time)
        }

        #expect(keys.count == 2)
        #expect(keys[0] == 1)
        #expect(keys[1] == 3)
    }

    @Test
    func forEach_yieldsDistinctIdentities() {
        var map = DynamicMap<BeatTime>()
        var ids: [EntryID] = []

        map.insert(time: 1, dynamic: .f)
        map.insert(time: 2, dynamic: .p)

        for entry in map {
            ids.append(entry.entryID)
        }

        #expect(Set(ids).count == 2)
    }

    @Test
    func insert_duplicate() {
        var map = DynamicMap<BeatTime>()

        let first = map.insert(time: 1, dynamic: .f)
        let second = map.insert(time: 1, dynamic: .f)

        #expect(first.inserted)
        #expect(!second.inserted)
        #expect(second.entryID == first.entryID)
    }

    @Test
    func insert_new() {
        var map = DynamicMap<BeatTime>()

        let first = map.insert(time: 1, dynamic: .f)
        let second = map.insert(time: 2, dynamic: .p)

        #expect(first.inserted)
        #expect(second.inserted)
        #expect(second.entryID != first.entryID)
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
    func last_empty() {
        #expect(DynamicMap<BeatTime>().last == nil)
    }

    @Test
    func last_returnsLastEntryInTimeOrder() throws {
        let extras = Extras(elements: [Extra(name: "tag")])
        var map = DynamicMap<BeatTime>()

        let later = map.insert(time: 2,
                               dynamic: .ff,
                               extras: extras)

        map.insert(time: 1,
                   dynamic: .mf)

        let last = try #require(map.last)

        #expect(last.entryID == later.entryID)
        #expect(last.time == 2)
        #expect(last.dynamic == .ff)
        #expect(last.extras == extras)
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
    func move_found() throws {
        var map = DynamicMap<BeatTime>()
        var movedID: EntryID?

        map.insert(time: 1, dynamic: .f)

        for entry in map {
            movedID = entry.entryID
        }

        let entryID = try #require(movedID)
        let newID = map.move(entryID: entryID, to: 5)

        #expect(newID == entryID)
        #expect(map[BeatTime(5)] == .f)
    }

    @Test
    func move_notFound() {
        var map = DynamicMap<BeatTime>()

        #expect(map.move(entryID: EntryID(), to: 1) == nil)
    }

    @Test
    func remove_entryID_found() throws {
        var map = DynamicMap<BeatTime>()
        var removedID: EntryID?

        map.insert(time: 1, dynamic: .f)

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
        var map = DynamicMap<BeatTime>()

        map.insert(time: 1, dynamic: .f)

        let removed = map.remove(entryID: EntryID())

        #expect(!removed)
        #expect(!map.isEmpty)
    }

    @Test
    func subscript_empty() {
        let map = DynamicMap<BeatTime>()

        #expect(map[BeatTime(1)] == .mp)
    }

    @Test
    func subscript_integerLiteral_isTime() {
        var map = DynamicMap<BeatTime>()

        map.insert(time: 0,
                   dynamic: .p)
        map.insert(time: 1,
                   dynamic: .ff)

        //
        // `1` must resolve to the time subscript, not a position — positions are an opaque
        // `Index` precisely so an integer literal can’t select them:
        //
        let value = map[1]

        #expect(value == .ff)
    }

    @Test
    func update_collapsesIntoDuplicate() throws {
        var map = DynamicMap<BeatTime>()
        var ids: [EntryID] = []

        map.insert(time: 1, dynamic: .f)
        map.insert(time: 1, dynamic: .p)

        for entry in map {
            ids.append(entry.entryID)
        }

        // Editing the second entry back to `.f` makes it an exact duplicate of
        // the first, so it should be dropped rather than left in place.
        let result = try map.update(entryID: #require(ids.last), dynamic: .f)

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
        var map = DynamicMap<BeatTime>()
        var foundEntryID: EntryID?

        map.insert(time: 1, dynamic: .f)

        for entry in map {
            foundEntryID = entry.entryID
        }

        let result = try map.update(entryID: #require(foundEntryID), dynamic: .p)

        #expect(result.updated)
        #expect(result.removedEntryID == nil)
        #expect(map[BeatTime(1)] == .p)
    }

    @Test
    func update_notFound() {
        var map = DynamicMap<BeatTime>()

        let result = map.update(entryID: EntryID(), dynamic: .p)

        #expect(!result.updated)
        #expect(result.removedEntryID == nil)
        #expect(map.isEmpty)
    }
}

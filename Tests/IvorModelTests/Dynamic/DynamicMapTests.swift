// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

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
        map.entries = [DynamicMap<BeatTime>.Entry(time: 1, dynamic: .f, extras: nil),
                       DynamicMap<BeatTime>.Entry(time: 1, dynamic: .f, extras: nil)]

        let data = try JSONEncoder().encode(map)
        let decoded = try JSONDecoder().decode(DynamicMap<BeatTime>.self, from: data)
        var count = 0

        decoded.forEach { _, _, _, _ in count += 1 }

        #expect(count == 1)
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

        map.forEach { _, time, _, _ in
            keys.append(time)
        }

        #expect(keys.count == 2)
        #expect(keys[0] == 1)
        #expect(keys[1] == 3)
    }

    @Test
    func forEach_yieldsDistinctIdentities() {
        var map = DynamicMap<BeatTime>()
        var ids: [DynamicMap<BeatTime>.EntryID] = []

        map.insert(time: 1, dynamic: .f)
        map.insert(time: 2, dynamic: .p)

        map.forEach { entryID, _, _, _ in ids.append(entryID) }

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
    func move_found() throws {
        var map = DynamicMap<BeatTime>()
        var movedID: DynamicMap<BeatTime>.EntryID?

        map.insert(time: 1, dynamic: .f)

        map.forEach { entryID, _, _, _ in movedID = entryID }

        let entryID = try #require(movedID)
        let newID = map.move(entryID: entryID, to: 5)

        #expect(newID == entryID)
        #expect(map[BeatTime(5)] == .f)
    }

    @Test
    func move_notFound() {
        var map = DynamicMap<BeatTime>()

        #expect(map.move(entryID: DynamicMap<BeatTime>.EntryID(), to: 1) == nil)
    }

    @Test
    func update_found() throws {
        var map = DynamicMap<BeatTime>()
        var foundEntryID: DynamicMap<BeatTime>.EntryID?

        map.insert(time: 1, dynamic: .f)

        map.forEach { entryID, _, _, _ in foundEntryID = entryID }

        let result = try map.update(entryID: #require(foundEntryID), dynamic: .p)

        #expect(result.updated)
        #expect(result.removedEntryID == nil)
        #expect(map[BeatTime(1)] == .p)
    }

    @Test
    func update_notFound() {
        var map = DynamicMap<BeatTime>()

        let result = map.update(entryID: DynamicMap<BeatTime>.EntryID(), dynamic: .p)

        #expect(!result.updated)
        #expect(result.removedEntryID == nil)
        #expect(map.isEmpty)
    }

    @Test
    func update_collapsesIntoDuplicate() throws {
        var map = DynamicMap<BeatTime>()
        var ids: [DynamicMap<BeatTime>.EntryID] = []

        map.insert(time: 1, dynamic: .f)
        map.insert(time: 1, dynamic: .p)

        map.forEach { entryID, _, _, _ in ids.append(entryID) }

        // Editing the second entry back to `.f` makes it an exact duplicate of
        // the first, so it should be dropped rather than left in place.
        let result = try map.update(entryID: #require(ids.last), dynamic: .f)

        #expect(result.updated)
        #expect(result.removedEntryID == ids.first)

        var remaining: [DynamicMap<BeatTime>.EntryID] = []

        map.forEach { entryID, _, _, _ in remaining.append(entryID) }

        #expect(remaining == [ids.last])
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
    func remove_found() {
        var map = DynamicMap<BeatTime>()

        let inserted = map.insert(time: 1,
                                  dynamic: .mf)
        let removedID = map.remove(time: 1,
                                   dynamic: .mf)

        #expect(removedID == inserted.entryID)
        #expect(map.isEmpty)
    }

    @Test
    func remove_notFound() {
        var map = DynamicMap<BeatTime>()

        map.insert(time: 1, dynamic: .f)

        let removedID = map.remove(time: 1, dynamic: .p)

        #expect(removedID == nil)
        #expect(!map.isEmpty)
    }

    @Test
    func remove_entryID_found() throws {
        var map = DynamicMap<BeatTime>()
        var removedID: DynamicMap<BeatTime>.EntryID?

        map.insert(time: 1, dynamic: .f)

        map.forEach { entryID, _, _, _ in removedID = entryID }

        let entryID = try #require(removedID)
        let removed = map.remove(entryID: entryID)

        #expect(removed)
        #expect(map.isEmpty)
    }

    @Test
    func remove_entryID_notFound() {
        var map = DynamicMap<BeatTime>()

        map.insert(time: 1, dynamic: .f)

        let removed = map.remove(entryID: DynamicMap<BeatTime>.EntryID())

        #expect(!removed)
        #expect(!map.isEmpty)
    }

    @Test
    func subscript_empty() {
        let map = DynamicMap<BeatTime>()

        #expect(map[BeatTime(1)] == .mp)
    }
}

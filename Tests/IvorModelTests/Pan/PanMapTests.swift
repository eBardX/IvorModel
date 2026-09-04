// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct PanMapTests {
}

// MARK: -

extension PanMapTests {
    @Test
    func codable_decodeDeduplicatesLegacyDuplicates() throws {
        var map = PanMap<BeatTime>()

        // Simulates a document saved before `insert`'s dedup rule existed: nothing
        // about `Codable` itself enforces uniqueness, so two exact-duplicate entries
        // can land in `entries` directly, bypassing `insert`'s own guard.
        map.entries = [PanMap<BeatTime>.Entry(time: 1, pan: .left, extras: nil),
                       PanMap<BeatTime>.Entry(time: 1, pan: .left, extras: nil)]

        let data = try JSONEncoder().encode(map)
        let decoded = try JSONDecoder().decode(PanMap<BeatTime>.self, from: data)
        var count = 0

        decoded.forEach { _, _, _, _ in count += 1 }

        #expect(count == 1)
    }

    @Test
    func forEach_yieldsDistinctIdentities() {
        var map = PanMap<BeatTime>()
        var ids: [PanMap<BeatTime>.EntryID] = []

        map.insert(time: 1, pan: .left)
        map.insert(time: 2, pan: .right)

        map.forEach { entryID, _, _, _ in ids.append(entryID) }

        #expect(Set(ids).count == 2)
    }

    @Test
    func insert_duplicate() {
        var map = PanMap<BeatTime>()

        let first = map.insert(time: 1, pan: .left)
        let second = map.insert(time: 1, pan: .left)

        #expect(first.inserted)
        #expect(!second.inserted)
        #expect(second.entryID == first.entryID)
    }

    @Test
    func insert_new() {
        var map = PanMap<BeatTime>()

        let first = map.insert(time: 1, pan: .left)
        let second = map.insert(time: 2, pan: .right)

        #expect(first.inserted)
        #expect(second.inserted)
        #expect(second.entryID != first.entryID)
    }

    @Test
    func move_found() throws {
        var map = PanMap<BeatTime>()
        var movedID: PanMap<BeatTime>.EntryID?

        map.insert(time: 1, pan: .left)

        map.forEach { entryID, _, _, _ in movedID = entryID }

        let entryID = try #require(movedID, "expected an entry ID")

        let newID = map.move(entryID: entryID, to: 5)

        #expect(newID == entryID)
        #expect(map[BeatTime(5)] == .left)
    }

    @Test
    func move_notFound() {
        var map = PanMap<BeatTime>()

        #expect(map.move(entryID: PanMap<BeatTime>.EntryID(), to: 1) == nil)
    }

    @Test
    func update_found() throws {
        var map = PanMap<BeatTime>()
        var foundEntryID: PanMap<BeatTime>.EntryID?

        map.insert(time: 1, pan: .left)

        map.forEach { entryID, _, _, _ in foundEntryID = entryID }

        let result = try map.update(entryID: #require(foundEntryID), pan: .right)

        #expect(result.updated)
        #expect(result.removedEntryID == nil)
        #expect(map[BeatTime(1)] == .right)
    }

    @Test
    func update_notFound() {
        var map = PanMap<BeatTime>()

        let result = map.update(entryID: PanMap<BeatTime>.EntryID(), pan: .right)

        #expect(!result.updated)
        #expect(result.removedEntryID == nil)
        #expect(map.isEmpty)
    }

    @Test
    func update_collapsesIntoDuplicate() throws {
        var map = PanMap<BeatTime>()
        var ids: [PanMap<BeatTime>.EntryID] = []

        map.insert(time: 1, pan: .left)
        map.insert(time: 1, pan: .right)

        map.forEach { entryID, _, _, _ in ids.append(entryID) }

        // Editing the second entry back to `.left` makes it an exact duplicate
        // of the first, so it should be dropped rather than left in place.
        let result = try map.update(entryID: #require(ids.last), pan: .left)

        #expect(result.updated)
        #expect(result.removedEntryID == ids.first)

        var remaining: [PanMap<BeatTime>.EntryID] = []

        map.forEach { entryID, _, _, _ in remaining.append(entryID) }

        #expect(remaining == [ids.last])
    }

    @Test
    func defaultPan() {
        let map = PanMap<BeatTime>()

        #expect(map.defaultPan == .center)
    }

    @Test
    func defaultPan_override() {
        let map = PanMap<BeatTime>(defaultPan: .right)

        #expect(map.defaultPan == .right)
    }

    @Test
    func isEmpty_afterInsert() {
        var map = PanMap<BeatTime>()

        map.insert(time: 1,
                   pan: .right)

        #expect(!map.isEmpty)
    }

    @Test
    func isEmpty_initial() {
        let map = PanMap<BeatTime>()

        #expect(map.isEmpty)
    }

    @Test
    func merge() {
        var map1 = PanMap<BeatTime>()
        var map2 = PanMap<BeatTime>()

        map1.insert(time: 1,
                    pan: .left)
        map2.insert(time: 3,
                    pan: .right)
        map1.merge(with: map2)

        #expect(!map1.isEmpty)
    }

    @Test
    func remove_found() {
        var map = PanMap<BeatTime>()

        let inserted = map.insert(time: 1,
                                  pan: .left)
        let removedID = map.remove(time: 1,
                                   pan: .left)

        #expect(removedID == inserted.entryID)
        #expect(map.isEmpty)
    }

    @Test
    func remove_notFound() {
        var map = PanMap<BeatTime>()

        map.insert(time: 1, pan: .left)

        let removedID = map.remove(time: 1, pan: .right)

        #expect(removedID == nil)
        #expect(!map.isEmpty)
    }

    @Test
    func remove_entryID_found() throws {
        var map = PanMap<BeatTime>()
        var removedID: PanMap<BeatTime>.EntryID?

        map.insert(time: 1, pan: .left)

        map.forEach { entryID, _, _, _ in removedID = entryID }

        let entryID = try #require(removedID, "expected an entry ID")
        let removed = map.remove(entryID: entryID)

        #expect(removed)
        #expect(map.isEmpty)
    }

    @Test
    func remove_entryID_notFound() {
        var map = PanMap<BeatTime>()

        map.insert(time: 1, pan: .left)

        let removed = map.remove(entryID: PanMap<BeatTime>.EntryID())

        #expect(!removed)
        #expect(!map.isEmpty)
    }

    @Test
    func subscript_empty() {
        let map = PanMap<BeatTime>()

        #expect(map[BeatTime(1)] == .center)
    }
}

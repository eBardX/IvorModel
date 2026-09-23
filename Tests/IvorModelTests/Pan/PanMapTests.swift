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
    func forEach_yieldsDistinctIdentities() {
        var map = PanMap<BeatTime>()
        var ids: [EntryID] = []

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
    func move_found() throws {
        var map = PanMap<BeatTime>()
        var movedID: EntryID?

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

        #expect(map.move(entryID: EntryID(), to: 1) == nil)
    }

    @Test
    func remove_entryID_found() throws {
        var map = PanMap<BeatTime>()
        var removedID: EntryID?

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

        let removed = map.remove(entryID: EntryID())

        #expect(!removed)
        #expect(!map.isEmpty)
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
    func subscript_empty() {
        let map = PanMap<BeatTime>()

        #expect(map[BeatTime(1)] == .center)
    }

    @Test
    func subscript_atEntryTime_isExact() {
        var map = PanMap<BeatTime>()

        map.insert(time: 1, pan: Pan(horizontal: 30, vertical: 10))
        map.insert(time: 3, pan: .right)

        #expect(map[BeatTime(1)] == Pan(horizontal: 30, vertical: 10))
    }

    @Test
    func subscript_interpolatesBothAngles() {
        var map = PanMap<BeatTime>()

        map.insert(time: 0, pan: Pan(horizontal: -90, vertical: 0))
        map.insert(time: 2, pan: Pan(horizontal: 90, vertical: 60))

        let pan = map[BeatTime(1)]

        #expect(abs(pan.horizontal.doubleValue) < 1e-9)
        #expect(abs(pan.vertical.doubleValue - 30) < 1e-9)
    }

    @Test
    func subscript_interpolatesOverhead() {
        var map = PanMap<BeatTime>()

        map.insert(time: 0, pan: .center)
        map.insert(time: 2, pan: Pan(horizontal: 0, vertical: 180))

        let pan = map[BeatTime(1)]

        #expect(abs(pan.horizontal.doubleValue) < 1e-9)
        #expect(abs(pan.vertical.doubleValue - 90) < 1e-9)
    }

    @Test
    func subscript_interpolatesShortestArc() {
        var map = PanMap<BeatTime>()

        map.insert(time: 0, pan: Pan(horizontal: 170))
        map.insert(time: 2, pan: Pan(horizontal: -170))

        #expect(abs(map[BeatTime(1)].horizontal.doubleValue - 180) < 1e-9)
        #expect(abs(map[BeatTime(Number(numerator: 3, denominator: 2))].horizontal.doubleValue - -175) < 1e-9)
    }

    @Test
    func subscript_halfTurnRotatesClockwise() {
        var map = PanMap<BeatTime>()

        map.insert(time: 0, pan: .center)
        map.insert(time: 2, pan: .behind)

        #expect(abs(map[BeatTime(1)].horizontal.doubleValue - 90) < 1e-9)
    }

    @Test
    func update_collapsesIntoDuplicate() throws {
        var map = PanMap<BeatTime>()
        var ids: [EntryID] = []

        map.insert(time: 1, pan: .left)
        map.insert(time: 1, pan: .right)

        map.forEach { entryID, _, _, _ in ids.append(entryID) }

        // Editing the second entry back to `.left` makes it an exact duplicate
        // of the first, so it should be dropped rather than left in place.
        let result = try map.update(entryID: #require(ids.last), pan: .left)

        #expect(result.updated)
        #expect(result.removedEntryID == ids.first)

        var remaining: [EntryID] = []

        map.forEach { entryID, _, _, _ in remaining.append(entryID) }

        #expect(remaining == [ids.last])
    }

    @Test
    func update_found() throws {
        var map = PanMap<BeatTime>()
        var foundEntryID: EntryID?

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

        let result = map.update(entryID: EntryID(), pan: .right)

        #expect(!result.updated)
        #expect(result.removedEntryID == nil)
        #expect(map.isEmpty)
    }
}

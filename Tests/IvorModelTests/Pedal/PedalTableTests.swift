// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct PedalTableTests {
    private let half = Pedal.Level(Number(numerator: 1, denominator: 2))
}

// MARK: -

extension PedalTableTests {
    @Test
    func codable_decodeFoldsAdjacentDuplicates() throws {
        var table = PedalTable<BeatTime>()

        // Nothing about `Codable` enforces the fold rule, so identical neighbors can land in
        // `entries` directly, bypassing `insert`'s own guard.
        table.entries = [PedalTable<BeatTime>.StoredEntry(time: 1, level: .down, extras: nil),
                         PedalTable<BeatTime>.StoredEntry(time: 1, level: .down, extras: nil)]

        let data = try JSONEncoder().encode(table)
        let decoded = try JSONDecoder().decode(PedalTable<BeatTime>.self, from: data)

        #expect(decoded.count == 1)
    }

    @Test
    func codable_encodesEntriesOnly() throws {
        var table = PedalTable<BeatTime>()

        table.insert(time: 1, level: .down)

        let data = try JSONEncoder().encode(table)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(Array(object.keys) == ["entries"])
    }

    @Test
    func codable_keepsRepedal() throws {
        var table = PedalTable<BeatTime>()

        table.insert(time: 1, level: .down)
        table.insert(time: 3, level: .up)
        table.insert(time: 3, level: .down)
        table.insert(time: 5, level: .up)

        let data = try JSONEncoder().encode(table)
        let decoded = try JSONDecoder().decode(PedalTable<BeatTime>.self, from: data)

        #expect(decoded.map(\.time) == [1, 3, 3, 5])
        #expect(decoded.map(\.level) == [.down, .up, .down, .up])
    }

    @Test
    func codable_roundTrip_withExtras() throws {
        let extras = Extras(elements: [Extra(name: "tag")])
        var table = PedalTable<BeatTime>()

        table.insert(time: 1, level: half, extras: extras)

        let data = try JSONEncoder().encode(table)
        let decoded = try JSONDecoder().decode(PedalTable<BeatTime>.self, from: data)

        #expect(decoded.first?.level == half)
        #expect(decoded.first?.extras == extras)
        #expect(decoded.hasExtras)
    }

    @Test
    func collection_empty() {
        let table = PedalTable<BeatTime>()

        #expect(table.isEmpty)
        #expect(table.startIndex == table.endIndex)
        #expect(table.first == nil)
        #expect(table.last == nil)
    }

    @Test
    func collection_iteratesEntriesInTimeOrder() {
        var table = PedalTable<BeatTime>()

        let later = table.insert(time: 2,
                                 level: .up)
        let earlier = table.insert(time: 1,
                                   level: .down)

        #expect(table.count == 2)
        #expect(table.map(\.entryID) == [earlier.entryID, later.entryID])
        #expect(table.map(\.time) == [1, 2])
        #expect(table.first?.level == .down)
        #expect(table[table.index(after: table.startIndex)].level == .up)
        #expect(table.index(table.startIndex, offsetBy: 2) == table.endIndex)
        #expect(table.distance(from: table.endIndex, to: table.startIndex) == -2)
        #expect(table.index(before: table.endIndex) == table.index(after: table.startIndex))
    }

    @Test
    func hasExtras_clearedWhenLastExtrasRemoved() {
        var table = PedalTable<BeatTime>()

        let entry = table.insert(time: 1, level: .down, extras: Extras(elements: [Extra(name: "tag")]))

        #expect(table.hasExtras)

        table.remove(entryID: entry.entryID)

        #expect(!table.hasExtras)
    }

    @Test
    func hasExtras_initial() {
        #expect(!PedalTable<BeatTime>().hasExtras)
    }

    @Test
    func insert_afterSameTimeEntries() {
        var table = PedalTable<BeatTime>()

        table.insert(time: 1, level: .down)
        table.insert(time: 1, level: .up)
        table.insert(time: 1, level: half)

        #expect(table.map(\.level) == [.down, .up, half])
        #expect(table[1] == half)
    }

    @Test
    func insert_duplicateOfEarlierSameTimeEntry_isKept() {
        var table = PedalTable<BeatTime>()

        table.insert(time: 1, level: .down)
        table.insert(time: 1, level: .up)

        let third = table.insert(time: 1, level: .down)

        #expect(third.inserted)
        #expect(table.map(\.level) == [.down, .up, .down])
        #expect(table[1] == .down)
    }

    @Test
    func insert_duplicateOfLastSameTimeEntry_folds() {
        var table = PedalTable<BeatTime>()

        let first = table.insert(time: 1, level: .down)
        let second = table.insert(time: 1, level: .down)

        #expect(first.inserted)
        #expect(!second.inserted)
        #expect(second.entryID == first.entryID)
        #expect(table.count == 1)
    }

    @Test
    func insert_new() {
        var table = PedalTable<BeatTime>()

        let first = table.insert(time: 1, level: .down)
        let second = table.insert(time: 2, level: .up)

        #expect(first.inserted)
        #expect(second.inserted)
        #expect(second.entryID != first.entryID)
    }

    @Test
    func insert_repedal_keepsBoth() {
        var table = PedalTable<BeatTime>()

        table.insert(time: 1, level: .down)
        table.insert(time: 3, level: .up)
        table.insert(time: 3, level: .down)

        #expect(table.map(\.level) == [.down, .up, .down])
        #expect(table[3] == .down)
    }

    @Test
    func insertBefore_foldsIntoIdenticalAnchor() throws {
        var table = PedalTable<BeatTime>()

        let down = table.insert(time: 2, level: .down)
        let result = try table.insert(time: 2, level: .down, before: down.entryID)

        #expect(!result.inserted)
        #expect(result.entryID == down.entryID)
        #expect(table.count == 1)
    }

    @Test
    func insertBefore_foldsIntoIdenticalPredecessor() throws {
        var table = PedalTable<BeatTime>()

        let up = table.insert(time: 2, level: .up)
        let down = table.insert(time: 2, level: .down)
        let result = try table.insert(time: 2, level: .up, before: down.entryID)

        #expect(!result.inserted)
        #expect(result.entryID == up.entryID)
        #expect(table.count == 2)
    }

    @Test
    func insertBefore_mismatchedTime_throws() {
        var table = PedalTable<BeatTime>()

        let down = table.insert(time: 2, level: .down)

        #expect(throws: PedalTable<BeatTime>.Error.invalidAnchor) {
            try table.insert(time: 3, level: .up, before: down.entryID)
        }
        #expect(table.count == 1)
    }

    @Test
    func insertBefore_placesEntryImmediatelyBeforeAnchor() throws {
        var table = PedalTable<BeatTime>()

        table.insert(time: 1, level: .up)

        let down = table.insert(time: 2, level: .down)

        table.insert(time: 2, level: half)

        let result = try table.insert(time: 2, level: .up, before: down.entryID)

        #expect(result.inserted)
        #expect(table.map(\.level) == [.up, .up, .down, half])
        #expect(table.map(\.entryID)[1] == result.entryID)
    }

    @Test
    func insertBefore_repedal() throws {
        var table = PedalTable<BeatTime>()

        table.insert(time: 1, level: .down)

        let down = table.insert(time: 3, level: .down)

        try table.insert(time: 3, level: .up, before: down.entryID)

        #expect(table.map(\.time) == [1, 3, 3])
        #expect(table.map(\.level) == [.down, .up, .down])
        #expect(table[3] == .down)
    }

    @Test
    func insertBefore_unknownAnchor_throws() {
        var table = PedalTable<BeatTime>()

        table.insert(time: 2, level: .down)

        #expect(throws: PedalTable<BeatTime>.Error.invalidAnchor) {
            try table.insert(time: 2, level: .up, before: EntryID())
        }
        #expect(table.count == 1)
    }

    @Test
    func last_returnsLastEntryInTimeOrder() throws {
        let extras = Extras(elements: [Extra(name: "tag")])
        var table = PedalTable<BeatTime>()

        let later = table.insert(time: 2,
                                 level: .up,
                                 extras: extras)

        table.insert(time: 1,
                     level: .down)

        let last = try #require(table.last)

        #expect(last.entryID == later.entryID)
        #expect(last.time == 2)
        #expect(last.level == .up)
        #expect(last.extras == extras)
    }

    @Test
    func move_found() {
        var table = PedalTable<BeatTime>()

        let entry = table.insert(time: 1, level: .down)
        let newID = table.move(entryID: entry.entryID, to: 5)

        #expect(newID == entry.entryID)
        #expect(table[BeatTime(1)] == .up)
        #expect(table[BeatTime(5)] == .down)
    }

    @Test
    func move_notFound() {
        var table = PedalTable<BeatTime>()

        #expect(table.move(entryID: EntryID(), to: 1) == nil)
    }

    @Test
    func move_ontoIdenticalLastEntry_folds() {
        var table = PedalTable<BeatTime>()

        let target = table.insert(time: 5, level: .down)
        let moving = table.insert(time: 1, level: .down)
        let newID = table.move(entryID: moving.entryID, to: 5)

        #expect(newID == target.entryID)
        #expect(table.count == 1)
    }

    @Test
    func pressEnd_downAtBoundByRepedal_returnsNextEntry() {
        var table = PedalTable<BeatTime>()

        table.insert(time: 4, level: .up)
        table.insert(time: 4, level: .down)

        let release = table.insert(time: 6, level: .up)

        #expect(table.pressEnd(after: 2...4) == release.entryID)
    }

    @Test
    func pressEnd_downWithLaterEntry_returnsIt() {
        var table = PedalTable<BeatTime>()

        table.insert(time: 1, level: .down)

        let release = table.insert(time: 6, level: .up)

        table.insert(time: 8, level: .down)

        #expect(table.pressEnd(after: 2...4) == release.entryID)
    }

    @Test
    func pressEnd_downWithNoLaterEntry_isNil() {
        var table = PedalTable<BeatTime>()

        table.insert(time: 1, level: .down)

        #expect(table.pressEnd(after: 2...4) == nil)
    }

    @Test
    func pressEnd_entryAtUpperBound_isNotTheEnd() {
        var table = PedalTable<BeatTime>()

        table.insert(time: 1, level: .down)
        table.insert(time: 4, level: half)

        let release = table.insert(time: 6, level: .up)

        #expect(table.pressEnd(after: 2...4) == release.entryID)
    }

    @Test
    func pressEnd_up_isNil() {
        var table = PedalTable<BeatTime>()

        table.insert(time: 1, level: .down)
        table.insert(time: 3, level: .up)
        table.insert(time: 6, level: .down)

        #expect(table.pressEnd(after: 2...4) == nil)
    }

    @Test
    func remove_entryID_found() {
        var table = PedalTable<BeatTime>()

        let entry = table.insert(time: 1, level: .down)

        let removed = table.remove(entryID: entry.entryID)

        #expect(removed)
        #expect(table.isEmpty)
    }

    @Test
    func remove_entryID_notFound() {
        var table = PedalTable<BeatTime>()

        table.insert(time: 1, level: .down)

        let removed = table.remove(entryID: EntryID())

        #expect(!removed)
        #expect(!table.isEmpty)
    }

    @Test
    func subscript_afterInsert() {
        var table = PedalTable<BeatTime>()

        table.insert(time: 2,
                     level: .down)
        table.insert(time: 5,
                     level: half)

        #expect(table[BeatTime(1)] == .up)
        #expect(table[BeatTime(2)] == .down)
        #expect(table[BeatTime(3)] == .down)
        #expect(table[BeatTime(5)] == half)
        #expect(table[BeatTime(7)] == half)
    }

    @Test
    func subscript_beforeFirstEntry_isUp() {
        var table = PedalTable<BeatTime>()

        table.insert(time: 2,
                     level: .down)

        #expect(table[BeatTime(0)] == .up)
        #expect(table[BeatTime(1)] == .up)
    }

    @Test
    func subscript_empty_isUp() {
        #expect(PedalTable<BeatTime>()[BeatTime(1)] == .up)
    }

    @Test
    func subscript_integerLiteral_isTime() {
        var table = PedalTable<BeatTime>()

        table.insert(time: 0,
                     level: .up)
        table.insert(time: 1,
                     level: .down)

        //
        // `1` must resolve to the time subscript, not a position — positions are an opaque
        // `Index` precisely so an integer literal can’t select them:
        //
        let value = table[1]

        #expect(value == .down)
    }

    @Test
    func update_collapsesIntoBothNeighbors() {
        var table = PedalTable<BeatTime>()

        let first = table.insert(time: 1, level: .down)
        let middle = table.insert(time: 1, level: .up)
        let last = table.insert(time: 1, level: .down)
        let result = table.update(entryID: middle.entryID, level: .down)

        #expect(result.updated)
        #expect(Set(result.removedEntryIDs) == [first.entryID, last.entryID])
        #expect(table.map(\.entryID) == [middle.entryID])
    }

    @Test
    func update_collapsesIntoNeighbor() {
        var table = PedalTable<BeatTime>()

        let first = table.insert(time: 1, level: .down)
        let second = table.insert(time: 1, level: .up)
        let result = table.update(entryID: second.entryID, level: .down)

        #expect(result.updated)
        #expect(result.removedEntryIDs == [first.entryID])
        #expect(table.map(\.entryID) == [second.entryID])
    }

    @Test
    func update_found() {
        var table = PedalTable<BeatTime>()

        let entry = table.insert(time: 1, level: .down)
        let result = table.update(entryID: entry.entryID, level: half)

        #expect(result.updated)
        #expect(result.removedEntryIDs.isEmpty)
        #expect(table[BeatTime(1)] == half)
    }

    @Test
    func update_keepsPlaceAmongSameTimeEntries() {
        var table = PedalTable<BeatTime>()

        let first = table.insert(time: 1, level: .down)

        table.insert(time: 1, level: .up)

        table.update(entryID: first.entryID, level: half)

        #expect(table.map(\.level) == [half, .up])
    }

    @Test
    func update_notFound() {
        var table = PedalTable<BeatTime>()

        let result = table.update(entryID: EntryID(), level: .down)

        #expect(!result.updated)
        #expect(result.removedEntryIDs.isEmpty)
        #expect(table.isEmpty)
    }
}

// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct PartMarkTableTests {
}

// MARK: -

extension PartMarkTableTests {
    private typealias Table = PartMarkTable<BeatTime>

    @Test
    func codable_roundTrip() throws {
        var table = Table()

        table.insert(time: 2, mark: .caesura(nil))
        table.insert(time: 0, mark: quarterFermataMark(1))
        table.insert(time: 2, mark: quarterFermataMark(2))

        let decoded = try codingRoundTrip(table)

        #expect(decoded.map(\.time) == [0, 2, 2])
        #expect(decoded.map(\.mark) == table.map(\.mark))
    }

    @Test
    func codable_sortsStablyAndFoldsDuplicates() throws {
        let caesura = try encodedJSON(PartMark<BeatTime>.caesura(nil))
        let fermata = try encodedJSON(quarterFermataMark(1))
        let one = try encodedJSON(1 as BeatTime)
        let two = try encodedJSON(2 as BeatTime)
        let entries = [[two, fermata], [one, caesura], [two, caesura], [two, caesura]].map { "[" + $0.joined(separator: ",") + "]" }
        let json = "{\"entries\":[" + entries.joined(separator: ",") + "]}"
        let table = try decodeJSON(Table.self, json)

        #expect(table.map(\.time) == [1, 2, 2])
        #expect(table.map(\.mark) == [.caesura(nil), quarterFermataMark(1), .caesura(nil)])
    }

    @Test
    func insert_foldsAnIdenticalNeighbor() {
        var table = Table()
        let first = table.insert(time: 1, mark: .caesura(nil))
        let second = table.insert(time: 1, mark: .caesura(nil))
        let third = table.insert(time: 1, mark: quarterFermataMark(1))

        #expect(first.inserted)
        #expect(!second.inserted)
        #expect(second.entryID == first.entryID)
        #expect(third.inserted)
        #expect(table.count == 2)
    }

    @Test
    func insert_keepsTimeOrderAndInsertionOrderAtATime() {
        var table = Table()

        table.insert(time: 3, mark: .caesura(nil))
        table.insert(time: 1, mark: quarterFermataMark(1))
        table.insert(time: 1, mark: .caesura(nil))

        #expect(table.map(\.time) == [1, 1, 3])
        #expect(table.map(\.mark) == [quarterFermataMark(1), .caesura(nil), .caesura(nil)])
    }

    @Test
    func move() {
        var table = Table()
        let moving = table.insert(time: 0, mark: .caesura(nil)).entryID
        let kept = table.insert(time: 2, mark: .caesura(nil)).entryID

        let moved = table.move(entryID: moving, to: 3)

        #expect(moved == moving)
        #expect(table.map(\.time) == [2, 3])

        // Landing right after an identical entry folds into it.
        let folded = table.move(entryID: moving, to: 2)
        let missing = table.move(entryID: EntryID(), to: 1)

        #expect(folded == kept)
        #expect(table.count == 1)
        #expect(missing == nil)
    }

    @Test
    func remove() {
        var table = Table()
        let entryID = table.insert(time: 0, mark: .caesura(nil)).entryID

        let removedMissing = table.remove(entryID: EntryID())
        let removed = table.remove(entryID: entryID)

        #expect(!removedMissing)
        #expect(removed)
        #expect(table.isEmpty)
    }

    @Test
    func update() {
        var table = Table()
        let first = table.insert(time: 1, mark: .caesura(nil)).entryID
        let second = table.insert(time: 1, mark: quarterFermataMark(1)).entryID

        let result = table.update(entryID: second, mark: .caesura(nil))

        #expect(result.updated)
        #expect(result.removedEntryIDs == [first])
        #expect(table.map(\.entryID) == [second])

        let missing = table.update(entryID: EntryID(), mark: .caesura(nil))

        #expect(!missing.updated)
        #expect(missing.removedEntryIDs.isEmpty)
    }

    @Test
    func update_keepsIdentityAndPlace() {
        var table = Table()
        let first = table.insert(time: 1, mark: .caesura(nil)).entryID
        let second = table.insert(time: 1, mark: quarterFermataMark(1)).entryID

        table.update(entryID: first, mark: quarterFermataMark(2))

        #expect(table.map(\.entryID) == [first, second])
        #expect(table.first?.mark == quarterFermataMark(2))
    }
}

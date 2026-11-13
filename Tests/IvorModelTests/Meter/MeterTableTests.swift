// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct MeterTableTests {
    private let symbolExtras = Extras(elements: [Extra(name: Extra.meterSymbol.name,
                                                       values: [.string("common")])])
}

// MARK: - Editing

extension MeterTableTests {
    @Test
    func insert_keepsEntriesSorted() throws {
        var table = MeterTable()

        try table.insert(beatTime: 2, meter: meter("3/4"))
        try table.insert(beatTime: 0, meter: meter("4/4"))
        try table.insert(beatTime: 1, meter: meter("6/8"))

        #expect(table.map(\.beatTime) == [0, 1, 2])
        #expect(table.map(\.meter.plain) == ["4/4", "6/8", "3/4"])
    }

    @Test
    func insert_onOccupiedTime_throws() throws {
        var table = try makeMeterTable([(0, "4/4")])

        #expect(throws: MeterTable.Error.entryExists(0)) {
            try table.insert(beatTime: 0, meter: meter("3/4"))
        }
        #expect(table.count == 1)
    }

    @Test
    func insert_insidePickup_throws() throws {
        var table = try makeMeterTable([(0, "3/4")], pickup: frac(1, 2))

        #expect(throws: MeterTable.Error.invalidPickup) {
            try table.insert(beatTime: beatTime(frac(1, 4)), meter: meter("2/4"))
        }

        // Ending exactly at the pickup is fine.
        try table.insert(beatTime: beatTime(frac(1, 2)), meter: meter("2/4"))

        #expect(table.count == 2)
    }

    @Test
    func insert_tracksExtras() throws {
        var table = MeterTable()

        try table.insert(beatTime: 0, meter: meter("4/4"))

        #expect(!table.hasExtras)

        try table.insert(beatTime: 1, meter: meter("4/4"), extras: symbolExtras)

        #expect(table.hasExtras)
        #expect(table.last?.extras == symbolExtras)
    }

    @Test
    func setPickup_validatesInvariants() throws {
        var table = try makeMeterTable([(0, "3/4"), (1, "2/4")])

        try table.setPickup(beats(frac(1, 4)))

        #expect(table.pickup == beats(frac(1, 4)))

        // Not shorter than the bar.
        #expect(throws: MeterTable.Error.invalidPickup) {
            try table.setPickup(beats(frac(3, 4)))
        }

        // Back to none.
        try table.setPickup(.zero)

        #expect(table.pickup == .zero)
    }

    @Test
    func setPickup_pastSecondEntry_throws() throws {
        var table = try makeMeterTable([(0, "3/4"), (frac(1, 4), "2/4")])

        try table.setPickup(beats(frac(1, 4)))

        #expect(throws: MeterTable.Error.invalidPickup) {
            try table.setPickup(beats(frac(1, 2)))
        }
    }

    @Test
    func setPickup_withoutMeteredEntryAtZero_throws() throws {
        var late = try makeMeterTable([(1, "3/4")])
        var free = try makeMeterTable([(0, "free")])
        var empty = MeterTable()

        #expect(throws: MeterTable.Error.invalidPickup) { try late.setPickup(beats(frac(1, 4))) }
        #expect(throws: MeterTable.Error.invalidPickup) { try free.setPickup(beats(frac(1, 4))) }
        #expect(throws: MeterTable.Error.invalidPickup) { try empty.setPickup(beats(frac(1, 4))) }
    }

    @Test
    func remove_entryAtZero_resetsPickup() throws {
        var table = try makeMeterTable([(0, "3/4"), (1, "2/4")], pickup: frac(1, 4))
        let first = try #require(table.first)

        let result = table.remove(entryID: first.entryID)

        #expect(result)
        #expect(table.pickup == .zero)
        #expect(table.map(\.beatTime) == [1])
    }

    @Test
    func remove_unknownEntry_returnsFalse() throws {
        var table = try makeMeterTable([(0, "3/4")])

        let result = table.remove(entryID: EntryID())

        #expect(!result)
        #expect(table.count == 1)
    }

    @Test
    func update_keepsIdentityAndTime() throws {
        var table = try makeMeterTable([(0, "3/4"), (1, "2/4")])
        let entry = try #require(table.last)

        let result = try table.update(entryID: entry.entryID, meter: meter("5/8"), extras: symbolExtras)

        #expect(result)

        let updated = try #require(table.last)

        #expect(updated.entryID == entry.entryID)
        #expect(updated.beatTime == 1)
        #expect(updated.meter == meter("5/8"))
        #expect(table.hasExtras)
    }

    @Test
    func update_entryAtZeroThatCantHoldPickup_throws() throws {
        var table = try makeMeterTable([(0, "3/4")], pickup: frac(1, 2))
        let entry = try #require(table.first)

        #expect(throws: MeterTable.Error.invalidPickup) {
            try table.update(entryID: entry.entryID, meter: meter("2/4"))
        }
        #expect(throws: MeterTable.Error.invalidPickup) {
            try table.update(entryID: entry.entryID, meter: .free)
        }
        #expect(table.first?.meter == meter("3/4"))

        let result = try table.update(entryID: entry.entryID, meter: meter("4/4"))

        #expect(result)
    }

    @Test
    func update_unknownEntry_returnsFalse() throws {
        var table = try makeMeterTable([(0, "3/4")])

        let result = try table.update(entryID: EntryID(), meter: meter("4/4"))

        #expect(!result)
    }

    @Test
    func move_reordersAndKeepsIdentity() throws {
        var table = try makeMeterTable([(0, "4/4"), (1, "3/4"), (2, "2/4")])
        let entry = try #require(table.last)

        let result = try table.move(entryID: entry.entryID, to: beatTime(frac(1, 2)))

        #expect(result)
        #expect(table.map(\.beatTime) == [0, beatTime(frac(1, 2)), 1])
        #expect(table.map(\.meter.plain) == ["4/4", "2/4", "3/4"])
        #expect(table[table.index(after: table.startIndex)].entryID == entry.entryID)
    }

    @Test
    func move_ontoOccupiedTime_throws() throws {
        var table = try makeMeterTable([(0, "4/4"), (1, "3/4")])
        let entry = try #require(table.last)

        #expect(throws: MeterTable.Error.entryExists(0)) {
            try table.move(entryID: entry.entryID, to: 0)
        }
    }

    @Test
    func move_intoPickup_throws() throws {
        var table = try makeMeterTable([(0, "4/4"), (1, "3/4")], pickup: frac(1, 2))
        let entry = try #require(table.last)

        #expect(throws: MeterTable.Error.invalidPickup) {
            try table.move(entryID: entry.entryID, to: beatTime(frac(1, 4)))
        }
        #expect(table.last?.beatTime == 1)
    }

    @Test
    func move_entryAtZero_resetsPickup() throws {
        var table = try makeMeterTable([(0, "4/4"), (2, "3/4")], pickup: frac(1, 2))
        let entry = try #require(table.first)

        let result = try table.move(entryID: entry.entryID, to: 1)

        #expect(result)
        #expect(table.pickup == .zero)
    }

    @Test
    func move_unknownEntry_returnsFalse() throws {
        var table = try makeMeterTable([(0, "3/4")])

        let result = try table.move(entryID: EntryID(), to: 1)

        #expect(!result)
    }
}

// MARK: - Codable, Equatable, Hashable

extension MeterTableTests {
    @Test
    func codable_roundTrips() throws {
        var table = try makeMeterTable([(0, "3/4"), (2, "2+2+3/8")], pickup: frac(1, 4))

        try table.insert(beatTime: 4, meter: meter("4/4"), extras: symbolExtras)

        let data = try JSONEncoder().encode(table)
        let decoded = try JSONDecoder().decode(MeterTable.self, from: data)

        #expect(decoded == table)
        #expect(decoded.hasExtras)
        #expect(decoded.pickup == beats(frac(1, 4)))
    }

    @Test
    func codable_encodesEntriesAndPickup() throws {
        let table = try makeMeterTable([(0, "3/4")], pickup: frac(1, 4))
        let encoder = JSONEncoder()

        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]

        let json = try #require(String(data: encoder.encode(table), encoding: .utf8))

        #expect(json == #"{"entries":[["0","3/4"]],"pickup":"1/4"}"#)
    }

    @Test(arguments: [#"{"entries":[["0","3/4"],["0","2/4"]],"pickup":"0"}"#,     // duplicate time
                      #"{"entries":[["1","3/4"],["0","2/4"]],"pickup":"0"}"#,     // out of order
                      #"{"entries":[["1","3/4"]],"pickup":"1/4"}"#,               // no entry at 0
                      #"{"entries":[["0","free"]],"pickup":"1/4"}"#,              // free at 0
                      #"{"entries":[["0","3/4"]],"pickup":"3/4"}"#,               // not shorter than the bar
                      #"{"entries":[["0","3/4"],["1/4","2/4"]],"pickup":"1/2"}"#, // past the second entry
                      #"{"entries":[["0","3/4"]]}"#])                             // pickup missing
    func codable_rejectsInvalidTable(_ json: String) {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(MeterTable.self, from: Data(json.utf8))
        }
    }

    @Test
    func equality_ignoresIdentity() throws {
        let table1 = try makeMeterTable([(0, "3/4"), (1, "2/4")], pickup: frac(1, 4))
        let table2 = try makeMeterTable([(0, "3/4"), (1, "2/4")], pickup: frac(1, 4))
        let table3 = try makeMeterTable([(0, "3/4"), (1, "2/4")])

        #expect(table1 == table2)
        #expect(table1.hashValue == table2.hashValue)
        #expect(table1 != table3)
    }
}

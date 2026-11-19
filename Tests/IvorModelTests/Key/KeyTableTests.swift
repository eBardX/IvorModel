// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct KeyTableTests {
}

// MARK: -

extension KeyTableTests {
    @Test
    func codable_encodesEntries() throws {
        var table = KeyTable()

        try table.insert(beatTime: 0, key: key(2))
        try table.insert(beatTime: 2, key: key(-3, .minor))
        try table.insert(beatTime: 4,
                         key: #require(Key(accidentals: [PitchClass.bFlat, .fSharp])))
        try table.insert(beatTime: 6, key: .atonal)

        let encoder = JSONEncoder()

        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]

        let json = try #require(String(data: encoder.encode(table), encoding: .utf8))

        #expect(json == #"{"entries":[["0",{"fifths":2}],["2",{"fifths":-3,"mode":"minor"}],["4",{"custom":["B♭","F♯"]}],["6","atonal"]]}"#)
    }

    @Test(arguments: [#"{"entries":[["0",{"fifths":0}],["0","atonal"]]}"#,    // duplicate time
                      #"{"entries":[["1",{"fifths":0}],["0","atonal"]]}"#,    // out of order
                      #"{"entries":[["0",{"custom":["F♯","F♭"]}]]}"#,          // repeated letter
                      #"{"entries":[["0",{"custom":["F♯"]}]]}"#,               // diatonic as custom
                      #"{"entries":[["0",["F♯"]]]}"#,                          // old format
                      #"{}"#])                                                  // entries missing
    func codable_rejectsInvalidTable(_ json: String) {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(KeyTable.self, from: Data(json.utf8))
        }
    }

    @Test
    func codable_roundTrips() throws {
        var table = try makeKeyTable([(0, 2), (frac(7, 2), -3)])

        try table.insert(beatTime: 8, key: key(1), extras: sampleExtras("minor"))

        let data = try JSONEncoder().encode(table)
        let decoded = try JSONDecoder().decode(KeyTable.self, from: data)

        #expect(decoded == table)
        #expect(decoded.hasExtras)
    }

    @Test
    func entry_snapshotsStoredEntry() throws {
        var table = KeyTable()
        let entryID = try table.insert(beatTime: 2, key: key(-1), extras: sampleExtras("minor"))
        let entry = try #require(table.first)

        #expect(entry.beatTime == 2)
        #expect(entry.entryID == entryID)
        #expect(entry.extras == sampleExtras("minor"))
        #expect(entry.key == key(-1))
    }

    @Test
    func equality_ignoresIdentity() throws {
        let table1 = try makeKeyTable([(0, 2), (4, -1)])
        let table2 = try makeKeyTable([(0, 2), (4, -1)])

        #expect(table1 == table2)
        #expect(table1.hashValue == table2.hashValue)
        #expect(try table1 != makeKeyTable([(0, 2)]))
    }

    @Test
    func init_isEmpty() {
        let table = KeyTable()

        #expect(table.isEmpty)
        #expect(!table.hasExtras)
        #expect(table.key(at: 0) == nil)
    }

    @Test
    func insert_keepsOrder() throws {
        let table = try makeKeyTable([(4, 1), (0, 2), (2, -3)])

        #expect(table.map(\.beatTime) == [0, 2, 4])
        #expect(table.map(\.key) == [key(2), key(-3), key(1)])
    }

    @Test
    func insert_redundantEntryAllowed() throws {
        let table = try makeKeyTable([(0, 2), (4, 2)])

        #expect(table.count == 2)
    }

    @Test
    func insert_sameTimeThrows() throws {
        var table = try makeKeyTable([(1, 2)])

        #expect(throws: KeyTable.Error.entryExists(1)) {
            try table.insert(beatTime: 1, key: key(3))
        }

        #expect(table.count == 1)
    }

    @Test
    func insert_withExtrasSetsHasExtras() throws {
        var table = KeyTable()

        try table.insert(beatTime: 0, key: key(0), extras: sampleExtras("none"))

        #expect(table.hasExtras)
    }

    @Test
    func keyAt_lookup() throws {
        let table = try makeKeyTable([(2, 2), (6, -1)])

        #expect(table.key(at: 0) == nil)       // before the first entry: no key
        #expect(table.key(at: 2) == key(2))
        #expect(table.key(at: 5) == key(2))
        #expect(table.key(at: 6) == key(-1))
        #expect(table.key(at: 100) == key(-1))
    }

    @Test
    func move_keepsIdentityAndReorders() throws {
        var table = try makeKeyTable([(0, 2), (4, -1)])
        let entryID = try #require(table.first?.entryID)

        let moved = try table.move(entryID: entryID, to: 6)

        #expect(moved)
        #expect(table.map(\.beatTime) == [4, 6])
        #expect(table.last?.entryID == entryID)
        #expect(table.last?.key == key(2))
    }

    @Test
    func move_occupiedTimeThrows() throws {
        var table = try makeKeyTable([(0, 2), (4, -1)])
        let entryID = try #require(table.first?.entryID)

        #expect(throws: KeyTable.Error.entryExists(4)) {
            try table.move(entryID: entryID, to: 4)
        }
    }

    @Test
    func move_unknownOrSameTime() throws {
        var table = try makeKeyTable([(0, 2)])
        let entryID = try #require(table.first?.entryID)

        let movedUnknown = try table.move(entryID: EntryID(), to: 1)
        let movedSame = try table.move(entryID: entryID, to: 0)

        #expect(!movedUnknown)
        #expect(movedSame)
        #expect(table.first?.beatTime == 0)
    }

    @Test
    func remove_entry() throws {
        var table = KeyTable()
        let entryID = try table.insert(beatTime: 0, key: key(1), extras: sampleExtras("major"))

        let removedUnknown = table.remove(entryID: EntryID())
        let removed = table.remove(entryID: entryID)

        #expect(!removedUnknown)
        #expect(removed)
        #expect(table.isEmpty)
        #expect(!table.hasExtras)
    }

    @Test
    func removeAll_emptiesTable() throws {
        var table = KeyTable()

        try table.insert(beatTime: 0, key: key(1), extras: sampleExtras("major"))
        try table.insert(beatTime: 4, key: key(2))

        table.removeAll()

        #expect(table.isEmpty)
        #expect(!table.hasExtras)
    }

    @Test
    func update_replacesKeyAndExtras() throws {
        var table = KeyTable()
        let entryID = try table.insert(beatTime: 3, key: key(1), extras: sampleExtras("major"))

        let updatedUnknown = table.update(entryID: EntryID(), key: key(2))
        let updated = table.update(entryID: entryID, key: key(-3))

        #expect(!updatedUnknown)
        #expect(updated)
        #expect(table.first?.beatTime == 3)
        #expect(table.first?.entryID == entryID)
        #expect(table.first?.key == key(-3))
        #expect(table.first?.extras == nil)
        #expect(!table.hasExtras)
    }
}

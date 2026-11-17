// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct KeySignatureTableTests {
}

// MARK: -

extension KeySignatureTableTests {
    @Test
    func codable_encodesEntries() throws {
        var table = KeySignatureTable()

        try table.insert(beatTime: 0, keySignature: keySignature(2))
        try table.insert(beatTime: 4,
                         keySignature: #require(KeySignature(accidentals: [PitchClass.bFlat, .fSharp])))

        let encoder = JSONEncoder()

        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]

        let json = try #require(String(data: encoder.encode(table), encoding: .utf8))

        #expect(json == #"{"entries":[["0",["F♯","C♯"]],["4",["B♭","F♯"]]]}"#)
    }

    @Test(arguments: [#"{"entries":[["0",[]],["0",["F♯"]]]}"#,     // duplicate time
                      #"{"entries":[["1",[]],["0",["F♯"]]]}"#,     // out of order
                      #"{"entries":[["0",["F♯","F♭"]]]}"#,         // repeated letter
                      #"{}"#])                                      // entries missing
    func codable_rejectsInvalidTable(_ json: String) {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(KeySignatureTable.self, from: Data(json.utf8))
        }
    }

    @Test
    func codable_roundTrips() throws {
        var table = try makeKeySignatureTable([(0, 2), (frac(7, 2), -3)])

        try table.insert(beatTime: 8, keySignature: keySignature(1), extras: modeExtras("minor"))

        let data = try JSONEncoder().encode(table)
        let decoded = try JSONDecoder().decode(KeySignatureTable.self, from: data)

        #expect(decoded == table)
        #expect(decoded.hasExtras)
    }

    @Test
    func entry_snapshotsStoredEntry() throws {
        var table = KeySignatureTable()
        let entryID = try table.insert(beatTime: 2, keySignature: keySignature(-1), extras: modeExtras("minor"))
        let entry = try #require(table.first)

        #expect(entry.beatTime == 2)
        #expect(entry.entryID == entryID)
        #expect(entry.extras == modeExtras("minor"))
        #expect(entry.keySignature == keySignature(-1))
    }

    @Test
    func equality_ignoresIdentity() throws {
        let table1 = try makeKeySignatureTable([(0, 2), (4, -1)])
        let table2 = try makeKeySignatureTable([(0, 2), (4, -1)])

        #expect(table1 == table2)
        #expect(table1.hashValue == table2.hashValue)
        #expect(try table1 != makeKeySignatureTable([(0, 2)]))
    }

    @Test
    func init_isEmpty() {
        let table = KeySignatureTable()

        #expect(table.isEmpty)
        #expect(!table.hasExtras)
        #expect(table.keySignature(at: 0) == nil)
    }

    @Test
    func insert_keepsOrder() throws {
        let table = try makeKeySignatureTable([(4, 1), (0, 2), (2, -3)])

        #expect(table.map(\.beatTime) == [0, 2, 4])
        #expect(table.map(\.keySignature) == [keySignature(2), keySignature(-3), keySignature(1)])
    }

    @Test
    func insert_redundantEntryAllowed() throws {
        let table = try makeKeySignatureTable([(0, 2), (4, 2)])

        #expect(table.count == 2)
    }

    @Test
    func insert_sameTimeThrows() throws {
        var table = try makeKeySignatureTable([(1, 2)])

        #expect(throws: KeySignatureTable.Error.entryExists(1)) {
            try table.insert(beatTime: 1, keySignature: keySignature(3))
        }

        #expect(table.count == 1)
    }

    @Test
    func insert_withExtrasSetsHasExtras() throws {
        var table = KeySignatureTable()

        try table.insert(beatTime: 0, keySignature: keySignature(0), extras: modeExtras("none"))

        #expect(table.hasExtras)
    }

    @Test
    func keySignatureAt_lookup() throws {
        let table = try makeKeySignatureTable([(2, 2), (6, -1)])

        #expect(table.keySignature(at: 0) == nil)       // before the first entry: no key
        #expect(table.keySignature(at: 2) == keySignature(2))
        #expect(table.keySignature(at: 5) == keySignature(2))
        #expect(table.keySignature(at: 6) == keySignature(-1))
        #expect(table.keySignature(at: 100) == keySignature(-1))
    }

    @Test
    func move_keepsIdentityAndReorders() throws {
        var table = try makeKeySignatureTable([(0, 2), (4, -1)])
        let entryID = try #require(table.first?.entryID)

        let moved = try table.move(entryID: entryID, to: 6)

        #expect(moved)
        #expect(table.map(\.beatTime) == [4, 6])
        #expect(table.last?.entryID == entryID)
        #expect(table.last?.keySignature == keySignature(2))
    }

    @Test
    func move_occupiedTimeThrows() throws {
        var table = try makeKeySignatureTable([(0, 2), (4, -1)])
        let entryID = try #require(table.first?.entryID)

        #expect(throws: KeySignatureTable.Error.entryExists(4)) {
            try table.move(entryID: entryID, to: 4)
        }
    }

    @Test
    func move_unknownOrSameTime() throws {
        var table = try makeKeySignatureTable([(0, 2)])
        let entryID = try #require(table.first?.entryID)

        let movedUnknown = try table.move(entryID: EntryID(), to: 1)
        let movedSame = try table.move(entryID: entryID, to: 0)

        #expect(!movedUnknown)
        #expect(movedSame)
        #expect(table.first?.beatTime == 0)
    }

    @Test
    func remove_entry() throws {
        var table = KeySignatureTable()
        let entryID = try table.insert(beatTime: 0, keySignature: keySignature(1), extras: modeExtras("major"))

        let removedUnknown = table.remove(entryID: EntryID())
        let removed = table.remove(entryID: entryID)

        #expect(!removedUnknown)
        #expect(removed)
        #expect(table.isEmpty)
        #expect(!table.hasExtras)
    }

    @Test
    func removeAll_emptiesTable() throws {
        var table = KeySignatureTable()

        try table.insert(beatTime: 0, keySignature: keySignature(1), extras: modeExtras("major"))
        try table.insert(beatTime: 4, keySignature: keySignature(2))

        table.removeAll()

        #expect(table.isEmpty)
        #expect(!table.hasExtras)
    }

    @Test
    func update_replacesKeySignatureAndExtras() throws {
        var table = KeySignatureTable()
        let entryID = try table.insert(beatTime: 3, keySignature: keySignature(1), extras: modeExtras("major"))

        let updatedUnknown = table.update(entryID: EntryID(), keySignature: keySignature(2))
        let updated = table.update(entryID: entryID, keySignature: keySignature(-3))

        #expect(!updatedUnknown)
        #expect(updated)
        #expect(table.first?.beatTime == 3)
        #expect(table.first?.entryID == entryID)
        #expect(table.first?.keySignature == keySignature(-3))
        #expect(table.first?.extras == nil)
        #expect(!table.hasExtras)
    }
}

// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct KeySignatureTableEntryTests {
}

// MARK: -

extension KeySignatureTableEntryTests {
    @Test
    func collection_yieldsInsertedEntry() throws {
        var table = KeySignatureTable()

        let entryID = try table.insert(beatTime: 2,
                                       keySignature: keySignature(3),
                                       extras: modeExtras("major"))

        let entry = try #require(table.first)

        #expect(entry.beatTime == 2)
        #expect(entry.entryID == entryID)
        #expect(entry.extras == modeExtras("major"))
        #expect(entry.keySignature == keySignature(3))
    }

    @Test
    func equality() {
        let stored = KeySignatureTable.StoredEntry(beatTime: 1,
                                                   keySignature: keySignature(0),
                                                   extras: nil)

        #expect(KeySignatureTable.Entry(stored) == KeySignatureTable.Entry(stored)) // swiftlint:disable:this identical_operands
    }

    @Test
    func inequality_differentEntryID() {
        let stored1 = KeySignatureTable.StoredEntry(beatTime: 1,
                                                    keySignature: keySignature(0),
                                                    extras: nil)
        let stored2 = KeySignatureTable.StoredEntry(beatTime: 1,
                                                    keySignature: keySignature(0),
                                                    extras: nil)

        #expect(KeySignatureTable.Entry(stored1) != KeySignatureTable.Entry(stored2))
    }

    @Test
    func init_copiesStoredEntry() {
        let entryID = EntryID()
        let stored = KeySignatureTable.StoredEntry(entryID: entryID,
                                                   beatTime: 3,
                                                   keySignature: keySignature(-2),
                                                   extras: modeExtras("dorian"))
        let entry = KeySignatureTable.Entry(stored)

        #expect(entry.beatTime == 3)
        #expect(entry.entryID == entryID)
        #expect(entry.extras == modeExtras("dorian"))
        #expect(entry.keySignature == keySignature(-2))
    }

    @Test
    func init_withoutExtras_hasNilExtras() {
        let stored = KeySignatureTable.StoredEntry(beatTime: 0,
                                                   keySignature: keySignature(1),
                                                   extras: nil)

        #expect(KeySignatureTable.Entry(stored).extras == nil)
    }
}

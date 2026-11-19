// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct KeyTableEntryTests {
}

// MARK: -

extension KeyTableEntryTests {
    @Test
    func collection_yieldsInsertedEntry() throws {
        var table = KeyTable()

        let entryID = try table.insert(beatTime: 2,
                                       key: key(3),
                                       extras: sampleExtras("major"))

        let entry = try #require(table.first)

        #expect(entry.beatTime == 2)
        #expect(entry.entryID == entryID)
        #expect(entry.extras == sampleExtras("major"))
        #expect(entry.key == key(3))
    }

    @Test
    func equality() {
        let stored = KeyTable.StoredEntry(beatTime: 1,
                                          key: key(0),
                                          extras: nil)

        #expect(KeyTable.Entry(stored) == KeyTable.Entry(stored)) // swiftlint:disable:this identical_operands
    }

    @Test
    func inequality_differentEntryID() {
        let stored1 = KeyTable.StoredEntry(beatTime: 1,
                                           key: key(0),
                                           extras: nil)
        let stored2 = KeyTable.StoredEntry(beatTime: 1,
                                           key: key(0),
                                           extras: nil)

        #expect(KeyTable.Entry(stored1) != KeyTable.Entry(stored2))
    }

    @Test
    func init_copiesStoredEntry() {
        let entryID = EntryID()
        let stored = KeyTable.StoredEntry(entryID: entryID,
                                          beatTime: 3,
                                          key: key(-2),
                                          extras: sampleExtras("dorian"))
        let entry = KeyTable.Entry(stored)

        #expect(entry.beatTime == 3)
        #expect(entry.entryID == entryID)
        #expect(entry.extras == sampleExtras("dorian"))
        #expect(entry.key == key(-2))
    }

    @Test
    func init_withoutExtras_hasNilExtras() {
        let stored = KeyTable.StoredEntry(beatTime: 0,
                                          key: key(1),
                                          extras: nil)

        #expect(KeyTable.Entry(stored).extras == nil)
    }
}

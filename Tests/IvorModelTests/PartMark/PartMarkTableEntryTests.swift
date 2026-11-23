// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct PartMarkTableEntryTests {
}

// MARK: -

extension PartMarkTableEntryTests {
    @Test
    func collection_yieldsInsertedEntry() throws {
        var table = PartMarkTable<BeatTime>()

        let (entryID, _) = table.insert(time: 2,
                                        mark: quarterFermataMark(1))

        let entry = try #require(table.first)

        #expect(entry.entryID == entryID)
        #expect(entry.mark == quarterFermataMark(1))
        #expect(entry.time == 2)
    }

    @Test
    func equality() {
        let stored = PartMarkTable<BeatTime>.StoredEntry(time: 1,
                                                         mark: .caesura(nil))

        #expect(PartMarkTable<BeatTime>.Entry(stored) == PartMarkTable<BeatTime>.Entry(stored)) // swiftlint:disable:this identical_operands
    }

    @Test
    func inequality_differentEntryID() {
        let stored1 = PartMarkTable<BeatTime>.StoredEntry(time: 1,
                                                          mark: .caesura(nil))
        let stored2 = PartMarkTable<BeatTime>.StoredEntry(time: 1,
                                                          mark: .caesura(nil))

        #expect(PartMarkTable<BeatTime>.Entry(stored1) != PartMarkTable<BeatTime>.Entry(stored2))
    }

    @Test
    func init_copiesStoredEntry() {
        let entryID = EntryID()
        let stored = PartMarkTable<BeatTime>.StoredEntry(entryID: entryID,
                                                         time: 3,
                                                         mark: quarterFermataMark(2))
        let entry = PartMarkTable<BeatTime>.Entry(stored)

        #expect(entry.entryID == entryID)
        #expect(entry.mark == quarterFermataMark(2))
        #expect(entry.time == 3)
    }
}

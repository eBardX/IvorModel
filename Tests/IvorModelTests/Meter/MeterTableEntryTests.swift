// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct MeterTableEntryTests {
}

// MARK: -

extension MeterTableEntryTests {
    @Test
    func collection_yieldsInsertedEntry() throws {
        var table = MeterTable()

        let entryID = try table.insert(beatTime: 2,
                                       meter: meter("3/4"),
                                       extras: makeChannelExtras(3))

        let entry = try #require(table.first)

        #expect(entry.beatTime == 2)
        #expect(entry.entryID == entryID)
        #expect(entry.extras == makeChannelExtras(3))
        #expect(entry.meter == meter("3/4"))
    }

    @Test
    func equality() {
        let stored = MeterTable.StoredEntry(beatTime: 1,
                                            meter: meter("4/4"),
                                            extras: nil)

        #expect(MeterTable.Entry(stored) == MeterTable.Entry(stored)) // swiftlint:disable:this identical_operands
    }

    @Test
    func inequality_differentEntryID() {
        let stored1 = MeterTable.StoredEntry(beatTime: 1,
                                             meter: meter("4/4"),
                                             extras: nil)
        let stored2 = MeterTable.StoredEntry(beatTime: 1,
                                             meter: meter("4/4"),
                                             extras: nil)

        #expect(MeterTable.Entry(stored1) != MeterTable.Entry(stored2))
    }

    @Test
    func init_copiesStoredEntry() {
        let entryID = EntryID()
        let stored = MeterTable.StoredEntry(entryID: entryID,
                                            beatTime: 3,
                                            meter: meter("6/8"),
                                            extras: makeChannelExtras(1))
        let entry = MeterTable.Entry(stored)

        #expect(entry.beatTime == 3)
        #expect(entry.entryID == entryID)
        #expect(entry.extras == makeChannelExtras(1))
        #expect(entry.meter == meter("6/8"))
    }

    @Test
    func init_withoutExtras_hasNilExtras() {
        let stored = MeterTable.StoredEntry(beatTime: 0,
                                            meter: .free,
                                            extras: nil)

        #expect(MeterTable.Entry(stored).extras == nil)
    }
}

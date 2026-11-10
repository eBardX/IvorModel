// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct PedalTableEntryTests {
}

// MARK: -

extension PedalTableEntryTests {
    @Test
    func collection_yieldsInsertedEntry() throws {
        var table = PedalTable<BeatTime>()

        let (entryID, _) = table.insert(time: 2,
                                        level: .down,
                                        extras: makeChannelExtras(3))

        let entry = try #require(table.first)

        #expect(entry.entryID == entryID)
        #expect(entry.extras == makeChannelExtras(3))
        #expect(entry.level == .down)
        #expect(entry.time == 2)
    }

    @Test
    func equality() {
        let stored = PedalTable<BeatTime>.StoredEntry(time: 1,
                                                      level: .down,
                                                      extras: nil)

        #expect(PedalTable<BeatTime>.Entry(stored) == PedalTable<BeatTime>.Entry(stored)) // swiftlint:disable:this identical_operands
    }

    @Test
    func inequality_differentEntryID() {
        let stored1 = PedalTable<BeatTime>.StoredEntry(time: 1,
                                                       level: .down,
                                                       extras: nil)
        let stored2 = PedalTable<BeatTime>.StoredEntry(time: 1,
                                                       level: .down,
                                                       extras: nil)

        #expect(PedalTable<BeatTime>.Entry(stored1) != PedalTable<BeatTime>.Entry(stored2))
    }

    @Test
    func init_copiesStoredEntry() {
        let entryID = EntryID()
        let stored = PedalTable<BeatTime>.StoredEntry(entryID: entryID,
                                                      time: 3,
                                                      level: .up,
                                                      extras: makeChannelExtras(1))
        let entry = PedalTable<BeatTime>.Entry(stored)

        #expect(entry.entryID == entryID)
        #expect(entry.extras == makeChannelExtras(1))
        #expect(entry.level == .up)
        #expect(entry.time == 3)
    }

    @Test
    func init_withoutExtras_hasNilExtras() {
        let stored = PedalTable<BeatTime>.StoredEntry(time: 0,
                                                      level: .down,
                                                      extras: nil)

        #expect(PedalTable<BeatTime>.Entry(stored).extras == nil)
    }
}

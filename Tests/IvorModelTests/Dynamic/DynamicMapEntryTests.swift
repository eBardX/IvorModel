// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct DynamicMapEntryTests {
}

// MARK: -

extension DynamicMapEntryTests {
    @Test
    func collection_yieldsInsertedEntry() throws {
        var map = DynamicMap<BeatTime>()

        let (entryID, _) = map.insert(time: 2,
                                      dynamic: .f,
                                      extras: makeChannelExtras(3))

        let entry = try #require(map.first)

        #expect(entry.entryID == entryID)
        #expect(entry.extras == makeChannelExtras(3))
        #expect(entry.dynamic == .f)
        #expect(entry.time == 2)
    }

    @Test
    func equality() {
        let stored = DynamicMap<BeatTime>.StoredEntry(time: 1,
                                                      dynamic: .f,
                                                      extras: nil)

        #expect(DynamicMap<BeatTime>.Entry(stored) == DynamicMap<BeatTime>.Entry(stored)) // swiftlint:disable:this identical_operands
    }

    @Test
    func inequality_differentEntryID() {
        let stored1 = DynamicMap<BeatTime>.StoredEntry(time: 1,
                                                       dynamic: .f,
                                                       extras: nil)
        let stored2 = DynamicMap<BeatTime>.StoredEntry(time: 1,
                                                       dynamic: .f,
                                                       extras: nil)

        #expect(DynamicMap<BeatTime>.Entry(stored1) != DynamicMap<BeatTime>.Entry(stored2))
    }

    @Test
    func init_copiesStoredEntry() {
        let entryID = EntryID()
        let stored = DynamicMap<BeatTime>.StoredEntry(entryID: entryID,
                                                      time: 3,
                                                      dynamic: .p,
                                                      extras: makeChannelExtras(1))
        let entry = DynamicMap<BeatTime>.Entry(stored)

        #expect(entry.entryID == entryID)
        #expect(entry.extras == makeChannelExtras(1))
        #expect(entry.dynamic == .p)
        #expect(entry.time == 3)
    }

    @Test
    func init_withoutExtras_hasNilExtras() {
        let stored = DynamicMap<BeatTime>.StoredEntry(time: 0,
                                                      dynamic: .f,
                                                      extras: nil)

        #expect(DynamicMap<BeatTime>.Entry(stored).extras == nil)
    }
}

// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct InstrumentTableEntryTests {
}

// MARK: -

extension InstrumentTableEntryTests {
    @Test
    func collection_yieldsInsertedEntry() throws {
        var map = InstrumentTable<BeatTime>()

        let (entryID, _) = map.insert(time: 2,
                                      instrument: Fixtures.oboe,
                                      extras: makeChannelExtras(3))

        let entry = try #require(map.first)

        #expect(entry.entryID == entryID)
        #expect(entry.extras == makeChannelExtras(3))
        #expect(entry.instrument == Fixtures.oboe)
        #expect(entry.time == 2)
    }

    @Test
    func equality() {
        let stored = InstrumentTable<BeatTime>.StoredEntry(time: 1,
                                                           instrument: Fixtures.oboe,
                                                           extras: nil)

        #expect(InstrumentTable<BeatTime>.Entry(stored) == InstrumentTable<BeatTime>.Entry(stored)) // swiftlint:disable:this identical_operands
    }

    @Test
    func inequality_differentEntryID() {
        let stored1 = InstrumentTable<BeatTime>.StoredEntry(time: 1,
                                                            instrument: Fixtures.oboe,
                                                            extras: nil)
        let stored2 = InstrumentTable<BeatTime>.StoredEntry(time: 1,
                                                            instrument: Fixtures.oboe,
                                                            extras: nil)

        #expect(InstrumentTable<BeatTime>.Entry(stored1) != InstrumentTable<BeatTime>.Entry(stored2))
    }

    @Test
    func init_copiesStoredEntry() {
        let entryID = EntryID()
        let stored = InstrumentTable<BeatTime>.StoredEntry(entryID: entryID,
                                                           time: 3,
                                                           instrument: Fixtures.flute,
                                                           extras: makeChannelExtras(1))
        let entry = InstrumentTable<BeatTime>.Entry(stored)

        #expect(entry.entryID == entryID)
        #expect(entry.extras == makeChannelExtras(1))
        #expect(entry.instrument == Fixtures.flute)
        #expect(entry.time == 3)
    }

    @Test
    func init_withoutExtras_hasNilExtras() {
        let stored = InstrumentTable<BeatTime>.StoredEntry(time: 0,
                                                           instrument: Fixtures.oboe,
                                                           extras: nil)

        #expect(InstrumentTable<BeatTime>.Entry(stored).extras == nil)
    }
}

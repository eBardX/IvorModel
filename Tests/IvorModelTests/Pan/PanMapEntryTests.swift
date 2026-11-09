// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct PanMapEntryTests {
}

// MARK: -

extension PanMapEntryTests {
    @Test
    func collection_yieldsInsertedEntry() throws {
        var map = PanMap<BeatTime>()

        let (entryID, _) = map.insert(time: 2,
                                      pan: .left,
                                      extras: makeChannelExtras(3))

        let entry = try #require(map.first)

        #expect(entry.entryID == entryID)
        #expect(entry.extras == makeChannelExtras(3))
        #expect(entry.pan == .left)
        #expect(entry.time == 2)
    }

    @Test
    func equality() {
        let stored = PanMap<BeatTime>.StoredEntry(time: 1,
                                                  pan: .left,
                                                  extras: nil)

        #expect(PanMap<BeatTime>.Entry(stored) == PanMap<BeatTime>.Entry(stored)) // swiftlint:disable:this identical_operands
    }

    @Test
    func inequality_differentEntryID() {
        let stored1 = PanMap<BeatTime>.StoredEntry(time: 1,
                                                   pan: .left,
                                                   extras: nil)
        let stored2 = PanMap<BeatTime>.StoredEntry(time: 1,
                                                   pan: .left,
                                                   extras: nil)

        #expect(PanMap<BeatTime>.Entry(stored1) != PanMap<BeatTime>.Entry(stored2))
    }

    @Test
    func init_copiesStoredEntry() {
        let entryID = EntryID()
        let stored = PanMap<BeatTime>.StoredEntry(entryID: entryID,
                                                  time: 3,
                                                  pan: Fixtures.leftPan,
                                                  extras: makeChannelExtras(1))
        let entry = PanMap<BeatTime>.Entry(stored)

        #expect(entry.entryID == entryID)
        #expect(entry.extras == makeChannelExtras(1))
        #expect(entry.pan == Fixtures.leftPan)
        #expect(entry.time == 3)
    }

    @Test
    func init_withoutExtras_hasNilExtras() {
        let stored = PanMap<BeatTime>.StoredEntry(time: 0,
                                                  pan: .left,
                                                  extras: nil)

        #expect(PanMap<BeatTime>.Entry(stored).extras == nil)
    }
}

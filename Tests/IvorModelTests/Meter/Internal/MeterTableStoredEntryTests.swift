// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct MeterTableStoredEntryTests {
}

// MARK: -

extension MeterTableStoredEntryTests {
    @Test
    func codable_extended() throws {
        let original = MeterTable.StoredEntry(beatTime: 1,
                                              meter: meter("3/4"),
                                              extras: makeChannelExtras(2))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MeterTable.StoredEntry.self,
                                               from: data)

        #expect(decoded == original)
        #expect(decoded.extras == makeChannelExtras(2))
    }

    @Test
    func codable_simple_encodesBeatTimeAndMeter() throws {
        let original = MeterTable.StoredEntry(beatTime: 1,
                                              meter: meter("3/4"),
                                              extras: nil)
        let data = try JSONEncoder().encode(original)

        #expect(String(data: data, encoding: .utf8) == #"["1","3\/4"]"#)
    }

    @Test
    func decode_assignsFreshIdentity() throws {
        let original = MeterTable.StoredEntry(beatTime: 1,
                                              meter: meter("3/4"),
                                              extras: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MeterTable.StoredEntry.self,
                                               from: data)

        #expect(decoded.entryID != original.entryID)
    }

    @Test
    func equality_ignoresIdentity() {
        let entry1 = MeterTable.StoredEntry(beatTime: 1,
                                            meter: meter("3/4"),
                                            extras: nil)
        let entry2 = MeterTable.StoredEntry(beatTime: 1,
                                            meter: meter("3/4"),
                                            extras: nil)

        #expect(entry1.entryID != entry2.entryID)
        #expect(entry1 == entry2)
    }

    @Test
    func inequality() {
        let entry = MeterTable.StoredEntry(beatTime: 1,
                                           meter: meter("3/4"),
                                           extras: nil)

        #expect(entry != MeterTable.StoredEntry(beatTime: 2, meter: meter("3/4"), extras: nil))
        #expect(entry != MeterTable.StoredEntry(beatTime: 1, meter: meter("2/4"), extras: nil))
        #expect(entry != MeterTable.StoredEntry(beatTime: 1, meter: meter("3/4"), extras: makeChannelExtras(1)))
    }

    @Test
    func init_emptyExtras_isSimple() {
        let entry = MeterTable.StoredEntry(beatTime: 0,
                                           meter: .free,
                                           extras: Extras(elements: []))

        #expect(entry.extras == nil)
    }

    @Test
    func init_keepsEntryID() {
        let entryID = EntryID()
        let entry = MeterTable.StoredEntry(entryID: entryID,
                                           beatTime: 0,
                                           meter: .free,
                                           extras: nil)

        #expect(entry.entryID == entryID)
    }

    @Test
    func init_withExtras_isExtended() {
        let entry = MeterTable.StoredEntry(beatTime: 2,
                                           meter: meter("6/8"),
                                           extras: makeChannelExtras(4))

        #expect(entry.beatTime == 2)
        #expect(entry.extras == makeChannelExtras(4))
        #expect(entry.meter == meter("6/8"))
    }

    @Test
    func moved_keepsIdentityMeterAndExtras() {
        let entry = MeterTable.StoredEntry(beatTime: 2,
                                           meter: meter("6/8"),
                                           extras: makeChannelExtras(4))
        let moved = entry.moved(to: 5)

        #expect(moved.beatTime == 5)
        #expect(moved.entryID == entry.entryID)
        #expect(moved.extras == entry.extras)
        #expect(moved.meter == entry.meter)
    }
}

// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct KeyTableStoredEntryTests {
}

// MARK: -

extension KeyTableStoredEntryTests {
    @Test
    func codable_extended() throws {
        let original = KeyTable.StoredEntry(beatTime: 1,
                                            key: key(2),
                                            extras: sampleExtras("major"))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(KeyTable.StoredEntry.self,
                                               from: data)

        #expect(decoded == original)
        #expect(decoded.extras == sampleExtras("major"))
    }

    @Test
    func codable_simple() throws {
        let original = KeyTable.StoredEntry(beatTime: 1,
                                            key: key(-3),
                                            extras: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(KeyTable.StoredEntry.self,
                                               from: data)

        #expect(decoded == original)
        #expect(decoded.extras == nil)
    }

    @Test
    func decode_assignsFreshIdentity() throws {
        let original = KeyTable.StoredEntry(beatTime: 1,
                                            key: key(2),
                                            extras: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(KeyTable.StoredEntry.self,
                                               from: data)

        #expect(decoded.entryID != original.entryID)
    }

    @Test
    func decode_normalizesExtraNames() throws {
        let original = KeyTable.StoredEntry(beatTime: 1,
                                            key: key(2),
                                            extras: Extras(elements: [Extra(name: "Fingering",
                                                                            values: [.string("1")])]))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(KeyTable.StoredEntry.self,
                                               from: data)

        #expect(decoded.extras == Extras(elements: [Extra(name: Extra.fingering.name,
                                                          values: [.string("1")])]))
    }

    @Test
    func equality_ignoresIdentity() {
        let entry1 = KeyTable.StoredEntry(beatTime: 1,
                                          key: key(2),
                                          extras: nil)
        let entry2 = KeyTable.StoredEntry(beatTime: 1,
                                          key: key(2),
                                          extras: nil)

        #expect(entry1.entryID != entry2.entryID)
        #expect(entry1 == entry2)
    }

    @Test
    func inequality() {
        let entry = KeyTable.StoredEntry(beatTime: 1,
                                         key: key(2),
                                         extras: nil)

        #expect(entry != KeyTable.StoredEntry(beatTime: 2, key: key(2), extras: nil))
        #expect(entry != KeyTable.StoredEntry(beatTime: 1, key: key(3), extras: nil))
        #expect(entry != KeyTable.StoredEntry(beatTime: 1, key: key(2), extras: sampleExtras("major")))
    }

    @Test
    func init_emptyExtras_isSimple() {
        let entry = KeyTable.StoredEntry(beatTime: 0,
                                         key: key(0),
                                         extras: Extras(elements: []))

        #expect(entry.extras == nil)
    }

    @Test
    func init_keepsEntryID() {
        let entryID = EntryID()
        let entry = KeyTable.StoredEntry(entryID: entryID,
                                         beatTime: 0,
                                         key: key(0),
                                         extras: nil)

        #expect(entry.entryID == entryID)
    }

    @Test
    func init_withExtras_isExtended() {
        let entry = KeyTable.StoredEntry(beatTime: 2,
                                         key: key(-1),
                                         extras: sampleExtras("major"))

        #expect(entry.beatTime == 2)
        #expect(entry.extras == sampleExtras("major"))
        #expect(entry.key == key(-1))
    }

    @Test
    func moved_keepsIdentityKeyAndExtras() {
        let entry = KeyTable.StoredEntry(beatTime: 2,
                                         key: key(4),
                                         extras: sampleExtras("major"))
        let moved = entry.moved(to: 5)

        #expect(moved.beatTime == 5)
        #expect(moved.entryID == entry.entryID)
        #expect(moved.extras == entry.extras)
        #expect(moved.key == entry.key)
    }

    @Test
    func with_keepsIdentityTimeAndExtras() {
        let entry = KeyTable.StoredEntry(beatTime: 2,
                                         key: key(1, .major),
                                         extras: sampleExtras("major"))
        let changed = entry.with(key(3, .major))

        #expect(changed.beatTime == 2)
        #expect(changed.entryID == entry.entryID)
        #expect(changed.extras == sampleExtras("major"))
        #expect(changed.key == key(3, .major))
    }
}

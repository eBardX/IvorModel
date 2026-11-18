// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct KeySignatureTableStoredEntryTests {
}

// MARK: -

extension KeySignatureTableStoredEntryTests {
    @Test
    func codable_extended() throws {
        let original = KeySignatureTable.StoredEntry(beatTime: 1,
                                                     keySignature: keySignature(2),
                                                     extras: modeExtras("major"))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(KeySignatureTable.StoredEntry.self,
                                               from: data)

        #expect(decoded == original)
        #expect(decoded.extras == modeExtras("major"))
    }

    @Test
    func codable_simple() throws {
        let original = KeySignatureTable.StoredEntry(beatTime: 1,
                                                     keySignature: keySignature(-3),
                                                     extras: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(KeySignatureTable.StoredEntry.self,
                                               from: data)

        #expect(decoded == original)
        #expect(decoded.extras == nil)
    }

    @Test
    func decode_assignsFreshIdentity() throws {
        let original = KeySignatureTable.StoredEntry(beatTime: 1,
                                                     keySignature: keySignature(2),
                                                     extras: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(KeySignatureTable.StoredEntry.self,
                                               from: data)

        #expect(decoded.entryID != original.entryID)
    }

    @Test
    func decode_normalizesExtraNames() throws {
        let original = KeySignatureTable.StoredEntry(beatTime: 1,
                                                     keySignature: keySignature(2),
                                                     extras: Extras(elements: [Extra(name: "KeySignatureMode",
                                                                                     values: [.string("minor")])]))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(KeySignatureTable.StoredEntry.self,
                                               from: data)

        #expect(decoded.extras == modeExtras("minor"))
    }

    @Test
    func equality_ignoresIdentity() {
        let entry1 = KeySignatureTable.StoredEntry(beatTime: 1,
                                                   keySignature: keySignature(2),
                                                   extras: nil)
        let entry2 = KeySignatureTable.StoredEntry(beatTime: 1,
                                                   keySignature: keySignature(2),
                                                   extras: nil)

        #expect(entry1.entryID != entry2.entryID)
        #expect(entry1 == entry2)
    }

    @Test
    func inequality() {
        let entry = KeySignatureTable.StoredEntry(beatTime: 1,
                                                  keySignature: keySignature(2),
                                                  extras: nil)

        #expect(entry != KeySignatureTable.StoredEntry(beatTime: 2, keySignature: keySignature(2), extras: nil))
        #expect(entry != KeySignatureTable.StoredEntry(beatTime: 1, keySignature: keySignature(3), extras: nil))
        #expect(entry != KeySignatureTable.StoredEntry(beatTime: 1, keySignature: keySignature(2), extras: modeExtras("major")))
    }

    @Test
    func init_emptyExtras_isSimple() {
        let entry = KeySignatureTable.StoredEntry(beatTime: 0,
                                                  keySignature: keySignature(0),
                                                  extras: Extras(elements: []))

        #expect(entry.extras == nil)
    }

    @Test
    func init_keepsEntryID() {
        let entryID = EntryID()
        let entry = KeySignatureTable.StoredEntry(entryID: entryID,
                                                  beatTime: 0,
                                                  keySignature: keySignature(0),
                                                  extras: nil)

        #expect(entry.entryID == entryID)
    }

    @Test
    func init_withExtras_isExtended() {
        let entry = KeySignatureTable.StoredEntry(beatTime: 2,
                                                  keySignature: keySignature(-1),
                                                  extras: modeExtras("major"))

        #expect(entry.beatTime == 2)
        #expect(entry.extras == modeExtras("major"))
        #expect(entry.keySignature == keySignature(-1))
    }

    @Test
    func moved_keepsIdentityKeySignatureAndExtras() {
        let entry = KeySignatureTable.StoredEntry(beatTime: 2,
                                                  keySignature: keySignature(4),
                                                  extras: modeExtras("major"))
        let moved = entry.moved(to: 5)

        #expect(moved.beatTime == 5)
        #expect(moved.entryID == entry.entryID)
        #expect(moved.extras == entry.extras)
        #expect(moved.keySignature == entry.keySignature)
    }

    @Test
    func with_droppingMode_onlyModeExtra_isSimple() {
        let entry = KeySignatureTable.StoredEntry(beatTime: 0,
                                                  keySignature: keySignature(1),
                                                  extras: modeExtras("major"))

        #expect(entry.with(keySignature(3), droppingMode: true).extras == nil)
    }

    @Test
    func with_droppingMode_removesOnlyModeExtra() {
        let extras = Extras(elements: [Extra(name: Extra.keySignatureMode.name, values: [.string("major")]),
                                       Extra(name: "custom")])
        let entry = KeySignatureTable.StoredEntry(beatTime: 2,
                                                  keySignature: keySignature(1),
                                                  extras: extras)
        let changed = entry.with(keySignature(3), droppingMode: true)

        #expect(changed.beatTime == 2)
        #expect(changed.entryID == entry.entryID)
        #expect(changed.extras == Extras(elements: [Extra(name: "custom")]))
        #expect(changed.keySignature == keySignature(3))
    }

    @Test
    func with_keepingMode_keepsExtras() {
        let entry = KeySignatureTable.StoredEntry(beatTime: 0,
                                                  keySignature: keySignature(1),
                                                  extras: modeExtras("major"))
        let changed = entry.with(keySignature(3), droppingMode: false)

        #expect(changed.entryID == entry.entryID)
        #expect(changed.extras == modeExtras("major"))
        #expect(changed.keySignature == keySignature(3))
    }
}

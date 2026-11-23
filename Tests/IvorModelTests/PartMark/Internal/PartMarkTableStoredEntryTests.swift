// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct PartMarkTableStoredEntryTests {
}

// MARK: -

extension PartMarkTableStoredEntryTests {
    private typealias StoredEntry = PartMarkTable<BeatTime>.StoredEntry

    @Test
    func codable_caesura() throws {
        let original = StoredEntry(time: 2,
                                   mark: .caesura(nil))
        let decoded = try codingRoundTrip(original)

        #expect(decoded == original)
    }

    @Test
    func codable_encodesTimeThenMarkWithoutIdentity() throws {
        let entry = StoredEntry(time: 2,
                                mark: .caesura(nil))
        let json = try encodedJSON(entry)

        #expect(json.hasPrefix(#"["2","#))
        #expect(!json.contains(entry.entryID.stringValue))
    }

    @Test
    func codable_fermata() throws {
        let original = StoredEntry(time: 1,
                                   mark: quarterFermataMark(2))
        let decoded = try codingRoundTrip(original)

        #expect(decoded == original)
        #expect(decoded.entryID != original.entryID)
    }

    @Test
    func comparable() {
        let earlier = StoredEntry(time: 1, mark: .caesura(nil))
        let later = StoredEntry(time: 2, mark: quarterFermataMark(1))

        #expect(earlier < later)
        #expect(!(later < earlier))
    }

    @Test
    func comparable_sameTimeIsNotLess() {
        let first = StoredEntry(time: 1, mark: .caesura(nil))
        let second = StoredEntry(time: 1, mark: quarterFermataMark(1))

        #expect(!(first < second))
        #expect(!(second < first))
    }

    @Test
    func entryID_defaultsToFreshIdentity() {
        let e1 = StoredEntry(time: 1, mark: .caesura(nil))
        let e2 = StoredEntry(time: 1, mark: .caesura(nil))

        #expect(e1.entryID != e2.entryID)
    }

    @Test
    func entryID_explicit() {
        let entryID = EntryID()
        let entry = StoredEntry(entryID: entryID, time: 1, mark: .caesura(nil))

        #expect(entry.entryID == entryID)
    }

    @Test
    func equality_ignoresIdentity() {
        let e1 = StoredEntry(time: 1, mark: .caesura(nil))
        let e2 = StoredEntry(time: 1, mark: .caesura(nil))

        #expect(e1.entryID != e2.entryID)
        #expect(e1 == e2)
    }

    @Test
    func inequality_differentMark() {
        #expect(StoredEntry(time: 1, mark: .caesura(nil)) != StoredEntry(time: 1, mark: quarterFermataMark(1)))
    }

    @Test
    func inequality_differentTime() {
        #expect(StoredEntry(time: 1, mark: .caesura(nil)) != StoredEntry(time: 2, mark: .caesura(nil)))
    }

    @Test
    func init_storesTimeAndMark() {
        let entry = StoredEntry(time: 3, mark: quarterFermataMark(2))

        #expect(entry.mark == quarterFermataMark(2))
        #expect(entry.time == 3)
    }
}

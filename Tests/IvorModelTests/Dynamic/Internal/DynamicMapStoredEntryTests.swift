// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct DynamicMapStoredEntryTests {
}

// MARK: -

extension DynamicMapStoredEntryTests {
    private typealias StoredEntry = DynamicMap<BeatTime>.StoredEntry

    @Test
    func codable_extended() throws {
        let original = StoredEntry(time: 1,
                                   dynamic: .f,
                                   extras: Extras(elements: [Extra(name: "accent")]))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StoredEntry.self,
                                               from: data)

        #expect(decoded.time == original.time)
        #expect(decoded.dynamic == original.dynamic)
        #expect(decoded.extras == original.extras)
    }

    @Test
    func codable_simple() throws {
        let original = StoredEntry(time: 1,
                                   dynamic: .f,
                                   extras: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(StoredEntry.self,
                                               from: data)

        #expect(decoded.time == original.time)
        #expect(decoded.dynamic == original.dynamic)
        #expect(decoded.extras == nil)
    }

    @Test
    func comparable() {
        let earlier = StoredEntry(time: 1, dynamic: .f, extras: nil)
        let later = StoredEntry(time: 2, dynamic: .p, extras: nil)

        #expect(earlier < later)
        #expect(!(later < earlier))
    }

    @Test
    func dynamic() {
        let entry = StoredEntry(time: 1, dynamic: .mf, extras: nil)

        #expect(entry.dynamic == .mf)
    }

    @Test
    func entryID_defaultsToFreshIdentity() {
        let e1 = StoredEntry(time: 1, dynamic: .f, extras: nil)
        let e2 = StoredEntry(time: 1, dynamic: .f, extras: nil)

        #expect(e1.entryID != e2.entryID)
    }

    @Test
    func entryID_explicit() {
        let entryID = EntryID()
        let entry = StoredEntry(entryID: entryID, time: 1, dynamic: .f, extras: nil)

        #expect(entry.entryID == entryID)
    }

    @Test
    func equality_ignoresIdentity() {
        let e1 = StoredEntry(time: 1, dynamic: .f, extras: nil)
        let e2 = StoredEntry(time: 1, dynamic: .f, extras: nil)

        #expect(e1.entryID != e2.entryID)
        #expect(e1 == e2)
    }

    @Test
    func extras_extended() {
        let extras = Extras(elements: [Extra(name: "accent")])
        let entry = StoredEntry(time: 1, dynamic: .f, extras: extras)

        #expect(entry.extras == extras)
    }

    @Test
    func extras_simple() {
        let entry = StoredEntry(time: 1, dynamic: .f, extras: nil)

        #expect(entry.extras == nil)
    }

    @Test
    func init_extended() {
        let entry = StoredEntry(time: 1,
                                dynamic: .f,
                                extras: Extras(elements: [Extra(name: "accent")]))

        #expect(entry.extras != nil)
    }

    @Test
    func init_simple() {
        let entry = StoredEntry(time: 1, dynamic: .f, extras: nil)

        #expect(entry.extras == nil)
    }

    @Test
    func init_simple_emptyExtras() {
        let entry = StoredEntry(time: 1, dynamic: .f, extras: Extras())

        #expect(entry.extras == nil)
    }

    @Test
    func time() {
        let entry = StoredEntry(time: 3, dynamic: .f, extras: nil)

        #expect(entry.time == 3)
    }
}

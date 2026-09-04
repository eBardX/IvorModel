// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct DynamicMapEntryTests {
}

// MARK: -

extension DynamicMapEntryTests {
    private typealias Entry = DynamicMap<BeatTime>.Entry

    @Test
    func codable_extended() throws {
        let original = Entry(time: 1,
                             dynamic: .f,
                             extras: Extras(elements: [Extra(name: "accent")]))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Entry.self,
                                               from: data)

        #expect(decoded.time == original.time)
        #expect(decoded.dynamic == original.dynamic)
        #expect(decoded.extras == original.extras)
    }

    @Test
    func codable_simple() throws {
        let original = Entry(time: 1,
                             dynamic: .f,
                             extras: nil)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Entry.self,
                                               from: data)

        #expect(decoded.time == original.time)
        #expect(decoded.dynamic == original.dynamic)
        #expect(decoded.extras == nil)
    }

    @Test
    func comparable() {
        let earlier = Entry(time: 1, dynamic: .f, extras: nil)
        let later = Entry(time: 2, dynamic: .p, extras: nil)

        #expect(earlier < later)
        #expect(!(later < earlier))
    }

    @Test
    func dynamic() {
        let entry = Entry(time: 1, dynamic: .mf, extras: nil)

        #expect(entry.dynamic == .mf)
    }

    @Test
    func equality_ignoresIdentity() {
        let e1 = Entry(time: 1, dynamic: .f, extras: nil)
        let e2 = Entry(time: 1, dynamic: .f, extras: nil)

        #expect(e1.entryID != e2.entryID)
        #expect(e1 == e2)
    }

    @Test
    func extras_extended() {
        let extras = Extras(elements: [Extra(name: "accent")])
        let entry = Entry(time: 1, dynamic: .f, extras: extras)

        #expect(entry.extras == extras)
    }

    @Test
    func extras_simple() {
        let entry = Entry(time: 1, dynamic: .f, extras: nil)

        #expect(entry.extras == nil)
    }

    @Test
    func entryID_defaultsToFreshIdentity() {
        let e1 = Entry(time: 1, dynamic: .f, extras: nil)
        let e2 = Entry(time: 1, dynamic: .f, extras: nil)

        #expect(e1.entryID != e2.entryID)
    }

    @Test
    func entryID_explicit() {
        let entryID = DynamicMap<BeatTime>.EntryID()
        let entry = Entry(entryID: entryID, time: 1, dynamic: .f, extras: nil)

        #expect(entry.entryID == entryID)
    }

    @Test
    func init_extended() {
        let entry = Entry(time: 1,
                          dynamic: .f,
                          extras: Extras(elements: [Extra(name: "accent")]))

        #expect(entry.extras != nil)
    }

    @Test
    func init_simple() {
        let entry = Entry(time: 1, dynamic: .f, extras: nil)

        #expect(entry.extras == nil)
    }

    @Test
    func init_simple_emptyExtras() {
        let entry = Entry(time: 1, dynamic: .f, extras: Extras())

        #expect(entry.extras == nil)
    }

    @Test
    func time() {
        let entry = Entry(time: 3, dynamic: .f, extras: nil)

        #expect(entry.time == 3)
    }
}

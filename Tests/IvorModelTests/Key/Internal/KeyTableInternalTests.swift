// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct KeyTableInternalTests {
}

// MARK: -

extension KeyTableInternalTests {
    @Test
    func entryIndex_at() throws {
        let table = try makeKeyTable([(0, 0), (1, 2)])

        #expect(table.entryIndex(at: 1) == 1)
        #expect(table.entryIndex(at: beatTime(frac(1, 2))) == nil)
    }

    @Test
    func firstIndex_entryID() throws {
        let table = try makeKeyTable([(0, 0), (1, 2)])
        let entryID = try #require(table.last).entryID
        let unknownIndex = table.firstIndex(entryID: EntryID())

        #expect(table.firstIndex(entryID: entryID) == 1)
        #expect(unknownIndex == nil)
    }

    @Test
    func governingIndex_at() throws {
        let table = try makeKeyTable([(1, 0), (2, 2)])

        #expect(table.governingIndex(at: 0) == nil)
        #expect(table.governingIndex(at: beatTime(frac(3, 2))) == 0)
        #expect(table.governingIndex(at: 2) == 1)
        #expect(table.governingIndex(at: 9) == 1)
    }

    @Test
    func hasExtras_in() {
        let plain = KeyTable.StoredEntry(beatTime: 0,
                                         key: key(0),
                                         extras: nil)
        let extended = KeyTable.StoredEntry(beatTime: 1,
                                            key: key(0),
                                            extras: sampleExtras("major"))

        #expect(!KeyTable.hasExtras(in: []))
        #expect(!KeyTable.hasExtras(in: [plain]))
        #expect(KeyTable.hasExtras(in: [plain, extended]))
    }

    @Test
    func insertionIndex_for() throws {
        let table = try makeKeyTable([(0, 0), (1, 2)])

        #expect(table.insertionIndex(for: 0) == 1)
        #expect(table.insertionIndex(for: beatTime(frac(1, 2))) == 1)
        #expect(table.insertionIndex(for: 2) == 2)
    }
}

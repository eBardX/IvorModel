// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct PedalTableInternalTests {
    private let onLevel = Pedal.Level.on
    private let offLevel = Pedal.Level.off
}

// MARK: -

extension PedalTableInternalTests {
    @Test
    func deduplicated_empty() {
        #expect(PedalTable<BeatTime>.deduplicated([]).isEmpty)
    }

    @Test
    func deduplicated_foldsOnlyNeighbors() {
        let first = PedalTable<BeatTime>.StoredEntry(time: 1, level: .on, extras: nil)
        let duplicate = PedalTable<BeatTime>.StoredEntry(time: 1, level: .on, extras: nil)
        let off = PedalTable<BeatTime>.StoredEntry(time: 1, level: .off, extras: nil)
        let repress = PedalTable<BeatTime>.StoredEntry(time: 1, level: .on, extras: nil)
        let result = PedalTable<BeatTime>.deduplicated([first, duplicate, off, repress])

        #expect(result.map(\.entryID) == [first.entryID, off.entryID, repress.entryID])
    }

    @Test
    func firstIndex_entryID_found() throws {
        var table = PedalTable<BeatTime>()
        var foundEntryID: EntryID?

        table.insert(time: 1, level: onLevel)

        for entry in table {
            foundEntryID = entry.entryID
        }

        #expect(try table.firstIndex(entryID: #require(foundEntryID)) == 0)
    }

    @Test
    func firstIndex_entryID_notFound() {
        let table = PedalTable<BeatTime>()
        let position = table.firstIndex(entryID: EntryID())

        #expect(position == nil)
    }

    @Test
    func hasExtras_withExtras() {
        let entries = [PedalTable<BeatTime>.StoredEntry(time: 1,
                                                        level: onLevel,
                                                        extras: Extras(elements: [Extra(name: "muted")]))]

        #expect(PedalTable<BeatTime>.hasExtras(in: entries))
    }

    @Test
    func hasExtras_withoutExtras() {
        let entries = [PedalTable<BeatTime>.StoredEntry(time: 1, level: onLevel, extras: nil)]

        #expect(!PedalTable<BeatTime>.hasExtras(in: entries))
    }

    @Test
    func insertionIndex_empty() {
        let table = PedalTable<BeatTime>()

        #expect(table.insertionIndex(for: 1) == 0)
    }

    @Test
    func insertionIndex_middle() {
        var table = PedalTable<BeatTime>()

        table.insert(time: 1, level: onLevel)
        table.insert(time: 3, level: offLevel)

        #expect(table.insertionIndex(for: 2) == 1)
    }
}

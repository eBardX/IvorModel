// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct PartMarkTableInternalTests {
}

// MARK: -

extension PartMarkTableInternalTests {
    private typealias StoredEntry = PartMarkTable<BeatTime>.StoredEntry

    @Test
    func convertedTimes_dropsAMarkWhoseSpanConvertsToZero() {
        var table = PartMarkTable<BeatTime>()

        table.insert(time: 1, mark: quarterFermataMark(1))
        table.insert(time: 2, mark: .caesura(nil))

        let converted = table.convertedTimes { _ in beatTime(5) }

        #expect(converted.map(\.mark) == [.caesura(nil)])
        #expect(converted.map(\.time) == [5])
    }

    @Test
    func convertedTimes_keepsTheOrderAtOneTime() {
        var table = PartMarkTable<BeatTime>()

        table.insert(time: 1, mark: .caesura(nil))
        table.insert(time: 1, mark: quarterFermataMark(1))

        let converted = table.convertedTimes { $0 }

        #expect(converted.map(\.mark) == [.caesura(nil), quarterFermataMark(1)])
    }

    @Test
    func convertedTimes_mapsTimesAndSpans() {
        var table = PartMarkTable<BeatTime>()

        table.insert(time: 1, mark: quarterFermataMark(1))
        table.insert(time: 2, mark: .caesura(nil))

        let converted = table.convertedTimes { beatTime($0.numberValue * 2) }

        #expect(converted.map(\.time) == [2, 4])
        #expect(converted.map(\.mark) == [quarterFermataMark(2), .caesura(nil)])
    }

    @Test
    func convertedTimes_spanConvertsAtTheMark() {
        var table = PartMarkTable<BeatTime>()

        table.insert(time: 1, mark: quarterFermataMark(4))

        //
        // Squaring times: a whole note starting at 1 ends at 2, so it spans 4 − 1 = 3.
        //
        let converted = table.convertedTimes { beatTime($0.numberValue * $0.numberValue) }

        #expect(converted.map(\.mark) == [.fermata(Fermata(), span: positiveBeats(3))])
    }

    @Test
    func deduplicated_empty() {
        #expect(PartMarkTable<BeatTime>.deduplicated([]).isEmpty)
    }

    @Test
    func deduplicated_foldsOnlyNeighbors() {
        let first = StoredEntry(time: 1, mark: .caesura(nil))
        let duplicate = StoredEntry(time: 1, mark: .caesura(nil))
        let fermata = StoredEntry(time: 1, mark: quarterFermataMark(1))
        let again = StoredEntry(time: 1, mark: .caesura(nil))
        let result = PartMarkTable<BeatTime>.deduplicated([first, duplicate, fermata, again])

        #expect(result.map(\.entryID) == [first.entryID, fermata.entryID, again.entryID])
    }

    @Test
    func firstIndex_entryID_found() {
        var table = PartMarkTable<BeatTime>()

        table.insert(time: 1, mark: .caesura(nil))

        let (entryID, _) = table.insert(time: 2, mark: quarterFermataMark(1))

        #expect(table.firstIndex(entryID: entryID) == 1)
    }

    @Test
    func firstIndex_entryID_notFound() {
        let position = PartMarkTable<BeatTime>().firstIndex(entryID: EntryID())

        #expect(position == nil)
    }

    @Test
    func insertionIndex_afterEntriesAtTheSameTime() {
        var table = PartMarkTable<BeatTime>()

        table.insert(time: 1, mark: .caesura(nil))
        table.insert(time: 1, mark: quarterFermataMark(1))
        table.insert(time: 3, mark: .caesura(nil))

        #expect(table.insertionIndex(for: 1) == 2)
    }

    @Test
    func insertionIndex_empty() {
        #expect(PartMarkTable<BeatTime>().insertionIndex(for: 1) == 0)
    }

    @Test
    func insertionIndex_middle() {
        var table = PartMarkTable<BeatTime>()

        table.insert(time: 1, mark: .caesura(nil))
        table.insert(time: 3, mark: .caesura(nil))

        #expect(table.insertionIndex(for: 2) == 1)
    }
}

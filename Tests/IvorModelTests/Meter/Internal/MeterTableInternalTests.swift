// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct MeterTableInternalTests {
}

// MARK: -

extension MeterTableInternalTests {
    @Test
    func barOffset_beforeFirstEntry_isNil() throws {
        let table = try makeMeterTable([(1, "3/4")])

        #expect(table.barOffset(at: 0) == nil)
    }

    @Test
    func barOffset_freeBar_isZero() throws {
        let table = try makeMeterTable([(0, "free")])
        let barOffset = try #require(table.barOffset(at: 2))

        #expect(barOffset.meter == .free)
        #expect(barOffset.offset == .zero)
    }

    @Test
    func barOffset_inFullBar() throws {
        let table = try makeMeterTable([(0, "3/4")], pickup: frac(1, 4))
        let barOffset = try #require(table.barOffset(at: beatTime(frac(1, 2))))

        #expect(barOffset.offset == beats(frac(1, 4)))
    }

    @Test
    func barOffset_inPickup_countsAsTailOfBar() throws {
        let table = try makeMeterTable([(0, "3/4")], pickup: frac(1, 4))
        let barOffset = try #require(table.barOffset(at: 0))

        #expect(barOffset.meter == meter("3/4"))
        #expect(barOffset.offset == beats(frac(1, 2)))
    }

    @Test
    func barsWithEntryIndex() throws {
        let table = try makeMeterTable([(0, "4/4"), (1, "3/4")])
        let bars = table.barsWithEntryIndex(overlapping: 0..<2)

        #expect(bars.map(\.bar.number) == [1, 2, 3])
        #expect(bars.map(\.entryIndex) == [0, 1, 1])
    }

    @Test
    func barsWithEntryIndex_emptyRange_isEmpty() throws {
        let table = try makeMeterTable([(0, "4/4")])

        #expect(table.barsWithEntryIndex(overlapping: 1..<1).isEmpty)
    }

    @Test
    func barsWithEntryIndex_pickupBar_isEntryZero() throws {
        let table = try makeMeterTable([(0, "3/4")], pickup: frac(1, 4))
        let bars = table.barsWithEntryIndex(overlapping: 0..<1)

        #expect(bars.first?.bar.isPickup == true)
        #expect(bars.first?.entryIndex == 0)
    }

    @Test
    func entryIndex_at() throws {
        let table = try makeMeterTable([(0, "4/4"), (1, "3/4")])

        #expect(table.entryIndex(at: 1) == 1)
        #expect(table.entryIndex(at: beatTime(frac(1, 2))) == nil)
    }

    @Test
    func firstIndex_entryID() throws {
        let table = try makeMeterTable([(0, "4/4"), (1, "3/4")])
        let entryID = try #require(table.last).entryID
        let unknownIndex = table.firstIndex(entryID: EntryID())

        #expect(table.firstIndex(entryID: entryID) == 1)
        #expect(unknownIndex == nil)
    }

    @Test
    func governingIndex_at() throws {
        let table = try makeMeterTable([(1, "4/4"), (2, "3/4")])

        #expect(table.governingIndex(at: 0) == nil)
        #expect(table.governingIndex(at: beatTime(frac(3, 2))) == 0)
        #expect(table.governingIndex(at: 2) == 1)
        #expect(table.governingIndex(at: 9) == 1)
    }

    @Test
    func hasExtras_in() {
        let plain = MeterTable.StoredEntry(beatTime: 0,
                                           meter: meter("4/4"),
                                           extras: nil)
        let extended = MeterTable.StoredEntry(beatTime: 1,
                                              meter: meter("4/4"),
                                              extras: makeChannelExtras(1))

        #expect(!MeterTable.hasExtras(in: []))
        #expect(!MeterTable.hasExtras(in: [plain]))
        #expect(MeterTable.hasExtras(in: [plain, extended]))
    }

    @Test
    func insertionIndex_for() throws {
        let table = try makeMeterTable([(0, "4/4"), (1, "3/4")])

        #expect(table.insertionIndex(for: 0) == 1)
        #expect(table.insertionIndex(for: beatTime(frac(1, 2))) == 1)
        #expect(table.insertionIndex(for: 2) == 2)
    }

    @Test
    func isBarline() throws {
        let table = try makeMeterTable([(0, "4/4"), (frac(3, 4), "4/4")])

        #expect(table.isBarline(0))
        #expect(table.isBarline(beatTime(frac(3, 4))))
        #expect(table.isBarline(beatTime(frac(7, 4))))
        #expect(!table.isBarline(1))
    }

    @Test
    func isBarline_beforeFirstEntry_isFalse() throws {
        let table = try makeMeterTable([(1, "4/4")])

        #expect(!table.isBarline(0))
    }

    @Test
    func isBarline_pickup() throws {
        let table = try makeMeterTable([(0, "3/4")], pickup: frac(1, 4))

        #expect(!table.isBarline(beatTime(frac(1, 8))))
        #expect(table.isBarline(beatTime(frac(1, 4))))
    }

    @Test
    func isValid_pickup() throws {
        let threeFour = try makeMeterTable([(0, "3/4"), (frac(1, 4), "2/4")]).entries
        let late = try makeMeterTable([(1, "3/4")]).entries
        let free = try makeMeterTable([(0, "free")]).entries

        #expect(MeterTable.isValid(pickup: .zero, for: late))
        #expect(MeterTable.isValid(pickup: beats(frac(1, 4)), for: threeFour))
        #expect(!MeterTable.isValid(pickup: beats(frac(1, 2)), for: threeFour))
        #expect(!MeterTable.isValid(pickup: beats(frac(1, 4)), for: late))
        #expect(!MeterTable.isValid(pickup: beats(frac(1, 4)), for: free))
        #expect(!MeterTable.isValid(pickup: beats(frac(3, 4)), for: Array(threeFour.prefix(1))))
        #expect(!MeterTable.isValid(pickup: beats(frac(1, 4)), for: []))
    }

    @Test
    func nextBarline_after() throws {
        let table = try makeMeterTable([(0, "4/4")])

        #expect(table.nextBarline(after: beatTime(frac(1, 2))) == 1)
        #expect(table.nextBarline(after: 1) == 2)
    }

    @Test
    func nextBarline_after_beforeFirstEntry() throws {
        let table = try makeMeterTable([(1, "4/4")])

        #expect(table.nextBarline(after: 0) == 1)
    }

    @Test
    func nextBarline_after_inOpenFreeBar_isNil() throws {
        let table = try makeMeterTable([(0, "free")])

        #expect(table.nextBarline(after: 1) == nil)
    }

    @Test
    func nextBarline_after_inPickup() throws {
        let table = try makeMeterTable([(0, "3/4")], pickup: frac(1, 4))

        #expect(table.nextBarline(after: 0) == beatTime(frac(1, 4)))
    }

    @Test
    func normalizePickup_capsAtSecondEntry() throws {
        var table = try makeMeterTable([(0, "3/4"), (frac(1, 4), "2/4")])

        table.pickup = beats(frac(1, 2))
        table.normalizePickup()

        #expect(table.pickup == beats(frac(1, 4)))
    }

    @Test
    func normalizePickup_dropsPickupWithoutMeteredEntryAtZero() throws {
        var table = try makeMeterTable([(0, "free")])

        table.pickup = beats(frac(1, 4))
        table.normalizePickup()

        #expect(table.pickup == .zero)
    }

    @Test
    func normalizePickup_wrapsToBarLength() throws {
        var table = try makeMeterTable([(0, "3/4")])

        table.pickup = 1
        table.normalizePickup()

        #expect(table.pickup == beats(frac(1, 4)))
    }

    @Test
    func pickupMeter() throws {
        #expect(try makeMeterTable([(0, "3/4")], pickup: frac(1, 4)).pickupMeter == meter("3/4"))
        #expect(try makeMeterTable([(0, "3/4")]).pickupMeter == nil)
    }

    @Test
    func spans() throws {
        let table = try makeMeterTable([(0, "3/4"), (2, "free"), (3, "4/4")], pickup: frac(1, 4))
        let spans = table.spans()

        #expect(spans.map(\.barCount) == [3, 1, nil])
        #expect(spans.map(\.end) == [2, 3, nil])
        #expect(spans.map(\.entryIndex) == [0, 1, 2])
        #expect(spans.map(\.firstBarNumber) == [1, 4, 5])
        #expect(spans.map(\.meter) == [meter("3/4"), .free, meter("4/4")])
        #expect(spans.map(\.start) == [beatTime(frac(1, 4)), 2, 3])
    }

    @Test
    func spans_pickupEndingOnSecondEntry_hasNoBars() throws {
        let table = try makeMeterTable([(0, "3/4"), (frac(1, 4), "2/4")], pickup: frac(1, 4))

        #expect(table.spans().first?.barCount == 0)
    }
}

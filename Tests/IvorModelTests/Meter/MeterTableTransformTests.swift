// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct MeterTableTransformTests {
}

// MARK: -

extension MeterTableTransformTests {
    @Test
    func augment_anchorBeforeFirstEntry_insertsNothing() throws {
        var table = try makeMeterTable([(1, "3/4")])

        try table.augment(by: 2, anchor: 0)

        #expect(summary(of: table) == ["3/2@2"])
    }

    @Test
    func augment_anchorInsidePickup_shortensPickup() throws {
        var table = try makeMeterTable([(0, "3/4")], pickup: frac(1, 2))

        try table.augment(by: 2, anchor: beatTime(frac(1, 4)))

        #expect(summary(of: table) == ["3/4@0", "3/2@1/4"])
        #expect(table.pickup == beats(frac(1, 4)))
    }

    @Test
    func augment_anchorMidBar_splitsTheBar() throws {
        var table = try makeMeterTable([(0, "4/4")])

        try table.augment(by: 2, anchor: beatTime(frac(1, 2)))

        #expect(summary(of: table) == ["4/4@0", "4/2@1/2"])

        let entries = Array(table)

        #expect(table.shortBar(before: entries[1].entryID)?.actual == beats(frac(1, 2)))
        #expect(entries[1].extras == nil)
    }

    @Test
    func augment_anchorOnBarline_keepsEarlierEntries() throws {
        let original = try makeMeterTable([(0, "4/4"), (2, "3/4")])
        var table = original

        try table.augment(by: frac(3, 2), anchor: 1)

        #expect(summary(of: table) == ["4/4@0", "12/8@1", "9/8@5/2"])
        expectPositionsKept(from: original, to: table, factor: frac(3, 2), anchor: 1)
    }

    @Test
    func augment_anchorZero_scalesPickupAndKeepsPositions() throws {
        let original = try makeMeterTable([(0, "3/4"), (1, "2/4")], pickup: frac(1, 4))
        var table = original

        try table.augment(by: 2)

        #expect(summary(of: table) == ["3/2@0", "2/2@2"])
        #expect(table.pickup == beats(frac(1, 2)))
        expectPositionsKept(from: original, to: table, factor: 2, anchor: 0)
    }

    @Test
    func augment_keepsExtras() throws {
        var table = MeterTable()
        let extras = Extras(elements: [Extra(name: Extra.midiTimeSignature.name,
                                             values: [.int(36), .int(8)])])

        try table.insert(beatTime: 0, meter: meter("6/8"), extras: extras)
        try table.augment(by: 2)

        #expect(table.first?.extras == extras)
    }

    @Test
    func augmentAndDiminish_rejectInvalidFactors() throws {
        var table = try makeMeterTable([(0, "4/4")])

        #expect(throws: MeterTable.Error.invalidAugmentationFactor(frac(1, 2))) {
            try table.augment(by: frac(1, 2))
        }
        #expect(throws: MeterTable.Error.invalidDiminutionFactor(0)) {
            try table.diminish(by: 0)
        }

        try table.augment(by: 1)

        #expect(summary(of: table) == ["4/4@0"])
    }

    @Test
    func diminish_isAugmentByReciprocal() throws {
        let original = try makeMeterTable([(0, "6/8"), (frac(3, 2), "2/4")], pickup: frac(3, 8))
        var table = original

        try table.diminish(by: 2)

        #expect(summary(of: table) == ["6/16@0", "2/8@3/4"])
        #expect(table.pickup == beats(frac(3, 16)))
        expectPositionsKept(from: original, to: table, factor: frac(1, 2), anchor: 0)
    }

    @Test
    func moveEarlier_capsPickupAtNextEntry() throws {
        var table = try makeMeterTable([(0, "4/4"), (2, "3/4"), (frac(5, 2), "2/4")])

        table.move(by: earlier(frac(9, 4)))

        #expect(summary(of: table) == ["3/4@0", "2/4@1/4"])
        #expect(table.pickup == beats(frac(1, 4)))
    }

    @Test
    func moveEarlier_entryLandingOnZeroWins() throws {
        let extras = Extras(elements: [Extra(name: Extra.meterSymbol.name, values: [.string("common")])])
        var table = MeterTable()

        try table.insert(beatTime: 0, meter: meter("4/4"), extras: extras)
        try table.insert(beatTime: 2, meter: meter("3/4"))

        table.move(by: earlier(2))

        #expect(summary(of: table) == ["3/4@0"])
        #expect(table.pickup == .zero)
        #expect(!table.hasExtras)
    }

    @Test
    func moveEarlier_keepsLastEntryLandingBeforeZero() throws {
        let original = try makeMeterTable([(0, "4/4"), (2, "3/4"), (4, "2/4")])
        var table = original

        table.move(by: earlier(frac(9, 4)))

        // 3/4 from 2 moves to -1/4, so its next barline lands at 1/2.
        #expect(summary(of: table) == ["3/4@0", "2/4@7/4"])
        #expect(table.pickup == beats(frac(1, 2)))
        expectBeatsKept(from: original, to: table, by: beats(frac(9, 4)), earlier: true)
    }

    @Test
    func moveEarlier_nothingBeforeZero_shiftsEverything() throws {
        var table = try makeMeterTable([(1, "3/4"), (2, "free")])

        table.move(by: earlier(frac(1, 2)))

        #expect(summary(of: table) == ["3/4@1/2", "free@3/2"])
        #expect(table.pickup == .zero)
    }

    @Test
    func moveEarlier_shortensExistingPickup() throws {
        var table = try makeMeterTable([(0, "3/4")], pickup: frac(1, 2))

        table.move(by: earlier(frac(1, 4)))

        #expect(summary(of: table) == ["3/4@0"])
        #expect(table.pickup == beats(frac(1, 4)))
    }

    @Test
    func moveLater_freeMeterKeepsNoPickup() throws {
        var table = try makeMeterTable([(0, "free"), (1, "4/4")])

        table.move(by: later(frac(1, 4)))

        #expect(summary(of: table) == ["free@0", "4/4@5/4"])
        #expect(table.pickup == .zero)
    }

    @Test
    func moveLater_keepsEntryAtZeroAndGrowsPickup() throws {
        let original = try makeMeterTable([(0, "3/4"), (frac(3, 2), "2/4")])
        var table = original

        table.move(by: later(frac(1, 4)))

        #expect(summary(of: table) == ["3/4@0", "2/4@7/4"])
        #expect(table.pickup == beats(frac(1, 4)))
        expectBeatsKept(from: original, to: table, by: beats(frac(1, 4)))
    }

    @Test
    func moveLater_withoutEntryAtZero_shiftsEverything() throws {
        var table = try makeMeterTable([(1, "4/4"), (2, "3/4")])

        table.move(by: later(frac(1, 2)))

        #expect(summary(of: table) == ["4/4@3/2", "3/4@5/2"])
    }

    @Test
    func moveLater_wrapsPickupToBarLength() throws {
        let original = try makeMeterTable([(0, "3/4")], pickup: frac(1, 2))
        var table = original

        table.move(by: later(frac(1, 4)))

        #expect(table.pickup == .zero)
        expectBeatsKept(from: original, to: table, by: beats(frac(1, 4)))
    }

    @Test
    func reverse_endingOnBarline_restatesMeterAfter() throws {
        let original = try makeMeterTable([(0, "3/4"), (frac(3, 4), "2/4")])
        var table = original

        table.reverse(within: 0...beatTime(frac(5, 4)))

        #expect(summary(of: table) == ["2/4@0", "3/4@1/2", "2/4@5/4"])
        #expect(table.pickup == .zero)
        expectSameBarlines(original, table, from: beatTime(frac(5, 4)), to: 4)
    }

    @Test
    func reverse_keepsExtrasOfGoverningEntry() throws {
        let extras = Extras(elements: [Extra(name: Extra.meterSymbol.name, values: [.string("cut")])])
        var table = MeterTable()

        try table.insert(beatTime: 0, meter: meter("2/2"), extras: extras)
        try table.insert(beatTime: 1, meter: meter("3/4"))

        table.reverse(within: 0...beatTime(frac(7, 4)))

        #expect(summary(of: table) == ["3/4@0", "2/2@3/4", "3/4@7/4"])
        #expect(Array(table)[1].extras == extras)
    }

    @Test
    func reverse_midWorkRange_keepsGridAfterRange() throws {
        let original = try makeMeterTable([(0, "3/4"), (frac(3, 2), "2/4")])
        var table = original

        table.reverse(within: beatTime(frac(3, 4))...beatTime(frac(7, 4)))

        #expect(summary(of: table) == ["3/4@0", "2/4@3/4", "3/4@1", "2/4@7/4", "2/4@2"])
        expectSameBarlines(original, table, from: 2, to: 4)
        expectSameBarlines(original, table, from: 0, to: beatTime(frac(3, 4)))
    }

    @Test
    func reverse_rangeBeforeFirstEntry_doesNothing() throws {
        let original = try makeMeterTable([(2, "3/4")])
        var table = original

        table.reverse(within: 0...2)

        #expect(table == original)
    }

    @Test
    func reverse_skipsRedundantEntries() throws {
        var table = try makeMeterTable([(0, "4/4"), (3, "3/4")])

        table.reverse(within: 0...3)

        #expect(summary(of: table) == ["4/4@0", "3/4@3"])
    }

    @Test
    func reverse_wholeTable_leftoverBecomesPickup() throws {
        let original = try makeMeterTable([(0, "3/4"), (frac(3, 4), "2/4")])
        var table = original

        table.reverse(within: 0...1)

        #expect(summary(of: table) == ["2/4@0", "3/4@1/4", "2/4@1", "2/4@5/4"])
        #expect(table.pickup == beats(frac(1, 4)))
        expectSameBarlines(original, table, from: beatTime(frac(5, 4)), to: 4)
    }

    @Test
    func reverse_withFreeBar() throws {
        let original = try makeMeterTable([(0, "free"), (2, "4/4")])
        var table = original

        table.reverse(within: 0...3)

        #expect(summary(of: table) == ["4/4@0", "free@1", "4/4@3"])
        expectSameBarlines(original, table, from: 3, to: 6)
    }
}

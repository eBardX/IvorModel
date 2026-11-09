// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct PedalTableThinTests {
    private let half = Pedal.Level(Number(numerator: 1, denominator: 2))
    private let level30 = Pedal.Level(Number(numerator: 30, denominator: 100))
    private let level32 = Pedal.Level(Number(numerator: 32, denominator: 100))
    private let level40 = Pedal.Level(Number(numerator: 40, denominator: 100))
    private let level45 = Pedal.Level(Number(numerator: 45, denominator: 100))
    private let level55 = Pedal.Level(Number(numerator: 55, denominator: 100))
    private let level60 = Pedal.Level(Number(numerator: 60, denominator: 100))
    private let tolerance = Pedal.Level(Number(numerator: 5, denominator: 100))
}

// MARK: -

extension PedalTableThinTests {
    private typealias PedalTableSB = PedalTable<BeatTime>

    @Test
    func thin_emptyTableIsNoOp() {
        var table = PedalTableSB()

        #expect(table.thin(.snap).isEmpty)
        #expect(table.thin(.merge(tolerance: tolerance)).isEmpty)
        #expect(table.isEmpty)
    }

    @Test
    func thin_entryWithExtrasIsKeptAndSnapped() {
        var table = PedalTableSB()
        let extras = Extras(elements: [Extra(name: "tag")])

        table.insert(time: 0, level: .on)
        table.insert(time: 1, level: level60, extras: extras)

        let removed = table.thin(.snap)

        #expect(removed.isEmpty)
        #expect(table.map(\.level) == [.on, .on])
        #expect(table.hasExtras)
    }

    @Test
    func thin_extrasEntryAheadKeepsLastEntryAtItsTime() {
        //
        // Off is already in effect, so the final Off at 1 would be dropped as a repeat; but the
        // half level with extras ahead of it is kept, so Off must stay to keep the level Off.
        //
        var table = PedalTableSB()
        let extras = Extras(elements: [Extra(name: "tag")])

        table.insert(time: 1, level: level30, extras: extras)
        table.insert(time: 1, level: .off)

        let removed = table.thin(.merge(tolerance: tolerance))

        #expect(removed.isEmpty)
        #expect(table[BeatTime(1)] == .off)
    }

    @Test
    func thin_mergeDropsSmallChanges() {
        var table = PedalTableSB()

        table.insert(time: 0, level: level30)

        let smallID = table.insert(time: 1, level: level32).entryID

        table.insert(time: 2, level: level40)

        let removed = table.thin(.merge(tolerance: tolerance))

        #expect(removed == [smallID])
        #expect(table.map(\.time) == [0, 2])
        #expect(table.map(\.level) == [level30, level40])
    }

    @Test
    func thin_mergeKeepsExactOffAndOn() {
        //
        // With a tolerance larger than any step, only the exact-level and threshold rules keep
        // anything: 0.55 crosses the threshold, On and Off are exact, and 0.60 after On is
        // dropped.
        //
        var table = PedalTableSB()

        table.insert(time: 0, level: level55)
        table.insert(time: 1, level: .on)
        table.insert(time: 2, level: level60)
        table.insert(time: 3, level: .off)

        table.thin(.merge(tolerance: .on))

        #expect(table.map(\.level) == [level55, .on, .off])
    }

    @Test
    func thin_mergeKeepsThresholdCrossing() {
        var table = PedalTableSB()

        table.insert(time: 0, level: level45)
        table.insert(time: 1, level: half)

        table.thin(.merge(tolerance: tolerance))

        #expect(table.map(\.level) == [level45, half])
    }

    @Test
    func thin_removesRepeatedLevel() {
        var table = PedalTableSB()

        table.insert(time: 0, level: .on)

        let repeatID = table.insert(time: 2, level: .on).entryID

        table.insert(time: 4, level: .off)

        #expect(table.thin(.merge(tolerance: tolerance)) == [repeatID])
        #expect(table.map(\.time) == [0, 4])
    }

    @Test
    func thin_removesSupersededSameTimeEntries() {
        var table = PedalTableSB()

        let halfID = table.insert(time: 1, level: half).entryID

        table.insert(time: 1, level: .on)

        #expect(table.thin(.merge(tolerance: tolerance)) == [halfID])
        #expect(table.map(\.level) == [.on])
    }

    @Test
    func thin_repedalSurvivesMerge() {
        var table = PedalTableSB()

        table.insert(time: 0, level: .on)
        table.insert(time: 2, level: level30)
        table.insert(time: 2, level: .on)

        #expect(table.thin(.merge(tolerance: .on)).isEmpty)
        #expect(table.map(\.level) == [.on, level30, .on])
    }

    @Test
    func thin_repedalSurvivesSnap() {
        var table = PedalTableSB()

        table.insert(time: 0, level: .on)
        table.insert(time: 2, level: level30)
        table.insert(time: 2, level: .on)
        table.insert(time: 4, level: .off)

        #expect(table.thin(.snap).isEmpty)
        #expect(table.map(\.time) == [0, 2, 2, 4])
        #expect(table.map(\.level) == [.on, .off, .on, .off])
    }

    @Test
    func thin_returnsRemovedIDsInTableOrder() {
        var table = PedalTableSB()

        table.insert(time: 0, level: .on)

        let id1 = table.insert(time: 1, level: level60).entryID
        let id2 = table.insert(time: 2, level: level55).entryID

        table.insert(time: 3, level: .off)

        #expect(table.thin(.snap) == [id1, id2])
    }

    @Test
    func thin_snapMakesSwitch() {
        var table = PedalTableSB()

        table.insert(time: 0, level: level60)
        table.insert(time: 1, level: level30)
        table.insert(time: 2, level: level45)
        table.insert(time: 3, level: half)

        let removed = table.thin(.snap)

        #expect(removed.count == 1)
        #expect(table.map(\.time) == [0, 1, 3])
        #expect(table.map(\.level) == [.on, .off, .on])
    }
}

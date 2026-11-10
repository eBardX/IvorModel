// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct PedalTableSimplifyTests {
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

extension PedalTableSimplifyTests {
    private typealias PedalTableSB = PedalTable<BeatTime>

    @Test
    func simplify_emptyTableIsNoOp() {
        var table = PedalTableSB()

        #expect(table.simplify(.snap).isEmpty)
        #expect(table.simplify(.merge(tolerance: tolerance)).isEmpty)
        #expect(table.isEmpty)
    }

    @Test
    func simplify_entryWithExtrasIsKeptAndSnapped() {
        var table = PedalTableSB()
        let extras = Extras(elements: [Extra(name: "tag")])

        table.insert(time: 0, level: .down)
        table.insert(time: 1, level: level60, extras: extras)

        let removed = table.simplify(.snap)

        #expect(removed.isEmpty)
        #expect(table.map(\.level) == [.down, .down])
        #expect(table.hasExtras)
    }

    @Test
    func simplify_extrasEntryAheadKeepsLastEntryAtItsTime() {
        //
        // Up is already in effect, so the final Up at 1 would be dropped as a repeat; but the
        // half level with extras ahead of it is kept, so Up must stay to keep the level Up.
        //
        var table = PedalTableSB()
        let extras = Extras(elements: [Extra(name: "tag")])

        table.insert(time: 1, level: level30, extras: extras)
        table.insert(time: 1, level: .up)

        let removed = table.simplify(.merge(tolerance: tolerance))

        #expect(removed.isEmpty)
        #expect(table[BeatTime(1)] == .up)
    }

    @Test
    func simplify_mergeDropsSmallChanges() {
        var table = PedalTableSB()

        table.insert(time: 0, level: level30)

        let smallID = table.insert(time: 1, level: level32).entryID

        table.insert(time: 2, level: level40)

        let removed = table.simplify(.merge(tolerance: tolerance))

        #expect(removed == [smallID])
        #expect(table.map(\.time) == [0, 2])
        #expect(table.map(\.level) == [level30, level40])
    }

    @Test
    func simplify_mergeKeepsExactUpAndDown() {
        //
        // With a tolerance larger than any step, only the exact-level and threshold rules keep
        // anything: 0.55 crosses the threshold, Down and Up are exact, and 0.60 after Down is
        // dropped.
        //
        var table = PedalTableSB()

        table.insert(time: 0, level: level55)
        table.insert(time: 1, level: .down)
        table.insert(time: 2, level: level60)
        table.insert(time: 3, level: .up)

        table.simplify(.merge(tolerance: .down))

        #expect(table.map(\.level) == [level55, .down, .up])
    }

    @Test
    func simplify_mergeKeepsThresholdCrossing() {
        var table = PedalTableSB()

        table.insert(time: 0, level: level45)
        table.insert(time: 1, level: half)

        table.simplify(.merge(tolerance: tolerance))

        #expect(table.map(\.level) == [level45, half])
    }

    @Test
    func simplify_removesRepeatedLevel() {
        var table = PedalTableSB()

        table.insert(time: 0, level: .down)

        let repeatID = table.insert(time: 2, level: .down).entryID

        table.insert(time: 4, level: .up)

        #expect(table.simplify(.merge(tolerance: tolerance)) == [repeatID])
        #expect(table.map(\.time) == [0, 4])
    }

    @Test
    func simplify_removesSupersededSameTimeEntries() {
        var table = PedalTableSB()

        let halfID = table.insert(time: 1, level: half).entryID

        table.insert(time: 1, level: .down)

        #expect(table.simplify(.merge(tolerance: tolerance)) == [halfID])
        #expect(table.map(\.level) == [.down])
    }

    @Test
    func simplify_repedalSurvivesMerge() {
        var table = PedalTableSB()

        table.insert(time: 0, level: .down)
        table.insert(time: 2, level: level30)
        table.insert(time: 2, level: .down)

        #expect(table.simplify(.merge(tolerance: .down)).isEmpty)
        #expect(table.map(\.level) == [.down, level30, .down])
    }

    @Test
    func simplify_repedalSurvivesSnap() {
        var table = PedalTableSB()

        table.insert(time: 0, level: .down)
        table.insert(time: 2, level: level30)
        table.insert(time: 2, level: .down)
        table.insert(time: 4, level: .up)

        #expect(table.simplify(.snap).isEmpty)
        #expect(table.map(\.time) == [0, 2, 2, 4])
        #expect(table.map(\.level) == [.down, .up, .down, .up])
    }

    @Test
    func simplify_returnsRemovedIDsInTableOrder() {
        var table = PedalTableSB()

        table.insert(time: 0, level: .down)

        let id1 = table.insert(time: 1, level: level60).entryID
        let id2 = table.insert(time: 2, level: level55).entryID

        table.insert(time: 3, level: .up)

        #expect(table.simplify(.snap) == [id1, id2])
    }

    @Test
    func simplify_snapMakesSwitch() {
        var table = PedalTableSB()

        table.insert(time: 0, level: level60)
        table.insert(time: 1, level: level30)
        table.insert(time: 2, level: level45)
        table.insert(time: 3, level: half)

        let removed = table.simplify(.snap)

        #expect(removed.count == 1)
        #expect(table.map(\.time) == [0, 1, 3])
        #expect(table.map(\.level) == [.down, .up, .down])
    }
}

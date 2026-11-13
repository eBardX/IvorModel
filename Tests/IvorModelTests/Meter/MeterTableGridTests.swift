// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct MeterTableGridTests {
}

// MARK: -

extension MeterTableGridTests {
    @Test
    func bars_acrossPickupShortBarAndOpenEndedFreeBar() throws {
        let table = try makeMeterTable([(0, "3/4"), (frac(3, 4), "3/4"), (2, "free")], pickup: frac(1, 4))
        let bars = table.bars(overlapping: 0..<3)

        #expect(bars.map(\.number) == [0, 1, 2, 3, 4])
        #expect(bars.map(\.range) == [0..<beatTime(frac(1, 4)),
                                      beatTime(frac(1, 4))..<beatTime(frac(3, 4)),
                                      beatTime(frac(3, 4))..<beatTime(frac(3, 2)),
                                      beatTime(frac(3, 2))..<2,
                                      2..<3])
        #expect(bars.map(\.isPickup) == [true, false, false, false, false])
        #expect(bars.map(\.isShort) == [false, true, false, true, false])
        #expect(bars.map(\.meter) == [meter("3/4"), meter("3/4"), meter("3/4"), meter("3/4"), .free])
        #expect(bars[0].beatStarts == [0])
        #expect(bars[1].beatStarts == [beatTime(frac(1, 4)), beatTime(frac(1, 2))])
        #expect(bars[2].beatStarts == [beatTime(frac(3, 4)), 1, beatTime(frac(5, 4))])
        #expect(bars[4].beatStarts.isEmpty)
    }

    @Test
    func bars_emptyRangeOrBeforeFirstEntry() throws {
        let table = try makeMeterTable([(1, "4/4")])

        #expect(table.bars(overlapping: 2..<2).isEmpty)
        #expect(table.bars(overlapping: 0..<1).isEmpty)
        #expect(table.bars(overlapping: 0..<2).map(\.number) == [1])
        #expect(MeterTable().bars(overlapping: 0..<10).isEmpty)
    }

    @Test
    func bars_freeBarEndsAtNextEntry() throws {
        let table = try makeMeterTable([(0, "free"), (frac(5, 2), "4/4")])
        let bars = table.bars(overlapping: 0..<4)

        #expect(bars.map(\.range) == [0..<beatTime(frac(5, 2)),
                                      beatTime(frac(5, 2))..<beatTime(frac(7, 2)),
                                      beatTime(frac(7, 2))..<beatTime(frac(9, 2))])
    }

    @Test
    func bars_returnsWholeBarsOverlappingTheRange() throws {
        let table = try makeMeterTable([(0, "4/4")])
        let bars = table.bars(overlapping: beatTime(frac(1, 2))..<beatTime(frac(5, 4)))

        #expect(bars.map(\.range) == [0..<1, 1..<2])
    }

    @Test
    func beatTime_rejectsPositionsOutsideTheGrid() throws {
        let pickup = try makeMeterTable([(0, "3/4")], pickup: frac(1, 4))
        let restart = try makeMeterTable([(0, "4/4"), (frac(3, 4), "4/4")])
        let free = try makeMeterTable([(0, "free"), (frac(5, 2), "4/4")])
        let late = try makeMeterTable([(1, "3/4")])

        // Only the tail beats exist in the pickup bar.
        #expect(pickup.beatTime(bar: 0, beat: 1, offset: .zero) == nil)
        #expect(pickup.beatTime(bar: 0, beat: 3, offset: .zero) == 0)
        #expect(pickup.beatTime(bar: 0, beat: 4, offset: .zero) == nil)

        // No pickup bar without a pickup; no bar before 0.
        #expect(restart.beatTime(bar: 0, beat: 1, offset: .zero) == nil)
        #expect(restart.beatTime(bar: -1, beat: 1, offset: .zero) == nil)

        // The offset must be shorter than the beat.
        #expect(restart.beatTime(bar: 1, beat: 1, offset: beats(frac(1, 4))) == nil)

        // A short bar's last beat is gone.
        #expect(restart.beatTime(bar: 1, beat: 3, offset: .zero) == beatTime(frac(1, 2)))
        #expect(restart.beatTime(bar: 1, beat: 4, offset: .zero) == nil)

        // `beat` is nil exactly in a free bar.
        #expect(free.beatTime(bar: 1, beat: nil, offset: 2) == 2)
        #expect(free.beatTime(bar: 1, beat: nil, offset: beats(frac(5, 2))) == nil)
        #expect(free.beatTime(bar: 1, beat: 1, offset: .zero) == nil)
        #expect(free.beatTime(bar: 2, beat: nil, offset: .zero) == nil)

        // Nothing before the first entry.
        #expect(late.beatTime(bar: 0, beat: 1, offset: .zero) == nil)
        #expect(late.beatTime(bar: 1, beat: 1, offset: .zero) == 1)
    }

    @Test
    func beatTimePlus_rejectsOffsetsOutsideTheBar() throws {
        let table = try makeMeterTable([(0, "4/4"), (frac(3, 4), "4/4")], pickup: 0)
        let pickup = try makeMeterTable([(0, "3/4")], pickup: frac(1, 4))

        #expect(table.beatTime(bar: 1, plus: beats(frac(1, 2))) == beatTime(frac(1, 2)))
        #expect(table.beatTime(bar: 1, plus: beats(frac(3, 4))) == nil)
        #expect(table.beatTime(bar: 2, plus: beats(frac(3, 4))) == beatTime(frac(3, 2)))
        #expect(table.beatTime(bar: 0, plus: .zero) == nil)
        #expect(pickup.beatTime(bar: 0, plus: beats(frac(1, 8))) == beatTime(frac(1, 8)))
        #expect(pickup.beatTime(bar: 0, plus: beats(frac(1, 4))) == nil)
    }

    @Test
    func isRestart_versusRedundant() throws {
        let restart = try makeMeterTable([(0, "4/4"), (frac(3, 4), "4/4")])
        let redundant = try makeMeterTable([(0, "4/4"), (2, "4/4")])
        let change = try makeMeterTable([(0, "4/4"), (frac(3, 4), "3/4")])
        let afterPickup = try makeMeterTable([(0, "3/4"), (1, "3/4")], pickup: frac(1, 4))

        #expect(try restart.isRestart(entryID: lastID(of: restart)))
        #expect(try !restart.isRestart(entryID: firstID(of: restart)))
        #expect(try !redundant.isRestart(entryID: lastID(of: redundant)))
        #expect(try !change.isRestart(entryID: lastID(of: change)))
        #expect(try !afterPickup.isRestart(entryID: lastID(of: afterPickup)))
        #expect(!restart.isRestart(entryID: EntryID()))
    }

    @Test
    func meter_isNilBeforeFirstEntry() throws {
        let table = try makeMeterTable([(1, "3/4"), (2, "free")])

        #expect(table.meter(at: beatTime(frac(1, 2))) == nil)
        #expect(table.meter(at: 1) == meter("3/4"))
        #expect(table.meter(at: 5) == .free)
        #expect(MeterTable().meter(at: 0) == nil)
        #expect(MeterTable().position(at: 0) == nil)
    }

    @Test(arguments: Fixtures.gridCases)
    func position(_ testCase: GridCase) throws {
        let table = try makeMeterTable(testCase.entries, pickup: testCase.pickup)
        let position = table.position(at: beatTime(testCase.time))

        guard let expected = testCase.expected
        else { #expect(position == nil); return }

        let actual = try #require(position)

        #expect(actual.bar == expected.bar)
        #expect(actual.beat == expected.beat)
        #expect(actual.offset == beats(expected.offset))
        #expect(actual.beatLength == expected.beatLength.map(beats))
    }

    @Test(arguments: Fixtures.gridTables)
    func position_andBeatTime_roundTrip(_ gridTable: GridTable) throws {
        let table = try makeMeterTable(gridTable.entries, pickup: gridTable.pickup)
        let step = beats(frac(1, 144))
        let first = try #require(table.first).beatTime

        for tick in 0..<720 {
            let time = beatTime(frac(tick, 144))

            guard let position = table.position(at: time)
            else { #expect(time < first); continue }

            #expect(table.beatTime(bar: position.bar,
                                   beat: position.beat,
                                   offset: position.offset) == time)

            let bar = try #require(table.bars(overlapping: time..<(time + step)).first)

            #expect(bar.number == position.bar)
            #expect(bar.range.contains(time))
            #expect(table.beatTime(bar: bar.number,
                                   plus: time - bar.range.lowerBound) == time)
            #expect(bar.beatStarts.contains(time) == (position.beat != nil && position.offset.isZero))
        }
    }

    @Test
    func position_inexactEntryTime() throws {
        let table = try makeMeterTable([(0, "4/4"), (Number(1.5), "3/4")])

        #expect(table.position(at: beatTime(frac(5, 4)))?.bar == 2)
        #expect(table.position(at: beatTime(Number(1.5)))?.bar == 3)
        #expect(table.bars(overlapping: beatTime(0)..<beatTime(2)).map(\.number) == [1, 2, 3])
    }

    @Test
    func position_inexactTime() throws {
        let table = try makeMeterTable([(0, "4/4")])
        let position = try #require(table.position(at: beatTime(Number(1.6))))

        #expect(position.bar == 2)
        #expect(position.beat == 3)
        #expect(abs(position.offset.numberValue.doubleValue - 0.1) < 1e-9)
    }

    @Test
    func position_partialPickupBeat() throws {
        // A pickup of an eighth in 3/4 is the second half of beat 3.
        let table = try makeMeterTable([(0, "3/4")], pickup: frac(1, 8))
        let position = try #require(table.position(at: 0))

        #expect(position.bar == 0)
        #expect(position.beat == 3)
        #expect(position.offset == beats(frac(1, 8)))
    }

    @Test
    func position_pickupEndingOnSecondEntry() throws {
        let table = try makeMeterTable([(0, "3/4"), (frac(1, 4), "2/4")], pickup: frac(1, 4))

        #expect(table.position(at: 0)?.bar == 0)
        #expect(table.position(at: 0)?.beat == 3)
        #expect(table.position(at: beatTime(frac(1, 4)))?.bar == 1)
        #expect(table.position(at: beatTime(frac(1, 4)))?.beatLength == beats(frac(1, 4)))
        #expect(table.position(at: beatTime(frac(3, 4)))?.bar == 2)
    }

    @Test
    func shortBar_reportsActualAndFullLength() throws {
        let restart = try makeMeterTable([(0, "4/4"), (frac(3, 4), "4/4")])
        let change = try makeMeterTable([(0, "3/4"), (frac(3, 2), "2/4")])
        let free = try makeMeterTable([(0, "free"), (1, "4/4")])
        let afterPickup = try makeMeterTable([(0, "3/4"), (1, "2/4")], pickup: frac(1, 4))
        let short = try #require(try restart.shortBar(before: lastID(of: restart)))

        #expect(short.actual == beats(frac(3, 4)))
        #expect(short.full == 1)
        #expect(try change.shortBar(before: lastID(of: change)) == nil)
        #expect(try free.shortBar(before: lastID(of: free)) == nil)
        #expect(try afterPickup.shortBar(before: lastID(of: afterPickup)) == nil)
        #expect(try restart.shortBar(before: firstID(of: restart)) == nil)
    }
}

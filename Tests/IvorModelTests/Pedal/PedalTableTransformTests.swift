// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct PedalTableTransformTests {
    private let half = Pedal.Level(Number(numerator: 1, denominator: 2))
}

// MARK: -

extension PedalTableTransformTests {
    private typealias PedalTableSB = PedalTable<BeatTime>

    @Test
    func augment_entryIDsRestrictsAffectedEntries() throws {
        var table = PedalTableSB()

        let entryID1 = table.insert(time: 0, level: .down).entryID

        table.insert(time: 4, level: .up)

        try table.augment(by: Number(2), entryIDs: [entryID1])

        #expect(table.map(\.time) == [0, 4])
    }

    @Test
    func augment_invalidAnchorThrows() {
        var table = PedalTableSB()

        table.insert(time: 2, level: .down)

        #expect(throws: PedalTableSB.Error.invalidAnchor) {
            try table.augment(by: Number(2), anchor: 3)
        }
    }

    @Test
    func augment_invalidFactor() {
        var table = PedalTableSB()

        #expect(throws: PedalTableSB.Error.self) {
            try table.augment(by: Number(0))
        }
    }

    @Test
    func augment_keepsRepedal() throws {
        var table = makeRepedaledPedalTable()

        try table.augment(by: Number(2))

        #expect(table.map(\.time) == [1, 5, 5, 9])
        #expect(table.map(\.level) == [.down, .up, .down, .up])
    }

    @Test
    func augment_nilAnchorWithEntryIDsUsesSelectedRange() throws {
        var table = PedalTableSB()

        table.insert(time: 0, level: .down)

        let entryID10 = table.insert(time: 10, level: .up).entryID
        let entryID14 = table.insert(time: 14, level: .down).entryID

        try table.augment(by: Number(2), entryIDs: [entryID10, entryID14])

        //
        // Anchored to the selected entries' own low bound (10), not the whole table's (0), so
        // the selected entry at 10 stays put while the one at 14 stretches relative to it:
        //
        #expect(table.map(\.time) == [0, 10, 18])
    }

    @Test
    func augment_scalesTimes() throws {
        var table = PedalTableSB()

        table.insert(time: 1, level: .down)
        table.insert(time: 3, level: .up)

        try table.augment(by: Number(2))

        #expect(table.map(\.time) == [1, 5])
    }

    @Test
    func augment_validAnchorDoesNotThrow() throws {
        var table = PedalTableSB()

        table.insert(time: 2, level: .down)

        try table.augment(by: Number(2), anchor: 2)

        #expect(table.map(\.time) == [2])
    }

    @Test
    func diminish_invalidFactor() {
        var table = PedalTableSB()

        #expect(throws: PedalTableSB.Error.self) {
            try table.diminish(by: Number(0))
        }
    }

    @Test
    func diminish_keepsRepedal() throws {
        var table = makeRepedaledPedalTable()

        try table.diminish(by: Number(2))

        #expect(table.map(\.time) == [1, 2, 2, 3])
        #expect(table.map(\.level) == [.down, .up, .down, .up])
    }

    @Test
    func diminish_scalesTimes() throws {
        var table = PedalTableSB()

        table.insert(time: 2, level: .down)
        table.insert(time: 6, level: .up)

        try table.diminish(by: Number(2))

        #expect(table.map(\.time) == [2, 4])
    }

    @Test
    func move_entryIDsRestrictsAffectedEntries() throws {
        var table = PedalTableSB()

        let entryID1 = table.insert(time: 0, level: .down).entryID

        table.insert(time: 4, level: .up)

        let directedDuration = try #require(BeatTime(0).duration(to: 2))

        try table.move(by: directedDuration, entryIDs: [entryID1])

        #expect(table.map(\.time) == [2, 4])
    }

    @Test
    func move_keepsRepedal() throws {
        var table = makeRepedaledPedalTable()

        let directedDuration = try #require(BeatTime(0).duration(to: 2))

        try table.move(by: directedDuration)

        #expect(table.map(\.time) == [3, 5, 5, 7])
        #expect(table.map(\.level) == [.down, .up, .down, .up])
    }

    @Test
    func move_shiftsTimes() throws {
        var table = PedalTableSB()

        table.insert(time: 0, level: .down)

        let directedDuration = try #require(BeatTime(0).duration(to: 2))

        try table.move(by: directedDuration)

        #expect(table.map(\.time) == [2])
    }

    @Test
    func quantize_entryIDsRestrictsAffectedEntries() throws {
        var table = PedalTableSB()

        let entryID1 = table.insert(time: 0.49, level: .down).entryID
        let entryID2 = table.insert(time: 4.49, level: .up).entryID

        let quantizer = try BeatQuantizer(factors: [1])

        table.quantize(using: quantizer, entryIDs: [entryID1])

        var timesByID: [EntryID: BeatTime] = [:]

        for entry in table {
            timesByID[entry.entryID] = entry.time
        }

        #expect(timesByID[entryID1] == 0)
        #expect(timesByID[entryID2] == BeatTime(4.49))
    }

    @Test
    func quantize_keepsRepedal() throws {
        var table = PedalTableSB()

        table.insert(time: 0.9, level: .down)
        table.insert(time: 3.1, level: .up)
        table.insert(time: 3.1, level: .down)
        table.insert(time: 4.9, level: .up)

        try table.quantize(using: BeatQuantizer(factors: [1]))

        #expect(table.map(\.time) == [1, 3, 3, 5])
        #expect(table.map(\.level) == [.down, .up, .down, .up])
    }

    @Test
    func quantize_snapsTimesToGrid() throws {
        var table = PedalTableSB()

        table.insert(time: 0.49, level: .down)
        table.insert(time: 3.6, level: .up)

        try table.quantize(using: BeatQuantizer(factors: [1]))

        #expect(table.map(\.time) == [0, 4])
    }

    @Test
    func reverse_entryIDsSelectionIsSelfContained() throws {
        var table = PedalTableSB()

        table.insert(time: 0, level: .down)

        let phraseID1 = table.insert(time: 10, level: .up).entryID
        let phraseID2 = table.insert(time: 12, level: half).entryID

        table.insert(time: 20, level: .down)

        try table.reverse(entryIDs: [phraseID1, phraseID2])

        //
        // Mirrored around its own bounds (10...12), not the whole table's (0...20). Up holds
        // for all of 10...12, so it starts there; the half level's stretch ends where the range
        // does, so it has no length and mirrors to 10 as well, ahead of Up:
        //
        #expect(table.map(\.time) == [0, 10, 10, 20])
        #expect(table[BeatTime(10)] == .up)
    }

    @Test
    func reverse_invalidAnchorThrows() {
        var table = PedalTableSB()

        table.insert(time: 0, level: .down)
        table.insert(time: 2, level: .up)

        #expect(throws: PedalTableSB.Error.invalidAnchor) {
            try table.reverse(within: BeatTime(1)...3)
        }
    }

    @Test
    func reverse_keepsRepedalUpThenDown() throws {
        //
        // Down at 0, re-pedaled at 3, up at 8, reversed within 0…8. The press from 3 to 8 now
        // runs 0 to 5, and the one from 0 to 3 runs 5 to 8, so the re-pedal lands at 5, still
        // Up then Down:
        //
        var table = PedalTableSB()

        table.insert(time: 0, level: .down)
        table.insert(time: 3, level: .up)
        table.insert(time: 3, level: .down)
        table.insert(time: 8, level: .up)

        try table.reverse(within: BeatTime(0)...8)

        #expect(table.map(\.time) == [0, 0, 5, 5])
        #expect(table.map(\.level) == [.up, .down, .up, .down])
        #expect(table[BeatTime(0)] == .down)
        #expect(table[BeatTime(5)] == .down)
    }

    @Test
    func reverse_leadingStretchKeepsPrecedingUnselectedLevel() throws {
        //
        // Down from 0, then half from 4 and Up from 6, with only the last two reversed within
        // 2…8. The stretch 2–4 is still Down, from the unselected entry, so Down (not Up) begins
        // the stretch it mirrors to, 6–8.
        //
        var table = PedalTableSB()

        table.insert(time: 0, level: .down)

        let halfID = table.insert(time: 4, level: half).entryID
        let offID = table.insert(time: 6, level: .up).entryID

        try table.reverse(within: BeatTime(2)...8,
                          entryIDs: [halfID, offID])

        #expect(table.map(\.time) == [0, 2, 4, 6])
        #expect(table.map(\.level) == [.down, .up, half, .down])
    }

    @Test
    func reverse_movesEachEntryToItsStretchStart() throws {
        //
        // Down for 0–4, then Up for 4–8, reversed within 0…8, is Up for 0–4, then Down for 4–8.
        //
        var table = PedalTableSB()

        table.insert(time: 0, level: .down)
        table.insert(time: 4, level: .up)

        try table.reverse(within: BeatTime(0)...8)

        #expect(table.map(\.time) == [0, 4])
        #expect(table.map(\.level) == [.up, .down])
    }

    @Test
    func reverse_movesLeadingStretchToRangeEnd() throws {
        //
        // Before the first entry, the pedal is up. Up for 0–2, Down for 2–4, then half for 4–8,
        // reversed within 0…8, is half for 0–4, Down for 4–6, then Up for 6–8. A new entry
        // begins the Up stretch.
        //
        var table = PedalTableSB()

        table.insert(time: 2, level: .down)
        table.insert(time: 4, level: half)

        try table.reverse(within: BeatTime(0)...8)

        #expect(table.map(\.time) == [0, 4, 6])
        #expect(table.map(\.level) == [half, .down, .up])
    }

    @Test
    func reverse_validAnchorDoesNotThrow() throws {
        var table = PedalTableSB()

        table.insert(time: 0, level: .down)
        table.insert(time: 2, level: .up)

        try table.reverse(within: BeatTime(0)...2)

        //
        // Down holds for all of 0…2, so it starts at 0. Up's stretch ends where the range does,
        // so it has no length and mirrors to 0 as well, ahead of Down:
        //
        #expect(table.map(\.time) == [0, 0])
        #expect(table[BeatTime(0)] == .down)
    }
}

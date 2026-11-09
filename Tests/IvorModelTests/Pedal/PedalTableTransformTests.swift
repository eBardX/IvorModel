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

        let entryID1 = table.insert(time: 0, level: .on).entryID

        table.insert(time: 4, level: .off)

        try table.augment(by: Number(2), entryIDs: [entryID1])

        #expect(table.map(\.time) == [0, 4])
    }

    @Test
    func augment_invalidAnchorThrows() {
        var table = PedalTableSB()

        table.insert(time: 2, level: .on)

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
        #expect(table.map(\.level) == [.on, .off, .on, .off])
    }

    @Test
    func augment_nilAnchorWithEntryIDsUsesSelectedRange() throws {
        var table = PedalTableSB()

        table.insert(time: 0, level: .on)

        let entryID10 = table.insert(time: 10, level: .off).entryID
        let entryID14 = table.insert(time: 14, level: .on).entryID

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

        table.insert(time: 1, level: .on)
        table.insert(time: 3, level: .off)

        try table.augment(by: Number(2))

        #expect(table.map(\.time) == [1, 5])
    }

    @Test
    func augment_validAnchorDoesNotThrow() throws {
        var table = PedalTableSB()

        table.insert(time: 2, level: .on)

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
        #expect(table.map(\.level) == [.on, .off, .on, .off])
    }

    @Test
    func diminish_scalesTimes() throws {
        var table = PedalTableSB()

        table.insert(time: 2, level: .on)
        table.insert(time: 6, level: .off)

        try table.diminish(by: Number(2))

        #expect(table.map(\.time) == [2, 4])
    }

    @Test
    func move_entryIDsRestrictsAffectedEntries() throws {
        var table = PedalTableSB()

        let entryID1 = table.insert(time: 0, level: .on).entryID

        table.insert(time: 4, level: .off)

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
        #expect(table.map(\.level) == [.on, .off, .on, .off])
    }

    @Test
    func move_shiftsTimes() throws {
        var table = PedalTableSB()

        table.insert(time: 0, level: .on)

        let directedDuration = try #require(BeatTime(0).duration(to: 2))

        try table.move(by: directedDuration)

        #expect(table.map(\.time) == [2])
    }

    @Test
    func quantize_entryIDsRestrictsAffectedEntries() throws {
        var table = PedalTableSB()

        let entryID1 = table.insert(time: 0.49, level: .on).entryID
        let entryID2 = table.insert(time: 4.49, level: .off).entryID

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

        table.insert(time: 0.9, level: .on)
        table.insert(time: 3.1, level: .off)
        table.insert(time: 3.1, level: .on)
        table.insert(time: 4.9, level: .off)

        try table.quantize(using: BeatQuantizer(factors: [1]))

        #expect(table.map(\.time) == [1, 3, 3, 5])
        #expect(table.map(\.level) == [.on, .off, .on, .off])
    }

    @Test
    func quantize_snapsTimesToGrid() throws {
        var table = PedalTableSB()

        table.insert(time: 0.49, level: .on)
        table.insert(time: 3.6, level: .off)

        try table.quantize(using: BeatQuantizer(factors: [1]))

        #expect(table.map(\.time) == [0, 4])
    }

    @Test
    func reverse_entryIDsSelectionIsSelfContained() throws {
        var table = PedalTableSB()

        table.insert(time: 0, level: .on)

        let phraseID1 = table.insert(time: 10, level: .off).entryID
        let phraseID2 = table.insert(time: 12, level: half).entryID

        table.insert(time: 20, level: .on)

        try table.reverse(entryIDs: [phraseID1, phraseID2])

        //
        // Mirrored around its own bounds (10...12), not the whole table's (0...20). Off holds
        // for all of 10...12, so it starts there; the half level's stretch ends where the range
        // does, so it has no length and mirrors to 10 as well, ahead of Off:
        //
        #expect(table.map(\.time) == [0, 10, 10, 20])
        #expect(table[BeatTime(10)] == .off)
    }

    @Test
    func reverse_invalidAnchorThrows() {
        var table = PedalTableSB()

        table.insert(time: 0, level: .on)
        table.insert(time: 2, level: .off)

        #expect(throws: PedalTableSB.Error.invalidAnchor) {
            try table.reverse(within: BeatTime(1)...3)
        }
    }

    @Test
    func reverse_keepsRepedalOffThenOn() throws {
        //
        // On at 0, re-pedaled at 3, up at 8, reversed within 0…8. The press from 3 to 8 now
        // runs 0 to 5, and the one from 0 to 3 runs 5 to 8, so the re-pedal lands at 5, still
        // Off then On:
        //
        var table = PedalTableSB()

        table.insert(time: 0, level: .on)
        table.insert(time: 3, level: .off)
        table.insert(time: 3, level: .on)
        table.insert(time: 8, level: .off)

        try table.reverse(within: BeatTime(0)...8)

        #expect(table.map(\.time) == [0, 0, 5, 5])
        #expect(table.map(\.level) == [.off, .on, .off, .on])
        #expect(table[BeatTime(0)] == .on)
        #expect(table[BeatTime(5)] == .on)
    }

    @Test
    func reverse_leadingStretchKeepsPrecedingUnselectedLevel() throws {
        //
        // On from 0, then half from 4 and Off from 6, with only the last two reversed within
        // 2…8. The stretch 2–4 is still On, from the unselected entry, so On (not Off) begins
        // the stretch it mirrors to, 6–8.
        //
        var table = PedalTableSB()

        table.insert(time: 0, level: .on)

        let halfID = table.insert(time: 4, level: half).entryID
        let offID = table.insert(time: 6, level: .off).entryID

        try table.reverse(within: BeatTime(2)...8,
                          entryIDs: [halfID, offID])

        #expect(table.map(\.time) == [0, 2, 4, 6])
        #expect(table.map(\.level) == [.on, .off, half, .on])
    }

    @Test
    func reverse_movesEachEntryToItsStretchStart() throws {
        //
        // On for 0–4, then Off for 4–8, reversed within 0…8, is Off for 0–4, then On for 4–8.
        //
        var table = PedalTableSB()

        table.insert(time: 0, level: .on)
        table.insert(time: 4, level: .off)

        try table.reverse(within: BeatTime(0)...8)

        #expect(table.map(\.time) == [0, 4])
        #expect(table.map(\.level) == [.off, .on])
    }

    @Test
    func reverse_movesLeadingStretchToRangeEnd() throws {
        //
        // Before the first entry, the pedal is up. Off for 0–2, On for 2–4, then half for 4–8,
        // reversed within 0…8, is half for 0–4, On for 4–6, then Off for 6–8. A new entry
        // begins the Off stretch.
        //
        var table = PedalTableSB()

        table.insert(time: 2, level: .on)
        table.insert(time: 4, level: half)

        try table.reverse(within: BeatTime(0)...8)

        #expect(table.map(\.time) == [0, 4, 6])
        #expect(table.map(\.level) == [half, .on, .off])
    }

    @Test
    func reverse_validAnchorDoesNotThrow() throws {
        var table = PedalTableSB()

        table.insert(time: 0, level: .on)
        table.insert(time: 2, level: .off)

        try table.reverse(within: BeatTime(0)...2)

        //
        // On holds for all of 0…2, so it starts at 0. Off's stretch ends where the range does,
        // so it has no length and mirrors to 0 as well, ahead of On:
        //
        #expect(table.map(\.time) == [0, 0])
        #expect(table[BeatTime(0)] == .on)
    }
}

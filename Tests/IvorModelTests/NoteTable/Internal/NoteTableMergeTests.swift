// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct NoteTableMergeTests {
}

// MARK: -

extension NoteTableMergeTests {
    @Test
    func mergingTimes_collapsedNote_keepsWindowLength() throws {
        let table = makeNoteTableSB([(0, beats(Number(numerator: 1, denominator: 16)), .c4)])

        let merged = table.mergingTimes(within: beats(Number(numerator: 1, denominator: 8)))
        let note = try #require(merged.first)

        #expect(note.attack == 0)
        #expect(note.duration == beats(Number(numerator: 1, denominator: 8)))
    }

    @Test
    func mergingTimes_distantTimes_unchanged() {
        let table = makeNoteTableSB([(0, 1, .c4),
                                     (beatTime(Number(numerator: 1, denominator: 16)), 1, .e4)])

        let merged = table.mergingTimes(within: beats(Number(numerator: 1, denominator: 32)))

        #expect(makeNoteTriplesSB(merged) == makeNoteTriplesSB(table))
    }

    @Test
    func mergingTimes_groupsMeasureFromGroupStart() {
        let table = makeNoteTableSB([(0, 4, .c4),
                                     (beatTime(Number(numerator: 1, denominator: 10)), 4, .d4),
                                     (beatTime(Number(numerator: 1, denominator: 5)), 4, .e4)])

        let merged = table.mergingTimes(within: beats(Number(numerator: 3, denominator: 20)))
        let attacks = merged.map(\.attack).sorted()

        #expect(attacks == [0, 0, beatTime(Number(numerator: 1, denominator: 5))])
    }

    @Test
    func mergingTimes_leavesOriginalUnchanged() {
        let table = makeNoteTableSB([(0, 1, .c4),
                                     (beatTime(Number(numerator: 1, denominator: 16)), 1, .e4)])
        let before = makeNoteTriplesSB(table)

        _ = table.mergingTimes(within: beats(Number(numerator: 1, denominator: 8)))

        #expect(makeNoteTriplesSB(table) == before)
    }

    @Test
    func mergingTimes_nearbyAttacksAndReleases_merge() {
        let table = makeNoteTableSB([(0, 1, .c4),
                                     (beatTime(Number(numerator: 1, denominator: 16)), 1, .e4)])

        let merged = table.mergingTimes(within: beats(Number(numerator: 1, denominator: 8)))

        #expect(merged.allSatisfy { $0.attack == 0 && $0.release == 1 })
    }

    @Test
    func mergingTimes_preservesNoteIDsAndPitches() {
        let table = makeNoteTableSB([(0, 1, .c4),
                                     (beatTime(Number(numerator: 1, denominator: 16)), 1, .e4)])

        let merged = table.mergingTimes(within: beats(Number(numerator: 1, denominator: 8)))

        #expect(Set(merged.map(\.noteID)) == Set(table.map(\.noteID)))
        #expect(Set(merged.map(\.startPitch)) == [.c4, .e4])
    }
}

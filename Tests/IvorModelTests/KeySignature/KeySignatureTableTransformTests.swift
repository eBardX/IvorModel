// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct KeySignatureTableTransformTests {
}

// MARK: -

extension KeySignatureTableTransformTests {

    // MARK: Time

    @Test
    func augment_scalesFromAnchor() throws {
        var table = try makeKeySignatureTable([(1, 2), (3, -1), (5, 0)])

        try table.augment(by: 2, anchor: 2)

        #expect(table.map(\.beatTime) == [1, 4, 8])
        #expect(table.map(\.keySignature) == [keySignature(2), keySignature(-1), keySignature(0)])
    }

    @Test
    func augment_invalidFactorThrows() throws {
        var table = try makeKeySignatureTable([(1, 2)])

        #expect(throws: KeySignatureTable.Error.invalidAugmentationFactor(frac(1, 2))) {
            try table.augment(by: frac(1, 2))
        }
    }

    @Test
    func diminish_scalesFromAnchor() throws {
        var table = try makeKeySignatureTable([(2, 2), (6, -1)])

        try table.diminish(by: 2)

        #expect(table.map(\.beatTime) == [1, 3])
    }

    @Test
    func diminish_invalidFactorThrows() throws {
        var table = try makeKeySignatureTable([(1, 2)])

        #expect(throws: KeySignatureTable.Error.invalidDiminutionFactor(0)) {
            try table.diminish(by: 0)
        }
    }

    @Test
    func move_earlier_keepsLastEntryBeforeZeroAtZero() throws {
        var table = try makeKeySignatureTable([(0, 2), (1, -1), (3, 0)])

        table.move(by: DirectedDuration(duration: beats(2), direction: .backward))

        #expect(table.map(\.beatTime) == [0, 1])
        #expect(table.map(\.keySignature) == [keySignature(-1), keySignature(0)])
    }

    @Test
    func move_earlier_entryLandingOnZeroWins() throws {
        var table = try makeKeySignatureTable([(0, 2), (2, -1), (3, 0)])

        table.move(by: DirectedDuration(duration: beats(2), direction: .backward))

        #expect(table.map(\.beatTime) == [0, 1])
        #expect(table.map(\.keySignature) == [keySignature(-1), keySignature(0)])
    }

    @Test
    func move_later_shiftsEveryEntry() throws {
        var table = try makeKeySignatureTable([(0, 2), (4, -1)])
        let ids = table.map(\.entryID)

        table.move(by: DirectedDuration(duration: beats(frac(1, 2)), direction: .forward))

        #expect(table.map(\.beatTime) == [beatTime(frac(1, 2)), beatTime(frac(9, 2))])
        #expect(table.map(\.entryID) == ids)
    }

    @Test
    func reverse_mirrorsSteps() throws {
        var table = try makeKeySignatureTable([(0, 2), (4, -2)])

        table.reverse(within: 0...8)

        // 2♭ was in effect after the range, so it's restated at 8.
        #expect(table.map(\.beatTime) == [0, 4, 8])
        #expect(table.map(\.keySignature) == [keySignature(-2), keySignature(2), keySignature(-2)])
    }

    @Test
    func reverse_leadingStretchAndKeyAfter() throws {
        //
        // 1♯ from 0, 2♯ from 3, 3♭ from 6; reversing 2…5 mirrors 2♯ (3…5) to 2…4 and the leading
        // 1♯ (2…3) to 4…5, and restates 2♯, which was in effect at 5, there.
        //
        var table = try makeKeySignatureTable([(0, 1), (3, 2), (6, -3)])

        table.reverse(within: 2...5)

        #expect(table.map(\.beatTime) == [0, 2, 4, 5, 6])
        #expect(table.map(\.keySignature) == [keySignature(1),
                                              keySignature(2),
                                              keySignature(1),
                                              keySignature(2),
                                              keySignature(-3)])
    }

    @Test
    func reverse_keepsExtrasOnLeadingAndAfter() throws {
        var table = KeySignatureTable()

        try table.insert(beatTime: 0, keySignature: keySignature(-3), extras: modeExtras("minor"))
        try table.insert(beatTime: 2, keySignature: keySignature(0))

        table.reverse(within: 1...4)

        #expect(table.map(\.beatTime) == [0, 1, 3, 4])
        #expect(table.map(\.keySignature) == [keySignature(-3), keySignature(0), keySignature(-3), keySignature(0)])
        #expect(table.map(\.extras) == [modeExtras("minor"), nil, modeExtras("minor"), nil])
    }

    @Test
    func reverse_entryAtUpperBoundStays() throws {
        var table = try makeKeySignatureTable([(0, 2), (4, -2), (8, -2)])

        table.reverse(within: 0...8)

        #expect(table.map(\.beatTime) == [0, 4, 8])
        #expect(table.map(\.keySignature) == [keySignature(-2), keySignature(2), keySignature(-2)])
    }

    @Test
    func reverse_noEntriesInRangeDoesNothing() throws {
        var table = try makeKeySignatureTable([(0, 2), (10, -1)])
        let original = table

        table.reverse(within: 2...6)

        #expect(table == original)
    }

    // MARK: Pitch

    @Test
    func invert_dropsModeKeepsOtherExtras() throws {
        let other = Extra(name: "other", values: [.int(1)])
        var table = KeySignatureTable()

        try table.insert(beatTime: 0,
                         keySignature: keySignature(1),
                         extras: modeExtras("major").inserting(other))

        let emptied = table.invert(around: Pitch.c4...Pitch.g4)

        #expect(!emptied)
        #expect(table.first?.keySignature == keySignature(-4))
        #expect(table.first?.extras == Extras(elements: [other]))
    }

    @Test
    func invert_noteRange() throws {
        var table = try makeKeySignatureTable([(0, 1), (4, 0)])

        let emptied = table.invert(around: NoteNumber(uintValue: 60)!...NoteNumber(uintValue: 67)!) // swiftlint:disable:this force_unwrapping

        #expect(!emptied)
        #expect(table.map(\.keySignature) == [keySignature(-4), keySignature(-3)])
    }

    @Test
    func invert_unfittableEmptiesTable() throws {
        var table = try makeKeySignatureTable([(0, 1)])

        try table.insert(beatTime: 4,
                         keySignature: #require(KeySignature(accidentals: [PitchClass.fFlat, .bSharp])))

        let emptied = table.invert(around: Pitch.c4...Pitch.g4)

        #expect(emptied)
        #expect(table.isEmpty)
    }

    @Test
    func transpose_interval_keepsMode() throws {
        var table = KeySignatureTable()

        try table.insert(beatTime: 0, keySignature: keySignature(-1), extras: modeExtras("minor"))

        let emptied = try table.transpose(by: #require(Pitch.c4.interval(to: .d4)))

        #expect(!emptied)
        #expect(table.first?.keySignature == keySignature(1))
        #expect(table.first?.extras == modeExtras("minor"))
    }

    @Test
    func transpose_noteDistance() throws {
        var table = try makeKeySignatureTable([(0, -1)])
        let up = DirectedInterval(interval: NoteDistance(uintValue: 1)!, direction: .ascending)    // swiftlint:disable:this force_unwrapping

        table.transpose(by: up)

        #expect(table.first?.keySignature == keySignature(-6))
    }

    @Test
    func transpose_ratio() throws {
        var fifth = try makeKeySignatureTable([(0, 0)])
        var septimal = try makeKeySignatureTable([(0, 0), (2, 1)])

        let fifthEmptied = try fifth.transpose(by: DirectedInterval(interval: #require(Ratio(numberValue: frac(3, 2))), direction: .ascending))
        let septimalEmptied = try septimal.transpose(by: DirectedInterval(interval: #require(Ratio(numberValue: frac(7, 4))), direction: .ascending))

        #expect(!fifthEmptied)
        #expect(fifth.first?.keySignature == keySignature(1))
        #expect(septimalEmptied)
        #expect(septimal.isEmpty)
    }

    @Test
    func transpose_unfittableEmptiesTable() throws {
        var table = try makeKeySignatureTable([(0, 2)])

        try table.insert(beatTime: 4,
                         keySignature: #require(KeySignature(accidentals: [PitchClass.fFlat, .bSharp])))

        let emptied = try table.transpose(by: #require(Pitch.c4.interval(to: .g4)))

        #expect(emptied)
        #expect(table.isEmpty)
        #expect(!table.hasExtras)
    }
}

// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct NoteTableTests {
}

// MARK: -

extension NoteTableTests {
    private typealias NoteTableSB = NoteTable<BeatTime, Pitch>

    @Test
    func forEach() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)
        table.insert(attack: 1, duration: 1, pitch: .e4)

        var pitches: [Pitch] = []

        table.forEach { _, _, startPitch, _, _ in
            pitches.append(startPitch)
        }

        #expect(pitches.count == 2)
        #expect(pitches[0] == .c4)
        #expect(pitches[1] == .e4)
    }

    @Test
    func hasExtras_initial() {
        let table = NoteTableSB()

        #expect(!table.hasExtras)
    }

    @Test
    func hasGlide_afterInsert() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, startPitch: .c4, endPitch: .e4)

        #expect(table.hasPortamento)
    }

    @Test
    func hasGlide_initial() {
        let table = NoteTableSB()

        #expect(!table.hasPortamento)
    }

    @Test
    func inserting() {
        let table = NoteTableSB().inserting(attack: 0, duration: 1, pitch: .c4)

        #expect(!table.isEmpty)
    }

    @Test
    func isEmpty_afterInsert() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)

        #expect(!table.isEmpty)
    }

    @Test
    func isEmpty_initial() {
        let table = NoteTableSB()

        #expect(table.isEmpty)
    }

    @Test
    func isMonophonic_initial() {
        let table = NoteTableSB()

        #expect(table.isMonophonic)
    }

    @Test
    func isMonophonic_overlapping() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 2, pitch: .c4)
        table.insert(attack: 1, duration: 2, pitch: .e4)

        #expect(!table.isMonophonic)
    }

    @Test
    func isMonophonic_sequential() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)
        table.insert(attack: 1, duration: 1, pitch: .e4)

        #expect(table.isMonophonic)
    }

    @Test
    func merge() {
        var table1 = NoteTableSB()
        var table2 = NoteTableSB()

        table1.insert(attack: 0, duration: 1, pitch: .c4)
        table2.insert(attack: 2, duration: 1, pitch: .g4)
        table1.merge(with: table2)

        #expect(!table1.isEmpty)
        #expect(table1.pitchRange?.lowerBound == .c4)
        #expect(table1.pitchRange?.upperBound == .g4)
    }

    @Test
    func merging() {
        let table1 = NoteTableSB().inserting(attack: 0, duration: 1, pitch: .c4)
        let table2 = NoteTableSB().inserting(attack: 2, duration: 1, pitch: .g4)
        let merged = table1.merging(with: table2)

        #expect(!merged.isEmpty)
    }

    @Test
    func pitchRange() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)
        table.insert(attack: 1, duration: 1, pitch: .g5)
        table.insert(attack: 2, duration: 1, pitch: .e4)

        #expect(table.pitchRange?.lowerBound == .c4)
        #expect(table.pitchRange?.upperBound == .g5)
    }

    @Test
    func remove() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)
        table.remove(attack: 0, duration: 1, pitch: .c4)

        #expect(table.isEmpty)
    }

    @Test
    func removing() {
        let table = NoteTableSB()
            .inserting(attack: 0, duration: 1, pitch: .c4)
            .removing(attack: 0, duration: 1, pitch: .c4)

        #expect(table.isEmpty)
    }

    @Test
    func timeRange() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 2, pitch: .c4)
        table.insert(attack: 3, duration: 1, pitch: .e4)

        #expect(table.timeRange?.lowerBound == 0)
        #expect(table.timeRange?.upperBound == 4)
    }
}

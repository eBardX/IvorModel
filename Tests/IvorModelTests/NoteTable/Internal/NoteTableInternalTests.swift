// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct NoteTableInternalTests {
}

// MARK: -

extension NoteTableInternalTests {
    private typealias NoteTableSB = NoteTable<BeatTime, Pitch>

    @Test
    func firstIndex_found() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)
        table.insert(attack: 1, duration: 1, pitch: .e4)

        #expect(table.firstIndex(attack: 1, duration: 1, startPitch: .e4, endPitch: .e4, extras: nil) == 1)
    }

    @Test
    func firstIndex_noteID_found() throws {
        var table = NoteTableSB()
        var foundNoteID: NoteTableSB.NoteID?

        table.insert(attack: 0, duration: 1, pitch: .c4)

        table.forEach { noteID, _, _, _, _, _ in foundNoteID = noteID }

        #expect(try table.firstIndex(noteID: #require(foundNoteID)) == 0)
    }

    @Test
    func firstIndex_noteID_notFound() {
        let table = NoteTableSB()
        let position = table.firstIndex(noteID: NoteTableSB.NoteID())

        #expect(position == nil)
    }

    @Test
    func firstIndex_notFound() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)

        let index = table.firstIndex(attack: 1, duration: 1, startPitch: .e4, endPitch: .e4, extras: nil)

        #expect(index == nil)
    }

    @Test
    func hasExtras_withExtras() {
        let notes = [NoteTableSB.Note(attack: 0,
                                      duration: 1,
                                      startPitch: .c4,
                                      endPitch: .c4,
                                      extras: Extras(elements: [Extra(name: "accent")]))]

        #expect(NoteTableSB.hasExtras(in: notes))
    }

    @Test
    func hasExtras_withoutExtras() {
        let notes = [NoteTableSB.Note(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)]

        #expect(!NoteTableSB.hasExtras(in: notes))
    }

    @Test
    func hasPortamento_withoutPortamento() {
        let notes = [NoteTableSB.Note(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)]

        #expect(!NoteTableSB.hasPortamento(in: notes))
    }

    @Test
    func hasPortamento_withPortamento() {
        let notes = [NoteTableSB.Note(attack: 0, duration: 1, startPitch: .c4, endPitch: .e4, extras: nil)]

        #expect(NoteTableSB.hasPortamento(in: notes))
    }

    @Test
    func insertionIndex_empty() {
        let table = NoteTableSB()

        #expect(table.insertionIndex(for: 1, duration: 1, startPitch: .c4, endPitch: .c4) == 0)
    }

    @Test
    func insertionIndex_middle() {
        var table = NoteTableSB()

        table.insert(attack: 0, duration: 1, pitch: .c4)
        table.insert(attack: 2, duration: 1, pitch: .c4)

        #expect(table.insertionIndex(for: 1, duration: 1, startPitch: .c4, endPitch: .c4) == 1)
    }

    @Test
    func isMonophonic_overlapping() {
        let notes = [NoteTableSB.Note(attack: 0, duration: 2, startPitch: .c4, endPitch: .c4, extras: nil),
                     NoteTableSB.Note(attack: 1, duration: 1, startPitch: .e4, endPitch: .e4, extras: nil)]

        #expect(!NoteTableSB.isMonophonic(in: notes))
    }

    @Test
    func isMonophonic_sequential() {
        let notes = [NoteTableSB.Note(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil),
                     NoteTableSB.Note(attack: 1, duration: 1, startPitch: .e4, endPitch: .e4, extras: nil)]

        #expect(NoteTableSB.isMonophonic(in: notes))
    }

    @Test
    func mergePitchRanges() {
        let merged = NoteTableSB.mergePitchRanges(Pitch.c4...Pitch.e4, Pitch.g4...Pitch.c5)

        #expect(merged.lowerBound == .c4)
        #expect(merged.upperBound == .c5)
    }

    @Test
    func mergeTimeRanges() {
        let merged = NoteTableSB.mergeTimeRanges(BeatTime(0)...BeatTime(1), BeatTime(2)...BeatTime(3))

        #expect(merged.lowerBound == 0)
        #expect(merged.upperBound == 3)
    }

    @Test
    func pitchRange_empty() {
        #expect(NoteTableSB.pitchRange(in: []) == nil)
    }

    @Test
    func pitchRange_nonEmpty() {
        let notes = [NoteTableSB.Note(attack: 0, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil),
                     NoteTableSB.Note(attack: 1, duration: 1, startPitch: .g5, endPitch: .g5, extras: nil)]

        let range = NoteTableSB.pitchRange(in: notes)

        #expect(range?.lowerBound == .c4)
        #expect(range?.upperBound == .g5)
    }

    @Test
    func timeRange_empty() {
        #expect(NoteTableSB.timeRange(in: []) == nil)
    }

    @Test
    func timeRange_nonEmpty() {
        let notes = [NoteTableSB.Note(attack: 0, duration: 2, startPitch: .c4, endPitch: .c4, extras: nil),
                     NoteTableSB.Note(attack: 3, duration: 1, startPitch: .c4, endPitch: .c4, extras: nil)]

        let range = NoteTableSB.timeRange(in: notes)

        #expect(range?.lowerBound == 0)
        #expect(range?.upperBound == 4)
    }
}

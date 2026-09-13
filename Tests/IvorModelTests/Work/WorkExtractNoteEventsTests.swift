// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct WorkExtractNoteEventsTests {
}

// MARK: -

extension WorkExtractNoteEventsTests {
    @Test
    func extractNoteEvents_absoluteBeat_returnsMatchingOverloadOnly() {
        var part = Part<BeatTime, Frequency>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 1, pitch: Frequency(440))

        let work = Work(content: .absoluteBeat([part], TempoMap()))

        let matching: [Work.TaggedNoteEvent<BeatTime, Frequency>]? = work.extractNoteEvents()
        let mismatch1: [Work.TaggedNoteEvent<WallTime, Frequency>]? = work.extractNoteEvents()
        let mismatch2: [Work.TaggedNoteEvent<BeatTime, NoteNumber>]? = work.extractNoteEvents()
        let mismatch3: [Work.TaggedNoteEvent<WallTime, NoteNumber>]? = work.extractNoteEvents()
        let mismatch4: [Work.TaggedNoteEvent<BeatTime, Pitch>]? = work.extractNoteEvents()
        let mismatch5: [Work.TaggedNoteEvent<WallTime, Pitch>]? = work.extractNoteEvents()

        #expect(matching != nil)
        #expect(mismatch1 == nil)
        #expect(mismatch2 == nil)
        #expect(mismatch3 == nil)
        #expect(mismatch4 == nil)
        #expect(mismatch5 == nil)
    }

    @Test
    func extractNoteEvents_absoluteWall_returnsMatchingOverloadOnly() {
        var part = Part<WallTime, Frequency>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 1, pitch: Frequency(440))

        let work = Work(content: .absoluteWall([part]))

        let matching: [Work.TaggedNoteEvent<WallTime, Frequency>]? = work.extractNoteEvents()
        let mismatch: [Work.TaggedNoteEvent<BeatTime, Frequency>]? = work.extractNoteEvents()

        #expect(matching != nil)
        #expect(mismatch == nil)
    }

    @Test
    func extractNoteEvents_emptyWork_returnsEmptyArrayNotNil() throws {
        let work = Work(content: .standardBeat([], TempoMap()))

        let events: [Work.TaggedNoteEvent<BeatTime, Pitch>]? = work.extractNoteEvents()
        let unwrapped = try #require(events)

        #expect(unwrapped.isEmpty)
    }

    @Test
    func extractNoteEvents_keyboardBeat_returnsMatchingOverloadOnly() {
        var part = Part<BeatTime, NoteNumber>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 1, pitch: NoteNumber(60))

        let work = Work(content: .keyboardBeat([part], TempoMap()))

        let matching: [Work.TaggedNoteEvent<BeatTime, NoteNumber>]? = work.extractNoteEvents()
        let mismatch: [Work.TaggedNoteEvent<WallTime, NoteNumber>]? = work.extractNoteEvents()

        #expect(matching != nil)
        #expect(mismatch == nil)
    }

    @Test
    func extractNoteEvents_keyboardWall_returnsMatchingOverloadOnly() {
        var part = Part<WallTime, NoteNumber>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 1, pitch: NoteNumber(60))

        let work = Work(content: .keyboardWall([part]))

        let matching: [Work.TaggedNoteEvent<WallTime, NoteNumber>]? = work.extractNoteEvents()
        let mismatch: [Work.TaggedNoteEvent<BeatTime, NoteNumber>]? = work.extractNoteEvents()

        #expect(matching != nil)
        #expect(mismatch == nil)
    }

    @Test
    func extractNoteEvents_multiPart_mergesSortedByAttackTimeAcrossParts() throws {
        var part1 = Part<BeatTime, Pitch>(name: "Violin")
        var part2 = Part<BeatTime, Pitch>(name: "Cello")

        // Each part's own notes are contiguous (no gaps), so `extractNoteEvents()` doesn't insert
        // any rest events for that part; only the cross-part merge/sort is under test here.
        part1.noteTable.insert(attack: 0, duration: 2, pitch: .c4)
        part1.noteTable.insert(attack: 2, duration: 2, pitch: .d4)

        part2.noteTable.insert(attack: 0, duration: 1, pitch: .e3)
        part2.noteTable.insert(attack: 1, duration: 1, pitch: .f3)
        part2.noteTable.insert(attack: 2, duration: 2, pitch: .g3)

        let part1ID = part1.partID
        let part2ID = part2.partID
        let work = Work(content: .standardBeat([part1, part2], TempoMap()))

        let events: [Work.TaggedNoteEvent<BeatTime, Pitch>]? = work.extractNoteEvents()
        let unwrapped = try #require(events)

        #expect(unwrapped.map(\.attack) == [0, 0, 1, 2, 2])
        #expect(unwrapped.map(\.partID) == [part1ID, part2ID, part2ID, part1ID, part2ID])
    }

    @Test
    func extractNoteEvents_partWithEmptyNoteTable_returnsEmptyArrayNotNil() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        let work = Work(content: .standardBeat([part], TempoMap()))

        let events: [Work.TaggedNoteEvent<BeatTime, Pitch>]? = work.extractNoteEvents()
        let unwrapped = try #require(events)

        #expect(unwrapped.isEmpty)
    }

    @Test
    func extractNoteEvents_singlePart_matchesNoteTableExtractionAndAttackTimes() throws {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 2, pitch: .c4)
        part.noteTable.insert(attack: 2, duration: 3, pitch: .d4)
        part.noteTable.insert(attack: 5, duration: 1, pitch: .e4)

        let expectedEvents = part.noteTable.extractNoteEvents()
        let partID = part.partID
        let work = Work(content: .standardBeat([part], TempoMap()))

        let events: [Work.TaggedNoteEvent<BeatTime, Pitch>]? = work.extractNoteEvents()
        let unwrapped = try #require(events)

        #expect(unwrapped.count == expectedEvents.count)
        #expect(unwrapped.map(\.noteEvent) == expectedEvents)
        #expect(unwrapped.allSatisfy { $0.partID == partID })

        #expect(unwrapped[0].attack == 0)
        #expect(unwrapped[1].attack == 2)
        #expect(unwrapped[2].attack == 5)

        #expect(unwrapped[0].attack == part.noteTable.timeRange?.lowerBound)
    }

    @Test
    func extractNoteEvents_standardBeat_returnsMatchingOverloadOnly() {
        var part = Part<BeatTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)

        let work = Work(content: .standardBeat([part], TempoMap()))

        let matching: [Work.TaggedNoteEvent<BeatTime, Pitch>]? = work.extractNoteEvents()
        let mismatch: [Work.TaggedNoteEvent<WallTime, Pitch>]? = work.extractNoteEvents()

        #expect(matching != nil)
        #expect(mismatch == nil)
    }

    @Test
    func extractNoteEvents_standardWall_returnsMatchingOverloadOnly() {
        var part = Part<WallTime, Pitch>(name: "Violin")

        part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)

        let work = Work(content: .standardWall([part]))

        let matching: [Work.TaggedNoteEvent<WallTime, Pitch>]? = work.extractNoteEvents()
        let mismatch: [Work.TaggedNoteEvent<BeatTime, Pitch>]? = work.extractNoteEvents()

        #expect(matching != nil)
        #expect(mismatch == nil)
    }
}

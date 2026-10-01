// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct WorkPartAccessTests {
}

// MARK: -

extension WorkPartAccessTests {
    @Test
    func modifyPart_editsOnlyMatchingPart() throws {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        var work = Work(content: .standardBeat([part1, part2], TempoMap()))

        let noteID = try work.modifyPart(part2.partID, as: Part<BeatTime, Pitch>.self) {
            $0.noteTable.insert(attack: 0, duration: 1, pitch: .c4)
        }

        #expect(noteID != nil)
        #expect(work.part(part1.partID, as: Part<BeatTime, Pitch>.self)?.noteCount == 0)
        #expect(work.part(part2.partID, as: Part<BeatTime, Pitch>.self)?.noteTable.last?.noteID == noteID)
        #expect(work.partIDs == [part1.partID, part2.partID])
    }

    @Test
    func modifyPart_lockedWork_throws() {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))
        var bodyCalled = false

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) {
            try work.modifyPart(part.partID, as: Part<BeatTime, Pitch>.self) {
                bodyCalled = true
                $0.name = "Cello"
            }
        }
        #expect(!bodyCalled)
        #expect(work.partName(at: 0) == "Violin")
    }

    @Test
    func modifyPart_missingID_returnsNil() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))
        var bodyCalled = false

        let result: Void? = try work.modifyPart(PartID(), as: Part<BeatTime, Pitch>.self) { _ in
            bodyCalled = true
        }

        #expect(result == nil)
        #expect(!bodyCalled)
    }

    @Test
    func modifyPart_wallContent_editsPart() throws {
        let part = Part<WallTime, Frequency>(name: "Violin")
        var work = Work(content: .absoluteWall([part]))

        try work.modifyPart(part.partID, as: Part<WallTime, Frequency>.self) {
            $0.name = "Cello"
        }

        #expect(work.partName(at: 0) == "Cello")
    }

    @Test
    func modifyPart_wrongType_returnsNil() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))
        var bodyCalled = false

        let result: Void? = try work.modifyPart(part.partID, as: Part<WallTime, Pitch>.self) { _ in
            bodyCalled = true
        }

        #expect(result == nil)
        #expect(!bodyCalled)
        #expect(work.partName(at: 0) == "Violin")
    }

    @Test
    func modifyTempoMap_beatContent_editsTempoMap() throws {
        var work = Work(content: .keyboardBeat([], TempoMap()))

        let inserted = try work.modifyTempoMap {
            $0.insert(beatTime: 1, tempo: .default)
        }

        let entryIDs = work.tempoMap?.map(\.entryID) ?? []

        #expect(inserted?.inserted == true)
        #expect(entryIDs == [inserted?.entryID])
    }

    @Test
    func modifyTempoMap_lockedWork_throws() {
        var work = Work(content: .standardBeat([], TempoMap()))
        var bodyCalled = false

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) {
            try work.modifyTempoMap { _ in
                bodyCalled = true
            }
        }
        #expect(!bodyCalled)
        #expect(work.tempoMap?.isEmpty == true)
    }

    @Test
    func modifyTempoMap_wallContent_returnsNil() throws {
        var work = Work(content: .standardWall([]))
        var bodyCalled = false

        let result: Void? = try work.modifyTempoMap { _ in
            bodyCalled = true
        }

        #expect(result == nil)
        #expect(!bodyCalled)
    }

    @Test
    func part_found() {
        let part1 = Part<WallTime, NoteNumber>(name: "Violin")
        let part2 = Part<WallTime, NoteNumber>(name: "Cello")
        let work = Work(content: .keyboardWall([part1, part2]))

        #expect(work.part(part2.partID, as: Part<WallTime, NoteNumber>.self)?.name == "Cello")
    }

    @Test
    func part_missingID_returnsNil() {
        let work = Work(content: .keyboardWall([Part(name: "Violin")]))

        #expect(work.part(PartID(), as: Part<WallTime, NoteNumber>.self) == nil)
    }

    @Test
    func part_wrongType_returnsNil() {
        let part = Part<WallTime, NoteNumber>(name: "Violin")
        let work = Work(content: .keyboardWall([part]))

        #expect(work.part(part.partID, as: Part<WallTime, Pitch>.self) == nil)
    }
}

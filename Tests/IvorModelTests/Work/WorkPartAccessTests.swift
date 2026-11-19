// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
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
    func modifyKeyTable_beatWork() throws {
        var work = makeKeyWork(KeyTable())

        let result = try work.modifyKeyTable { table in
            try? table.insert(beatTime: 0, key: key(3))

            return table.count
        }

        #expect(result == 1)
        #expect(work.keyTable?.first?.key == key(3))
    }

    @Test
    func modifyKeyTable_lockedThrows() {
        var work = makeKeyWork(KeyTable())

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) {
            try work.modifyKeyTable { _ in }
        }
    }

    @Test
    func modifyKeyTable_wallWorkReturnsNil() throws {
        var work = makeC4WallWork([(0, 1)])
        var called = false

        let result: Void? = try work.modifyKeyTable { _ in called = true }

        #expect(result == nil)
        #expect(!called)
        #expect(work.keyTable == nil)
    }

    @Test
    func modifyMeterTable_editsTable() throws {
        var work = Work()

        let entryID = try work.modifyMeterTable { table in
            try? table.insert(beatTime: .zero, meter: meter("5/8"))
        }

        #expect(entryID != nil)
        #expect(work.meterTable?.map(\.meter) == [meter("5/8")])
    }

    @Test
    func modifyMeterTable_lockedWork_throws() {
        var work = Work()

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) {
            try work.modifyMeterTable { _ in }
        }
    }

    @Test
    func modifyMeterTable_wallWork_returnsNilWithoutCallingBody() throws {
        var work = Work(content: .empty(timeBasis: .wall, pitchNotation: .standard))
        var called = false

        let result: Void? = try work.modifyMeterTable { _ in called = true }

        #expect(result == nil)
        #expect(!called)
    }

    @Test
    func modifyPart_editsOnlyMatchingPart() throws {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        var work = Work(content: .standardBeat([part1, part2], TempoMap(), MeterTable(), KeyTable()))

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
        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))
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
        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))
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
        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))
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
        var work = Work(content: .keyboardBeat([], TempoMap(), MeterTable(), KeyTable()))

        let inserted = try work.modifyTempoMap {
            $0.insert(beatTime: 1, tempo: .default)
        }

        let entryIDs = work.tempoMap?.map(\.entryID) ?? []

        #expect(inserted?.inserted == true)
        #expect(entryIDs == [inserted?.entryID])
    }

    @Test
    func modifyTempoMap_lockedWork_throws() {
        var work = Work(content: .standardBeat([], TempoMap(), MeterTable(), KeyTable()))
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

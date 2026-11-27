// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct WorkPartEditingTests {
}

// MARK: -

extension WorkPartEditingTests {
    @Test
    func addPart_appendsToEmptyWork() throws {
        var work = Work(content: .standardBeat([], TempoMap(), MeterTable(), KeyTable()))

        let partID = try work.addPart(name: "Violin")

        #expect(work.partCount == 1)
        #expect(work.partIDs == [partID])
        #expect(work.partName(at: 0) == "Violin")
    }

    @Test
    func addPart_appendsToNonEmptyWork() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))

        let partID = try work.addPart(name: "Cello")

        #expect(work.partCount == 2)
        #expect(work.partIDs.last == partID)
        #expect(work.partName(at: 1) == "Cello")
    }

    @Test
    func addPart_lockedWork_throws() {
        var work = Work(content: .standardBeat([], TempoMap(), MeterTable(), KeyTable()))

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) {
            try work.addPart(name: "Violin")
        }
        #expect(work.partCount == 0)
    }

    @Test
    func addPart_normalizesName() throws {
        var work = Work(content: .standardBeat([], TempoMap(), MeterTable(), KeyTable()))

        try work.addPart(name: "  Violin \n 2 ")

        #expect(work.partName(at: 0) == "Violin 2")
    }

    @Test
    func duplicatePart_keepsArpeggioGroups() throws {
        // A roll spans one part only, so the copy's rolls can keep their groups without joining
        // the original's.
        var work = try makeOrnamentedStandardWork()
        let originalID = work.partIDs[0]
        let copyID = try #require(try work.duplicatePart(originalID))
        let original = try #require(work.part(originalID, as: Part<BeatTime, Pitch>.self))
        let copy = try #require(work.part(copyID, as: Part<BeatTime, Pitch>.self))

        #expect(original.strands[0].noteTable.arpeggioGroups == [1, 2])
        #expect(copy.strands[0].noteTable.arpeggioGroups == [1, 2])
        #expect(copy.unusedArpeggioGroup == 3)
    }

    @Test
    func duplicatePart_givesTheCopyItsOwnNoteIDs() throws {
        var work = try makeOrnamentedStandardWork()
        let originalID = work.partIDs[0]
        let copyID = try #require(try work.duplicatePart(originalID))
        let original = try #require(work.part(originalID, as: Part<BeatTime, Pitch>.self))
        let copy = try #require(work.part(copyID, as: Part<BeatTime, Pitch>.self))

        #expect(copy.noteCount == original.noteCount)
        #expect(Set(copy.strands[0].noteTable.map(\.noteID)).isDisjoint(with: original.strands[0].noteTable.map(\.noteID)))
        #expect(work.content.firstDuplicateNoteID == nil)
    }

    @Test
    func duplicatePart_insertsAfterOriginal() throws {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        var work = Work(content: .standardBeat([part1, part2], TempoMap(), MeterTable(), KeyTable()))

        let duplicateID = try work.duplicatePart(part1.partID)

        #expect(work.partCount == 3)
        #expect(work.partIDs == [part1.partID, duplicateID, part2.partID])
        #expect(work.partName(at: 1) == "Violin")
    }

    @Test
    func duplicatePart_lockedWork_throws() {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) {
            try work.duplicatePart(part.partID)
        }
        #expect(work.partIDs == [part.partID])
    }

    @Test
    func duplicatePart_missingID_isNoOp() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))

        let duplicateID = try work.duplicatePart(PartID())

        #expect(duplicateID == nil)
        #expect(work.partCount == 1)
    }

    @Test
    func index_ofPartID_found() {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        let work = Work(content: .standardBeat([part1, part2], TempoMap(), MeterTable(), KeyTable()))

        #expect(work.index(ofPartID: part2.partID) == 1)
    }

    @Test
    func index_ofPartID_notFound() {
        let work = Work(content: .standardBeat([], TempoMap(), MeterTable(), KeyTable()))

        #expect(work.index(ofPartID: PartID()) == nil)
    }

    @Test
    func partIDs_matchesParts() {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        let work = Work(content: .standardBeat([part1, part2], TempoMap(), MeterTable(), KeyTable()))

        #expect(work.partIDs == [part1.partID, part2.partID])
    }

    @Test
    func removePart_lockedWork_throws() {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) {
            try work.removePart(part.partID)
        }
        #expect(work.partIDs == [part.partID])
    }

    @Test
    func removePart_missingID_isNoOp() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))

        try work.removePart(PartID())

        #expect(work.partCount == 1)
    }

    @Test
    func removePart_removesExistingPart() throws {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        var work = Work(content: .standardBeat([part1, part2], TempoMap(), MeterTable(), KeyTable()))

        try work.removePart(part1.partID)

        #expect(work.partCount == 1)
        #expect(work.partIDs == [part2.partID])
    }

    @Test
    func removePart_removingOnlyPart_leavesWorkEmpty() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))

        try work.removePart(part.partID)

        #expect(work.partCount == 0)
        #expect(work.partIDs.isEmpty)
    }

    @Test
    func renamePart_lockedWork_throws() {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) {
            try work.renamePart(part.partID,
                                to: "Cello")
        }
        #expect(work.partName(at: 0) == "Violin")
    }

    @Test
    func renamePart_missingID_isNoOp() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))

        try work.renamePart(PartID(),
                            to: "Cello")

        #expect(work.partName(at: 0) == "Violin")
    }

    @Test
    func renamePart_normalizesName() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))

        try work.renamePart(part.partID,
                            to: "\tCello  1 ")

        #expect(work.partName(at: 0) == "Cello 1")
    }

    @Test
    func renamePart_renamesExistingPart() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))

        try work.renamePart(part.partID,
                            to: "Cello")

        #expect(work.partName(at: 0) == "Cello")
        #expect(work.partIDs == [part.partID])
    }

    @Test
    func shiftPart_clampsOutOfRangeIndex() throws {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        var work = Work(content: .standardBeat([part1, part2], TempoMap(), MeterTable(), KeyTable()))

        try work.shiftPart(part1.partID,
                           to: 100)

        #expect(work.partIDs == [part2.partID, part1.partID])
    }

    @Test
    func shiftPart_lockedWork_throws() {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        var work = Work(content: .standardBeat([part1, part2], TempoMap(), MeterTable(), KeyTable()))

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) {
            try work.shiftPart(part2.partID,
                               to: 0)
        }
        #expect(work.partIDs == [part1.partID, part2.partID])
    }

    @Test
    func shiftPart_missingID_isNoOp() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))

        try work.shiftPart(PartID(),
                           to: 0)

        #expect(work.partIDs == [part.partID])
    }

    @Test
    func shiftPart_movesToTargetIndex() throws {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        let part3 = Part<BeatTime, Pitch>(name: "Viola")
        var work = Work(content: .standardBeat([part1, part2, part3], TempoMap(), MeterTable(), KeyTable()))

        try work.shiftPart(part3.partID,
                           to: 0)

        #expect(work.partIDs == [part3.partID, part1.partID, part2.partID])
    }

    @Test
    func shiftPart_movingFirstUp_isInertNoOp() throws {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        var work = Work(content: .standardBeat([part1, part2], TempoMap(), MeterTable(), KeyTable()))

        try work.shiftPart(part1.partID,
                           to: -1)

        #expect(work.partIDs == [part1.partID, part2.partID])
    }
}

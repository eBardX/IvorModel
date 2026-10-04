// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing

struct WorkPartEditingTests {
}

// MARK: -

extension WorkPartEditingTests {
    @Test
    func addPart_appendsToEmptyWork() throws {
        var work = Work(content: .standardBeat([], TempoMap()))

        let partID = try work.addPart(name: "Violin")

        #expect(work.partCount == 1)
        #expect(work.partIDs == [partID])
        #expect(work.partName(at: 0) == "Violin")
    }

    @Test
    func addPart_appendsToNonEmptyWork() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))

        let partID = try work.addPart(name: "Cello")

        #expect(work.partCount == 2)
        #expect(work.partIDs.last == partID)
        #expect(work.partName(at: 1) == "Cello")
    }

    @Test
    func addPart_normalizesName() throws {
        var work = Work(content: .standardBeat([], TempoMap()))

        try work.addPart(name: "  Violin \n 2 ")

        #expect(work.partName(at: 0) == "Violin 2")
    }

    @Test
    func duplicatePart_insertsAfterOriginal() throws {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        var work = Work(content: .standardBeat([part1, part2], TempoMap()))

        let duplicateID = try work.duplicatePart(part1.partID)

        #expect(work.partCount == 3)
        #expect(work.partIDs == [part1.partID, duplicateID, part2.partID])
        #expect(work.partName(at: 1) == "Violin")
    }

    @Test
    func duplicatePart_missingID_isNoOp() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))

        let duplicateID = try work.duplicatePart(PartID())

        #expect(duplicateID == nil)
        #expect(work.partCount == 1)
    }

    @Test
    func index_ofPartID_found() {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        let work = Work(content: .standardBeat([part1, part2], TempoMap()))

        #expect(work.index(ofPartID: part2.partID) == 1)
    }

    @Test
    func index_ofPartID_notFound() {
        let work = Work(content: .standardBeat([], TempoMap()))

        #expect(work.index(ofPartID: PartID()) == nil)
    }

    @Test
    func partIDs_matchesParts() {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        let work = Work(content: .standardBeat([part1, part2], TempoMap()))

        #expect(work.partIDs == [part1.partID, part2.partID])
    }

    @Test
    func removePart_missingID_isNoOp() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))

        try work.removePart(PartID())

        #expect(work.partCount == 1)
    }

    @Test
    func removePart_removesExistingPart() throws {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        var work = Work(content: .standardBeat([part1, part2], TempoMap()))

        try work.removePart(part1.partID)

        #expect(work.partCount == 1)
        #expect(work.partIDs == [part2.partID])
    }

    @Test
    func removePart_removingOnlyPart_leavesWorkEmpty() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))

        try work.removePart(part.partID)

        #expect(work.partCount == 0)
        #expect(work.partIDs.isEmpty)
    }

    @Test
    func renamePart_missingID_isNoOp() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))

        try work.renamePart(PartID(),
                            to: "Cello")

        #expect(work.partName(at: 0) == "Violin")
    }

    @Test
    func renamePart_normalizesName() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))

        try work.renamePart(part.partID,
                            to: "\tCello  1 ")

        #expect(work.partName(at: 0) == "Cello 1")
    }

    @Test
    func renamePart_renamesExistingPart() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))

        try work.renamePart(part.partID,
                            to: "Cello")

        #expect(work.partName(at: 0) == "Cello")
        #expect(work.partIDs == [part.partID])
    }

    @Test
    func shiftPart_clampsOutOfRangeIndex() throws {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        var work = Work(content: .standardBeat([part1, part2], TempoMap()))

        try work.shiftPart(part1.partID,
                           to: 100)

        #expect(work.partIDs == [part2.partID, part1.partID])
    }

    @Test
    func shiftPart_missingID_isNoOp() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))

        try work.shiftPart(PartID(),
                           to: 0)

        #expect(work.partIDs == [part.partID])
    }

    @Test
    func shiftPart_movesToTargetIndex() throws {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        let part3 = Part<BeatTime, Pitch>(name: "Viola")
        var work = Work(content: .standardBeat([part1, part2, part3], TempoMap()))

        try work.shiftPart(part3.partID,
                           to: 0)

        #expect(work.partIDs == [part3.partID, part1.partID, part2.partID])
    }

    @Test
    func shiftPart_movingFirstUp_isInertNoOp() throws {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        var work = Work(content: .standardBeat([part1, part2], TempoMap()))

        try work.shiftPart(part1.partID,
                           to: -1)

        #expect(work.partIDs == [part1.partID, part2.partID])
    }

    @Test
    func addPart_lockedWork_throws() {
        var work = Work(content: .standardBeat([], TempoMap()))

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) {
            try work.addPart(name: "Violin")
        }
        #expect(work.partCount == 0)
    }

    @Test
    func duplicatePart_lockedWork_throws() {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) {
            try work.duplicatePart(part.partID)
        }
        #expect(work.partIDs == [part.partID])
    }

    @Test
    func removePart_lockedWork_throws() {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) {
            try work.removePart(part.partID)
        }
        #expect(work.partIDs == [part.partID])
    }

    @Test
    func renamePart_lockedWork_throws() {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) {
            try work.renamePart(part.partID,
                                to: "Cello")
        }
        #expect(work.partName(at: 0) == "Violin")
    }

    @Test
    func shiftPart_lockedWork_throws() {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        var work = Work(content: .standardBeat([part1, part2], TempoMap()))

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) {
            try work.shiftPart(part2.partID,
                               to: 0)
        }
        #expect(work.partIDs == [part1.partID, part2.partID])
    }
}

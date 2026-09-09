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
    func addPart_appendsToEmptyWork() {
        var work = Work(content: .standardBeat([], TempoMap()))

        let partID = work.addPart(name: "Violin")

        #expect(work.partCount == 1)
        #expect(work.partIDs == [partID])
        #expect(work.partName(at: 0) == "Violin")
    }

    @Test
    func addPart_appendsToNonEmptyWork() {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))

        let partID = work.addPart(name: "Cello")

        #expect(work.partCount == 2)
        #expect(work.partIDs.last == partID)
        #expect(work.partName(at: 1) == "Cello")
    }

    @Test
    func duplicatePart_insertsAfterOriginal() {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        var work = Work(content: .standardBeat([part1, part2], TempoMap()))

        let duplicateID = work.duplicatePart(part1.partID)

        #expect(work.partCount == 3)
        #expect(work.partIDs == [part1.partID, duplicateID, part2.partID])
        #expect(work.partName(at: 1) == "Violin")
    }

    @Test
    func duplicatePart_missingID_isNoOp() {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))

        let duplicateID = work.duplicatePart(PartID())

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
    func movePart_clampsOutOfRangeIndex() {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        var work = Work(content: .standardBeat([part1, part2], TempoMap()))

        work.movePart(part1.partID,
                      to: 100)

        #expect(work.partIDs == [part2.partID, part1.partID])
    }

    @Test
    func movePart_missingID_isNoOp() {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))

        work.movePart(PartID(),
                      to: 0)

        #expect(work.partIDs == [part.partID])
    }

    @Test
    func movePart_movesToTargetIndex() {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        let part3 = Part<BeatTime, Pitch>(name: "Viola")
        var work = Work(content: .standardBeat([part1, part2, part3], TempoMap()))

        work.movePart(part3.partID,
                      to: 0)

        #expect(work.partIDs == [part3.partID, part1.partID, part2.partID])
    }

    @Test
    func movePart_movingFirstUp_isInertNoOp() {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        var work = Work(content: .standardBeat([part1, part2], TempoMap()))

        work.movePart(part1.partID,
                      to: -1)

        #expect(work.partIDs == [part1.partID, part2.partID])
    }

    @Test
    func partIDs_matchesParts() {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        let work = Work(content: .standardBeat([part1, part2], TempoMap()))

        #expect(work.partIDs == [part1.partID, part2.partID])
    }

    @Test
    func removePart_missingID_isNoOp() {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))

        work.removePart(PartID())

        #expect(work.partCount == 1)
    }

    @Test
    func removePart_removesExistingPart() {
        let part1 = Part<BeatTime, Pitch>(name: "Violin")
        let part2 = Part<BeatTime, Pitch>(name: "Cello")
        var work = Work(content: .standardBeat([part1, part2], TempoMap()))

        work.removePart(part1.partID)

        #expect(work.partCount == 1)
        #expect(work.partIDs == [part2.partID])
    }

    @Test
    func removePart_removingOnlyPart_leavesWorkEmpty() {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))

        work.removePart(part.partID)

        #expect(work.partCount == 0)
        #expect(work.partIDs.isEmpty)
    }

    @Test
    func renamePart_missingID_isNoOp() {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))

        work.renamePart(PartID(),
                        to: "Cello")

        #expect(work.partName(at: 0) == "Violin")
    }

    @Test
    func renamePart_renamesExistingPart() {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        var work = Work(content: .standardBeat([part], TempoMap()))

        work.renamePart(part.partID,
                        to: "Cello")

        #expect(work.partName(at: 0) == "Cello")
        #expect(work.partIDs == [part.partID])
    }
}

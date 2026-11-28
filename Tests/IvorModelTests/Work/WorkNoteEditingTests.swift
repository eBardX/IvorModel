// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct WorkNoteEditingTests {
}

// MARK: - Moving, copying and removing notes

extension WorkNoteEditingTests {
    @Test
    func moveNotes_withinAPart_keepsIDsAndGroups() throws {
        var work = StrandFixture.work()
        let (_, leftHand) = StrandFixture.hands(work)
        let g4 = try #require(StrandFixture.piano(work).strands[0].noteTable.last)

        try work.moveNotes([g4.noteID], to: leftHand)

        let piano = StrandFixture.piano(work)

        #expect(piano.strands[0].noteTable.map(\.startPitch) == [.e4])
        #expect(piano.strands[1].noteTable.map(\.startPitch) == [.c3, .g4])
        #expect(piano.strands[1].noteTable.last?.noteID == g4.noteID)
        #expect(piano.strands[1].dynamicMap?.map(\.dynamic) == [.f])
        #expect(work.content.invariantError == nil)
    }

    @Test
    func moveNotes_toAnotherPart_getsAFreshArpeggioGroup() throws {
        var work = StrandFixture.work()
        let (rightHand, _) = StrandFixture.hands(work)
        let c5 = try #require(StrandFixture.flute(work).strands[0].noteTable.first)

        try work.moveNotes([c5.noteID], to: rightHand)

        let moved = try #require(StrandFixture.piano(work).strands[0].noteTable.first { $0.noteID == c5.noteID })

        //
        // The piano's own roll is group 1, so the flute's C5 leaves its group for group 2.
        //
        #expect(moved.ornamentation?.arpeggio?.group == ArpeggioGroup(uintValue: 2))
        #expect(StrandFixture.flute(work).strands[0].noteTable.map(\.startPitch) == [.d5])
        #expect(StrandFixture.piano(work).arpeggioGroups.count == 2)
    }

    @Test
    func moveNotes_refusals() {
        var work = StrandFixture.work()
        let (rightHand, _) = StrandFixture.hands(work)
        let noteID = NoteID()
        let strandID = StrandID()

        #expect(throws: Work.Error.unknownNoteID(noteID)) { try work.moveNotes([noteID], to: rightHand) }
        #expect(throws: Work.Error.unknownStrandID(strandID)) { try work.moveNotes([], to: strandID) }

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) { try work.moveNotes([], to: rightHand) }
    }

    @Test
    func copyNotes_givesNewIDsAndLeavesTheOriginals() throws {
        var work = StrandFixture.work()
        let (_, leftHand) = StrandFixture.hands(work)
        let originals = StrandFixture.piano(work).strands[0].noteTable.map(\.noteID)
        let copies = try work.copyNotes(Set(originals), to: leftHand)
        let piano = StrandFixture.piano(work)

        #expect(Set(copies.keys) == Set(originals))
        #expect(Set(copies.values).isDisjoint(with: originals))
        #expect(piano.strands[0].noteTable.map(\.noteID) == originals)
        #expect(Set(piano.strands[1].noteTable.map(\.noteID)).isSuperset(of: copies.values))
        #expect(work.content.invariantError == nil)
    }

    @Test
    func removeNotes_removesFromEveryStrand() throws {
        var work = StrandFixture.work()
        let piano = StrandFixture.piano(work)
        let noteIDs = try Set([#require(piano.strands[0].noteTable.first?.noteID),
                               #require(piano.strands[1].noteTable.first?.noteID)])

        try work.removeNotes(noteIDs)

        #expect(StrandFixture.piano(work).strands.map(\.noteTable.count) == [1, 0])
        #expect(throws: Work.Error.self) { try work.removeNotes(noteIDs) }
    }
}

// MARK: - Splitting and merging strands

extension WorkNoteEditingTests {
    @Test
    func splitStrand_upperPitches_goAbove() throws {
        var work = StrandFixture.work()
        let (rightHand, _) = StrandFixture.hands(work)
        let upper = try work.scope(matching: Work.Scope.Criteria<BeatTime, Pitch>(pitchRange: Pitch.f4...Pitch.c8),
                                   within: Work.Scope(strands: [rightHand]))
        let g4 = try #require(StrandFixture.piano(work).strands[0].noteTable.last?.noteID)
        let newStrand = try work.splitStrand(rightHand, scope: upper)
        let piano = StrandFixture.piano(work)

        #expect(piano.strandIDs.first == newStrand)
        #expect(piano.strands[0].noteTable.map(\.noteID) == [g4])
        #expect(piano.strands[1].noteTable.map(\.startPitch) == [.e4])
    }

    @Test
    func splitStrand_otherwise_goesAfterAndCopiesOwnTablesAndExtras() throws {
        var work = StrandFixture.work()
        let (rightHand, leftHand) = StrandFixture.hands(work)
        let extras = Extras(elements: [Extra(name: Extra.exportStaff.name, values: [.int(2)])])

        try work.setExtras(extras, ofStrand: leftHand)

        let lower = try work.scope(matching: Work.Scope.Criteria<BeatTime, Pitch>(timeRange: beatTime(0)...beatTime(0)),
                                   within: Work.Scope(strands: [leftHand]))
        let newStrand = try work.splitStrand(leftHand, scope: lower)
        let piano = StrandFixture.piano(work)

        #expect(piano.strandIDs == [rightHand, leftHand, newStrand])
        #expect(piano.strands[2].noteTable.map(\.startPitch) == [.c3])
        #expect(piano.strands[2].dynamicMap?.map(\.dynamic) == [.f])
        #expect(piano.strands[2].extras == extras)
        #expect(piano.strands[1].noteTable.isEmpty)
    }

    @Test
    func splitStrand_scopeOutsideTheStrand_throws() throws {
        var work = StrandFixture.work()
        let (rightHand, leftHand) = StrandFixture.hands(work)

        #expect(throws: Work.Error.scopeOutsideStrand(rightHand)) {
            try work.splitStrand(rightHand, scope: Work.Scope(strands: [leftHand]))
        }
        #expect(throws: Work.Error.scopeOutsideStrand(rightHand)) {
            try work.splitStrand(rightHand, scope: Work.Scope(parts: [StrandFixture.fluteID(work)]))
        }
    }

    @Test
    func mergeStrands_firstKeepsItsNameAndTables() throws {
        var work = StrandFixture.work()
        let (rightHand, leftHand) = StrandFixture.hands(work)
        let leftNote = try #require(StrandFixture.piano(work).strands[1].noteTable.first?.noteID)

        try work.shiftStrand(leftHand, to: 0)

        #expect(try work.mergeStrands([rightHand, leftHand]) == leftHand)

        let piano = StrandFixture.piano(work)

        #expect(piano.strandIDs == [leftHand])
        #expect(piano.strands[0].name == "LH")
        #expect(piano.strands[0].dynamicMap?.map(\.dynamic) == [.f])
        #expect(piano.strands[0].noteTable.map(\.startPitch).sorted() == [.c3, .e4, .g4])
        #expect(piano.strands[0].noteTable.contains { $0.noteID == leftNote })
        #expect(try work.mergeStrands([]) == nil)
    }

    @Test
    func mergeStrands_differentParts_throws() throws {
        var work = StrandFixture.work()
        let (rightHand, _) = StrandFixture.hands(work)
        let fluteStrand = try #require(StrandFixture.flute(work).strandIDs.first)

        #expect(throws: Work.Error.strandsInDifferentParts) {
            try work.mergeStrands([rightHand, fluteStrand])
        }
    }
}

// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct WorkPartJoiningTests {
}

// MARK: - Extracting a strand

extension WorkPartJoiningTests {
    @Test
    func extractStrand_makesAPartWithTheOldPartsTables() throws {
        var work = StrandFixture.work()
        let pianoID = StrandFixture.pianoID(work)
        let fluteID = StrandFixture.fluteID(work)
        let (rightHand, leftHand) = StrandFixture.hands(work)
        let leftNotes = StrandFixture.piano(work).strands[1].noteTable.map(\.noteID)
        let realizationID = try #require(work.realizations.first?.realizationID)
        let assignment = try makeAssignment(program: 1)

        work.modifyRealization(realizationID) { $0[pianoID][Fixtures.oboe] = assignment }

        let newID = try work.extractStrand(leftHand)
        let extracted = try #require(work.part(newID, as: Part<BeatTime, Pitch>.self))

        #expect(work.partIDs == [pianoID, newID, fluteID])
        #expect(StrandFixture.piano(work).strandIDs == [rightHand])
        #expect(extracted.name == "LH")
        #expect(extracted.strandIDs == [leftHand])
        #expect(extracted.strands[0].noteTable.map(\.noteID) == leftNotes)
        #expect(extracted.strands[0].dynamicMap == nil)
        #expect(extracted.dynamicMap.map(\.dynamic) == [.f])
        #expect(extracted.instrumentTable.map(\.instrument) == [Fixtures.oboe])
        #expect(extracted.pedals[.sustain]?.map(\.time) == [0, 2])
        #expect(extracted.panMap.count == 1)
        #expect(work.realization(realizationID)?[newID][Fixtures.oboe] == assignment)
        #expect(work.content.invariantError == nil)
    }

    @Test
    func extractStrand_refusals() {
        var work = StrandFixture.work()
        let fluteStrand = StrandFixture.flute(work).strandIDs[0]
        let unknownID = StrandID()

        #expect(throws: Work.Error.lastStrand(fluteStrand)) { try work.extractStrand(fluteStrand) }
        #expect(throws: Work.Error.unknownStrandID(unknownID)) { try work.extractStrand(unknownID) }

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) { try work.extractStrand(StrandFixture.hands(work).1) }
    }
}

// MARK: - Joining parts

extension WorkPartJoiningTests {
    @Test
    func joinParts_appendsStrandsAndKeepsTheFirstPartsTables() throws {
        var work = StrandFixture.work()
        let pianoID = StrandFixture.pianoID(work)
        let fluteID = StrandFixture.fluteID(work)
        let pianoStrands = StrandFixture.piano(work).strandIDs
        let fluteStrand = StrandFixture.flute(work).strandIDs[0]
        let fluteNotes = StrandFixture.flute(work).noteIDs

        let dropped = try work.joinParts([fluteID, pianoID])
        let piano = StrandFixture.piano(work)

        //
        // The flute's empty dynamic map and instrument table differ from the piano's, so its
        // strand gets them as its own; it has no pedals, pan or marks to lose.
        //
        #expect(dropped.isEmpty)
        #expect(work.partIDs == [pianoID])
        #expect(piano.strandIDs == pianoStrands + [fluteStrand])
        #expect(Set(piano.noteIDs).isSuperset(of: fluteNotes))
        #expect(piano.strands[2].dynamicMap?.isEmpty == true)
        #expect(piano.strands[2].instrumentTable?.isEmpty == true)
        #expect(piano.pedals[.sustain]?.count == 2)
        #expect(work.content.invariantError == nil)
    }

    @Test
    func joinParts_renumbersArpeggioGroupsApart() throws {
        var work = StrandFixture.work()

        try work.joinParts(Set(work.partIDs))

        let piano = StrandFixture.piano(work)

        #expect(piano.strands[2].noteTable.arpeggioGroups == [ArpeggioGroup(uintValue: 2).require()])
        #expect(piano.strands[0].noteTable.arpeggioGroups == [ArpeggioGroup(uintValue: 1).require()])
    }

    @Test
    func joinParts_identicalTablesMerge_differingOnesAreReported() throws {
        var work = StrandFixture.work()
        let pianoID = StrandFixture.pianoID(work)
        let fluteID = StrandFixture.fluteID(work)
        let piano = StrandFixture.piano(work)

        _ = try work.modifyPart(fluteID, as: Part<BeatTime, Pitch>.self) { flute in
            flute.dynamicMap = piano.dynamicMap
            flute.instrumentTable = piano.instrumentTable
            flute.pedals = piano.pedals
            flute.panMap.insert(time: 1, pan: .right)
        }

        let dropped = try work.joinParts([pianoID, fluteID])
        let joined = StrandFixture.piano(work)

        #expect(dropped == [fluteID: .pan])
        #expect(joined.strands[2].dynamicMap == nil)
        #expect(joined.strands[2].instrumentTable == nil)
        #expect(joined.panMap.map(\.time) == [0])
    }

    @Test
    func joinParts_mergesPatchTablesFirstPartWinning() throws {
        var work = StrandFixture.work()
        let pianoID = StrandFixture.pianoID(work)
        let fluteID = StrandFixture.fluteID(work)
        let realizationID = try #require(work.realizations.first?.realizationID)
        let first = try makeAssignment(program: 1)
        let second = try makeAssignment(program: 2)

        work.modifyRealization(realizationID) { realization in
            realization[pianoID][Fixtures.oboe] = first
            realization[fluteID][Fixtures.oboe] = second
            realization[fluteID][Fixtures.flute] = second
        }

        try work.joinParts([pianoID, fluteID])

        let realization = try #require(work.realization(realizationID))

        #expect(realization[pianoID][Fixtures.oboe] == first)
        #expect(realization[pianoID][Fixtures.flute] == second)
        #expect(realization.partTables[fluteID] == nil)
    }

    @Test
    func joinParts_refusalsAndNoOps() throws {
        var work = StrandFixture.work()
        let unknownID = PartID()

        #expect(throws: Work.Error.unknownPartID(unknownID)) { try work.joinParts([unknownID]) }
        #expect(try work.joinParts([StrandFixture.pianoID(work)]).isEmpty)
        #expect(work.partIDs.count == 2)

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) { try work.joinParts(Set(work.partIDs)) }
    }
}

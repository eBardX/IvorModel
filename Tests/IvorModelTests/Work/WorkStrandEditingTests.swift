// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiTools

struct WorkStrandEditingTests {
}

// MARK: -

extension WorkStrandEditingTests {
    @Test
    func addStrand_appendsAnEmptyStrand() throws {
        var work = StrandFixture.work()
        let strandID = try work.addStrand(named: "Pedals", to: StrandFixture.pianoID(work))
        let piano = StrandFixture.piano(work)

        #expect(piano.strandIDs.last == strandID)
        #expect(piano.strands.map(\.name) == ["RH", "LH", "Pedals"])
        #expect(piano.strands[2].noteTable.isEmpty)
        #expect(work.content.invariantError == nil)
    }

    @Test
    func addStrand_refusals() {
        var work = StrandFixture.work()
        let unknownID = PartID()

        #expect(throws: Work.Error.unknownPartID(unknownID)) { try work.addStrand(to: unknownID) }

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) { try work.addStrand(to: StrandFixture.pianoID(work)) }
    }

    @Test
    func giveOwnTables_copyThePartsAndKeepAnExistingOne() throws {
        var work = StrandFixture.work()
        let (rightHand, leftHand) = StrandFixture.hands(work)

        try work.giveOwnDynamicMap(to: rightHand)
        try work.giveOwnDynamicMap(to: leftHand)
        try work.giveOwnInstrumentTable(to: rightHand)

        let piano = StrandFixture.piano(work)

        #expect(piano.strands[0].dynamicMap?.map(\.dynamic) == [.p])
        #expect(piano.strands[1].dynamicMap?.map(\.dynamic) == [.f])
        #expect(piano.strands[0].instrumentTable?.map(\.instrument) == [Fixtures.oboe])
    }

    @Test
    func removeOwnTables_fallBackToThePart() throws {
        var work = StrandFixture.work()
        let (rightHand, leftHand) = StrandFixture.hands(work)

        try work.giveOwnInstrumentTable(to: rightHand)
        try work.removeOwnInstrumentTable(from: rightHand)
        try work.removeOwnDynamicMap(from: leftHand)

        let piano = StrandFixture.piano(work)

        #expect(piano.strands[0].instrumentTable == nil)
        #expect(piano.strands[1].dynamicMap == nil)
    }

    @Test
    func removeStrand_removesItsNotesAndRefusesTheLast() throws {
        var work = StrandFixture.work()
        let (rightHand, leftHand) = StrandFixture.hands(work)
        let fluteStrand = try #require(work.part(StrandFixture.fluteID(work), as: Part<BeatTime, Pitch>.self)?.strandIDs.first)

        try work.removeStrand(leftHand)

        #expect(StrandFixture.piano(work).strandIDs == [rightHand])
        #expect(throws: Work.Error.lastStrand(rightHand)) { try work.removeStrand(rightHand) }
        #expect(throws: Work.Error.lastStrand(fluteStrand)) { try work.removeStrand(fluteStrand) }
        #expect(throws: Work.Error.unknownStrandID(leftHand)) { try work.removeStrand(leftHand) }
    }

    @Test
    func renameSetExtrasAndShift() throws {
        var work = StrandFixture.work()
        let (rightHand, leftHand) = StrandFixture.hands(work)
        let extras = Extras(elements: [Extra(name: Extra.exportStaff.name, values: [.int(2)])])

        try work.renameStrand(rightHand, to: " Right ")
        try work.setExtras(extras, ofStrand: leftHand)
        try work.shiftStrand(leftHand, to: -5)

        let piano = StrandFixture.piano(work)

        #expect(piano.strandIDs == [leftHand, rightHand])
        #expect(piano.strands[1].name == "Right")
        #expect(piano.strands[0].extras == extras)

        try work.shiftStrand(leftHand, to: 99)

        #expect(StrandFixture.piano(work).strandIDs == [rightHand, leftHand])
    }

    @Test
    func strandEdits_lockedWork_throw() {
        var work = StrandFixture.work()
        let (rightHand, _) = StrandFixture.hands(work)

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) { try work.renameStrand(rightHand, to: "R") }
        #expect(throws: Work.Error.workIsLocked) { try work.removeEmptyStrands() }
    }

    @Test
    func removeEmptyStrands_removesOnlyEmptyStrandsInScope() throws {
        var work = StrandFixture.work()
        let pianoID = StrandFixture.pianoID(work)
        let fluteID = StrandFixture.fluteID(work)
        let pedals = try work.addStrand(named: "Pedals", to: pianoID)
        let divisi = try work.addStrand(named: "div.", to: fluteID)
        var scoped = work

        #expect(try scoped.removeEmptyStrands(scope: Work.Scope(parts: [pianoID])) == [pedals])
        #expect(scoped.part(fluteID, as: Part<BeatTime, Pitch>.self)?.strandIDs.contains(divisi) == true)
        #expect(try work.removeEmptyStrands() == [pedals, divisi])
        #expect(StrandFixture.piano(work).strands.count == 2)
    }

    @Test
    func removeEmptyStrands_neverEmptiesAPart() throws {
        var work = Work(content: .standardBeat([Part(name: "Empty")], TempoMap(), MeterTable(), KeyTable()))
        let partID = work.partIDs[0]
        let first = try #require(work.part(partID, as: Part<BeatTime, Pitch>.self)?.strandIDs.first)
        let second = try work.addStrand(to: partID)

        #expect(try work.removeEmptyStrands() == [second])
        #expect(work.part(partID, as: Part<BeatTime, Pitch>.self)?.strandIDs == [first])
    }

    @Test
    func errors_haveMessages() {
        let strandID = StrandID()

        #expect(Work.Error.lastStrand(strandID).message.contains(strandID.stringValue))
        #expect(Work.Error.scopeOutsideStrand(strandID).message.contains(strandID.stringValue))
        #expect(!Work.Error.strandsInDifferentParts.message.isEmpty)
    }
}

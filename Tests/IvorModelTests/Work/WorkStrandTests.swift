// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct WorkStrandTests {
}

// MARK: -

extension WorkStrandTests {
    @Test
    func addPart_givesOneEmptyUnnamedStrand() throws {
        var work = Work(content: .standardBeat([], TempoMap(), MeterTable(), KeyTable()))
        let partID = try work.addPart(name: "Flute")
        let part = try #require(work.part(partID, as: Part<BeatTime, Pitch>.self))

        #expect(part.strands.count == 1)
        #expect(part.strands[0].name.isEmpty)
        #expect(part.noteCount == 0)
    }

    @Test
    func convert_keepsStrandsAndConvertsTheirOwnTables() throws {
        let work = Work(content: .standardBeat([Self._piano()], TempoMap(), MeterTable(), KeyTable()))
        let converted = try #require(try work.convert(timeBasis: .wall,
                                                      pitchNotation: .standard))

        guard case let .standardWall(parts) = converted.content.cases
        else { Issue.record("Expected standard wall content"); return }

        let part = try #require(parts.first)

        #expect(part.strandIDs == Self._strandIDs(of: work))
        #expect(part.strands.map(\.noteTable.count) == [2, 1])
        #expect(part.strands[1].dynamicMap?.count == 1)
    }

    @Test
    func errors_haveMessages() {
        let strandID = StrandID()
        let partID = PartID()

        #expect(Work.Error.duplicateStrandID(strandID).message.contains(strandID.stringValue))
        #expect(Work.Error.partHasNoStrands(partID).message.contains(partID.stringValue))
    }

    @Test
    func keyTable_forAStrand_isTheWorks() throws {
        let keyTable = try makeKeyTable([(0, 2)])
        let work = Work(content: .standardBeat([Self._piano()], TempoMap(), MeterTable(), keyTable))

        #expect(work.keyTable(for: Self._strandIDs(of: work)[1]) == keyTable)
        #expect(Work(content: .standardWall([])).keyTable(for: StrandID()) == nil)
    }

    @Test
    func modifyStrand_editsTheStrandInWhicheverPart() throws {
        var work = Work(content: .standardBeat([Part(name: "Flute"), Self._piano()], TempoMap(), MeterTable(), KeyTable()))
        let leftHand = Self._strandIDs(of: work)[2]

        let noteID = try work.modifyStrand(leftHand, as: Strand<BeatTime, Pitch>.self) {
            $0.noteTable.insert(attack: 4, duration: 1, pitch: .g3)
        }

        #expect(noteID != nil)
        #expect(work.strand(leftHand, as: Strand<BeatTime, Pitch>.self)?.noteTable.count == 2)
        #expect(try work.modifyStrand(StrandID(), as: Strand<BeatTime, Pitch>.self) { _ in } == nil)
        #expect(try work.modifyStrand(leftHand, as: Strand<WallTime, Pitch>.self) { _ in } == nil)
    }

    @Test
    func modifyStrand_lockedWork_throws() {
        var work = Work(content: .standardBeat([Self._piano()], TempoMap(), MeterTable(), KeyTable()))
        let leftHand = Self._strandIDs(of: work)[1]

        work.isLocked = true

        #expect(throws: Work.Error.workIsLocked) {
            try work.modifyStrand(leftHand, as: Strand<BeatTime, Pitch>.self) { $0.name = "Left" }
        }
    }

    @Test
    func modifyStrand_sharedNoteID_throwsAndLeavesWork() throws {
        var work = Work(content: .standardBeat([Self._piano()], TempoMap(), MeterTable(), KeyTable()))
        let strandIDs = Self._strandIDs(of: work)
        let rightHand = try #require(work.strand(strandIDs[0], as: Strand<BeatTime, Pitch>.self))
        let sharedID = try #require(rightHand.noteTable.first?.noteID)

        #expect(throws: Work.Error.duplicateNoteID(sharedID)) {
            try work.modifyStrand(strandIDs[1], as: Strand<BeatTime, Pitch>.self) {
                $0.noteTable.merge(with: rightHand.noteTable)
            }
        }
        #expect(work.strand(strandIDs[1], as: Strand<BeatTime, Pitch>.self)?.noteTable.count == 1)
    }

    @Test
    func rendered_keepsStrandsApart() throws {
        let work = Work(content: .standardBeat([Self._piano()], TempoMap(), MeterTable(), KeyTable()))
        let rendered = try work.rendered().work

        guard case let .standardBeat(parts, _, _, _) = rendered.content.cases
        else { Issue.record("Expected standard beat content"); return }

        let part = try #require(parts.first)

        #expect(part.strandIDs == Self._strandIDs(of: work))
        #expect(part.strands.map { $0.noteTable.map(\.startPitch) } == [[.e4, .g4], [.c3]])
    }

    @Test
    func replaceContent_duplicateStrandID_throws() throws {
        var work = Work(content: .standardBeat([], TempoMap(), MeterTable(), KeyTable()))
        let strand = Strand<BeatTime, Pitch>()
        let violin = Part(name: "Violin", strands: [strand])
        let viola = Part(name: "Viola", strands: [strand])

        #expect(throws: Work.Error.duplicateStrandID(strand.strandID)) {
            try work.replaceContent(with: .standardBeat([violin, viola], TempoMap(), MeterTable(), KeyTable()))
        }
        #expect(work.partIDs.isEmpty)
    }

    @Test
    func replaceContent_partWithNoStrands_throws() throws {
        var work = Work(content: .standardBeat([], TempoMap(), MeterTable(), KeyTable()))
        let part = Part<BeatTime, Pitch>(partID: PartID(), name: "Empty", strands: [])

        #expect(throws: Work.Error.partHasNoStrands(part.partID)) {
            try work.replaceContent(with: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))
        }
    }

    // MARK: Private Type Methods

    private static func _piano() -> Part<BeatTime, Pitch> {
        var rightHand = NoteTable<BeatTime, Pitch>()
        var leftHand = NoteTable<BeatTime, Pitch>()
        var leftDynamics = DynamicMap<BeatTime>()

        rightHand.insert(attack: 0, duration: 1, pitch: .e4)
        rightHand.insert(attack: 1, duration: 1, pitch: .g4)
        leftHand.insert(attack: 1, duration: 2, pitch: .c3)
        leftDynamics.insert(time: 1, dynamic: .p)

        return Part(name: "Piano",
                    strands: [Strand(name: "RH", noteTable: rightHand),
                              Strand(name: "LH", noteTable: leftHand, dynamicMap: leftDynamics)])
    }

    private static func _strandIDs(of work: Work) -> [StrandID] {
        work.content.body.strandIDs
    }
}

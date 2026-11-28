// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

//
// A template source is a scope within one part: its chosen strands, or notes of them, are
// merged into one note sequence before analysis.
//
// The fixture's piano has a right hand (E4 at 0, G4 at 3, a beat each) and a left hand (C3
// at 1, two beats, with its own dynamic map at f); the piano's own dynamic is p. The flute
// has a C5 at 0.
//

struct TemplateStrandSourceTests {
}

// MARK: - Analysis

extension TemplateStrandSourceTests {
    @Test
    func twoStrands_analyzeAsOneMergedStrand() throws {
        let work = Self._work()
        let stranded = try Template.analyzeNoteEvents(in: work,
                                                      scope: Work.Scope(parts: [Self._pianoID(work)]),
                                                      maximumOrder: 1,
                                                      name: "Piano")
        let merged = try Template.analyzeNoteEvents(in: makeStandardBeatWork([(0, 1, .e4), (1, 2, .c3), (3, 1, .g4)]),
                                                    scope: .all,
                                                    maximumOrder: 1,
                                                    name: "Piano")

        #expect(try jointNoteEvents(of: stranded) == jointNoteEvents(of: merged))
        #expect(try Self._pitches(of: stranded) == [.c3, .e4, .g4])
    }

    @Test
    func oneStrandOfTwo_learnsOnlyThatStrand() throws {
        let work = Self._work()
        let (rightHand, _) = Self._hands(work)
        let template = try Template.analyzeNoteEvents(in: work,
                                                      scope: Work.Scope(strands: [rightHand]),
                                                      maximumOrder: 1,
                                                      name: "RH")
        let source = try #require(template.sources.first)

        #expect(try Self._pitches(of: template) == [.e4, .g4])
        #expect(source.partID == Self._pianoID(work))
        #expect(source.strands == [Template.SourceStrand(strandID: rightHand, name: "RH")])
        #expect(!source.isNoteSelection)
    }

    @Test
    func wholePart_recordsEveryStrandInScoreOrder() throws {
        let work = Self._work()
        let (rightHand, leftHand) = Self._hands(work)
        let template = try Template.analyzeNoteEvents(in: work,
                                                      scope: Work.Scope(strands: [leftHand, rightHand]),
                                                      maximumOrder: 1,
                                                      name: "Piano")
        let source = try #require(template.sources.first)

        #expect(source.partName == "Piano")
        #expect(source.strands.map(\.strandID) == [rightHand, leftHand])
        #expect(source.strands.map(\.name) == ["RH", "LH"])
        #expect(!source.isNoteSelection)
    }

    @Test
    func noteSelection_learnsOnlyThoseNotes() throws {
        let work = Self._work()
        let piano = Self._piano(work)
        let g4 = try #require(piano.strands[0].noteTable.last?.noteID)
        let c3 = try #require(piano.strands[1].noteTable.first?.noteID)
        let template = try Template.analyzeNoteEvents(in: work,
                                                      scope: Work.Scope(notes: [g4, c3]),
                                                      maximumOrder: 1,
                                                      name: "Some")
        let source = try #require(template.sources.first)

        #expect(try Self._pitches(of: template) == [.c3, .g4])
        #expect(source.isNoteSelection)
        #expect(source.strands.map(\.strandID) == piano.strandIDs)
    }

    @Test
    func restsAreWhereNoChosenStrandSounds() throws {
        let work = Self._work()
        let (rightHand, _) = Self._hands(work)
        let options = Template.AnalysisOptions(maximumOrder: 1, restSplit: .beat(beats(1)))

        //
        // The right hand rests from 1 to 3, while the left hand plays.
        //
        #expect(try Template.sequenceCount(in: work, scope: Work.Scope(parts: [Self._pianoID(work)]), options: options) == 1)
        #expect(try Template.sequenceCount(in: work, scope: Work.Scope(strands: [rightHand]), options: options) == 2)
    }

    @Test
    func adding_appendsTheNewSourcesStrands() throws {
        let work = Self._work()
        let (rightHand, leftHand) = Self._hands(work)
        let template = try Template.analyzeNoteEvents(in: work,
                                                      scope: Work.Scope(strands: [rightHand]),
                                                      maximumOrder: 1,
                                                      name: "RH")
        let added = try template.adding(Work.Scope(strands: [leftHand]), of: work, name: "Both")

        #expect(added.sources.map { $0.strands.map(\.strandID) } == [[rightHand], [leftHand]])
        #expect(try Self._pitches(of: added) == [.c3, .e4, .g4])
    }
}

// MARK: - Source context

extension TemplateStrandSourceTests {
    @Test
    func context_readsThroughTheLeadingStrandsOwnTables() throws {
        let work = Self._work()
        let (rightHand, leftHand) = Self._hands(work)
        let pianoID = Self._pianoID(work)

        func dynamic(_ scope: Work.Scope) throws -> Dynamic {
            try Template.analyzeNoteEvents(in: work, scope: scope, maximumOrder: 1, name: "T").sourceContext.dynamic
        }

        //
        // The right hand attacks first, at 0, and has no dynamic map of its own; the left hand,
        // alone, reads its own.
        //
        #expect(try dynamic(Work.Scope(parts: [pianoID])) == .p)
        #expect(try dynamic(Work.Scope(strands: [rightHand])) == .p)
        #expect(try dynamic(Work.Scope(strands: [leftHand])) == .f)
    }

    @Test
    func context_tieGoesToTheFirstStrand() throws {
        var work = Self._work(leftAttack: 0)
        let (_, leftHand) = Self._hands(work)
        let scope = Work.Scope(parts: [Self._pianoID(work)])

        //
        // Both hands attack at 0: the right hand first in score order, then the left.
        //
        #expect(try Template.analyzeNoteEvents(in: work, scope: scope, maximumOrder: 1, name: "T").sourceContext.dynamic == .p)

        try work.shiftStrand(leftHand, to: 0)

        #expect(try Template.analyzeNoteEvents(in: work, scope: scope, maximumOrder: 1, name: "T").sourceContext.dynamic == .f)
    }

    @Test
    func context_selectionIsReadAtItsFirstAttack() throws {
        let work = Self._work()
        let piano = Self._piano(work)
        let g4 = try #require(piano.strands[0].noteTable.last?.noteID)
        let c3 = try #require(piano.strands[1].noteTable.first?.noteID)

        //
        // The selection's first attack is the left hand's C3, at 1.
        //
        let context = try Template.analyzeNoteEvents(in: work,
                                                     scope: Work.Scope(notes: [g4, c3]),
                                                     maximumOrder: 1,
                                                     name: "T").sourceContext

        #expect(context.dynamic == .f)
        #expect(context.instrument == Fixtures.oboe)
    }
}

// MARK: - Refusals and generation

extension TemplateStrandSourceTests {
    @Test
    func scopes_refused() throws {
        let work = Self._work()
        let (rightHand, _) = Self._hands(work)
        let fluteNote = try #require(work.part(work.partIDs[1], as: Part<BeatTime, Pitch>.self)?.strands[0].noteTable.first?.noteID)
        let noteID = NoteID()
        let strandID = StrandID()

        func analyze(_ scope: Work.Scope) throws(Template.Error) {
            _ = try Template.analyzeNoteEvents(in: work, scope: scope, maximumOrder: 1, name: "T")
        }

        #expect(throws: Template.Error.sourceSpansParts) { try analyze(.all) }
        #expect(throws: Template.Error.sourceSpansParts) { try analyze(Work.Scope(strands: [rightHand]).union(Work.Scope(notes: [fluteNote]))) }
        #expect(throws: Template.Error.sourceIsEmpty) { try analyze(Work.Scope(parts: [])) }
        #expect(throws: Template.Error.strandNotFound(strandID)) { try analyze(Work.Scope(strands: [strandID])) }
        #expect(throws: Template.Error.noteNotFound(noteID)) { try analyze(Work.Scope(notes: [noteID])) }
    }

    @Test
    func generation_makesOnePartWithOneUnnamedStrand() throws {
        let work = Self._work()
        let template = try Template.analyzeNoteEvents(in: work,
                                                      scope: Work.Scope(parts: [Self._pianoID(work)]),
                                                      maximumOrder: 1,
                                                      name: "Piano")
        let generated = try template.generateWork(name: "New", partName: "Melody", order: 1, limit: 4)
        let part = try #require(generated.part(generated.partIDs[0], as: Part<BeatTime, Pitch>.self))

        #expect(generated.partCount == 1)
        #expect(part.strands.count == 1)
        #expect(part.strands[0].name.isEmpty)
        #expect(part.strands[0].dynamicMap == nil)
    }
}

// MARK: - Private Type Methods

extension TemplateStrandSourceTests {
    private static func _hands(_ work: Work) -> (StrandID, StrandID) {
        let strandIDs = _piano(work).strandIDs

        return (strandIDs[0], strandIDs[1])
    }

    private static func _piano(_ work: Work) -> Part<BeatTime, Pitch> {
        // swiftlint:disable:next force_unwrapping
        work.part(_pianoID(work), as: Part<BeatTime, Pitch>.self)!
    }

    private static func _pianoID(_ work: Work) -> PartID {
        work.partIDs[0]
    }

    private static func _pitches(of template: Template) throws -> Set<Pitch> {
        guard case let .standardBeat(model) = template.content
        else { throw Template.Error.incompatibleOptions }

        return Set(model.vocabulary.pitches.keys)
    }

    private static func _work(leftAttack: Number = 1) -> Work {
        var rightNotes = NoteTable<BeatTime, Pitch>()
        var leftNotes = NoteTable<BeatTime, Pitch>()
        var fluteNotes = NoteTable<BeatTime, Pitch>()
        var leftDynamics = DynamicMap<BeatTime>()
        var pianoDynamics = DynamicMap<BeatTime>()
        var instruments = InstrumentTable<BeatTime>()

        rightNotes.insert(attack: beatTime(0), duration: beats(1), pitch: .e4)
        rightNotes.insert(attack: beatTime(3), duration: beats(1), pitch: .g4)
        leftNotes.insert(attack: beatTime(leftAttack), duration: beats(2), pitch: .c3)
        fluteNotes.insert(attack: beatTime(0), duration: beats(1), pitch: .c5)
        leftDynamics.insert(time: .zero, dynamic: .f)
        pianoDynamics.insert(time: .zero, dynamic: .p)
        instruments.insert(time: .zero, instrument: Fixtures.oboe)

        let piano = Part(name: "Piano",
                         strands: [Strand(name: "RH", noteTable: rightNotes),
                                   Strand(name: "LH", noteTable: leftNotes, dynamicMap: leftDynamics)],
                         dynamicMap: pianoDynamics,
                         instrumentTable: instruments)

        return Work(name: "Duet",
                    content: .standardBeat([piano, Part(name: "Flute", noteTable: fluteNotes)],
                                           TempoMap(),
                                           MeterTable(),
                                           KeyTable()))
    }
}

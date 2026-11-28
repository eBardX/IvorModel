// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct WorkScopeTests {
}

// MARK: - Resolution

extension WorkScopeTests {
    @Test
    func resolved_all_takesEveryPartWhole() throws {
        let work = Self._work()
        let resolution = try Work.Scope.all.resolved(in: work.content.body)

        #expect(resolution.selections == [Self._pianoID(work): .whole, Self._fluteID(work): .whole])
        #expect(resolution.coversWork)
    }

    @Test
    func resolved_everyPartNamed_coversTheWork() throws {
        let work = Self._work()
        let resolution = try Work.Scope(parts: work.partIDs).resolved(in: work.content.body)

        #expect(resolution.coversWork)
    }

    @Test
    func resolved_oneStrand_takesOnlyThatStrand() throws {
        let work = Self._work()
        let (rightHand, _) = Self._hands(work)
        let resolution = try Work.Scope(strands: [rightHand]).resolved(in: work.content.body)

        #expect(resolution.selections == [Self._pianoID(work): .strands([rightHand: .whole])])
        #expect(!resolution.coversWork)
    }

    @Test
    func resolved_wholesAddUp() throws {
        let work = Self._work()
        let (rightHand, leftHand) = Self._hands(work)
        let scope = Work.Scope(strands: [rightHand]).union(Work.Scope(strands: [leftHand]))
        let resolution = try scope.resolved(in: work.content.body)

        #expect(resolution.selections == [Self._pianoID(work): .whole])
    }

    @Test
    func resolved_notesNeverAddUp() throws {
        let work = Self._work()
        let piano = Self._piano(work)
        let noteIDs = Set(piano.strands[0].noteTable.map(\.noteID))
        let resolution = try Work.Scope(notes: noteIDs).resolved(in: work.content.body)

        #expect(resolution.selections == [piano.partID: .strands([piano.strandIDs[0]: .notes(noteIDs)])])
    }

    @Test
    func resolved_mixes_wholeAbsorbsItsParts() throws {
        let work = Self._work()
        let piano = Self._piano(work)
        let rightHandNote = try #require(piano.strands[0].noteTable.first?.noteID)
        let leftHandNote = try #require(piano.strands[1].noteTable.first?.noteID)
        let scope = Work.Scope(strands: [piano.strandIDs[0]])
            .union(Work.Scope(notes: [rightHandNote, leftHandNote]))
            .union(Work.Scope(parts: [Self._fluteID(work)]))
        let resolution = try scope.resolved(in: work.content.body)

        #expect(resolution.selections == [piano.partID: .strands([piano.strandIDs[0]: .whole,
                                                                  piano.strandIDs[1]: .notes([leftHandNote])]),
                                          Self._fluteID(work): .whole])
    }

    @Test
    func resolved_unknownIDs_throw() {
        let body = Self._work().content.body
        let partID = PartID()
        let strandID = StrandID()
        let noteID = NoteID()

        #expect(throws: Work.Error.unknownPartID(partID)) { try Work.Scope(parts: [partID]).resolved(in: body) }
        #expect(throws: Work.Error.unknownStrandID(strandID)) { try Work.Scope(strands: [strandID]).resolved(in: body) }
        #expect(throws: Work.Error.unknownNoteID(noteID)) { try Work.Scope(notes: [noteID]).resolved(in: body) }
    }

    @Test
    func isEmpty_andUnion() {
        #expect(Work.Scope(parts: []).isEmpty)
        #expect(!Work.Scope.all.isEmpty)
        #expect(Work.Scope(parts: []).union(.all) == .all)
    }
}

// MARK: - The table rule

extension WorkScopeTests {
    @Test
    func tableRule_wholeWork_carriesEverything() throws {
        var work = Self._work()

        try work.move(by: later(1))

        let piano = Self._piano(work)

        #expect(work.tempoMap?.map(\.beatTime) == [1, 3])
        #expect(piano.dynamicMap.map(\.time) == [1])
        #expect(piano.strands[1].dynamicMap?.map(\.time) == [2])
        #expect(piano.pedals[.sustain]?.map(\.time) == [1, 3])
        #expect(piano.panMap.map(\.time) == [1])
    }

    @Test
    func tableRule_somePartsWhole_leavesWorkTablesUnlessOptedIn() throws {
        var work = Self._work()
        var optedIn = work
        let scope = Work.Scope(parts: [Self._pianoID(work)])

        try work.move(by: later(1), scope: scope)
        try optedIn.move(by: later(1), alsoCarry: .tempo, scope: scope)

        #expect(work.tempoMap?.map(\.beatTime) == [0, 2])
        #expect(Self._piano(work).pedals[.sustain]?.map(\.time) == [1, 3])
        #expect(optedIn.tempoMap?.map(\.beatTime) == [1, 3])
    }

    @Test
    func tableRule_strandUsingThePartsMap_carriesItButNotPedalsOrPan() throws {
        var work = Self._work()
        let (rightHand, _) = Self._hands(work)

        try work.move(by: later(1), scope: Work.Scope(strands: [rightHand]))

        let piano = Self._piano(work)

        //
        // The right hand is the only strand without its own dynamic map, so the part's is its
        // alone; the pedals and pan are the whole part's.
        //
        #expect(piano.strands[0].noteTable.map(\.attack) == [1, 2].map(beatTime))
        #expect(piano.strands[1].noteTable.map(\.attack) == [1].map(beatTime))
        #expect(piano.dynamicMap.map(\.time) == [1])
        #expect(piano.strands[1].dynamicMap?.map(\.time) == [1])
        #expect(piano.pedals[.sustain]?.map(\.time) == [0, 2])
        #expect(piano.panMap.map(\.time) == [0])
    }

    @Test
    func tableRule_strandWithItsOwnMap_carriesOnlyThat() throws {
        var work = Self._work()
        let (_, leftHand) = Self._hands(work)

        try work.move(by: later(1), scope: Work.Scope(strands: [leftHand]))

        let piano = Self._piano(work)

        #expect(piano.strands[1].noteTable.map(\.attack) == [2].map(beatTime))
        #expect(piano.strands[1].dynamicMap?.map(\.time) == [2])
        #expect(piano.dynamicMap.map(\.time) == [0])
    }

    @Test
    func tableRule_partsMapUsedByTwoStrands_needsBoth() throws {
        var rightHand = NoteTable<BeatTime, Pitch>()
        var leftHand = NoteTable<BeatTime, Pitch>()
        var dynamics = DynamicMap<BeatTime>()

        rightHand.insert(attack: 0, duration: 1, pitch: .e4)
        leftHand.insert(attack: 0, duration: 1, pitch: .c3)
        dynamics.insert(time: 0, dynamic: .p)

        let part = Part(name: "Piano",
                        strands: [Strand(noteTable: rightHand), Strand(noteTable: leftHand)],
                        dynamicMap: dynamics)
        var work = Work(content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))
        var optedIn = work

        try work.move(by: later(1), scope: Work.Scope(strands: [part.strandIDs[0]]))
        try optedIn.move(by: later(1), alsoCarry: .dynamic, scope: Work.Scope(strands: [part.strandIDs[0]]))

        #expect(work.part(part.partID, as: Part<BeatTime, Pitch>.self)?.dynamicMap.map(\.time) == [0])
        #expect(optedIn.part(part.partID, as: Part<BeatTime, Pitch>.self)?.dynamicMap.map(\.time) == [1])
    }

    @Test
    func tableRule_someNotes_carryTheirOwnMapsEntriesOnly() throws {
        var work = Self._work()
        let piano = Self._piano(work)
        let leftHandNote = try #require(piano.strands[1].noteTable.first?.noteID)
        var optedIn = work

        try work.move(by: later(1), scope: Work.Scope(notes: [leftHandNote]))
        try optedIn.move(by: later(1), alsoCarry: .pedal, scope: Work.Scope(notes: [leftHandNote]))

        let moved = Self._piano(work)

        //
        // The left hand's note at 1 takes its own map's entry at 1 along; the pedals stay,
        // unless opted in, when only their entries in the note's range (and the release of a
        // press under way at its end) move.
        //
        #expect(moved.strands[1].noteTable.map(\.attack) == [2].map(beatTime))
        #expect(moved.strands[1].dynamicMap?.map(\.time) == [2])
        #expect(moved.pedals[.sustain]?.map(\.time) == [0, 2])
        #expect(Self._piano(optedIn).pedals[.sustain]?.map(\.time) == [0, 3])
    }

    @Test
    func transpose_oneStrand_leavesTheOtherAndTheDynamics() throws {
        var work = Self._work()
        let (rightHand, _) = Self._hands(work)

        try work.transpose(by: DirectedInterval(interval: Interval.perfect8, direction: .ascending), scope: Work.Scope(strands: [rightHand]))

        let piano = Self._piano(work)

        #expect(piano.strands[0].noteTable.map(\.startPitch) == [.e5, .g5])
        #expect(piano.strands[1].noteTable.map(\.startPitch) == [.c3])
        #expect(piano.dynamicMap.map(\.dynamic) == [.p])
        #expect(piano.strands[1].dynamicMap?.map(\.dynamic) == [.f])
    }
}

// MARK: - Defaults

extension WorkScopeTests {
    @Test
    func augment_noteScope_anchorsAtTheFirstChosenNote() throws {
        var work = Self._work()
        let piano = Self._piano(work)
        let secondNote = try #require(piano.strands[0].noteTable.last?.noteID)

        try work.augment(by: 2, anchor: nil as BeatTime?, scope: Work.Scope(notes: [secondNote]))

        let note = try #require(Self._piano(work).strands[0].noteTable.last)

        #expect(note.attack == beatTime(1))
        #expect(note.duration == beats(2))
    }

    @Test
    func reverse_noteScope_mirrorsWithinTheNotesExtent() throws {
        var work = Self._work()
        let piano = Self._piano(work)
        let noteIDs = piano.strands[0].noteTable.map(\.noteID)

        try work.reverse(within: nil as ClosedRange<BeatTime>?, scope: Work.Scope(notes: noteIDs))

        #expect(Self._piano(work).strands[0].noteTable.map(\.startPitch) == [.g4, .e4])
        #expect(Self._piano(work).strands[0].noteTable.map(\.attack) == [0, 1].map(beatTime))
    }
}

// MARK: - Finding notes

extension WorkScopeTests {
    @Test
    func scopeMatching_byAttackOrSounding() throws {
        let work = Self._work()
        let byAttack = Work.Scope.Criteria<BeatTime, Pitch>(timeRange: beatTime(frac(1, 2))...beatTime(1))
        let bySounding = Work.Scope.Criteria<BeatTime, Pitch>(timeRange: beatTime(frac(1, 2))...beatTime(1),
                                                              timeMatch: .sounding)

        #expect(try Self._pitches(work, work.scope(matching: byAttack)) == [.c3, .g4])
        #expect(try Self._pitches(work, work.scope(matching: bySounding)) == [.c3, .e4, .g4, .c5])
    }

    @Test
    func scopeMatching_byStartEndOrEither() throws {
        var work = Self._work()
        let fluteID = Self._fluteID(work)

        _ = try work.modifyPart(fluteID, as: Part<BeatTime, Pitch>.self) { part in
            part.strands[0].noteTable.insert(attack: 2, duration: 1, startPitch: .c4, endPitch: .c6)
        }

        let range = Pitch.c6...Pitch.c6
        let start = try work.scope(matching: Work.Scope.Criteria<BeatTime, Pitch>(pitchRange: range, pitchMatch: .start))
        let end = try work.scope(matching: Work.Scope.Criteria<BeatTime, Pitch>(pitchRange: range, pitchMatch: .end))
        let either = try work.scope(matching: Work.Scope.Criteria<BeatTime, Pitch>(pitchRange: Pitch.c4...Pitch.c4))

        #expect(try Self._pitches(work, start).isEmpty)
        #expect(try Self._pitches(work, end) == [.c4])
        #expect(try Self._pitches(work, either) == [.c4])
    }

    @Test
    func scopeMatching_withinAScope_andMismatchedTypes() throws {
        let work = Self._work()
        let (_, leftHand) = Self._hands(work)
        let everything = Work.Scope.Criteria<BeatTime, Pitch>()

        #expect(try Self._pitches(work, work.scope(matching: everything, within: Work.Scope(strands: [leftHand]))) == [.c3])
        #expect(throws: Work.Error.timeBasisMismatch(expected: .beat)) {
            try work.scope(matching: Work.Scope.Criteria<WallTime, Pitch>())
        }
        #expect(throws: Work.Error.pitchNotationMismatch(expected: .standard)) {
            try work.scope(matching: Work.Scope.Criteria<BeatTime, NoteNumber>())
        }
    }

    // MARK: Private Type Methods

    private static func _fluteID(_ work: Work) -> PartID {
        work.partIDs[1]
    }

    private static func _hands(_ work: Work) -> (StrandID, StrandID) {
        let strandIDs = _piano(work).strandIDs

        return (strandIDs[0], strandIDs[1])
    }

    private static func _piano(_ work: Work) -> Part<BeatTime, Pitch> {
        // swiftlint:disable:next force_unwrapping
        work.part(work.partIDs[0], as: Part<BeatTime, Pitch>.self)!
    }

    private static func _pianoID(_ work: Work) -> PartID {
        work.partIDs[0]
    }

    //
    // The start pitches of the notes `scope` names, in pitch order.
    //
    private static func _pitches(_ work: Work,
                                 _ scope: Work.Scope) throws -> [Pitch] {
        let resolution = try scope.resolved(in: work.content.body)
        guard case let .standardBeat(parts, _, _, _) = work.content.cases
        else { throw Work.Error.timeBasisMismatch(expected: .beat) }

        return parts.flatMap { part -> [Pitch] in
            guard let selection = resolution.selections[part.partID]
            else { return [] }

            let plan = part.carryPlan(for: selection, applyTo: [], alsoCarry: [])

            return zip(part.strands, plan.strandSelections).flatMap { strand, strandSelection -> [Pitch] in
                guard let strandSelection
                else { return [] }

                return strand.noteTable.filter { strandSelection.noteIDs?.contains($0.noteID) ?? true }.map(\.startPitch)
            }
        }.sorted()
    }

    //
    // A piano and a flute. The piano's right hand (E4 at 0, G4 at 1) uses the part's dynamic
    // map (p at 0); its left hand (C3 at 1) has its own (f at 1). The piano has a sustain press
    // from 0 to 2 and a pan entry at 0. The flute plays C5 from 0 to 2. The tempo map has
    // entries at 0 and 2.
    //
    private static func _work() -> Work {
        var rightHand = NoteTable<BeatTime, Pitch>()
        var leftHand = NoteTable<BeatTime, Pitch>()
        var partDynamics = DynamicMap<BeatTime>()
        var leftDynamics = DynamicMap<BeatTime>()
        var sustain = PedalTable<BeatTime>()
        var fluteNotes = NoteTable<BeatTime, Pitch>()
        var tempoMap = TempoMap()

        rightHand.insert(attack: 0, duration: 1, pitch: .e4)
        rightHand.insert(attack: 1, duration: 1, pitch: .g4)
        leftHand.insert(attack: 1, duration: 1, pitch: .c3)
        partDynamics.insert(time: 0, dynamic: .p)
        leftDynamics.insert(time: 1, dynamic: .f)
        sustain.insert(time: 0, level: .down)
        sustain.insert(time: 2, level: .up)
        fluteNotes.insert(attack: 0, duration: 2, pitch: .c5)
        tempoMap.insert(beatTime: 0, tempo: .default)
        tempoMap.insert(beatTime: 2, tempo: .default)

        var piano = Part(name: "Piano",
                         strands: [Strand(name: "RH", noteTable: rightHand),
                                   Strand(name: "LH", noteTable: leftHand, dynamicMap: leftDynamics)],
                         dynamicMap: partDynamics)

        piano.pedals[.sustain] = sustain
        piano.panMap.insert(time: 0, pan: .center)

        return Work(content: .standardBeat([piano, Part(name: "Flute", noteTable: fluteNotes)],
                                           tempoMap,
                                           MeterTable(),
                                           KeyTable()))
    }
}

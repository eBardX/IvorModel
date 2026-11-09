// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

//
// A template's source context: the setting its first source part started in, recorded at
// analysis and carried over to the works it generates.
//
struct TemplateSourceContextTests {
}

// MARK: -

extension TemplateSourceContextTests {
    @Test
    func adding_keepsOriginalContext() throws {
        let original = makeSourceContextWork(instrument: Fixtures.flute)
        let other = makeSourceContextWork(instrument: Fixtures.oboe)
        let template = try Template.analyzeNoteEvents(in: original, at: 0, maximumOrder: 1, name: "Test")
        let added = try template.adding(partAt: 0, of: other, name: "Both")

        #expect(added.sourceContext == template.sourceContext)
        #expect(added.sourceContext.instrument == Fixtures.flute)
    }

    @Test
    func analyze_beatWork_recordsSettingAtFirstAttack() throws {
        let template = try Template.analyzeNoteEvents(in: makeSourceContextWork(), at: 0, maximumOrder: 1, name: "Test")
        let context = template.sourceContext

        #expect(context.dynamic == .f)
        #expect(context.instrument == Fixtures.oboe)
        #expect(context.pan == Fixtures.leftPan)
        #expect(context.tempo == Fixtures.slowTempo)
    }

    @Test
    func analyze_wallWork_hasNoTempo() throws {
        var noteTable = NoteTable<WallTime, Pitch>()

        // swiftlint:disable:next force_unwrapping
        noteTable.insert(attack: .zero, duration: WallDuration(uintValue: 1_000_000)!, pitch: .c4)

        var dynamicMap = DynamicMap<WallTime>()

        dynamicMap.insert(time: .zero, dynamic: .pp)

        let work = Work(name: "Wall",
                        content: .standardWall([Part(name: "Voice",
                                                     noteTable: noteTable,
                                                     dynamicMap: dynamicMap)]))
        let template = try Template.analyzeNoteEvents(in: work, at: 0, maximumOrder: 1, name: "Test")

        #expect(template.sourceContext.tempo == nil)
        #expect(template.sourceContext.dynamic == .pp)
    }

    @Test
    func generate_defaultContext_leavesMapsEmpty() throws {
        let template = try Template.analyzeNoteEvents(in: makePlainSourceWork(), at: 0, maximumOrder: 1, name: "Test")

        #expect(template.sourceContext == Template.SourceContext(tempo: .default))

        let generated = try template.generateWork(name: "Out", partName: "Part", order: 1, limit: 4)

        guard case let .standardBeat(parts, tempoMap) = generated.content
        else { Issue.record("not standard beat"); return }

        let part = try #require(parts.first)

        #expect(part.dynamicMap.isEmpty)
        #expect(part.instrumentTable.isEmpty)
        #expect(part.panMap.isEmpty)
        #expect(tempoMap.isEmpty)
    }

    @Test
    func generate_startsInSourceContext() throws {
        let template = try Template.analyzeNoteEvents(in: makeSourceContextWork(), at: 0, maximumOrder: 1, name: "Test")
        let generated = try template.generateWork(name: "Out", partName: "Part", order: 1, limit: 4)

        guard case let .standardBeat(parts, tempoMap) = generated.content
        else { Issue.record("not standard beat"); return }

        let part = try #require(parts.first)

        #expect(part.dynamicMap.count == 1)
        #expect(part.dynamicMap[.zero] == .f)
        #expect(part.instrumentTable.count == 1)
        #expect(part.instrumentTable[.zero] == Fixtures.oboe)
        #expect(part.panMap.count == 1)
        #expect(part.panMap[.zero] == Fixtures.leftPan)
        #expect(tempoMap.count == 1)
        #expect(tempoMap[.zero] == Fixtures.slowTempo)
    }

    @Test
    func missingPart_givesDefaults() {
        let context = Template.SourceContext(content: makeSourceContextWork().content, index: 3)

        //
        // Without a part there's no first attack, so the tempo is the one at time zero.
        //
        #expect(context == Template.SourceContext(tempo: Tempo(uintValue: 120)))
    }

    @Test
    func part_hasNoPedals() throws {
        let template = try Template.analyzeNoteEvents(in: makeSourceContextWork(), at: 0, maximumOrder: 1, name: "Test")
        let part = template.sourceContext.part(name: "Generated",
                                               noteTable: NoteTable<BeatTime, Pitch>())

        #expect(part.pedals.isEmpty)
    }

    @Test
    func sourceContext_roundTripsThroughProject() throws {
        let template = try Template.analyzeNoteEvents(in: makeSourceContextWork(), at: 0, maximumOrder: 1, name: "Test")
        var project = Project()

        project.updateTemplate(template)

        let loaded = try #require(Project.load(from: project.save()).fetchTemplate(template.templateID))

        #expect(loaded.sourceContext == template.sourceContext)
    }
}

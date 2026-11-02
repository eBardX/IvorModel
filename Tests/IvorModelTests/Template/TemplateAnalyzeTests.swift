// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers

struct TemplateAnalyzeTests {
}

// MARK: -

extension TemplateAnalyzeTests {
    @Test
    func adding_incompatibleWork_throws() throws {
        let template = try analyzeAddingTemplate(makeNamedStandardBeatWork("Tune", Fixtures.threeNoteMelody))
        var noteTable = NoteTable<BeatTime, NoteNumber>()

        // swiftlint:disable:next force_unwrapping
        noteTable.insert(attack: 0, duration: 1, pitch: NoteNumber(uintValue: 60)!)

        let keyboard = Work(content: .keyboardBeat([Part(name: "Piano", noteTable: noteTable)], TempoMap()))

        #expect(throws: Template.Error.incompatibleOptions) {
            try template.adding(partAt: 0, of: keyboard, name: "Mixed")
        }
    }

    @Test
    func adding_itself_doublesEveryTransition() throws {
        let work = makeNamedStandardBeatWork("Tune", Fixtures.threeNoteMelody)
        let template = try analyzeAddingTemplate(work)
        let added = try template.adding(partAt: 0, of: work, name: "Twice")

        #expect(try standardBeatTransitions(of: added, .joint) == standardBeatTransitions(of: template, .joint).mapValues { $0 * 2 })
        #expect(try beginCount(of: added, .joint) == 2)
    }

    @Test
    func adding_keepsOriginalAndRecordsSources() throws {
        let tune = makeNamedStandardBeatWork("Tune", Fixtures.threeNoteMelody)
        let other = makeNamedStandardBeatWork("Other", [(0, 2, .a4), (2, 1, .b4)])
        let template = try analyzeAddingTemplate(tune)
        let added = try template.adding(partAt: 0, of: other, name: " Both\n Tunes ")

        #expect(added.templateID != template.templateID)
        #expect(added.name == "Both Tunes")
        #expect(added.analysisOptions == template.analysisOptions)
        #expect(template.sources.map(\.workName) == ["Tune"])
        #expect(added.sources.map(\.workName) == ["Tune", "Other"])
        #expect(added.sources.map(\.partName) == ["Piano", "Piano"])
        #expect(added.sources.last?.workID == other.workID)
        #expect(try beginCount(of: template, .joint) == 1)
    }

    @Test
    func adding_lockedTemplate_isAllowed() throws {
        let work = makeNamedStandardBeatWork("Tune", Fixtures.threeNoteMelody)
        var template = try analyzeAddingTemplate(work)

        template.isLocked = true

        #expect(try template.adding(partAt: 0, of: work, name: "Twice").isLocked == false)
    }

    @Test
    func adding_missingPart_throws() throws {
        let work = makeNamedStandardBeatWork("Tune", Fixtures.threeNoteMelody)
        let template = try analyzeAddingTemplate(work)

        #expect(throws: Template.Error.partNotFound(5)) {
            try template.adding(partAt: 5, of: work, name: "Missing")
        }
    }

    @Test
    func adding_separatedTemplate_mergesBothChains() throws {
        let work = makeNamedStandardBeatWork("Tune", Fixtures.threeNoteMelody)
        let template = try analyzeAddingTemplate(work,
                                                 states: .init(separatesPitchAndDuration: true))
        let added = try template.adding(partAt: 0, of: work, name: "Twice")

        #expect(added.chainRoles == [.duration, .pitch])
        #expect(try beginCount(of: added, .duration) == 2)
        #expect(try beginCount(of: added, .pitch) == 2)
    }

    @Test
    func adding_vocabulary_isSummedAndStartsFromOriginal() throws {
        let tune = makeNamedStandardBeatWork("Tune", Fixtures.threeNoteMelody)
        let other = makeNamedStandardBeatWork("Other", [(0, 2, .a4), (2, 1, .c4)])
        let added = try analyzeAddingTemplate(tune).adding(partAt: 0, of: other, name: "Both")
        let vocabulary = try standardBeatVocabulary(of: added)

        #expect(vocabulary.pitches[.c4] == 2)
        #expect(vocabulary.pitches[.a4] == 1)
        #expect(vocabulary.durations[1] == 3)
        #expect(vocabulary.first?.tiedPitches.map(\.pitch) == [.c4])
    }

    @Test
    func adding_withVariants_addsSummaries() throws {
        let work = makeNamedStandardBeatWork("Tune", Fixtures.threeNoteMelody)
        let template = try analyzeAddingTemplate(work,
                                                 variants: .init(retrogrades: true))
        let added = try template.adding(partAt: 0, of: work, name: "Twice")

        #expect(template.analysisSummary.sequenceCount == 2)
        #expect(added.analysisSummary.sequenceCount == 4)
        #expect(try beginCount(of: added, .joint) == 4)
    }

    @Test
    func analyzeNoteEvents_invalidMaximumOrder() {
        var noteTable = NoteTable<BeatTime, Pitch>()

        noteTable.insert(attack: 0, duration: 1, pitch: .c4)

        let part = Part<BeatTime, Pitch>(name: "Piano", noteTable: noteTable)
        let work = Work(content: .standardBeat([part], TempoMap()))

        #expect(throws: Template.Error.self) {
            try Template.analyzeNoteEvents(in: work,
                                           at: 0,
                                           maximumOrder: 0)
        }
    }

    @Test
    func analyzeNoteEvents_partNotFound() {
        let part = Part<BeatTime, Pitch>(name: "Piano")
        let work = Work(content: .standardBeat([part], TempoMap()))

        #expect(throws: Template.Error.self) {
            try Template.analyzeNoteEvents(in: work,
                                           at: 1,
                                           maximumOrder: 1)
        }
    }

    @Test
    func analyzeNoteEvents_success() throws {
        var table = NoteTable<BeatTime, Pitch>()

        table.insert(attack: 0, duration: 1, pitch: .c4)
        table.insert(attack: 1, duration: 1, pitch: .e4)

        let part = Part<BeatTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(name: "My Work", content: .standardBeat([part], TempoMap()))

        let tmpl = try Template.analyzeNoteEvents(in: work,
                                                  at: 0,
                                                  maximumOrder: 1)

        #expect(tmpl.name.contains("My Work"))
        #expect(tmpl.pitchNotation == .standard)
        #expect(tmpl.timeBasis == .beat)
        #expect(tmpl.maximumOrder == 1)
    }

    @Test
    func sources_roundTripThroughProject() throws {
        let tune = makeNamedStandardBeatWork("Tune", Fixtures.threeNoteMelody)
        let template = try analyzeAddingTemplate(tune).adding(partAt: 0, of: tune, name: "Twice")
        var project = Project()

        project.updateTemplate(template)

        let loaded = try #require(Project.load(from: project.save()).fetchTemplate(template.templateID))

        #expect(loaded.sources == template.sources)
        #expect(loaded.sources.count == 2)
    }
}

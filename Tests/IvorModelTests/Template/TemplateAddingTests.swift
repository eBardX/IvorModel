// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers

struct TemplateAddingTests {
}

// MARK: -

extension TemplateAddingTests {
    @Test
    func adding_itself_doublesEveryTransition() throws {
        let work = _standardWork("Tune", _melody)
        let template = try _analyze(work)
        let added = try template.adding(partAt: 0, of: work, name: "Twice")

        #expect(try _transitions(of: added, .joint) == _transitions(of: template, .joint).mapValues { $0 * 2 })
        #expect(try _beginCount(of: added, .joint) == 2)
    }

    @Test
    func adding_keepsOriginalAndRecordsSources() throws {
        let tune = _standardWork("Tune", _melody)
        let other = _standardWork("Other", [(0, 2, .a4), (2, 1, .b4)])
        let template = try _analyze(tune)
        let added = try template.adding(partAt: 0, of: other, name: " Both\n Tunes ")

        #expect(added.templateID != template.templateID)
        #expect(added.name == "Both Tunes")
        #expect(added.analysisOptions == template.analysisOptions)
        #expect(template.sources.map(\.workName) == ["Tune"])
        #expect(added.sources.map(\.workName) == ["Tune", "Other"])
        #expect(added.sources.map(\.partName) == ["Piano", "Piano"])
        #expect(added.sources.last?.workID == other.workID)
        #expect(try _beginCount(of: template, .joint) == 1)
    }

    @Test
    func adding_lockedTemplate_isAllowed() throws {
        let work = _standardWork("Tune", _melody)
        var template = try _analyze(work)

        template.isLocked = true

        #expect(try template.adding(partAt: 0, of: work, name: "Twice").isLocked == false)
    }

    @Test
    func adding_separatedTemplate_mergesBothChains() throws {
        let work = _standardWork("Tune", _melody)
        let template = try _analyze(work,
                                    states: .init(separatesPitchAndDuration: true))
        let added = try template.adding(partAt: 0, of: work, name: "Twice")

        #expect(added.chainRoles == [.duration, .pitch])
        #expect(try _beginCount(of: added, .duration) == 2)
        #expect(try _beginCount(of: added, .pitch) == 2)
    }

    @Test
    func adding_withVariants_addsSummaries() throws {
        let work = _standardWork("Tune", _melody)
        let template = try _analyze(work,
                                    variants: .init(retrogrades: true))
        let added = try template.adding(partAt: 0, of: work, name: "Twice")

        #expect(template.analysisSummary.sequenceCount == 2)
        #expect(added.analysisSummary.sequenceCount == 4)
        #expect(try _beginCount(of: added, .joint) == 4)
    }

    @Test
    func adding_vocabulary_isSummedAndStartsFromOriginal() throws {
        let tune = _standardWork("Tune", _melody)
        let other = _standardWork("Other", [(0, 2, .a4), (2, 1, .c4)])
        let added = try _analyze(tune).adding(partAt: 0, of: other, name: "Both")
        let vocabulary = try _vocabulary(of: added)

        #expect(vocabulary.pitches[.c4] == 2)
        #expect(vocabulary.pitches[.a4] == 1)
        #expect(vocabulary.durations[1] == 3)
        #expect(vocabulary.first?.tiedPitches.map(\.pitch) == [.c4])
    }

    @Test
    func adding_incompatibleWork_throws() throws {
        let template = try _analyze(_standardWork("Tune", _melody))
        var noteTable = NoteTable<BeatTime, NoteNumber>()

        // swiftlint:disable:next force_unwrapping
        noteTable.insert(attack: 0, duration: 1, pitch: NoteNumber(uintValue: 60)!)

        let keyboard = Work(content: .keyboardBeat([Part(name: "Piano", noteTable: noteTable)], TempoMap()))

        #expect(throws: Template.Error.incompatibleOptions) {
            try template.adding(partAt: 0, of: keyboard, name: "Mixed")
        }
    }

    @Test
    func adding_missingPart_throws() throws {
        let work = _standardWork("Tune", _melody)
        let template = try _analyze(work)

        #expect(throws: Template.Error.partNotFound(5)) {
            try template.adding(partAt: 5, of: work, name: "Missing")
        }
    }

    @Test
    func sources_roundTripThroughProject() throws {
        let tune = _standardWork("Tune", _melody)
        let template = try _analyze(tune).adding(partAt: 0, of: tune, name: "Twice")
        var project = Project()

        project.updateTemplate(template)

        let loaded = try #require(Project.load(from: project.save()).fetchTemplate(template.templateID))

        #expect(loaded.sources == template.sources)
        #expect(loaded.sources.count == 2)
    }
}

// MARK: - Private Types

private struct _BeginCountVisitor: Template.ContentVisitor {
    let role: Template.ChainRole

    func visit<TimeType>(_ model: Template.Model<TimeType, some Any>) -> UInt? where TimeType.DurationType: TemplateDuration {
        guard let chain = model.chains.chain(for: role)
        else { return nil }

        var count: UInt = 0

        chain.forEach { transition in
            if case .begin = transition.source {
                count += transition.weight
            }
        }

        return count
    }
}

// MARK: - Private Constants

private let _melody: [(Number, Number, Pitch)] = [(0, 1, .c4), (1, 1, .e4), (2, 2, .g4)]

// MARK: - Private Functions

private func _analyze(_ work: Work,
                      states: Template.AnalysisOptions.StateRecipe = .exact,
                      variants: Template.AnalysisOptions.Variants = .none) throws -> Template {
    try Template.analyzeNoteEvents(in: work,
                                   at: 0,
                                   options: .init(maximumOrder: 2,
                                                  states: states,
                                                  variants: variants))
}

private func _beginCount(of template: Template,
                         _ role: Template.ChainRole) throws -> UInt {
    try #require(template.accept(_BeginCountVisitor(role: role)))
}

private func _standardWork(_ name: String,
                           _ notes: [(Number, Number, Pitch)]) -> Work {
    var noteTable = NoteTable<BeatTime, Pitch>()

    for (attack, duration, pitch) in notes {
        // swiftlint:disable:next force_unwrapping
        noteTable.insert(attack: BeatTime(numberValue: attack)!,
                         // swiftlint:disable:next force_unwrapping
                         duration: BeatDuration(numberValue: duration)!,
                         pitch: pitch)
    }

    return Work(name: name,
                content: .standardBeat([Part(name: "Piano", noteTable: noteTable)], TempoMap()))
}

//
// Each transition of the chain with `role`, by its source and target, with its weight.
//
private func _transitions(of template: Template,
                          _ role: Template.ChainRole) throws -> [String: UInt] {
    guard case let .standardBeat(model) = template.content
    else { throw Template.Error.incompatibleOptions }

    var result: [String: UInt] = [:]

    try #require(model.chains.chain(for: role)).forEach { transition in
        result["\(transition.source) → \(transition.target)"] = transition.weight
    }

    return result
}

private func _vocabulary(of template: Template) throws -> Template.Vocabulary<BeatTime, Pitch> {
    guard case let .standardBeat(model) = template.content
    else { throw Template.Error.incompatibleOptions }

    return model.vocabulary
}

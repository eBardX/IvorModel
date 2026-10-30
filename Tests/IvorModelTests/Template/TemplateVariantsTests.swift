// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers

struct TemplateVariantsTests {
}

// MARK: -

extension TemplateVariantsTests {
    @Test
    func analysis_noVariants_trainsOneSequence() throws {
        let template = try _analyze(_standardWork(_melody))

        #expect(template.analysisSummary == Template.AnalysisSummary())
        #expect(try _beginCount(of: template, .joint) == 1)
    }

    @Test
    func analysis_tonerowForms_trainFortyEightSequences() throws {
        let row: [UInt] = [0, 11, 7, 8, 3, 1, 2, 10, 6, 5, 4, 9]
        let template = try _analyze(_keyboardWork(row.map { 60 + $0 }),
                                    variants: .init(transpositions: _keyboardTranspositions,
                                                    inverts: true,
                                                    retrogrades: true))

        #expect(template.analysisOptions.variants.sequenceCount == 48)
        #expect(template.analysisSummary == Template.AnalysisSummary(sequenceCount: 48))
        #expect(try _beginCount(of: template, .joint) == 48)
    }

    @Test
    func analysis_symmetricRow_mergesIdenticalForms() throws {
        //
        // A chromatic scale inverted within its own range is its own retrograde.
        //
        let template = try _analyze(_keyboardWork((0..<12).map { 60 + $0 }),
                                    variants: .init(inverts: true,
                                                    retrogrades: true))

        #expect(template.analysisSummary.mergedCount == 2)
        #expect(template.analysisSummary.sequenceCount == 2)
    }

    @Test
    func analysis_intervalRecipe_mergesTranspositions() throws {
        let template = try _analyze(_standardWork(_melody),
                                    states: .init(pitch: .interval),
                                    variants: .init(transpositions: [_up(.major2), _down(.perfect5)]))

        #expect(template.analysisSummary == Template.AnalysisSummary(sequenceCount: 1,
                                                                     mergedCount: 2))
    }

    @Test
    func analysis_relativeDurations_mergeAugmentation() throws {
        let template = try _analyze(_standardWork(_melody),
                                    states: .init(duration: .relative),
                                    variants: .init(timeFactors: [2, Number(numerator: 1, denominator: 2)]))

        #expect(template.analysisSummary == Template.AnalysisSummary(sequenceCount: 1,
                                                                     mergedCount: 2))
    }

    @Test
    func analysis_inversion_staysInRange() throws {
        let template = try _analyze(_standardWork(_melody),
                                    variants: .init(inverts: true))
        let pitches = try _vocabulary(of: template).pitches.keys

        #expect(Set(pitches) == [.c4, .eFlat4, .e4, .g4])
        #expect(try _vocabulary(of: template).pitchRange == Pitch.c4...Pitch.g4)
    }

    @Test
    func analysis_retrograde_reversesTies() throws {
        //
        // C4 sounds across E4's attack, so it's sliced and tied: [C4⌒] [⌒C4 E4].  Reversed, E4
        // sounds first: [C4⌒ E4] [⌒C4].
        //
        let work = _standardWork([(0, 2, .c4), (1, 1, .e4)])
        let template = try _analyze(work,
                                    variants: .init(retrogrades: true))
        let noteEvents = try makeNoteEvents(_states(of: template, .joint))

        #expect(noteEvents.contains { event in
            event.tiedPitches.count == 2
                && event.tiedPitches.contains { $0.pitch == .c4 && $0.startsTie && !$0.endsTie }
        })
        #expect(template.analysisSummary.sequenceCount == 2)
    }

    @Test
    func analysis_outOfRangeTransposition_isSkipped() throws {
        let template = try _analyze(_keyboardWork([120, 124]),
                                    variants: .init(transpositions: [_up(12), _down(12)]))
        let summary = template.analysisSummary

        #expect(summary.sequenceCount == 2)
        #expect(summary.skippedVariants.count == 1)
        #expect(summary.skippedVariants.first?.transposition == _up(12))
    }

    @Test
    func analysis_separatedChains_trainEachSequence() throws {
        let template = try _analyze(_standardWork(_melody),
                                    states: .init(separatesPitchAndDuration: true),
                                    variants: .init(retrogrades: true))

        #expect(try _beginCount(of: template, .duration) == 2)
        #expect(try _beginCount(of: template, .pitch) == 2)
    }

    @Test
    func analysis_vocabulary_includesTranspositionsAndStartsFromOriginal() throws {
        let template = try _analyze(_standardWork(_melody),
                                    variants: .init(transpositions: [_up(.major2)]))
        let vocabulary = try _vocabulary(of: template)

        #expect(Set(vocabulary.pitches.keys) == [.c4, .d4, .e4, .fSharp4, .g4, .a4])
        #expect(vocabulary.first?.tiedPitches.map(\.pitch) == [.c4])
    }

    @Test
    func coding_variantsAndSummary_roundTrip() throws {
        let template = try _analyze(_keyboardWork([120, 124]),
                                    variants: .init(transpositions: [_up(12)],
                                                    inverts: true,
                                                    timeFactors: [Number(numerator: 3, denominator: 2)]))
        var project = Project()

        project.updateTemplate(template)

        let loaded = try #require(Project.load(from: project.save()).fetchTemplate(template.templateID))

        #expect(loaded.analysisOptions == template.analysisOptions)
        #expect(loaded.analysisSummary == template.analysisSummary)
        #expect(!loaded.analysisSummary.skippedVariants.isEmpty)
    }

    @Test
    func sequenceCount_isProductOfChoices() {
        typealias Variants = Template.AnalysisOptions.Variants

        #expect(Variants.none.sequenceCount == 1)
        #expect(Variants(inverts: true).sequenceCount == 2)
        #expect(Variants(transpositions: [_up(.major2)], retrogrades: true).sequenceCount == 4)
        #expect(Variants(transpositions: [_up(.major2), _down(.major2)],
                         inverts: true,
                         retrogrades: true,
                         timeFactors: [2]).sequenceCount == 24)
    }

    @Test
    func validation_incompatibleTransposition_throws() {
        let transposition = Template.AnalysisOptions.Transposition.ratio(DirectedInterval(interval: Ratio(cents: 100),
                                                                                          direction: .ascending))

        #expect(throws: Template.Error.incompatibleOptions) {
            try _analyze(_standardWork(_melody),
                         variants: .init(transpositions: [transposition]))
        }
    }

    @Test(arguments: [Template.AnalysisOptions.Variants(timeFactors: [1]),
                      Template.AnalysisOptions.Variants(timeFactors: [-2]),
                      Template.AnalysisOptions.Variants(timeFactors: [2, 2]),
                      Template.AnalysisOptions.Variants(transpositions: [.interval(DirectedInterval(interval: .perfect1,
                                                                                                    direction: .same))]),
                      Template.AnalysisOptions.Variants(transpositions: [_up(.major2), _up(.major2)])])
    func validation_invalidVariants_throw(variants: Template.AnalysisOptions.Variants) {
        #expect(throws: Template.Error.invalidVariants) {
            try _analyze(_standardWork(_melody),
                         variants: variants)
        }
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

//
// Down a perfect fourth to up an augmented fourth, without the unison.
//
private let _keyboardTranspositions: [Template.AnalysisOptions.Transposition] = [5, 4, 3, 2, 1].map { _down($0) } + [1, 2, 3, 4, 5, 6].map { _up($0) }

private let _melody: [(Number, Number, Pitch)] = [(0, 1, .c4), (1, 1, .e4), (2, 2, .g4)]

// MARK: - Private Functions

private func _analyze(_ work: Work,
                      states: Template.AnalysisOptions.StateRecipe = .exact,
                      variants: Template.AnalysisOptions.Variants = .none) throws -> Template {
    try Template.analyzeNoteEvents(in: work,
                                   at: 0,
                                   options: .init(maximumOrder: 1,
                                                  states: states,
                                                  variants: variants))
}

//
// How many sequences the chain with `role` was trained on: the weight of its transitions from
// the start.
//
private func _beginCount(of template: Template,
                         _ role: Template.ChainRole) throws -> UInt {
    try #require(template.accept(_BeginCountVisitor(role: role)))
}

private func _chain(of template: Template,
                    _ role: Template.ChainRole) throws -> MarkovChain<Template.State<BeatTime, Pitch>> {
    switch template.content {
    case let .standardBeat(model):
        return try #require(model.chains.chain(for: role))

    default:
        throw Template.Error.incompatibleOptions
    }
}

private func _down(_ interval: Interval) -> Template.AnalysisOptions.Transposition {
    .interval(DirectedInterval(interval: interval,
                               direction: .descending))
}

private func _down(_ semitones: UInt) -> Template.AnalysisOptions.Transposition {
    // swiftlint:disable:next force_unwrapping
    .noteDistance(DirectedInterval(interval: NoteDistance(uintValue: semitones)!,
                                   direction: .descending))
}

private func _keyboardWork(_ noteNumbers: [UInt]) -> Work {
    var noteTable = NoteTable<BeatTime, NoteNumber>()

    for (index, noteNumber) in noteNumbers.enumerated() {
        // swiftlint:disable:next force_unwrapping
        noteTable.insert(attack: BeatTime(numberValue: Number(index))!,
                         duration: 1,
                         // swiftlint:disable:next force_unwrapping
                         pitch: NoteNumber(uintValue: noteNumber)!)
    }

    return Work(content: .keyboardBeat([Part(name: "Piano", noteTable: noteTable)], TempoMap()))
}

private func _standardWork(_ notes: [(Number, Number, Pitch)]) -> Work {
    var noteTable = NoteTable<BeatTime, Pitch>()

    for (attack, duration, pitch) in notes {
        // swiftlint:disable:next force_unwrapping
        noteTable.insert(attack: BeatTime(numberValue: attack)!,
                         // swiftlint:disable:next force_unwrapping
                         duration: BeatDuration(numberValue: duration)!,
                         pitch: pitch)
    }

    return Work(content: .standardBeat([Part(name: "Piano", noteTable: noteTable)], TempoMap()))
}

private func _states(of template: Template,
                     _ role: Template.ChainRole) throws -> [Template.State<BeatTime, Pitch>] {
    try _chain(of: template, role).states
}

private func _up(_ interval: Interval) -> Template.AnalysisOptions.Transposition {
    .interval(DirectedInterval(interval: interval,
                               direction: .ascending))
}

private func _up(_ semitones: UInt) -> Template.AnalysisOptions.Transposition {
    // swiftlint:disable:next force_unwrapping
    .noteDistance(DirectedInterval(interval: NoteDistance(uintValue: semitones)!,
                                   direction: .ascending))
}

private func _vocabulary(of template: Template) throws -> Template.Vocabulary<BeatTime, Pitch> {
    guard case let .standardBeat(model) = template.content
    else { throw Template.Error.incompatibleOptions }

    return model.vocabulary
}

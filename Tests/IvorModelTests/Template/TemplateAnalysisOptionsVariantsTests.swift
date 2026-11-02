// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers

struct TemplateAnalysisOptionsVariantsTests {
}

// MARK: -

extension TemplateAnalysisOptionsVariantsTests {
    @Test
    func analysis_intervalRecipe_mergesTranspositions() throws {
        let template = try analyzeVariantsTemplate(makeStandardBeatWork(Fixtures.threeNoteMelody),
                                                   states: .init(pitch: .interval),
                                                   variants: .init(transpositions: [ascending(.major2), descending(.perfect5)]))

        #expect(template.analysisSummary == Template.AnalysisSummary(sequenceCount: 1,
                                                                     mergedCount: 2))
    }

    @Test
    func analysis_inversion_staysInRange() throws {
        let template = try analyzeVariantsTemplate(makeStandardBeatWork(Fixtures.threeNoteMelody),
                                                   variants: .init(inverts: true))
        let pitches = try standardBeatVocabulary(of: template).pitches.keys

        #expect(Set(pitches) == [.c4, .eFlat4, .e4, .g4])
        #expect(try standardBeatVocabulary(of: template).pitchRange == Pitch.c4...Pitch.g4)
    }

    @Test
    func analysis_noVariants_trainsOneSequence() throws {
        let template = try analyzeVariantsTemplate(makeStandardBeatWork(Fixtures.threeNoteMelody))

        #expect(template.analysisSummary == Template.AnalysisSummary())
        #expect(try beginCount(of: template, .joint) == 1)
    }

    @Test
    func analysis_outOfRangeTransposition_isSkipped() throws {
        let template = try analyzeVariantsTemplate(makeKeyboardBeatWork([120, 124]),
                                                   variants: .init(transpositions: [ascending(12), descending(12)]))
        let summary = template.analysisSummary

        #expect(summary.sequenceCount == 2)
        #expect(summary.skippedVariants.count == 1)
        #expect(summary.skippedVariants.first?.transposition == ascending(12))
    }

    @Test
    func analysis_relativeDurations_mergeAugmentation() throws {
        let template = try analyzeVariantsTemplate(makeStandardBeatWork(Fixtures.threeNoteMelody),
                                                   states: .init(duration: .relative),
                                                   variants: .init(timeFactors: [2, Number(numerator: 1, denominator: 2)]))

        #expect(template.analysisSummary == Template.AnalysisSummary(sequenceCount: 1,
                                                                     mergedCount: 2))
    }

    @Test
    func analysis_retrograde_reversesTies() throws {
        //
        // C4 sounds across E4's attack, so it's sliced and tied: [C4⌒] [⌒C4 E4].  Reversed, E4
        // sounds first: [C4⌒ E4] [⌒C4].
        //
        let work = makeStandardBeatWork([(0, 2, .c4), (1, 1, .e4)])
        let template = try analyzeVariantsTemplate(work,
                                                   variants: .init(retrogrades: true))
        let noteEvents = try makeNoteEvents(standardBeatStates(of: template, .joint))

        #expect(noteEvents.contains { event in
            event.tiedPitches.count == 2
                && event.tiedPitches.contains { $0.pitch == .c4 && $0.startsTie && !$0.endsTie }
        })
        #expect(template.analysisSummary.sequenceCount == 2)
    }

    @Test
    func analysis_separatedChains_trainEachSequence() throws {
        let template = try analyzeVariantsTemplate(makeStandardBeatWork(Fixtures.threeNoteMelody),
                                                   states: .init(separatesPitchAndDuration: true),
                                                   variants: .init(retrogrades: true))

        #expect(try beginCount(of: template, .duration) == 2)
        #expect(try beginCount(of: template, .pitch) == 2)
    }

    @Test
    func analysis_symmetricRow_mergesIdenticalForms() throws {
        //
        // A chromatic scale inverted within its own range is its own retrograde.
        //
        let template = try analyzeVariantsTemplate(makeKeyboardBeatWork((0..<12).map { 60 + $0 }),
                                                   variants: .init(inverts: true,
                                                                   retrogrades: true))

        #expect(template.analysisSummary.mergedCount == 2)
        #expect(template.analysisSummary.sequenceCount == 2)
    }

    @Test
    func analysis_tonerowForms_trainFortyEightSequences() throws {
        let row: [UInt] = [0, 11, 7, 8, 3, 1, 2, 10, 6, 5, 4, 9]
        let template = try analyzeVariantsTemplate(makeKeyboardBeatWork(row.map { 60 + $0 }),
                                                   variants: .init(transpositions: Fixtures.keyboardTranspositions,
                                                                   inverts: true,
                                                                   retrogrades: true))

        #expect(template.analysisOptions.variants.sequenceCount == 48)
        #expect(template.analysisSummary == Template.AnalysisSummary(sequenceCount: 48))
        #expect(try beginCount(of: template, .joint) == 48)
    }

    @Test
    func analysis_vocabulary_includesTranspositionsAndStartsFromOriginal() throws {
        let template = try analyzeVariantsTemplate(makeStandardBeatWork(Fixtures.threeNoteMelody),
                                                   variants: .init(transpositions: [ascending(.major2)]))
        let vocabulary = try standardBeatVocabulary(of: template)

        #expect(Set(vocabulary.pitches.keys) == [.c4, .d4, .e4, .fSharp4, .g4, .a4])
        #expect(vocabulary.first?.tiedPitches.map(\.pitch) == [.c4])
    }

    @Test
    func coding_variantsAndSummary_roundTrip() throws {
        let template = try analyzeVariantsTemplate(makeKeyboardBeatWork([120, 124]),
                                                   variants: .init(transpositions: [ascending(12)],
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
        #expect(Variants(transpositions: [ascending(.major2)], retrogrades: true).sequenceCount == 4)
        #expect(Variants(transpositions: [ascending(.major2), descending(.major2)],
                         inverts: true,
                         retrogrades: true,
                         timeFactors: [2]).sequenceCount == 24)
    }

    @Test
    func validation_incompatibleTransposition_throws() {
        let transposition = Template.AnalysisOptions.Transposition.ratio(DirectedInterval(interval: Ratio(cents: 100),
                                                                                          direction: .ascending))

        #expect(throws: Template.Error.incompatibleOptions) {
            try analyzeVariantsTemplate(makeStandardBeatWork(Fixtures.threeNoteMelody),
                                        variants: .init(transpositions: [transposition]))
        }
    }

    @Test(arguments: [Template.AnalysisOptions.Variants(timeFactors: [1]),
                      Template.AnalysisOptions.Variants(timeFactors: [-2]),
                      Template.AnalysisOptions.Variants(timeFactors: [2, 2]),
                      Template.AnalysisOptions.Variants(transpositions: [.interval(DirectedInterval(interval: .perfect1,
                                                                                                    direction: .same))]),
                      Template.AnalysisOptions.Variants(transpositions: [ascending(.major2), ascending(.major2)])])
    func validation_invalidVariants_throw(variants: Template.AnalysisOptions.Variants) {
        #expect(throws: Template.Error.invalidVariants) {
            try analyzeVariantsTemplate(makeStandardBeatWork(Fixtures.threeNoteMelody),
                                        variants: variants)
        }
    }
}

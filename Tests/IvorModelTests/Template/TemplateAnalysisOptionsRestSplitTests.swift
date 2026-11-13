// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers

//
// Long rests, both ways: split at in analysis, so that a template never learns them, and ruled
// out in generation by the longest-rest constraint.
//
struct TemplateAnalysisOptionsRestSplitTests {
}

// MARK: -

extension TemplateAnalysisOptionsRestSplitTests {
    @Test
    func analyze_noSplit_learnsEveryRest() throws {
        let template = try analyzeRestSplitTune(restSplit: nil)

        #expect(try beginCount(of: template, .joint) == 1)
        #expect(try standardBeatVocabulary(of: template).durations[beats(4)] != nil)
        #expect(template.analysisSummary.sequenceCount == 1)
    }

    @Test
    func analyze_split_restExactlyAtMinimumSplits() throws {
        let template = try analyzeRestSplitTune(restSplit: .beat(beats(4)))

        #expect(try beginCount(of: template, .joint) == 2)
    }

    @Test
    func analyze_split_separatedChains_splitBoth() throws {
        let template = try analyzeRestSplitTune(restSplit: .beat(beats(2)),
                                                states: .init(separatesPitchAndDuration: true))

        #expect(try beginCount(of: template, .duration) == 2)
        #expect(try beginCount(of: template, .pitch) == 2)
    }

    @Test
    func analyze_split_startsNewSequenceAndDropsLongRest() throws {
        let template = try analyzeRestSplitTune(restSplit: .beat(beats(2)))
        let vocabulary = try standardBeatVocabulary(of: template)

        #expect(try beginCount(of: template, .joint) == 2)
        #expect(try endCount(of: template, .joint) == 2)
        #expect(template.analysisSummary.sequenceCount == 2)
        #expect(template.analysisOptions.restSplit == .beat(beats(2)))

        //
        // The long rest is never learned; the short one and the long note still are.
        //
        #expect(vocabulary.durations[beats(4)] == 1)
        #expect(vocabulary.durations[beats(1)] == 5)
        #expect(try !hasJointState(in: template) { $0.isRest && $0.duration == .absolute(beats(4)) })
        #expect(try hasJointState(in: template) { $0.isRest && $0.duration == .absolute(beats(1)) })
    }

    @Test
    func analyze_split_withRetrograde_splitsEachVariant() throws {
        let template = try analyzeRestSplitTune(restSplit: .beat(beats(2)),
                                                variants: .init(retrogrades: true))

        #expect(template.analysisSummary.sequenceCount == 4)
        #expect(try beginCount(of: template, .joint) == 4)
    }

    @Test
    func analyze_wallSplitOnBeatWork_throws() throws {
        // swiftlint:disable:next force_unwrapping
        let split = Template.AnalysisOptions.RestSplit.wall(WallDuration(uintValue: 1_000_000)!)

        #expect(throws: Template.Error.incompatibleOptions) {
            try analyzeRestSplitTune(restSplit: split)
        }
    }

    @Test
    func analyze_zeroSplit_throws() throws {
        #expect(throws: Template.Error.invalidTolerance) {
            try analyzeRestSplitTune(restSplit: .beat(.zero))
        }
    }

    @Test
    func constraints_maximumRestDuration_leavesNotesAlone() {
        let constraints = Template.GenerationOptions<BeatTime, Pitch>.Constraints(maximumRestDuration: beats(2))

        #expect(!constraints.isEmpty)
        #expect(constraints.allows(NoteEvent(tiedPitches: [], duration: beats(2))))
        #expect(!constraints.allows(NoteEvent(tiedPitches: [], duration: beats(4))))
        #expect(constraints.allows(NoteEvent(tiedPitches: [.init(pitch: .g4)], duration: beats(4))))
    }

    @Test
    func generate_maximumRestDuration_neverChoosesLongRest() throws {
        let template = try analyzeRestSplitTune(restSplit: nil)
        let constraints = Template.GenerationOptions<BeatTime, Pitch>.Constraints(maximumRestDuration: beats(2))
        var sawShortRest = false

        for seed in UInt64(0)..<10 {
            let work = try template.generateWork(name: "G",
                                                 partName: "Part",
                                                 options: .init(order: 1,
                                                                length: .noteCount(30),
                                                                stopsAtEnd: false,
                                                                backsOff: true,
                                                                constraints: constraints),
                                                 seed: seed)

            guard case let .standardBeat(parts, _, _) = work.content
            else { Issue.record("not standard beat"); return }

            let events = try #require(parts.first).noteTable.extractNoteEvents()

            #expect(!events.isEmpty)
            #expect(events.allSatisfy { constraints.allows($0) })

            sawShortRest = sawShortRest || events.contains { $0.tiedPitches.isEmpty }
        }

        #expect(sawShortRest)
    }

    @Test
    func restSplit_codable_roundTrip() throws {
        let options = Template.AnalysisOptions(maximumOrder: 2,
                                               restSplit: .beat(beats(2)))
        let decoded = try JSONDecoder().decode(Template.AnalysisOptions.self,
                                               from: JSONEncoder().encode(options))

        #expect(decoded == options)
    }

    @Test
    func sequenceCount_countsEachVariantsSplits() throws {
        let split = Template.AnalysisOptions.RestSplit.beat(beats(2))

        #expect(try Template.sequenceCount(in: makeRestSplitTune(), at: 0, options: .init(maximumOrder: 1)) == 1)
        #expect(try Template.sequenceCount(in: makeRestSplitTune(), at: 0, options: .init(maximumOrder: 1, restSplit: split)) == 2)
        #expect(try Template.sequenceCount(in: makeRestSplitTune(),
                                           at: 0,
                                           options: .init(maximumOrder: 1,
                                                          variants: .init(retrogrades: true),
                                                          restSplit: split)) == 4)
    }

    @Test
    func sequenceCount_invalidOptions_throw() {
        #expect(throws: Template.Error.invalidTolerance) {
            try Template.sequenceCount(in: makeRestSplitTune(), at: 0, options: .init(maximumOrder: 1, restSplit: .beat(.zero)))
        }

        #expect(throws: Template.Error.partNotFound(4)) {
            try Template.sequenceCount(in: makeRestSplitTune(), at: 4, options: .init(maximumOrder: 1))
        }
    }

    @Test
    func sequenceCount_matchesAnalysisWithoutMerges() throws {
        let options = Template.AnalysisOptions(maximumOrder: 2,
                                               variants: .init(retrogrades: true),
                                               restSplit: .beat(beats(2)))
        let summary = try Template.analyzeNoteEvents(in: makeRestSplitTune(), at: 0, options: options, name: "Test").analysisSummary

        #expect(summary.mergedCount == 0)
        #expect(try Template.sequenceCount(in: makeRestSplitTune(), at: 0, options: options) == summary.sequenceCount)
    }

    @Test
    func sequenceCount_timeScaling_changesWhichRestsSplit() throws {
        //
        // Halved, the four-beat rest lasts two beats — still long enough at two, not at three.
        //
        let variants = Template.AnalysisOptions.Variants(timeFactors: [Number(numerator: 1, denominator: 2)])

        #expect(try Template.sequenceCount(in: makeRestSplitTune(),
                                           at: 0,
                                           options: .init(maximumOrder: 1,
                                                          variants: variants,
                                                          restSplit: .beat(beats(2)))) == 4)
        #expect(try Template.sequenceCount(in: makeRestSplitTune(),
                                           at: 0,
                                           options: .init(maximumOrder: 1,
                                                          variants: variants,
                                                          restSplit: .beat(beats(3)))) == 3)
    }
}

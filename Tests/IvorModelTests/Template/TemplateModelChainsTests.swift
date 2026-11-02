// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers

struct TemplateModelChainsTests {
}

// MARK: -

extension TemplateModelChainsTests {
    @Test
    func analysis_eachChainLearnsItsHalf() throws {
        let template = try analyzeSeparatedTemplate(makeStandardBeatWork(Fixtures.melodyWithRest))
        let durationStates = try sortedStandardBeatStates(of: template, .duration)
        let pitchStates = try sortedStandardBeatStates(of: template, .pitch)

        #expect(template.chainRoles == [.duration, .pitch])
        #expect(durationStates.allSatisfy { $0.pitches == nil && $0.duration != nil })
        #expect(durationStates.contains { $0.isRest })
        #expect(pitchStates.allSatisfy { !$0.isRest && $0.duration == nil && $0.pitches != nil })
        #expect(pitchStates.count == 4)
    }

    @Test
    func analysis_jointRecipe_hasOneChain() throws {
        let template = try Template.analyzeNoteEvents(in: makeStandardBeatWork(Fixtures.melodyWithRest),
                                                      at: 0,
                                                      maximumOrder: 1)

        #expect(template.chainRoles == [.joint])
        #expect(template.metrics(for: .joint) != nil)
        #expect(template.metrics(for: .duration) == nil)
        #expect(template.metrics(for: .pitch) == nil)
    }

    @Test
    func analysis_pitchChain_ignoresRhythm() throws {
        let melody: [(Number, Number, Pitch)] = [(0, 1, .c4), (1, 1, .d4), (2, 1, .e4)]
        let rhythm: [(Number, Number, Pitch)] = [(0, 2, .c4), (2, 1, .d4), (3, Number(numerator: 1, denominator: 2), .e4)]

        let original = try analyzeSeparatedTemplate(makeStandardBeatWork(melody))
        let altered = try analyzeSeparatedTemplate(makeStandardBeatWork(rhythm))

        #expect(try sortedStandardBeatStates(of: original, .pitch) == sortedStandardBeatStates(of: altered, .pitch))
        #expect(try sortedStandardBeatStates(of: original, .duration) != sortedStandardBeatStates(of: altered, .duration))
    }

    @Test(arguments: [Template.AnalysisOptions.StateRecipe(pitch: .omitted,
                                                           duration: .absolute,
                                                           separatesPitchAndDuration: true),
                      Template.AnalysisOptions.StateRecipe(pitch: .absolute,
                                                           duration: .omitted,
                                                           separatesPitchAndDuration: true)])
    func analysis_separatingWithoutBothFeatures_throws(recipe: Template.AnalysisOptions.StateRecipe) {
        #expect(throws: Template.Error.invalidStateRecipe) {
            try Template.analyzeNoteEvents(in: makeStandardBeatWork([(0, 1, .c4)]),
                                           at: 0,
                                           options: .init(maximumOrder: 1,
                                                          states: recipe))
        }
    }

    @Test
    func coding_generationOptions_roundTripWithAndWithoutPitchChain() throws {
        let plain = Template.GenerationOptions<BeatTime, Pitch>(order: 2)
        let separate = Template.GenerationOptions<BeatTime, Pitch>(order: 2,
                                                                   pitchChain: .init(order: 1,
                                                                                     mixing: .blend(with: 0, weight: 0.25),
                                                                                     contrast: 2))

        for options in [plain, separate] {
            let decoded = try JSONDecoder().decode(Template.GenerationOptions<BeatTime, Pitch>.self,
                                                   from: JSONEncoder().encode(options))

            #expect(decoded == options)
        }
    }

    @Test
    func coding_separatedTemplate_roundTripsThroughProject() throws {
        let template = try analyzeSeparatedTemplate(makeStandardBeatWork(Fixtures.melodyWithRest),
                                                    pitch: .interval,
                                                    duration: .relative)
        var project = Project()

        project.updateTemplate(template)

        let loaded = try #require(Project.load(from: project.save()).fetchTemplate(template.templateID))

        #expect(loaded.analysisOptions == template.analysisOptions)
        #expect(loaded.chainRoles == [.duration, .pitch])
        #expect(try sortedStandardBeatStates(of: loaded, .duration) == sortedStandardBeatStates(of: template, .duration))
        #expect(try sortedStandardBeatStates(of: loaded, .pitch) == sortedStandardBeatStates(of: template, .pitch))
    }

    @Test
    func generation_constraintsFilterTheirOwnChain() throws {
        let template = try analyzeSeparatedTemplate(makeStandardBeatWork(Fixtures.risingScale))
        let allowed: Set<Pitch> = [.c4, .e4, .g4]

        let work = try template.generateWork(name: "G",
                                             options: Template.GenerationOptions<BeatTime, Pitch>(order: 0,
                                                                                                  length: .noteCount(30),
                                                                                                  stopsAtEnd: false,
                                                                                                  constraints: .init(allowedPitches: allowed,
                                                                                                                     maximumDuration: 1)),
                                             seed: 3)
        let notes = try standardBeatNoteTriples(of: work)

        #expect(notes.count == 30)
        #expect(notes.allSatisfy { allowed.contains($0.pitch) && $0.duration == 1 })
    }

    @Test
    func generation_durationChainEnd_stopsGeneration() throws {
        let template = try analyzeSeparatedTemplate(makeStandardBeatWork(Fixtures.risingScale))

        let work = try template.generateWork(name: "G",
                                             options: Template.GenerationOptions<BeatTime, Pitch>(order: 1,
                                                                                                  length: .noteCount(50),
                                                                                                  pitchChain: .init(order: 0)),
                                             seed: 5)

        #expect(try standardBeatNoteTriples(of: work).map(\.duration) == [1, 2, 3, 4, 5])
    }

    @Test
    func generation_jointTemplateWithPitchChain_throws() throws {
        let template = try Template.analyzeNoteEvents(in: makeStandardBeatWork(Fixtures.risingScale),
                                                      at: 0,
                                                      maximumOrder: 1)

        #expect(throws: Template.Error.incompatibleOptions) {
            try template.generateWork(name: "G",
                                      options: Template.GenerationOptions<BeatTime, Pitch>(pitchChain: .init(order: 1)),
                                      seed: 1)
        }
    }

    @Test
    func generation_pitchChainEnd_stopsGeneration() throws {
        let template = try analyzeSeparatedTemplate(makeStandardBeatWork(Fixtures.risingScale))

        let work = try template.generateWork(name: "G",
                                             options: Template.GenerationOptions<BeatTime, Pitch>(order: 0,
                                                                                                  length: .noteCount(50),
                                                                                                  pitchChain: .init(order: 1)),
                                             seed: 5)

        #expect(try standardBeatNoteTriples(of: work).map(\.pitch) == [.c4, .d4, .e4, .f4, .g4])
    }

    @Test
    func generation_pitchChainLoops_restartsOnlyThePitchChain() throws {
        let template = try analyzeSeparatedTemplate(makeStandardBeatWork(Fixtures.risingScale))

        let work = try template.generateWork(name: "G",
                                             options: Template.GenerationOptions<BeatTime, Pitch>(order: 0,
                                                                                                  length: .noteCount(12),
                                                                                                  loops: true,
                                                                                                  pitchChain: .init(order: 1)),
                                             seed: 5)

        #expect(try standardBeatNoteTriples(of: work).map(\.pitch) == [.c4,
                                                                       .d4,
                                                                       .e4,
                                                                       .f4,
                                                                       .g4,
                                                                       .c4,
                                                                       .d4,
                                                                       .e4,
                                                                       .f4,
                                                                       .g4,
                                                                       .c4,
                                                                       .d4])
    }

    @Test
    func generation_pitchOrderAboveMaximum_throws() throws {
        let template = try analyzeSeparatedTemplate(makeStandardBeatWork(Fixtures.risingScale))

        #expect(throws: Template.Error.invalidOrder(1)) {
            try template.generateWork(name: "G",
                                      options: Template.GenerationOptions<BeatTime, Pitch>(pitchChain: .init(order: 2)),
                                      seed: 1)
        }
    }

    @Test
    func generation_rangeKeepsRelativePitchChainWithinSource() throws {
        //
        // Always rising: unchecked, a looped interval chain would climb out of sight.
        //
        let melody: [(Number, Number, Pitch)] = [(0, 1, .c4), (1, 1, .e4), (2, 1, .g4), (3, 1, .c5)]
        let template = try analyzeSeparatedTemplate(makeStandardBeatWork(melody),
                                                    pitch: .interval)

        let work = try template.generateWork(name: "G",
                                             options: Template.GenerationOptions<BeatTime, Pitch>(order: 0,
                                                                                                  length: .noteCount(40),
                                                                                                  stopsAtEnd: false),
                                             seed: 9)
        let pitches = try standardBeatNoteTriples(of: work).map(\.pitch)

        #expect(pitches.count == 40)
        #expect(pitches.allSatisfy { (Pitch.c4...Pitch.c5).contains($0) })
    }

    @Test(arguments: [(Template.AnalysisOptions.StateRecipe.PitchFeature.absolute,
                       Template.AnalysisOptions.StateRecipe.DurationFeature.absolute),
                      (.interval, .relative)])
    func generation_reproducesSource(pitch: Template.AnalysisOptions.StateRecipe.PitchFeature,
                                     duration: Template.AnalysisOptions.StateRecipe.DurationFeature) throws {
        //
        // Every pitch, interval, duration and ratio is different, so order 1 has one path in each
        // chain: the source itself, rest included.
        //
        let template = try analyzeSeparatedTemplate(makeStandardBeatWork(Fixtures.melodyWithRest),
                                                    pitch: pitch,
                                                    duration: duration)

        let work = try template.generateWork(name: "G",
                                             options: Template.GenerationOptions<BeatTime, Pitch>(length: .noteCount(20)),
                                             seed: 1)

        #expect(try standardBeatNoteTriples(of: work) == standardBeatNoteTriples(of: makeStandardBeatWork(Fixtures.melodyWithRest)))
    }

    @Test
    func generation_sameSeed_sameWork() throws {
        let template = try analyzeSeparatedTemplate(makeStandardBeatWork(Fixtures.melodyWithRest + [(9, 1, .c4), (10, 2, .e4)]))
        let options = Template.GenerationOptions<BeatTime, Pitch>(order: 0,
                                                                  length: .noteCount(25),
                                                                  stopsAtEnd: false)

        let notes1 = try standardBeatNoteTriples(of: template.generateWork(name: "G", options: options, seed: 7))
        let notes2 = try standardBeatNoteTriples(of: template.generateWork(name: "G", options: options, seed: 7))

        #expect(notes1 == notes2)
        #expect(!notes1.isEmpty)
    }

    @Test
    func metrics_separatedTemplate_describesEachChain() throws {
        let template = try analyzeSeparatedTemplate(makeStandardBeatWork(Fixtures.melodyWithRest))

        let durationMetrics = try #require(template.metrics(for: .duration))
        let pitchMetrics = try #require(template.metrics(for: .pitch))

        #expect(template.metrics(for: .joint) == nil)
        #expect(durationMetrics.stateCount == 5)
        #expect(pitchMetrics.stateCount == 4)
        #expect(durationMetrics.order == 1)
        #expect(pitchMetrics.order == 1)
    }
}

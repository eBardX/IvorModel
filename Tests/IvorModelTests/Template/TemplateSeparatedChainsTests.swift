// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers

struct TemplateSeparatedChainsTests {
}

// MARK: -

extension TemplateSeparatedChainsTests {
    @Test
    func analysis_eachChainLearnsItsHalf() throws {
        let template = try _analyze(_beatWork(_melodyWithRest))
        let durationStates = try _states(of: template, .duration)
        let pitchStates = try _states(of: template, .pitch)

        #expect(template.chainRoles == [.duration, .pitch])
        #expect(durationStates.allSatisfy { $0.pitches == nil && $0.duration != nil })
        #expect(durationStates.contains { $0.isRest })
        #expect(pitchStates.allSatisfy { !$0.isRest && $0.duration == nil && $0.pitches != nil })
        #expect(pitchStates.count == 4)
    }

    @Test
    func analysis_jointRecipe_hasOneChain() throws {
        let template = try Template.analyzeNoteEvents(in: _beatWork(_melodyWithRest),
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

        let original = try _analyze(_beatWork(melody))
        let altered = try _analyze(_beatWork(rhythm))

        #expect(try _states(of: original, .pitch) == _states(of: altered, .pitch))
        #expect(try _states(of: original, .duration) != _states(of: altered, .duration))
    }

    @Test(arguments: [Template.AnalysisOptions.StateRecipe(pitch: .omitted,
                                                           duration: .absolute,
                                                           separatesPitchAndDuration: true),
                      Template.AnalysisOptions.StateRecipe(pitch: .absolute,
                                                           duration: .omitted,
                                                           separatesPitchAndDuration: true)])
    func analysis_separatingWithoutBothFeatures_throws(recipe: Template.AnalysisOptions.StateRecipe) {
        #expect(throws: Template.Error.invalidStateRecipe) {
            try Template.analyzeNoteEvents(in: _beatWork([(0, 1, .c4)]),
                                           at: 0,
                                           options: .init(maximumOrder: 1,
                                                          states: recipe))
        }
    }

    @Test
    func coding_separatedTemplate_roundTripsThroughProject() throws {
        let template = try _analyze(_beatWork(_melodyWithRest),
                                    pitch: .interval,
                                    duration: .relative)
        var project = Project()

        project.updateTemplate(template)

        let loaded = try #require(Project.load(from: project.save()).fetchTemplate(template.templateID))

        #expect(loaded.analysisOptions == template.analysisOptions)
        #expect(loaded.chainRoles == [.duration, .pitch])
        #expect(try _states(of: loaded, .duration) == _states(of: template, .duration))
        #expect(try _states(of: loaded, .pitch) == _states(of: template, .pitch))
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

    @Test(arguments: [(Template.AnalysisOptions.StateRecipe.PitchFeature.absolute,
                       Template.AnalysisOptions.StateRecipe.DurationFeature.absolute),
                      (.interval, .relative)])
    func generation_reproducesSource(pitch: Template.AnalysisOptions.StateRecipe.PitchFeature,
                                     duration: Template.AnalysisOptions.StateRecipe.DurationFeature) throws {
        //
        // Every pitch, interval, duration and ratio is different, so order 1 has one path in each
        // chain: the source itself, rest included.
        //
        let template = try _analyze(_beatWork(_melodyWithRest),
                                    pitch: pitch,
                                    duration: duration)

        let work = try template.generateWork(name: "G",
                                             options: Template.GenerationOptions<BeatTime, Pitch>(length: .noteCount(20)),
                                             seed: 1)

        #expect(try _notes(of: work) == _notes(of: _beatWork(_melodyWithRest)))
    }

    @Test
    func generation_constraintsFilterTheirOwnChain() throws {
        let template = try _analyze(_beatWork(_scale))
        let allowed: Set<Pitch> = [.c4, .e4, .g4]

        let work = try template.generateWork(name: "G",
                                             options: Template.GenerationOptions<BeatTime, Pitch>(order: 0,
                                                                                                  length: .noteCount(30),
                                                                                                  stopsAtEnd: false,
                                                                                                  constraints: .init(allowedPitches: allowed,
                                                                                                                     maximumDuration: 1)),
                                             seed: 3)
        let notes = try _notes(of: work)

        #expect(notes.count == 30)
        #expect(notes.allSatisfy { allowed.contains($0.pitch) && $0.duration == 1 })
    }

    @Test
    func generation_durationChainEnd_stopsGeneration() throws {
        let template = try _analyze(_beatWork(_scale))

        let work = try template.generateWork(name: "G",
                                             options: Template.GenerationOptions<BeatTime, Pitch>(order: 1,
                                                                                                  length: .noteCount(50),
                                                                                                  pitchChain: .init(order: 0)),
                                             seed: 5)

        #expect(try _notes(of: work).map(\.duration) == [1, 2, 3, 4, 5])
    }

    @Test
    func generation_jointTemplateWithPitchChain_throws() throws {
        let template = try Template.analyzeNoteEvents(in: _beatWork(_scale),
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
        let template = try _analyze(_beatWork(_scale))

        let work = try template.generateWork(name: "G",
                                             options: Template.GenerationOptions<BeatTime, Pitch>(order: 0,
                                                                                                  length: .noteCount(50),
                                                                                                  pitchChain: .init(order: 1)),
                                             seed: 5)

        #expect(try _notes(of: work).map(\.pitch) == [.c4, .d4, .e4, .f4, .g4])
    }

    @Test
    func generation_pitchChainLoops_restartsOnlyThePitchChain() throws {
        let template = try _analyze(_beatWork(_scale))

        let work = try template.generateWork(name: "G",
                                             options: Template.GenerationOptions<BeatTime, Pitch>(order: 0,
                                                                                                  length: .noteCount(12),
                                                                                                  loops: true,
                                                                                                  pitchChain: .init(order: 1)),
                                             seed: 5)

        #expect(try _notes(of: work).map(\.pitch) == [.c4,
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
        let template = try _analyze(_beatWork(_scale))

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
        let template = try _analyze(_beatWork(melody),
                                    pitch: .interval)

        let work = try template.generateWork(name: "G",
                                             options: Template.GenerationOptions<BeatTime, Pitch>(order: 0,
                                                                                                  length: .noteCount(40),
                                                                                                  stopsAtEnd: false),
                                             seed: 9)
        let pitches = try _notes(of: work).map(\.pitch)

        #expect(pitches.count == 40)
        #expect(pitches.allSatisfy { (Pitch.c4...Pitch.c5).contains($0) })
    }

    @Test
    func generation_sameSeed_sameWork() throws {
        let template = try _analyze(_beatWork(_melodyWithRest + [(9, 1, .c4), (10, 2, .e4)]))
        let options = Template.GenerationOptions<BeatTime, Pitch>(order: 0,
                                                                  length: .noteCount(25),
                                                                  stopsAtEnd: false)

        let notes1 = try _notes(of: template.generateWork(name: "G", options: options, seed: 7))
        let notes2 = try _notes(of: template.generateWork(name: "G", options: options, seed: 7))

        #expect(notes1 == notes2)
        #expect(!notes1.isEmpty)
    }

    @Test
    func metrics_separatedTemplate_describesEachChain() throws {
        let template = try _analyze(_beatWork(_melodyWithRest))

        let durationMetrics = try #require(template.metrics(for: .duration))
        let pitchMetrics = try #require(template.metrics(for: .pitch))

        #expect(template.metrics(for: .joint) == nil)
        #expect(durationMetrics.stateCount == 5)
        #expect(pitchMetrics.stateCount == 4)
        #expect(durationMetrics.order == 1)
        #expect(pitchMetrics.order == 1)
    }
}

// MARK: - Private Constants

//
// Four notes and a rest, with every pitch, duration, interval and ratio different.
//
private let _melodyWithRest: [(Number, Number, Pitch)] = [(0, 1, .c4),
                                                          (1, 2, .d4),
                                                          (Number(numerator: 7, denominator: 2), 3, .f4),
                                                          (Number(numerator: 13, denominator: 2), Number(numerator: 5, denominator: 2), .b4)]

//
// Five rising pitches, each with its own duration.
//
private let _scale: [(Number, Number, Pitch)] = [(0, 1, .c4),
                                                 (1, 2, .d4),
                                                 (3, 3, .e4),
                                                 (6, 4, .f4),
                                                 (10, 5, .g4)]

// MARK: - Private Functions

private func _analyze(_ work: Work,
                      pitch: Template.AnalysisOptions.StateRecipe.PitchFeature = .absolute,
                      duration: Template.AnalysisOptions.StateRecipe.DurationFeature = .absolute) throws -> Template {
    try Template.analyzeNoteEvents(in: work,
                                   at: 0,
                                   options: .init(maximumOrder: 1,
                                                  states: .init(pitch: pitch,
                                                                duration: duration,
                                                                separatesPitchAndDuration: true)))
}

private func _beatWork(_ notes: [(Number, Number, Pitch)]) -> Work {
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

private func _notes(of work: Work) throws -> [NoteTripleSB] {
    guard case let .standardBeat(parts, _) = work.content
    else { throw Template.Error.incompatibleOptions }

    return try makeNoteTriplesSB(#require(parts.first).noteTable)
}

private func _states(of template: Template,
                     _ role: Template.ChainRole) throws -> [Template.State<BeatTime, Pitch>] {
    guard case let .standardBeat(model) = template.content
    else { throw Template.Error.incompatibleOptions }

    return try #require(model.chains.chain(for: role)).states.sorted()
}

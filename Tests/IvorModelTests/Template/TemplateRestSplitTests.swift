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
struct TemplateRestSplitTests {
}

// MARK: -

extension TemplateRestSplitTests {
    @Test
    func analyze_noSplit_learnsEveryRest() throws {
        let template = try _analyze(restSplit: nil)

        #expect(try _beginCount(of: template, .joint) == 1)
        #expect(try _vocabulary(of: template).durations[_beats(4)] != nil)
        #expect(template.analysisSummary.sequenceCount == 1)
    }

    @Test
    func analyze_split_restExactlyAtMinimumSplits() throws {
        let template = try _analyze(restSplit: .beat(_beats(4)))

        #expect(try _beginCount(of: template, .joint) == 2)
    }

    @Test
    func analyze_split_separatedChains_splitBoth() throws {
        let template = try _analyze(restSplit: .beat(_beats(2)),
                                    states: .init(separatesPitchAndDuration: true))

        #expect(try _beginCount(of: template, .duration) == 2)
        #expect(try _beginCount(of: template, .pitch) == 2)
    }

    @Test
    func analyze_split_startsNewSequenceAndDropsLongRest() throws {
        let template = try _analyze(restSplit: .beat(_beats(2)))
        let vocabulary = try _vocabulary(of: template)

        #expect(try _beginCount(of: template, .joint) == 2)
        #expect(try _endCount(of: template, .joint) == 2)
        #expect(template.analysisSummary.sequenceCount == 2)
        #expect(template.analysisOptions.restSplit == .beat(_beats(2)))

        //
        // The long rest is never learned; the short one and the long note still are.
        //
        #expect(vocabulary.durations[_beats(4)] == 1)
        #expect(vocabulary.durations[_beats(1)] == 5)
        #expect(try !_hasState(in: template) { $0.isRest && $0.duration == .absolute(_beats(4)) })
        #expect(try _hasState(in: template) { $0.isRest && $0.duration == .absolute(_beats(1)) })
    }

    @Test
    func analyze_split_withRetrograde_splitsEachVariant() throws {
        let template = try _analyze(restSplit: .beat(_beats(2)),
                                    variants: .init(retrogrades: true))

        #expect(template.analysisSummary.sequenceCount == 4)
        #expect(try _beginCount(of: template, .joint) == 4)
    }

    @Test
    func analyze_wallSplitOnBeatWork_throws() throws {
        // swiftlint:disable:next force_unwrapping
        let split = Template.AnalysisOptions.RestSplit.wall(WallDuration(uintValue: 1_000_000)!)

        #expect(throws: Template.Error.incompatibleOptions) {
            try _analyze(restSplit: split)
        }
    }

    @Test
    func analyze_zeroSplit_throws() throws {
        #expect(throws: Template.Error.invalidTolerance) {
            try _analyze(restSplit: .beat(.zero))
        }
    }

    @Test
    func constraints_maximumRestDuration_leavesNotesAlone() {
        let constraints = Template.GenerationOptions<BeatTime, Pitch>.Constraints(maximumRestDuration: _beats(2))

        #expect(!constraints.isEmpty)
        #expect(constraints.allows(NoteEvent(tiedPitches: [], duration: _beats(2))))
        #expect(!constraints.allows(NoteEvent(tiedPitches: [], duration: _beats(4))))
        #expect(constraints.allows(NoteEvent(tiedPitches: [.init(pitch: .g4)], duration: _beats(4))))
    }

    @Test
    func generate_maximumRestDuration_neverChoosesLongRest() throws {
        let template = try _analyze(restSplit: nil)
        let constraints = Template.GenerationOptions<BeatTime, Pitch>.Constraints(maximumRestDuration: _beats(2))
        var sawShortRest = false

        for seed in UInt64(0)..<10 {
            let work = try template.generateWork(name: "G",
                                                 options: .init(order: 1,
                                                                length: .noteCount(30),
                                                                stopsAtEnd: false,
                                                                backsOff: true,
                                                                constraints: constraints),
                                                 seed: seed)

            guard case let .standardBeat(parts, _) = work.content
            else { Issue.record("not standard beat"); return }

            let events = try #require(parts.first).noteTable.extractNoteEvents()

            #expect(!events.isEmpty)
            #expect(events.allSatisfy { constraints.allows($0) })

            sawShortRest = sawShortRest || events.contains { $0.tiedPitches.isEmpty }
        }

        #expect(sawShortRest)
    }

    @Test
    func sequenceCount_countsEachVariantsSplits() throws {
        let split = Template.AnalysisOptions.RestSplit.beat(_beats(2))

        #expect(try Template.sequenceCount(in: _work(), at: 0, options: .init(maximumOrder: 1)) == 1)
        #expect(try Template.sequenceCount(in: _work(), at: 0, options: .init(maximumOrder: 1, restSplit: split)) == 2)
        #expect(try Template.sequenceCount(in: _work(),
                                           at: 0,
                                           options: .init(maximumOrder: 1,
                                                          variants: .init(retrogrades: true),
                                                          restSplit: split)) == 4)
    }

    @Test
    func sequenceCount_matchesAnalysisWithoutMerges() throws {
        let options = Template.AnalysisOptions(maximumOrder: 2,
                                               variants: .init(retrogrades: true),
                                               restSplit: .beat(_beats(2)))
        let summary = try Template.analyzeNoteEvents(in: _work(), at: 0, options: options).analysisSummary

        #expect(summary.mergedCount == 0)
        #expect(try Template.sequenceCount(in: _work(), at: 0, options: options) == summary.sequenceCount)
    }

    @Test
    func sequenceCount_timeScaling_changesWhichRestsSplit() throws {
        //
        // Halved, the four-beat rest lasts two beats — still long enough at two, not at three.
        //
        let variants = Template.AnalysisOptions.Variants(timeFactors: [Number(numerator: 1, denominator: 2)])

        #expect(try Template.sequenceCount(in: _work(),
                                           at: 0,
                                           options: .init(maximumOrder: 1,
                                                          variants: variants,
                                                          restSplit: .beat(_beats(2)))) == 4)
        #expect(try Template.sequenceCount(in: _work(),
                                           at: 0,
                                           options: .init(maximumOrder: 1,
                                                          variants: variants,
                                                          restSplit: .beat(_beats(3)))) == 3)
    }

    @Test
    func sequenceCount_invalidOptions_throw() {
        #expect(throws: Template.Error.invalidTolerance) {
            try Template.sequenceCount(in: _work(), at: 0, options: .init(maximumOrder: 1, restSplit: .beat(.zero)))
        }

        #expect(throws: Template.Error.partNotFound(4)) {
            try Template.sequenceCount(in: _work(), at: 4, options: .init(maximumOrder: 1))
        }
    }

    @Test
    func restSplit_codable_roundTrip() throws {
        let options = Template.AnalysisOptions(maximumOrder: 2,
                                               restSplit: .beat(_beats(2)))
        let decoded = try JSONDecoder().decode(Template.AnalysisOptions.self,
                                               from: JSONEncoder().encode(options))

        #expect(decoded == options)
    }
}

// MARK: - Private Types

private typealias _State = Template.State<BeatTime, Pitch>

// MARK: - Private Functions

private func _analyze(restSplit: Template.AnalysisOptions.RestSplit?,
                      states: Template.AnalysisOptions.StateRecipe = .exact,
                      variants: Template.AnalysisOptions.Variants = .none) throws -> Template {
    try Template.analyzeNoteEvents(in: _work(),
                                   at: 0,
                                   options: .init(maximumOrder: 2,
                                                  states: states,
                                                  variants: variants,
                                                  restSplit: restSplit))
}

private func _beats(_ value: Number) -> BeatDuration {
    // swiftlint:disable:next force_unwrapping
    BeatDuration(numberValue: value)!
}

//
// C D, a four-beat rest, E F, a one-beat rest, then G held for four beats.
//
private func _work() -> Work {
    var noteTable = NoteTable<BeatTime, Pitch>()

    for (attack, duration, pitch) in [(0, 1, Pitch.c4), (1, 1, .d4), (6, 1, .e4), (7, 1, .f4), (9, 4, .g4)] as [(Number, Number, Pitch)] {
        // swiftlint:disable:next force_unwrapping
        noteTable.insert(attack: BeatTime(numberValue: attack)!,
                         duration: _beats(duration),
                         pitch: pitch)
    }

    return Work(name: "Tune",
                content: .standardBeat([Part(name: "Flute", noteTable: noteTable)], TempoMap()))
}

private func _beginCount(of template: Template,
                         _ role: Template.ChainRole) throws -> UInt {
    var count: UInt = 0

    try _chain(of: template, role).forEach { transition in
        if case .begin = transition.source {
            count += transition.weight
        }
    }

    return count
}

private func _chain(of template: Template,
                    _ role: Template.ChainRole) throws -> MarkovChain<_State> {
    guard case let .standardBeat(model) = template.content
    else { throw Template.Error.incompatibleOptions }

    return try #require(model.chains.chain(for: role))
}

private func _endCount(of template: Template,
                       _ role: Template.ChainRole) throws -> UInt {
    var count: UInt = 0

    try _chain(of: template, role).forEach { transition in
        //
        // Order-1 contexts only, so that each sequence's end counts once.
        //
        if case .end = transition.target, case let .states(states) = transition.source, states.count == 1 {
            count += transition.weight
        }
    }

    return count
}

private func _hasState(in template: Template,
                       where predicate: (_State) -> Bool) throws -> Bool {
    var found = false

    try _chain(of: template, .joint).forEach { transition in
        if case let .state(state) = transition.target, predicate(state) {
            found = true
        }
    }

    return found
}

private func _vocabulary(of template: Template) throws -> Template.Vocabulary<BeatTime, Pitch> {
    guard case let .standardBeat(model) = template.content
    else { throw Template.Error.incompatibleOptions }

    return model.vocabulary
}

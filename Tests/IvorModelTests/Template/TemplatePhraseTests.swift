// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct TemplatePhraseTests {
}

// MARK: -

extension TemplatePhraseTests {
    @Test
    func phrase_fromSource_continuesAsSourceGoesOn() throws {
        let source = _beatWork(_melody)
        let template = try _analyze(source)

        let work = try template.generateWork(name: "G",
                                             options: Options(order: 2,
                                                              length: .noteCount(20),
                                                              phrase: .init(noteEvents: _noteEvents(of: source).prefix(2).map(\.self))),
                                             seed: 1)

        #expect(try _notes(of: work) == _notes(of: source))
    }

    @Test
    func phrase_notIncluded_outputIsContinuationAlone() throws {
        let source = _beatWork(_melody)
        let template = try _analyze(source)

        let work = try template.generateWork(name: "G",
                                             options: Options(order: 2,
                                                              length: .noteCount(20),
                                                              phrase: .init(noteEvents: _noteEvents(of: source).prefix(2).map(\.self),
                                                                            includesPhrase: false)),
                                             seed: 1)
        let notes = try _notes(of: work)

        #expect(notes.first?.attack == 0)
        #expect(notes.map(\.pitch) == [.g4, .b4])
    }

    @Test
    func phrase_tieAcrossJoin_isOneNote() throws {
        //
        // C4 sounds across E4's attack, so the source's first event is [C4⌒], and the next
        // [⌒C4 E4].  A phrase of just the first event is continued with the tie's end.
        //
        let source = _beatWork([(0, 2, .c4), (1, 1, .e4), (2, 1, .g4)])
        let template = try _analyze(source, maximumOrder: 1)

        let work = try template.generateWork(name: "G",
                                             options: Options(length: .noteCount(20),
                                                              phrase: .init(noteEvents: [_noteEvents(of: source)[0]])),
                                             seed: 1)

        #expect(try _notes(of: work) == _notes(of: source))
    }

    @Test
    func phrase_intervalRecipe_continuesFromPhrasesBass() throws {
        let source = _beatWork([(0, 1, .c4), (1, 1, .e4), (2, 1, .g4), (3, 1, .c5)])
        let template = try _analyze(source,
                                    maximumOrder: 1,
                                    states: .init(pitch: .interval))
        let transposed = _noteEvents(of: _beatWork([(0, 1, .d4), (1, 1, .fSharp4)]))

        let work = try template.generateWork(name: "G",
                                             options: Options(length: .noteCount(20),
                                                              constraints: .init(pitchRange: Pitch.c4...Pitch.c6),
                                                              phrase: .init(noteEvents: transposed,
                                                                            includesPhrase: false)),
                                             seed: 1)

        #expect(try _notes(of: work).map(\.pitch) == [.a4, .d5])
    }

    @Test
    func phrase_unfamiliar_stopsWithoutBackOff() throws {
        let source = _beatWork(_melody)
        let template = try _analyze(source,
                                    maximumOrder: 1)
        let unfamiliar = _noteEvents(of: _beatWork([(0, 1, .fSharp5)]))

        let stopped = try template.generateWork(name: "G",
                                                options: Options(length: .noteCount(5),
                                                                 phrase: .init(noteEvents: unfamiliar)),
                                                seed: 1)
        let backedOff = try template.generateWork(name: "G",
                                                  options: Options(length: .noteCount(5),
                                                                   backsOff: true,
                                                                   phrase: .init(noteEvents: unfamiliar)),
                                                  seed: 1)

        #expect(try _notes(of: stopped).count == 1)
        #expect(try _notes(of: backedOff).count == 6)
    }

    @Test
    func phrase_separatedChains_continueBothHalves() throws {
        let source = _beatWork(_melody)
        let template = try _analyze(source,
                                    states: .init(separatesPitchAndDuration: true))

        let work = try template.generateWork(name: "G",
                                             options: Options(order: 2,
                                                              length: .noteCount(20),
                                                              phrase: .init(noteEvents: _noteEvents(of: source).prefix(2).map(\.self))),
                                             seed: 1)

        #expect(try _notes(of: work) == _notes(of: source))
    }

    @Test
    func phrase_empty_throws() throws {
        let template = try _analyze(_beatWork(_melody))

        #expect(throws: Template.Error.invalidPhrase) {
            try template.generateWork(name: "G",
                                      options: Options(phrase: .init(noteEvents: [])),
                                      seed: 1)
        }
    }

    @Test
    func phrase_recipe_roundTripsAndReproduces() throws {
        let source = _beatWork(_melody)
        let template = try _analyze(source, maximumOrder: 1)
        let options = Options(order: 0,
                              length: .noteCount(12),
                              stopsAtEnd: false,
                              phrase: .init(noteEvents: _noteEvents(of: source).prefix(2).map(\.self)))

        let decoded = try JSONDecoder().decode(Options.self,
                                               from: JSONEncoder().encode(options))
        let work1 = try template.generateWork(name: "G", options: options, seed: 7)
        let work2 = try template.generateWork(name: "G", options: decoded, seed: 7)

        #expect(decoded == options)
        #expect(try _notes(of: work1) == _notes(of: work2))
        #expect(work1.generation?.options == .standardBeat(options))
    }

    @Test
    func phraseLearner_mapsDurationsToRepresentatives() throws {
        var noteTable = NoteTable<WallTime, Pitch>()
        var attack: UInt = 0

        for milliseconds: UInt in [500, 510, 500, 505, 500] {
            try noteTable.insert(attack: #require(WallTime(uintValue: attack * 1_000)),
                                 duration: #require(WallDuration(uintValue: milliseconds * 1_000)),
                                 pitch: .c4)
            attack += milliseconds
        }

        let template = try Template.analyzeNoteEvents(in: Work(content: .standardWall([Part(name: "Flute", noteTable: noteTable)])),
                                                      at: 0,
                                                      options: .init(maximumOrder: 1,
                                                                     durations: .proportional(0.05)))

        guard case let .standardWall(model) = template.content
        else { throw Template.Error.incompatibleOptions }

        let learner = Template.PhraseLearner(analysisOptions: template.analysisOptions,
                                             vocabulary: model.vocabulary,
                                             grouping: { _ in [:] },
                                             rounding: { $0 })
        let representative = try #require(WallDuration(uintValue: 500_000))
        let member = try #require(WallDuration(uintValue: 510_000))
        let near = try #require(WallDuration(uintValue: 520_000))
        let far = try #require(WallDuration(uintValue: 900_000))

        let learned = learner.learn([member, near, far].map { NoteEvent(tiedPitches: [.init(pitch: .c4)], duration: $0) })

        #expect(learned.noteEvents.map(\.duration) == [representative, representative, far])
        #expect(learned.states.count == 3)
    }
}

// MARK: - Private Type Aliases

private typealias Options = Template.GenerationOptions<BeatTime, Pitch>

// MARK: - Private Constants

//
// Every pitch and duration different, so each context leads to one place: the source itself.
//
private let _melody: [(Number, Number, Pitch)] = [(0, 1, .c4),
                                                  (1, 2, .e4),
                                                  (3, Number(numerator: 1, denominator: 2), .g4),
                                                  (Number(numerator: 7, denominator: 2), 3, .b4)]

// MARK: - Private Functions

private func _analyze(_ work: Work,
                      maximumOrder: Int = 2,
                      states: Template.AnalysisOptions.StateRecipe = .exact) throws -> Template {
    try Template.analyzeNoteEvents(in: work,
                                   at: 0,
                                   options: .init(maximumOrder: maximumOrder,
                                                  states: states))
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

private func _noteEvents(of work: Work) -> [NoteEvent<BeatTime, Pitch>] {
    guard case let .standardBeat(parts, _) = work.content
    else { return [] }

    return parts.first?.noteTable.extractNoteEvents() ?? []
}

private func _notes(of work: Work) throws -> [NoteTripleSB] {
    guard case let .standardBeat(parts, _) = work.content
    else { throw Template.Error.incompatibleOptions }

    return try makeNoteTriplesSB(#require(parts.first).noteTable)
}

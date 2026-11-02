// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct TemplateGenerationOptionsPhraseTests {
}

// MARK: -

extension TemplateGenerationOptionsPhraseTests {
    @Test
    func phrase_empty_throws() throws {
        let template = try analyzePhraseTemplate(makeStandardBeatWork(Fixtures.phraseMelody))

        #expect(throws: Template.Error.invalidPhrase) {
            try template.generateWork(name: "G",
                                      options: StandardBeatOptions(phrase: .init(noteEvents: [])),
                                      seed: 1)
        }
    }

    @Test
    func phrase_fromSource_continuesAsSourceGoesOn() throws {
        let source = makeStandardBeatWork(Fixtures.phraseMelody)
        let template = try analyzePhraseTemplate(source)

        let work = try template.generateWork(name: "G",
                                             options: StandardBeatOptions(order: 2,
                                                                          length: .noteCount(20),
                                                                          phrase: .init(noteEvents: standardBeatNoteEventsOrEmpty(of: source)
                                                                                                    .prefix(2).map(\.self))),
                                             seed: 1)

        #expect(try standardBeatNoteTriples(of: work) == standardBeatNoteTriples(of: source))
    }

    @Test
    func phrase_intervalRecipe_continuesFromPhrasesBass() throws {
        let source = makeStandardBeatWork([(0, 1, .c4), (1, 1, .e4), (2, 1, .g4), (3, 1, .c5)])
        let template = try analyzePhraseTemplate(source,
                                                 maximumOrder: 1,
                                                 states: .init(pitch: .interval))
        let transposed = standardBeatNoteEventsOrEmpty(of: makeStandardBeatWork([(0, 1, .d4), (1, 1, .fSharp4)]))

        let work = try template.generateWork(name: "G",
                                             options: StandardBeatOptions(length: .noteCount(20),
                                                                          constraints: .init(pitchRange: Pitch.c4...Pitch.c6),
                                                                          phrase: .init(noteEvents: transposed,
                                                                                        includesPhrase: false)),
                                             seed: 1)

        #expect(try standardBeatNoteTriples(of: work).map(\.pitch) == [.a4, .d5])
    }

    @Test
    func phrase_notIncluded_outputIsContinuationAlone() throws {
        let source = makeStandardBeatWork(Fixtures.phraseMelody)
        let template = try analyzePhraseTemplate(source)

        let work = try template.generateWork(name: "G",
                                             options: StandardBeatOptions(order: 2,
                                                                          length: .noteCount(20),
                                                                          phrase: .init(noteEvents: standardBeatNoteEventsOrEmpty(of: source)
                                                                                                    .prefix(2).map(\.self),
                                                                                        includesPhrase: false)),
                                             seed: 1)
        let notes = try standardBeatNoteTriples(of: work)

        #expect(notes.first?.attack == 0)
        #expect(notes.map(\.pitch) == [.g4, .b4])
    }

    @Test
    func phrase_recipe_roundTripsAndReproduces() throws {
        let source = makeStandardBeatWork(Fixtures.phraseMelody)
        let template = try analyzePhraseTemplate(source, maximumOrder: 1)
        let options = StandardBeatOptions(order: 0,
                                          length: .noteCount(12),
                                          stopsAtEnd: false,
                                          phrase: .init(noteEvents: standardBeatNoteEventsOrEmpty(of: source)
                                                                    .prefix(2).map(\.self)))

        let decoded = try JSONDecoder().decode(StandardBeatOptions.self,
                                               from: JSONEncoder().encode(options))
        let work1 = try template.generateWork(name: "G", options: options, seed: 7)
        let work2 = try template.generateWork(name: "G", options: decoded, seed: 7)

        #expect(decoded == options)
        #expect(try standardBeatNoteTriples(of: work1) == standardBeatNoteTriples(of: work2))
        #expect(work1.generation?.options == .standardBeat(options))
    }

    @Test
    func phrase_separatedChains_continueBothHalves() throws {
        let source = makeStandardBeatWork(Fixtures.phraseMelody)
        let template = try analyzePhraseTemplate(source,
                                                 states: .init(separatesPitchAndDuration: true))

        let work = try template.generateWork(name: "G",
                                             options: StandardBeatOptions(order: 2,
                                                                          length: .noteCount(20),
                                                                          phrase: .init(noteEvents: standardBeatNoteEventsOrEmpty(of: source)
                                                                                                    .prefix(2).map(\.self))),
                                             seed: 1)

        #expect(try standardBeatNoteTriples(of: work) == standardBeatNoteTriples(of: source))
    }

    @Test
    func phrase_tieAcrossJoin_isOneNote() throws {
        //
        // C4 sounds across E4's attack, so the source's first event is [C4⌒], and the next
        // [⌒C4 E4].  A phrase of just the first event is continued with the tie's end.
        //
        let source = makeStandardBeatWork([(0, 2, .c4), (1, 1, .e4), (2, 1, .g4)])
        let template = try analyzePhraseTemplate(source, maximumOrder: 1)

        let work = try template.generateWork(name: "G",
                                             options: StandardBeatOptions(length: .noteCount(20),
                                                                          phrase: .init(noteEvents: [standardBeatNoteEventsOrEmpty(of: source)[0]])),
                                             seed: 1)

        #expect(try standardBeatNoteTriples(of: work) == standardBeatNoteTriples(of: source))
    }

    @Test
    func phrase_unfamiliar_stopsWithoutBackOff() throws {
        let source = makeStandardBeatWork(Fixtures.phraseMelody)
        let template = try analyzePhraseTemplate(source,
                                                 maximumOrder: 1)
        let unfamiliar = standardBeatNoteEventsOrEmpty(of: makeStandardBeatWork([(0, 1, .fSharp5)]))

        let stopped = try template.generateWork(name: "G",
                                                options: StandardBeatOptions(length: .noteCount(5),
                                                                             phrase: .init(noteEvents: unfamiliar)),
                                                seed: 1)
        let backedOff = try template.generateWork(name: "G",
                                                  options: StandardBeatOptions(length: .noteCount(5),
                                                                               backsOff: true,
                                                                               phrase: .init(noteEvents: unfamiliar)),
                                                  seed: 1)

        #expect(try standardBeatNoteTriples(of: stopped).count == 1)
        #expect(try standardBeatNoteTriples(of: backedOff).count == 6)
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

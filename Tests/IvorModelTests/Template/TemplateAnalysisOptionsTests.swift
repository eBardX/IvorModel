// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers

struct TemplateAnalysisOptionsTests {
}

// MARK: -

extension TemplateAnalysisOptionsTests {
    @Test
    func analyzeNoteEvents_beatGrid_mergesStaggeredChord() throws {
        let work = makeStandardBeatWork([(0, 1, .c4),
                                         (Number(numerator: 1, denominator: 32), 1, .e4)])

        let exact = try jointNoteEvents(of: Template.analyzeNoteEvents(in: work,
                                                                       at: 0,
                                                                       maximumOrder: 1,
                                                                       name: "Test"))

        #expect(exact.count == 3)

        let states = try jointNoteEvents(of: Template.analyzeNoteEvents(in: work,
                                                                        at: 0,
                                                                        options: .init(maximumOrder: 1,
                                                                                       timing: .grid(factors: [4])),
                                                                        name: "Test"))

        #expect(states == [NoteEvent(pitches: [.c4, .e4], duration: 1)])
    }

    @Test
    func analyzeNoteEvents_cents_roundsAndMergesPitches() throws {
        //
        // Each is within half a cent of 440 Hz.
        //
        let work = try makeAbsoluteWallWork([(0, 500, [440.1, 439.9]),
                                             (500, 500, [440.12])])

        let template = try Template.analyzeNoteEvents(in: work,
                                                      at: 0,
                                                      options: .init(maximumOrder: 1,
                                                                     pitches: .cents(1)),
                                                      name: "Test")
        let states = try absoluteWallNoteEvents(of: template)

        #expect(states == [NoteEvent(pitches: [440], duration: wallDuration(500))])
    }

    @Test
    func analyzeNoteEvents_cents_semitones() throws {
        let work = try makeAbsoluteWallWork([(0, 500, [450])])

        let states = try absoluteWallNoteEvents(of: Template.analyzeNoteEvents(in: work,
                                                                               at: 0,
                                                                               options: .init(maximumOrder: 1,
                                                                                              pitches: .cents(100)),
                                                                               name: "Test"))

        #expect(states == [NoteEvent(pitches: [440], duration: wallDuration(500))])
    }

    @Test
    func analyzeNoteEvents_exact_recordsOptions() throws {
        let template = try Template.analyzeNoteEvents(in: makeStandardBeatWork([(0, 1, .c4)]),
                                                      at: 0,
                                                      maximumOrder: 2,
                                                      name: "Test")

        #expect(template.analysisOptions == Template.AnalysisOptions(maximumOrder: 2))
    }

    @Test
    func analyzeNoteEvents_incompatibleOptions_throws() throws {
        let beatWork = makeStandardBeatWork([(0, 1, .c4)])
        let wallWork = makeC4WallWork([(0, 500)])

        for options in [Template.AnalysisOptions(maximumOrder: 1, timing: .window(wallDuration(10))),
                        Template.AnalysisOptions(maximumOrder: 1, durations: .step(wallDuration(10))),
                        Template.AnalysisOptions(maximumOrder: 1, pitches: .cents(1))] {
            #expect(throws: Template.Error.incompatibleOptions) {
                try Template.analyzeNoteEvents(in: beatWork,
                                               at: 0,
                                               options: options,
                                               name: "Test")
            }
        }

        #expect(throws: Template.Error.incompatibleOptions) {
            try Template.analyzeNoteEvents(in: wallWork,
                                           at: 0,
                                           options: .init(maximumOrder: 1,
                                                          timing: .grid(factors: [4])),
                                           name: "Test")
        }
    }

    @Test
    func analyzeNoteEvents_invalidOptions_throw() throws {
        let work = makeC4WallWork([(0, 500)])

        #expect(throws: Template.Error.invalidMaximumOrder) {
            try Template.analyzeNoteEvents(in: work,
                                           at: 0,
                                           options: .init(maximumOrder: 0),
                                           name: "Test")
        }

        let zero = wallDuration(0)

        for options in [Template.AnalysisOptions(maximumOrder: 1, timing: .grid(factors: [])),
                        Template.AnalysisOptions(maximumOrder: 1, timing: .grid(factors: [4, 0])),
                        Template.AnalysisOptions(maximumOrder: 1, timing: .window(zero)),
                        Template.AnalysisOptions(maximumOrder: 1, durations: .proportional(0)),
                        Template.AnalysisOptions(maximumOrder: 1, durations: .proportional(.nan)),
                        Template.AnalysisOptions(maximumOrder: 1, durations: .step(zero)),
                        Template.AnalysisOptions(maximumOrder: 1, pitches: .cents(-1)),
                        Template.AnalysisOptions(maximumOrder: 1, pitches: .cents(.infinity))] {
            #expect(throws: Template.Error.invalidTolerance) {
                try Template.analyzeNoteEvents(in: work,
                                               at: 0,
                                               options: options,
                                               name: "Test")
            }
        }
    }

    @Test
    func analyzeNoteEvents_proportional_mostCommonWins() throws {
        let work = makeC4WallWork([(0, 500), (500, 510), (1_010, 510), (1_520, 1_000)])

        let durations = try standardWallNoteEvents(of: Template.analyzeNoteEvents(in: work,
                                                                                  at: 0,
                                                                                  options: .init(maximumOrder: 1,
                                                                                                 durations: .proportional(0.05)),
                                                                                  name: "Test"))
            .map(\.duration)

        #expect(durations == [wallDuration(510), wallDuration(1_000)])
    }

    @Test
    func analyzeNoteEvents_proportional_tieKeepsShortest() throws {
        let work = makeC4WallWork([(0, 500), (500, 510)])

        let durations = try standardWallNoteEvents(of: Template.analyzeNoteEvents(in: work,
                                                                                  at: 0,
                                                                                  options: .init(maximumOrder: 1,
                                                                                                 durations: .proportional(0.05)),
                                                                                  name: "Test"))
            .map(\.duration)

        #expect(durations == [wallDuration(500)])
    }

    @Test
    func analyzeNoteEvents_step_roundsButNeverToZero() throws {
        let work = makeC4WallWork([(0, 480), (480, 530), (1_010, 20)])

        let durations = try standardWallNoteEvents(of: Template.analyzeNoteEvents(in: work,
                                                                                  at: 0,
                                                                                  options: .init(maximumOrder: 1,
                                                                                                 durations: .step(wallDuration(100))),
                                                                                  name: "Test"))
            .map(\.duration)

        #expect(durations == [wallDuration(100), wallDuration(500)])
    }

    @Test
    func analyzeNoteEvents_window_mergesStaggeredChord() throws {
        var noteTable = NoteTable<WallTime, Pitch>()

        noteTable.insert(attack: wallTime(0), duration: wallDuration(1_000), pitch: .c4)
        noteTable.insert(attack: wallTime(20), duration: wallDuration(1_000), pitch: .e4)

        let work = Work(content: .standardWall([Part(name: "Piano", noteTable: noteTable)]))

        let exact = try standardWallNoteEvents(of: Template.analyzeNoteEvents(in: work,
                                                                              at: 0,
                                                                              maximumOrder: 1,
                                                                              name: "Test"))

        #expect(exact.count == 3)

        let states = try standardWallNoteEvents(of: Template.analyzeNoteEvents(in: work,
                                                                               at: 0,
                                                                               options: .init(maximumOrder: 1,
                                                                                              timing: .window(wallDuration(50))),
                                                                               name: "Test"))

        #expect(states == [NoteEvent(pitches: [.c4, .e4], duration: wallDuration(1_000))])
    }

    @Test
    func codable_roundTrips() throws {
        let options = Template.AnalysisOptions(maximumOrder: 3,
                                               timing: .window(wallDuration(30)),
                                               durations: .proportional(0.05),
                                               pitches: .cents(1))
        let template = try Template.analyzeNoteEvents(in: makeAbsoluteWallWork([(0, 500, [440])]),
                                                      at: 0,
                                                      options: options,
                                                      name: "Test")

        let decoded = try JSONDecoder().decode(Template.self,
                                               from: JSONEncoder().encode(template))

        #expect(decoded.analysisOptions == options)
        #expect(decoded.version == Template.currentVersion)
    }

    @Test
    func mergingTimes_shortNoteKeepsWindow() {
        var noteTable = NoteTable<WallTime, Pitch>()

        noteTable.insert(attack: wallTime(0), duration: wallDuration(10), pitch: .c4)

        let merged = noteTable.mergingTimes(within: wallDuration(50))

        #expect(merged.notes.map(\.duration) == [wallDuration(50)])
    }
}

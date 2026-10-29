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
        let work = _beatWork([(0, 1, .c4),
                              (Number(numerator: 1, denominator: 32), 1, .e4)])

        let exact = try _states(of: Template.analyzeNoteEvents(in: work,
                                                               at: 0,
                                                               maximumOrder: 1))

        #expect(exact.count == 3)

        let states = try _states(of: Template.analyzeNoteEvents(in: work,
                                                                at: 0,
                                                                options: .init(maximumOrder: 1,
                                                                               timing: .grid(factors: [4]))))

        #expect(states == [NoteEvent(pitches: [.c4, .e4], duration: 1)])
    }

    @Test
    func analyzeNoteEvents_cents_roundsAndMergesPitches() throws {
        //
        // Each is within half a cent of 440 Hz.
        //
        let work = try _absoluteWallWork([(0, 500, [440.1, 439.9]),
                                          (500, 500, [440.12])])

        let template = try Template.analyzeNoteEvents(in: work,
                                                      at: 0,
                                                      options: .init(maximumOrder: 1,
                                                                     pitches: .cents(1)))
        let states = try _absoluteWallStates(of: template)

        #expect(states == [NoteEvent(pitches: [440], duration: _ms(500))])
    }

    @Test
    func analyzeNoteEvents_cents_semitones() throws {
        let work = try _absoluteWallWork([(0, 500, [450])])

        let states = try _absoluteWallStates(of: Template.analyzeNoteEvents(in: work,
                                                                            at: 0,
                                                                            options: .init(maximumOrder: 1,
                                                                                           pitches: .cents(100))))

        #expect(states == [NoteEvent(pitches: [440], duration: _ms(500))])
    }

    @Test
    func analyzeNoteEvents_exact_recordsOptions() throws {
        let template = try Template.analyzeNoteEvents(in: _beatWork([(0, 1, .c4)]),
                                                      at: 0,
                                                      maximumOrder: 2)

        #expect(template.analysisOptions == Template.AnalysisOptions(maximumOrder: 2))
    }

    @Test
    func analyzeNoteEvents_incompatibleOptions_throws() throws {
        let beatWork = _beatWork([(0, 1, .c4)])
        let wallWork = _wallWork([(0, 500)])

        for options in [Template.AnalysisOptions(maximumOrder: 1, timing: .window(_ms(10))),
                        Template.AnalysisOptions(maximumOrder: 1, durations: .step(_ms(10))),
                        Template.AnalysisOptions(maximumOrder: 1, pitches: .cents(1))] {
            #expect(throws: Template.Error.incompatibleOptions) {
                try Template.analyzeNoteEvents(in: beatWork,
                                               at: 0,
                                               options: options)
            }
        }

        #expect(throws: Template.Error.incompatibleOptions) {
            try Template.analyzeNoteEvents(in: wallWork,
                                           at: 0,
                                           options: .init(maximumOrder: 1,
                                                          timing: .grid(factors: [4])))
        }
    }

    @Test
    func analyzeNoteEvents_invalidOptions_throw() throws {
        let work = _wallWork([(0, 500)])

        #expect(throws: Template.Error.invalidMaximumOrder) {
            try Template.analyzeNoteEvents(in: work,
                                           at: 0,
                                           options: .init(maximumOrder: 0))
        }

        let zero = _ms(0)

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
                                               options: options)
            }
        }
    }

    @Test
    func analyzeNoteEvents_proportional_mostCommonWins() throws {
        let work = _wallWork([(0, 500), (500, 510), (1_010, 510), (1_520, 1_000)])

        let durations = try _wallStates(of: Template.analyzeNoteEvents(in: work,
                                                                       at: 0,
                                                                       options: .init(maximumOrder: 1,
                                                                                      durations: .proportional(0.05))))
            .map(\.duration)

        #expect(durations == [_ms(510), _ms(1_000)])
    }

    @Test
    func analyzeNoteEvents_proportional_tieKeepsShortest() throws {
        let work = _wallWork([(0, 500), (500, 510)])

        let durations = try _wallStates(of: Template.analyzeNoteEvents(in: work,
                                                                       at: 0,
                                                                       options: .init(maximumOrder: 1,
                                                                                      durations: .proportional(0.05))))
            .map(\.duration)

        #expect(durations == [_ms(500)])
    }

    @Test
    func analyzeNoteEvents_step_roundsButNeverToZero() throws {
        let work = _wallWork([(0, 480), (480, 530), (1_010, 20)])

        let durations = try _wallStates(of: Template.analyzeNoteEvents(in: work,
                                                                       at: 0,
                                                                       options: .init(maximumOrder: 1,
                                                                                      durations: .step(_ms(100)))))
            .map(\.duration)

        #expect(durations == [_ms(100), _ms(500)])
    }

    @Test
    func analyzeNoteEvents_window_mergesStaggeredChord() throws {
        var noteTable = NoteTable<WallTime, Pitch>()

        noteTable.insert(attack: _time(0), duration: _ms(1_000), pitch: .c4)
        noteTable.insert(attack: _time(20), duration: _ms(1_000), pitch: .e4)

        let work = Work(content: .standardWall([Part(name: "Piano", noteTable: noteTable)]))

        let exact = try _wallStates(of: Template.analyzeNoteEvents(in: work,
                                                                   at: 0,
                                                                   maximumOrder: 1))

        #expect(exact.count == 3)

        let states = try _wallStates(of: Template.analyzeNoteEvents(in: work,
                                                                    at: 0,
                                                                    options: .init(maximumOrder: 1,
                                                                                   timing: .window(_ms(50)))))

        #expect(states == [NoteEvent(pitches: [.c4, .e4], duration: _ms(1_000))])
    }

    @Test
    func codable_roundTrips() throws {
        let options = Template.AnalysisOptions(maximumOrder: 3,
                                               timing: .window(_ms(30)),
                                               durations: .proportional(0.05),
                                               pitches: .cents(1))
        let template = try Template.analyzeNoteEvents(in: _absoluteWallWork([(0, 500, [440])]),
                                                      at: 0,
                                                      options: options)

        let decoded = try JSONDecoder().decode(Template.self,
                                               from: JSONEncoder().encode(template))

        #expect(decoded.analysisOptions == options)
        #expect(decoded.version == Template.currentVersion)
    }

    @Test
    func mergingTimes_shortNoteKeepsWindow() {
        var noteTable = NoteTable<WallTime, Pitch>()

        noteTable.insert(attack: _time(0), duration: _ms(10), pitch: .c4)

        let merged = noteTable.mergingTimes(within: _ms(50))

        #expect(merged.notes.map(\.duration) == [_ms(50)])
    }
}

// MARK: - Private Functions

private func _absoluteWallStates(of template: Template) throws -> [NoteEvent<WallTime, Frequency>] {
    guard case let .absoluteWall(model) = template.content
    else { throw Template.Error.incompatibleOptions }

    return makeNoteEvents(model.markovChain.states).sorted { $0.duration < $1.duration }
}

private func _absoluteWallWork(_ notes: [(UInt, UInt, [Double])]) throws -> Work {
    var noteTable = NoteTable<WallTime, Frequency>()

    for (attack, duration, frequencies) in notes {
        for frequency in frequencies {
            try noteTable.insert(attack: _time(attack),
                                 duration: _ms(duration),
                                 pitch: #require(Frequency(numberValue: Number(floatLiteral: frequency))))
        }
    }

    return Work(content: .absoluteWall([Part(name: "Violin", noteTable: noteTable)]))
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

//
// `WallDuration(uintValue:)` and `WallTime(uintValue:)` never return `nil`.
//
private func _ms(_ milliseconds: UInt) -> WallDuration {
    WallDuration(uintValue: milliseconds * 1_000)! // swiftlint:disable:this force_unwrapping
}

private func _states(of template: Template) throws -> [NoteEvent<BeatTime, Pitch>] {
    guard case let .standardBeat(model) = template.content
    else { throw Template.Error.incompatibleOptions }

    return makeNoteEvents(model.markovChain.states)
}

private func _time(_ milliseconds: UInt) -> WallTime {
    WallTime(uintValue: milliseconds * 1_000)! // swiftlint:disable:this force_unwrapping
}

private func _wallStates(of template: Template) throws -> [NoteEvent<WallTime, Pitch>] {
    guard case let .standardWall(model) = template.content
    else { throw Template.Error.incompatibleOptions }

    return makeNoteEvents(model.markovChain.states).sorted { $0.duration < $1.duration }
}

//
// One C4 after another, each at the given attack and duration in milliseconds.
//
private func _wallWork(_ notes: [(UInt, UInt)]) -> Work {
    var noteTable = NoteTable<WallTime, Pitch>()

    for (attack, duration) in notes {
        noteTable.insert(attack: _time(attack),
                         duration: _ms(duration),
                         pitch: .c4)
    }

    return Work(content: .standardWall([Part(name: "Flute", noteTable: noteTable)]))
}

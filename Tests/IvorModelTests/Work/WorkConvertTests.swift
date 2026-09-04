// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiTools

struct WorkConvertTests {
}

// MARK: -

extension WorkConvertTests {
    @Test
    func convert_missingKeyboardMap() {
        let part = Part<BeatTime, Frequency>(name: "Piano")
        let work = Work(content: .absoluteBeat([part], TempoMap()))

        #expect(throws: Work.Error.self) {
            try work.convert(timeBasis: .beat,
                             pitchNotation: .keyboard,
                             context: Work.ConvertContext())
        }
    }

    @Test
    func convert_missingPitchSpeller() {
        let noteNumber = NoteNumber(uintValue: 69).require()
        var table = NoteTable<BeatTime, NoteNumber>()

        table.insert(attack: 0, duration: 1, pitch: noteNumber)

        let part = Part<BeatTime, NoteNumber>(name: "Piano", noteTable: table)
        let work = Work(content: .keyboardBeat([part], TempoMap()))

        #expect(throws: Work.Error.self) {
            try work.convert(timeBasis: .beat,
                             pitchNotation: .standard,
                             context: Work.ConvertContext())
        }
    }

    @Test
    func convert_missingPitchStandard() {
        var table = NoteTable<BeatTime, Pitch>()

        table.insert(attack: 0, duration: 1, pitch: .a4)

        let part = Part<BeatTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardBeat([part], TempoMap()))
        let context = Work.ConvertContext().tuningSystem(EqualTemperament.edo12)

        #expect(throws: Work.Error.self) {
            try work.convert(timeBasis: .beat,
                             pitchNotation: .absolute,
                             context: context)
        }
    }

    @Test
    func convert_missingTuningSystem() {
        var table = NoteTable<BeatTime, Pitch>()

        table.insert(attack: 0, duration: 1, pitch: .a4)

        let part = Part<BeatTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardBeat([part], TempoMap()))

        #expect(throws: Work.Error.self) {
            try work.convert(timeBasis: .beat,
                             pitchNotation: .absolute,
                             context: Work.ConvertContext())
        }
    }

    @Test
    func convert_noOp() throws {
        var table = NoteTable<BeatTime, Pitch>()

        table.insert(attack: 0, duration: 1, pitch: .a4)

        let part = Part<BeatTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardBeat([part], TempoMap()))

        let result = try work.convert(timeBasis: work.timeBasis,
                                      pitchNotation: work.pitchNotation)

        #expect(result == work)
    }

    @Test
    func convert_timeBasis_beatToWall() throws {
        var table = NoteTable<BeatTime, Pitch>()

        table.insert(attack: 0, duration: 1, pitch: .a4)

        let part = Part<BeatTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardBeat([part], TempoMap()))

        let result = try work.convert(timeBasis: .wall,
                                      pitchNotation: .standard)

        #expect(result.timeBasis == .wall)
        #expect(result.partCount == 1)
    }

    @Test
    func convert_timeBasis_wallToBeat() throws {
        var table = NoteTable<WallTime, Pitch>()

        table.insert(attack: 0, duration: 1, pitch: .a4)

        let part = Part<WallTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardWall([part]))

        let result = try work.convert(timeBasis: .beat,
                                      pitchNotation: .standard)

        #expect(result.timeBasis == .beat)
        #expect(result.partCount == 1)
    }
}

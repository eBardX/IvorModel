// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorSMPTE
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
    func convert_keepsNameAndSMPTEStartTime() throws {
        let startTime = try #require(SMPTETime(string: "01:00:00:00", frameRate: .fps24))
        let work = Work(name: "My Work",
                        content: .standardBeat([], TempoMap()),
                        smpteStartTime: startTime)

        let result = try #require(try work.convert(timeBasis: .beat,
                                                   pitchNotation: .absolute))

        #expect(result.name == "My Work")
        #expect(result.smpteStartTime == startTime)
    }

    @Test
    func convert_lockedWork_convertsPitchNotation() throws {
        var work = Work(content: .standardBeat([], TempoMap()))

        work.isLocked = true

        let result = try #require(try work.convert(timeBasis: .beat,
                                                   pitchNotation: .absolute))

        #expect(result.pitchNotation == .absolute)
        #expect(!result.isLocked)
        #expect(work.isLocked)
        #expect(work.pitchNotation == .standard)
    }

    @Test
    func convert_lockedWork_convertsTimeBasis() throws {
        var work = Work(content: .standardBeat([], TempoMap()))

        work.isLocked = true

        let result = try #require(try work.convert(timeBasis: .wall,
                                                   pitchNotation: .standard))

        #expect(result.timeBasis == .wall)
        #expect(!result.isLocked)
        #expect(work.timeBasis == .beat)
    }

    @Test
    func convert_missingPitchStandard() {
        var table = NoteTable<BeatTime, Pitch>()

        table.insert(attack: 0, duration: 1, pitch: .a4)

        let part = Part<BeatTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardBeat([part], TempoMap()))
        let context = Work.ConvertContext().tuningSystem(EqualTemperament.edo12)

        #expect(throws: Work.Error.missingPitchStandard) {
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

        #expect(throws: Work.Error.missingTuningSystem) {
            try work.convert(timeBasis: .beat,
                             pitchNotation: .absolute,
                             context: Work.ConvertContext())
        }
    }

    @Test
    func convert_noOp_returnsNil() throws {
        let work = Work(content: .standardBeat([], TempoMap()))

        let result = try work.convert(timeBasis: work.timeBasis,
                                      pitchNotation: work.pitchNotation)

        #expect(result == nil)
    }

    @Test
    func convert_returnsNewWorkID() throws {
        let work = Work(content: .standardBeat([], TempoMap()))

        let result = try #require(try work.convert(timeBasis: .wall,
                                                   pitchNotation: .absolute))

        #expect(result.workID != work.workID)
    }

    @Test
    func convert_standardToAbsolute() throws {
        var table = NoteTable<BeatTime, Pitch>()

        table.insert(attack: 0, duration: 1, pitch: .a4)

        let part = Part<BeatTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardBeat([part], TempoMap()))

        let result = try #require(try work.convert(timeBasis: .beat,
                                                   pitchNotation: .absolute))

        guard case let .absoluteBeat(parts, _) = result.content
        else {
            Issue.record("Expected absolute-beat content")
            return
        }

        #expect(parts.first?.noteTable.first?.startPitch == 440)
    }

    @Test
    func convert_timeBasis_beatToWall() throws {
        var table = NoteTable<BeatTime, Pitch>()

        table.insert(attack: 0, duration: 1, pitch: .a4)

        let part = Part<BeatTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardBeat([part], TempoMap()))

        let result = try #require(try work.convert(timeBasis: .wall,
                                                   pitchNotation: .standard))

        #expect(result.timeBasis == .wall)
        #expect(result.partCount == 1)
    }

    @Test
    func convert_timeBasis_wallToBeat() throws {
        var table = NoteTable<WallTime, Pitch>()

        table.insert(attack: 0, duration: 1, pitch: .a4)

        let part = Part<WallTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardWall([part]))

        let result = try #require(try work.convert(timeBasis: .beat,
                                                   pitchNotation: .standard))

        #expect(result.timeBasis == .beat)
        #expect(result.partCount == 1)
    }

    @Test(arguments: [(PitchNotation.absolute, PitchNotation.keyboard),
                      (.absolute, .standard),
                      (.keyboard, .absolute),
                      (.keyboard, .standard),
                      (.standard, .keyboard)])
    func convert_unsupportedPitchConversion(source: PitchNotation,
                                            target: PitchNotation) {
        let work = Work(content: .empty(timeBasis: .beat,
                                        pitchNotation: source))

        #expect(throws: Work.Error.unsupportedPitchConversion(from: source,
                                                              to: target)) {
            try work.convert(timeBasis: .beat,
                             pitchNotation: target)
        }
    }
}

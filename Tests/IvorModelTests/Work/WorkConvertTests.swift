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
    func convert_beatToWall_keepsInfo() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        let work = Work(content: .standardBeat([part], TempoMap()),
                        info: makeWorkInfo())

        let result = try #require(try work.convert(timeBasis: .wall,
                                                   pitchNotation: .standard))

        guard case .standardWall = result.content
        else { Issue.record("Expected .standardWall content."); return }

        #expect(result.info == work.info)
    }

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
    func convert_emptyKeyboardMap() {
        var table = NoteTable<BeatTime, Pitch>()

        table.insert(attack: 0, duration: 1, pitch: .a4)

        let part = Part<BeatTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardBeat([part], TempoMap()))
        let kmap = KeyboardMap(referenceNote: 69,
                               referenceFrequency: 440,
                               middleNote: 69,
                               equivalenceRatio: .octave,
                               ratios: [nil, nil] as [Ratio?])
        let context = Work.ConvertContext.default.keyboardMap(kmap)

        #expect(throws: Work.Error.emptyKeyboardMap) {
            try work.convert(timeBasis: .beat,
                             pitchNotation: .keyboard,
                             context: context)
        }
    }

    @Test
    func convert_missingKeyboardMap() {
        var table = NoteTable<BeatTime, Pitch>()

        table.insert(attack: 0, duration: 1, pitch: .a4)

        let part = Part<BeatTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardBeat([part], TempoMap()))
        let context = Work.ConvertContext()
            .pitchStandard(.a440)
            .tuningSystem(EqualTemperament.edo12)

        #expect(throws: Work.Error.missingKeyboardMap) {
            try work.convert(timeBasis: .beat,
                             pitchNotation: .keyboard,
                             context: context)
        }
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
    func convert_pitchNotation_keepsInfo() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin")
        let work = Work(content: .standardBeat([part], TempoMap()),
                        info: makeWorkInfo())

        let result = try #require(try work.convert(timeBasis: .beat,
                                                   pitchNotation: .absolute))

        guard case .absoluteBeat = result.content
        else { Issue.record("Expected .absoluteBeat content."); return }

        #expect(result.info == work.info)
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
    func convert_standardToKeyboard() throws {
        var table = NoteTable<BeatTime, Pitch>()

        table.insert(attack: 0, duration: 1, pitch: .a4)
        table.insert(attack: 1, duration: 1, pitch: "B#3")

        let part = Part<BeatTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardBeat([part], TempoMap()))

        let result = try #require(try work.convert(timeBasis: .beat,
                                                   pitchNotation: .keyboard))

        guard case let .keyboardBeat(parts, _) = result.content
        else {
            Issue.record("Expected keyboard-beat content")
            return
        }

        let pitches = parts.first?.noteTable.map(\.startPitch)

        #expect(try pitches == [#require(NoteNumber(uintValue: 69)), #require(NoteNumber(uintValue: 60))])
        #expect(parts.first?.partID == part.partID)
    }

    @Test
    func convert_standardToKeyboard_pitchOutOfRange() {
        var table = NoteTable<WallTime, Pitch>()

        table.insert(attack: 0, duration: 1, pitch: .a4)
        table.insert(attack: 1, duration: 1, pitch: "G#9")

        let part = Part<WallTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardWall([part]))

        #expect(throws: Work.Error.pitchOutOfRange(partID: part.partID)) {
            try work.convert(timeBasis: .wall,
                             pitchNotation: .keyboard)
        }
    }

    @Test
    func convert_standardToKeyboard_dropsOutOfRangeNotes() throws {
        var table = NoteTable<WallTime, Pitch>()

        table.insert(attack: 0, duration: 1, pitch: .a4)
        table.insert(attack: 1, duration: 1, pitch: "G#9")
        table.insert(attack: 2, duration: 1, pitch: "Cb-1")

        let part = Part<WallTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardWall([part]))

        let result = try #require(try work.convert(timeBasis: .wall,
                                                   pitchNotation: .keyboard,
                                                   dropsOutOfRangeNotes: true))

        guard case let .keyboardWall(parts) = result.content
        else {
            Issue.record("Expected keyboard-wall content")
            return
        }

        #expect(parts.first?.noteTable.count == 1)
        #expect(parts.first?.noteTable.first?.startPitch == NoteNumber(uintValue: 69))
    }

    @Test
    func convert_standardToKeyboard_wall() throws {
        var table = NoteTable<WallTime, Pitch>()

        table.insert(attack: 0, duration: 1, pitch: "C4")

        let part = Part<WallTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardWall([part]))

        let result = try #require(try work.convert(timeBasis: .wall,
                                                   pitchNotation: .keyboard))

        guard case let .keyboardWall(parts) = result.content
        else {
            Issue.record("Expected keyboard-wall content")
            return
        }

        #expect(parts.first?.noteTable.first?.startPitch == NoteNumber(uintValue: 60))
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
                      (.keyboard, .standard)])
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

    @Test
    func convert_wallToBeat_keepsInfo() throws {
        let part = Part<WallTime, Pitch>(name: "Violin")
        let work = Work(content: .standardWall([part]),
                        info: makeWorkInfo())

        let result = try #require(try work.convert(timeBasis: .beat,
                                                   pitchNotation: .standard))

        guard case .standardBeat = result.content
        else { Issue.record("Expected .standardBeat content."); return }

        #expect(result.info == work.info)
    }
}

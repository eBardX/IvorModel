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
    func absoluteToKeyboard_default() throws {
        let work = makeWallWork(frequencies: [440, 220])

        let pitches = try keyboardWallPitches(of: work.convert(timeBasis: .wall,
                                                               pitchNotation: .keyboard))

        #expect(pitches == [69, 57])
    }

    @Test
    func absoluteToKeyboard_keyMatchingWithin_rejectsDistantPitch() throws {
        let work = makeWallWork(frequencies: [440, 450])
        let context = Work.ConvertContext.default.keyMatching(.within(Ratio(cents: 5)))

        #expect(throws: try Work.Error.unconvertiblePitch(partID: firstAbsolutePartID(of: work))) {
            try work.convert(timeBasis: .wall,
                             pitchNotation: .keyboard,
                             context: context)
        }

        let pitches = try keyboardWallPitches(of: work.convert(timeBasis: .wall,
                                                               pitchNotation: .keyboard,
                                                               context: context,
                                                               dropsUnconvertibleNotes: true))

        #expect(pitches == [69])
    }

    @Test
    func absoluteToStandard_spellsInContext() throws {
        let work = makeWallWork(frequencies: Fixtures.eMajorKeys.map(pianoFrequency(of:)))

        let pitches = try standardWallPitches(of: work.convert(timeBasis: .wall,
                                                               pitchNotation: .standard))

        #expect(pitches[6] == "D#5")
    }

    @Test
    func convert_beatToWall_keepsExtras() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin", extras: makeChannelExtras(3))
        let work = Work(content: .standardBeat([part], TempoMap()),
                        extras: makeTimeCodeExtras())

        let result = try #require(try work.convert(timeBasis: .wall,
                                                   pitchNotation: .standard))

        #expect(result.extras == work.extras)
        #expect(result.part(part.partID, as: Part<WallTime, Pitch>.self)?.extras == part.extras)
    }

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
    func convert_keepsPartExtrasAcrossPitchNotations() throws {
        let part = Part<BeatTime, Pitch>(name: "Violin", extras: makeChannelExtras(3))
        let work = Work(content: .standardBeat([part], TempoMap()))

        let result = try #require(try work.convert(timeBasis: .beat,
                                                   pitchNotation: .absolute))

        #expect(result.part(part.partID, as: Part<BeatTime, Frequency>.self)?.extras == part.extras)
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
    func convert_missingKeyboardLayout() {
        var table = NoteTable<BeatTime, Pitch>()

        table.insert(attack: 0, duration: 1, pitch: .a4)

        let part = Part<BeatTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardBeat([part], TempoMap()))
        let context = Work.ConvertContext()
            .pitchStandard(.a440)
            .tuningSystem(EqualTemperament.edo12)

        #expect(throws: Work.Error.missingKeyboardLayout) {
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
    func convert_standardToKeyboard_dropsUnconvertibleNotes() throws {
        var table = NoteTable<WallTime, Pitch>()

        table.insert(attack: 0, duration: 1, pitch: .a4)
        table.insert(attack: 1, duration: 1, pitch: "G#9")
        table.insert(attack: 2, duration: 1, pitch: "Cb-1")

        let part = Part<WallTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardWall([part]))

        let result = try #require(try work.convert(timeBasis: .wall,
                                                   pitchNotation: .keyboard,
                                                   dropsUnconvertibleNotes: true))

        guard case let .keyboardWall(parts) = result.content
        else {
            Issue.record("Expected keyboard-wall content")
            return
        }

        #expect(parts.first?.noteTable.count == 1)
        #expect(parts.first?.noteTable.first?.startPitch == NoteNumber(uintValue: 69))
    }

    @Test
    func convert_standardToKeyboard_unconvertiblePitch() {
        var table = NoteTable<WallTime, Pitch>()

        table.insert(attack: 0, duration: 1, pitch: .a4)
        table.insert(attack: 1, duration: 1, pitch: "G#9")

        let part = Part<WallTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(content: .standardWall([part]))

        #expect(throws: Work.Error.unconvertiblePitch(partID: part.partID)) {
            try work.convert(timeBasis: .wall,
                             pitchNotation: .keyboard)
        }
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

    @Test
    func keyboardToAbsolute_default() throws {
        let work = makeWallWork(noteNumbers: [69, 81])

        let pitches = try absoluteWallPitches(of: work.convert(timeBasis: .wall,
                                                               pitchNotation: .absolute))

        #expect(pitches == [440, 880])
    }

    @Test
    func keyboardToAbsolute_degreeLayout_requiresTuningSystem() throws {
        let work = makeWallWork(noteNumbers: [69])
        let context = Work.ConvertContext().keyboardLayout(.piano)

        #expect(throws: Work.Error.missingTuningSystem) {
            try work.convert(timeBasis: .wall,
                             pitchNotation: .absolute,
                             context: context)
        }
    }

    @Test
    func keyboardToAbsolute_portamento_convertsBothPitches() throws {
        var table = NoteTable<WallTime, NoteNumber>()

        table.insert(attack: 0, duration: 1, startPitch: 57, endPitch: 69)

        let work = Work(content: .keyboardWall([Part(name: "Synth", noteTable: table)]))

        let result = try #require(try work.convert(timeBasis: .wall,
                                                   pitchNotation: .absolute))

        guard case let .absoluteWall(parts) = result.content
        else { Issue.record("Expected absolute-wall content"); return }

        let note = try #require(parts.first?.noteTable.first)

        #expect(note.startPitch == 220)
        #expect(note.endPitch == 440)
    }

    @Test
    func keyboardToAbsolute_rawLayout_needsNoTuningSystem() throws {
        let layout = try KeyboardLayout(ratios: (0..<12).map { Ratio(cents: Number($0) * 100) },
                                        equivalenceRatio: .octave,
                                        referenceFrequency: 415)
        let work = makeWallWork(noteNumbers: [69])
        let context = Work.ConvertContext().keyboardLayout(layout)

        let pitches = try absoluteWallPitches(of: work.convert(timeBasis: .wall,
                                                               pitchNotation: .absolute,
                                                               context: context))

        #expect(pitches == [415])
    }

    @Test
    func keyboardToStandard_degreeLayoutWithoutSpeller_throws() {
        let work = makeWallWork(noteNumbers: [60])
        let context = Work.ConvertContext()
            .keyboardLayout(.bohlenPierce)
            .tuningSystem(EqualTemperament.edo12)

        #expect(throws: Work.Error.missingPitchSpeller) {
            try work.convert(timeBasis: .wall,
                             pitchNotation: .standard,
                             context: context)
        }
    }

    @Test
    func keyboardToStandard_pitchClassLayoutWithoutSpeller_usesLayoutSpelling() throws {
        let work = makeWallWork(noteNumbers: Fixtures.eMajorKeys)
        let context = Work.ConvertContext()
            .keyboardLayout(.piano)
            .tuningSystem(EqualTemperament.edo12)

        let pitches = try standardWallPitches(of: work.convert(timeBasis: .wall,
                                                               pitchNotation: .standard,
                                                               context: context))

        #expect(pitches[6] == "Eb5")
    }

    @Test
    func keyboardToStandard_spellsInContext() throws {
        let work = makeWallWork(noteNumbers: Fixtures.eMajorKeys)

        let pitches = try standardWallPitches(of: work.convert(timeBasis: .wall,
                                                               pitchNotation: .standard))

        #expect(pitches[6] == "D#5")
    }

    @Test
    func standardToKeyboard_invalidKeyboardLayout() throws {
        let layout = try KeyboardLayout(pitchClasses: [.c, .d, .cSharp])
        let work = Work(content: .standardWall([Part<WallTime, Pitch>(name: "Piano")]))
        let context = Work.ConvertContext.default.keyboardLayout(layout)

        #expect(throws: Work.Error.invalidKeyboardLayout(.slotOutsidePeriod(index: 2))) {
            try work.convert(timeBasis: .wall,
                             pitchNotation: .keyboard,
                             context: context)
        }
    }
}

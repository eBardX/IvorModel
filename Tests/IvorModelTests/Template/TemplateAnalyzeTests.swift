// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

struct TemplateAnalyzeTests {
}

// MARK: -

extension TemplateAnalyzeTests {
    @Test
    func analyzeNoteEvents_invalidMaximumOrder() {
        var noteTable = NoteTable<BeatTime, Pitch>()

        noteTable.insert(attack: 0, duration: 1, pitch: .c4)

        let part = Part<BeatTime, Pitch>(name: "Piano", noteTable: noteTable)
        let work = Work(content: .standardBeat([part], TempoMap()))

        #expect(throws: Template.Error.self) {
            try Template.analyzeNoteEvents(in: work,
                                           at: 0,
                                           maximumOrder: 0)
        }
    }

    @Test
    func analyzeNoteEvents_partNotFound() {
        let part = Part<BeatTime, Pitch>(name: "Piano")
        let work = Work(content: .standardBeat([part], TempoMap()))

        #expect(throws: Template.Error.self) {
            try Template.analyzeNoteEvents(in: work,
                                           at: 1,
                                           maximumOrder: 1)
        }
    }

    @Test
    func analyzeNoteEvents_success() throws {
        var table = NoteTable<BeatTime, Pitch>()

        table.insert(attack: 0, duration: 1, pitch: .c4)
        table.insert(attack: 1, duration: 1, pitch: .e4)

        let part = Part<BeatTime, Pitch>(name: "Piano", noteTable: table)
        let work = Work(name: "My Work", content: .standardBeat([part], TempoMap()))

        let tmpl = try Template.analyzeNoteEvents(in: work,
                                                  at: 0,
                                                  maximumOrder: 1)

        #expect(tmpl.name.contains("My Work"))
        #expect(tmpl.pitchNotation == .standard)
        #expect(tmpl.timeBasis == .beat)
        #expect(tmpl.maximumOrder == 1)
    }
}

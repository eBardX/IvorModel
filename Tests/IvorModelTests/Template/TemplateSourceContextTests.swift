// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers

//
// A template's source context: the setting its first source part started in, recorded at
// analysis and carried over to the works it generates.
//
struct TemplateSourceContextTests {
}

// MARK: -

extension TemplateSourceContextTests {
    @Test
    func adding_keepsOriginalContext() throws {
        let original = _beatWork(instrument: _flute)
        let other = _beatWork(instrument: _oboe)
        let template = try Template.analyzeNoteEvents(in: original, at: 0, maximumOrder: 1)
        let added = try template.adding(partAt: 0, of: other, name: "Both")

        #expect(added.sourceContext == template.sourceContext)
        #expect(added.sourceContext.instrument == _flute)
    }

    @Test
    func analyze_beatWork_recordsSettingAtFirstAttack() throws {
        let template = try Template.analyzeNoteEvents(in: _beatWork(), at: 0, maximumOrder: 1)
        let context = template.sourceContext

        #expect(context.dynamic == .f)
        #expect(context.instrument == _oboe)
        #expect(context.pan == _left)
        #expect(context.tempo == _tempo)
    }

    @Test
    func analyze_wallWork_hasNoTempo() throws {
        var noteTable = NoteTable<WallTime, Pitch>()

        // swiftlint:disable:next force_unwrapping
        noteTable.insert(attack: .zero, duration: WallDuration(uintValue: 1_000_000)!, pitch: .c4)

        var dynamicMap = DynamicMap<WallTime>()

        dynamicMap.insert(time: .zero, dynamic: .pp)

        let work = Work(name: "Wall",
                        content: .standardWall([Part(name: "Voice",
                                                     noteTable: noteTable,
                                                     dynamicMap: dynamicMap)]))
        let template = try Template.analyzeNoteEvents(in: work, at: 0, maximumOrder: 1)

        #expect(template.sourceContext.tempo == nil)
        #expect(template.sourceContext.dynamic == .pp)
    }

    @Test
    func generate_defaultContext_leavesMapsEmpty() throws {
        let template = try Template.analyzeNoteEvents(in: _plainBeatWork(), at: 0, maximumOrder: 1)

        #expect(template.sourceContext == Template.SourceContext(tempo: .default))

        let generated = try template.generateWork(name: "Out", order: 1, limit: 4)

        guard case let .standardBeat(parts, tempoMap) = generated.content
        else { Issue.record("not standard beat"); return }

        let part = try #require(parts.first)

        #expect(part.dynamicMap.isEmpty)
        #expect(part.instrumentMap.isEmpty)
        #expect(part.panMap.isEmpty)
        #expect(tempoMap.isEmpty)
    }

    @Test
    func generate_startsInSourceContext() throws {
        let template = try Template.analyzeNoteEvents(in: _beatWork(), at: 0, maximumOrder: 1)
        let generated = try template.generateWork(name: "Out", order: 1, limit: 4)

        guard case let .standardBeat(parts, tempoMap) = generated.content
        else { Issue.record("not standard beat"); return }

        let part = try #require(parts.first)

        #expect(part.dynamicMap.count == 1)
        #expect(part.dynamicMap[.zero] == .f)
        #expect(part.instrumentMap.count == 1)
        #expect(part.instrumentMap[.zero] == _oboe)
        #expect(part.panMap.count == 1)
        #expect(part.panMap[.zero] == _left)
        #expect(tempoMap.count == 1)
        #expect(tempoMap[.zero] == _tempo)
    }

    @Test
    func missingPart_givesDefaults() {
        let context = Template.SourceContext(content: _beatWork().content, index: 3)

        //
        // Without a part there's no first attack, so the tempo is the one at time zero.
        //
        #expect(context == Template.SourceContext(tempo: Tempo(uintValue: 120)))
    }

    @Test
    func sourceContext_roundTripsThroughProject() throws {
        let template = try Template.analyzeNoteEvents(in: _beatWork(), at: 0, maximumOrder: 1)
        var project = Project()

        project.updateTemplate(template)

        let loaded = try #require(Project.load(from: project.save()).fetchTemplate(template.templateID))

        #expect(loaded.sourceContext == template.sourceContext)
    }
}

// MARK: - Private Functions

// swiftlint:disable force_unwrapping

private let _flute = Instrument(stringValue: "Flute")!
private let _left = Pan(horizontal: -45)
private let _oboe = Instrument(stringValue: "Oboe")!
private let _tempo = Tempo(uintValue: 96)!

// swiftlint:enable force_unwrapping

//
// A melody starting at beat 2, in a part whose maps change before then — so that the setting at
// its first attack differs from the setting at time zero.
//
private func _beatWork(instrument: Instrument = _oboe) -> Work {
    var part = _plainPart()

    part.dynamicMap.insert(time: .zero, dynamic: .f)
    part.instrumentMap.insert(time: .zero, instrument: _flute)
    part.instrumentMap.insert(time: _beat(1), instrument: instrument)
    part.panMap.insert(time: .zero, pan: Pan(horizontal: 30))
    part.panMap.insert(time: _beat(1), pan: _left)

    var tempoMap = TempoMap()

    tempoMap.insert(beatTime: .zero, tempo: Tempo(uintValue: 120)!) // swiftlint:disable:this force_unwrapping
    tempoMap.insert(beatTime: _beat(1), tempo: _tempo)

    return Work(name: "Tune",
                content: .standardBeat([part], tempoMap))
}

private func _beat(_ value: Number) -> BeatTime {
    // swiftlint:disable:next force_unwrapping
    BeatTime(numberValue: value)!
}

private func _plainBeatWork() -> Work {
    Work(name: "Plain",
         content: .standardBeat([_plainPart()], TempoMap()))
}

private func _plainPart() -> Part<BeatTime, Pitch> {
    var noteTable = NoteTable<BeatTime, Pitch>()

    for (offset, pitch) in [Pitch.c4, .e4, .g4, .c4].enumerated() {
        noteTable.insert(attack: _beat(Number(2 + offset)),
                         // swiftlint:disable:next force_unwrapping
                         duration: BeatDuration(numberValue: 1)!,
                         pitch: pitch)
    }

    return Part(name: "Piano",
                noteTable: noteTable)
}

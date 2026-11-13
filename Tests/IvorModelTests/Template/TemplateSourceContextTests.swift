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
        let original = makeSourceContextWork(instrument: Fixtures.flute)
        let other = makeSourceContextWork(instrument: Fixtures.oboe)
        let template = try Template.analyzeNoteEvents(in: original, at: 0, maximumOrder: 1, name: "Test")
        let added = try template.adding(partAt: 0, of: other, name: "Both")

        #expect(added.sourceContext == template.sourceContext)
        #expect(added.sourceContext.instrument == Fixtures.flute)
    }

    @Test
    func analyze_beatWork_recordsSettingAtFirstAttack() throws {
        let template = try Template.analyzeNoteEvents(in: makeSourceContextWork(), at: 0, maximumOrder: 1, name: "Test")
        let context = template.sourceContext

        #expect(context.dynamic == .f)
        #expect(context.instrument == Fixtures.oboe)
        #expect(context.pan == Fixtures.leftPan)
        #expect(context.tempo == Fixtures.slowTempo)
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
        let template = try Template.analyzeNoteEvents(in: work, at: 0, maximumOrder: 1, name: "Test")

        #expect(template.sourceContext.tempo == nil)
        #expect(template.sourceContext.dynamic == .pp)
    }

    @Test
    func generate_defaultContext_leavesMapsEmpty() throws {
        let template = try Template.analyzeNoteEvents(in: makePlainSourceWork(), at: 0, maximumOrder: 1, name: "Test")

        #expect(template.sourceContext == Template.SourceContext(tempo: .default))

        let generated = try template.generateWork(name: "Out", partName: "Part", order: 1, limit: 4)

        guard case let .standardBeat(parts, tempoMap, _) = generated.content
        else { Issue.record("not standard beat"); return }

        let part = try #require(parts.first)

        #expect(part.dynamicMap.isEmpty)
        #expect(part.instrumentTable.isEmpty)
        #expect(part.panMap.isEmpty)
        #expect(tempoMap.isEmpty)
    }

    @Test
    func generate_startsInSourceContext() throws {
        let template = try Template.analyzeNoteEvents(in: makeSourceContextWork(), at: 0, maximumOrder: 1, name: "Test")
        let generated = try template.generateWork(name: "Out", partName: "Part", order: 1, limit: 4)

        guard case let .standardBeat(parts, tempoMap, _) = generated.content
        else { Issue.record("not standard beat"); return }

        let part = try #require(parts.first)

        #expect(part.dynamicMap.count == 1)
        #expect(part.dynamicMap[.zero] == .f)
        #expect(part.instrumentTable.count == 1)
        #expect(part.instrumentTable[.zero] == Fixtures.oboe)
        #expect(part.panMap.count == 1)
        #expect(part.panMap[.zero] == Fixtures.leftPan)
        #expect(tempoMap.count == 1)
        #expect(tempoMap[.zero] == Fixtures.slowTempo)
    }

    @Test
    func analyze_firstAttackBeforeFirstMeterEntry_hasNoMeter() throws {
        let template = try Template.analyzeNoteEvents(in: makeMeteredSourceWork(makeMeterTable([(3, "3/4")])),
                                                      at: 0,
                                                      maximumOrder: 1,
                                                      name: "Test")

        #expect(template.sourceContext.meter == nil)
        #expect(template.sourceContext.barPosition == .zero)
    }

    @Test
    func analyze_freeMeter_hasNoBarPosition() throws {
        let template = try Template.analyzeNoteEvents(in: makeMeteredSourceWork(makeMeterTable([(0, "free")])),
                                                      at: 0,
                                                      maximumOrder: 1,
                                                      name: "Test")

        #expect(template.sourceContext.meter == .free)
        #expect(template.sourceContext.barPosition == .zero)
    }

    @Test
    func analyze_meterlessSource_hasNoMeter() throws {
        let template = try Template.analyzeNoteEvents(in: makePlainSourceWork(), at: 0, maximumOrder: 1, name: "Test")

        #expect(template.sourceContext.meter == nil)
        #expect(template.sourceContext.barPosition == .zero)
    }

    @Test
    func analyze_startInPickup_countsPickupAsTailOfBar() throws {
        //
        // A one-beat pickup in 3/4, with the first attack at 0: that's beat 3.
        //
        var work = makeStandardBeatWork([(0, frac(1, 4), .c4), (frac(1, 4), frac(1, 4), .d4)])

        let meterTable = try makeMeterTable([(0, "3/4")], pickup: frac(1, 4))

        try work.modifyMeterTable { $0 = meterTable }

        let template = try Template.analyzeNoteEvents(in: work, at: 0, maximumOrder: 1, name: "Test")

        #expect(template.sourceContext.meter == meter("3/4"))
        #expect(template.sourceContext.barPosition == beats(frac(1, 2)))
    }

    @Test
    func analyze_wallWork_hasNoMeter() {
        let work = Work(name: "Wall",
                        content: .standardWall([Part(name: "Voice",
                                                     noteTable: NoteTable<WallTime, Pitch>())]))
        let context = Template.SourceContext(content: work.content, index: 0)

        #expect(context.meter == nil)
        #expect(context.barPosition == .zero)
    }

    @Test
    func generate_freeMeter_writesFreeMeterWithoutPickup() throws {
        let template = try Template.analyzeNoteEvents(in: makeMeteredSourceWork(makeMeterTable([(0, "free")])),
                                                      at: 0,
                                                      maximumOrder: 1,
                                                      name: "Test")
        let generated = try template.generateWork(name: "Out", partName: "Part", order: 1, limit: 4)

        #expect(generated.meterTable?.map(\.meter) == [.free])
        #expect(generated.meterTable?.pickup == .zero)
    }

    @Test
    func generate_meterlessSource_givesEmptyTable() throws {
        let template = try Template.analyzeNoteEvents(in: makePlainSourceWork(), at: 0, maximumOrder: 1, name: "Test")
        let generated = try template.generateWork(name: "Out", partName: "Part", order: 1, limit: 4)

        #expect(generated.meterTable == MeterTable())
    }

    @Test
    func generate_mixingTemplates_keepsFirstSourcesMeter() throws {
        let threeFour = try Template.analyzeNoteEvents(in: makeMeteredSourceWork(makeMeterTable([(0, "3/4")])),
                                                       at: 0,
                                                       maximumOrder: 1,
                                                       name: "3/4")
        let sixEight = try Template.analyzeNoteEvents(in: makeMeteredSourceWork(makeMeterTable([(0, "6/8")])),
                                                      at: 0,
                                                      maximumOrder: 1,
                                                      name: "6/8")
        let generated = try threeFour.generateWork(name: "Out",
                                                   partName: "Part",
                                                   options: blendOptions(with: sixEight, weight: 0.5),
                                                   seed: 1,
                                                   mixingWith: [sixEight])

        #expect(generated.meterTable?.map(\.meter) == [meter("3/4")])
    }

    @Test
    func generate_sourceOnBeat3Of3_4_givesOneBeatPickup() throws {
        //
        // The plain source part's first attack is at 2, which is beat 3 of the third bar of 3/4.
        //
        let template = try Template.analyzeNoteEvents(in: makeMeteredSourceWork(makeMeterTable([(0, "3/4")])),
                                                      at: 0,
                                                      maximumOrder: 1,
                                                      name: "Test")

        #expect(template.sourceContext.meter == meter("3/4"))
        #expect(template.sourceContext.barPosition == beats(frac(1, 2)))

        let generated = try template.generateWork(name: "Out", partName: "Part", order: 1, limit: 4)
        let meterTable = try #require(generated.meterTable)

        #expect(meterTable.map(\.meter) == [meter("3/4")])
        #expect(meterTable.first?.beatTime == .zero)
        #expect(meterTable.pickup == .quarter)
        #expect(meterTable.position(at: .zero)?.beat == 3)
    }

    @Test
    func meterTable_onBarline_hasNoPickup() {
        let context = Template.SourceContext(meter: meter("6/8"))
        let meterTable = context.meterTable()

        #expect(meterTable.map(\.meter) == [meter("6/8")])
        #expect(meterTable.pickup == .zero)
    }

    @Test
    func missingPart_givesDefaults() {
        let context = Template.SourceContext(content: makeSourceContextWork().content, index: 3)

        //
        // Without a part there's no first attack, so the tempo is the one at time zero.
        //
        #expect(context == Template.SourceContext(tempo: Tempo(120)))
    }

    @Test
    func part_hasNoPedals() throws {
        let template = try Template.analyzeNoteEvents(in: makeSourceContextWork(), at: 0, maximumOrder: 1, name: "Test")
        let part = template.sourceContext.part(name: "Generated",
                                               noteTable: NoteTable<BeatTime, Pitch>())

        #expect(part.pedals.isEmpty)
    }

    @Test
    func sourceContext_roundTripsThroughProject() throws {
        let template = try Template.analyzeNoteEvents(in: makeSourceContextWork(), at: 0, maximumOrder: 1, name: "Test")
        var project = Project()

        project.updateTemplate(template)

        let loaded = try #require(Project.load(from: project.save()).fetchTemplate(template.templateID))

        #expect(loaded.sourceContext == template.sourceContext)
    }
}

// MARK: - Private helpers

extension TemplateSourceContextTests {
    private func makeMeteredSourceWork(_ meterTable: MeterTable) -> Work {
        Work(name: "Metered",
             content: .standardBeat([makePlainSourcePart()], TempoMap(), meterTable))
    }
}

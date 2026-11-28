// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov
import XestiNumbers
import XestiTools

// swiftlint:disable file_length

func absoluteWallNoteEvents(of template: Template) throws -> [NoteEvent<WallTime, Frequency>] {
    guard case let .absoluteWall(model) = template.content
    else { throw Template.Error.incompatibleOptions }

    return try makeNoteEvents(#require(model.chains.chain(for: .joint)).states).sorted { $0.duration < $1.duration }
}

func absoluteWallPitches(of work: Work?) throws -> [Frequency] {
    guard case let .absoluteWall(parts) = try #require(work).content.cases
    else { Issue.record("Expected absolute-wall content"); return [] }

    return try #require(parts.first).strands[0].noteTable.map(\.startPitch)
}

func analyzeAddingTemplate(_ work: Work,
                           states: Template.AnalysisOptions.StateRecipe = .exact,
                           variants: Template.AnalysisOptions.Variants = .none) throws -> Template {
    try Template.analyzeNoteEvents(in: work,
                                   scope: .all,
                                   options: .init(maximumOrder: 2,
                                                  states: states,
                                                  variants: variants),
                                   name: "Test")
}

func analyzeMixTemplate(_ work: Work,
                        maximumOrder: Int = 1,
                        states: Template.AnalysisOptions.StateRecipe = .exact) throws -> Template {
    try Template.analyzeNoteEvents(in: work,
                                   scope: .all,
                                   options: .init(maximumOrder: maximumOrder,
                                                  states: states),
                                   name: work.name)
}

func analyzePhraseTemplate(_ work: Work,
                           maximumOrder: Int = 2,
                           states: Template.AnalysisOptions.StateRecipe = .exact) throws -> Template {
    try Template.analyzeNoteEvents(in: work,
                                   scope: .all,
                                   options: .init(maximumOrder: maximumOrder,
                                                  states: states),
                                   name: "Test")
}

func analyzeRecipeTemplate(_ work: Work,
                           pitch: Template.AnalysisOptions.StateRecipe.PitchFeature = .absolute,
                           duration: Template.AnalysisOptions.StateRecipe.DurationFeature = .absolute) throws -> Template {
    try Template.analyzeNoteEvents(in: work,
                                   scope: .all,
                                   options: .init(maximumOrder: 1,
                                                  states: .init(pitch: pitch,
                                                                duration: duration)),
                                   name: "Test")
}

func analyzeRestSplitTune(restSplit: Template.AnalysisOptions.RestSplit?,
                          states: Template.AnalysisOptions.StateRecipe = .exact,
                          variants: Template.AnalysisOptions.Variants = .none) throws -> Template {
    try Template.analyzeNoteEvents(in: makeRestSplitTune(),
                                   scope: .all,
                                   options: .init(maximumOrder: 2,
                                                  states: states,
                                                  variants: variants,
                                                  restSplit: restSplit),
                                   name: "Test")
}

func analyzeSeparatedTemplate(_ work: Work,
                              pitch: Template.AnalysisOptions.StateRecipe.PitchFeature = .absolute,
                              duration: Template.AnalysisOptions.StateRecipe.DurationFeature = .absolute) throws -> Template {
    try Template.analyzeNoteEvents(in: work,
                                   scope: .all,
                                   options: .init(maximumOrder: 1,
                                                  states: .init(pitch: pitch,
                                                                duration: duration,
                                                                separatesPitchAndDuration: true)),
                                   name: "Test")
}

func analyzeVariantsTemplate(_ work: Work,
                             states: Template.AnalysisOptions.StateRecipe = .exact,
                             variants: Template.AnalysisOptions.Variants = .none) throws -> Template {
    try Template.analyzeNoteEvents(in: work,
                                   scope: .all,
                                   options: .init(maximumOrder: 1,
                                                  states: states,
                                                  variants: variants),
                                   name: "Test")
}

func ascending(_ interval: Interval) -> Template.AnalysisOptions.Transposition {
    .interval(DirectedInterval(interval: interval,
                               direction: .ascending))
}

func ascending(_ semitones: UInt) -> Template.AnalysisOptions.Transposition {
    // swiftlint:disable:next force_unwrapping
    .noteDistance(DirectedInterval(interval: NoteDistance(uintValue: semitones)!,
                                   direction: .ascending))
}

func assembleNoteTable(_ noteEvents: [NoteEvent<BeatTime, Pitch>]) -> NoteTable<BeatTime, Pitch> {
    var assembler = NoteTable<BeatTime, Pitch>.Assembler(noteEvents: noteEvents)

    return assembler.assembleNoteTable()
}

// A rendering clock for a beat work at ♩ = 60.
func beatRenderingClock(meterTable: MeterTable = MeterTable(),
                        keyTable: KeyTable = KeyTable()) -> RenderingClock {
    RenderingClock(tempoMap: TempoMap(defaultTempo: Tempo(60)),
                   meterTable: meterTable,
                   keyTable: keyTable)
}

func beats(_ value: Number) -> BeatDuration {
    // swiftlint:disable:next force_unwrapping
    BeatDuration(numberValue: value)!
}

func beatTime(_ value: Number) -> BeatTime {
    // swiftlint:disable:next force_unwrapping
    BeatTime(numberValue: value)!
}

func beginCount(of template: Template,
                _ role: Template.ChainRole) throws -> UInt {
    try #require(template.accept(BeginCountVisitor(role: role)))
}

func blendOptions(with other: Template,
                  weight: Double = 0.4,
                  stopsAtEnd: Bool = false) -> Template.AnyGenerationOptions {
    .standardBeat(StandardBeatOptions(length: .noteCount(30),
                                      stopsAtEnd: stopsAtEnd,
                                      templateMix: .blend([.init(template: .init(other), weight: weight)])))
}

//
// The start pitches of the notes in `table` that carry a breath mark, lowest first.
//
func breathMarkPitches(_ table: NoteTable<BeatTime, Pitch>) -> [Pitch] {
    table.filter { $0.extras?.contains(.breathMark) ?? false }.map(\.startPitch).sorted()
}

// A C4 at 0, lasting a beat, with `ornamentation`.
func c4Table(_ ornamentation: BeatNotes.Ornamentation) throws -> BeatNotes {
    var table = BeatNotes()

    try table.insert(attack: 0, duration: 1, pitch: .c4, ornamentation: ornamentation)

    return table
}

// `value` encoded to JSON and decoded back.
func codingRoundTrip<Value: Codable>(_ value: Value) throws -> Value {
    try JSONDecoder().decode(Value.self, from: JSONEncoder().encode(value))
}

// `json` decoded as `Value`.
func decodeJSON<Value: Decodable>(_ type: Value.Type,
                                  _ json: String) throws -> Value {
    try JSONDecoder().decode(type, from: Data(json.utf8))
}

func descending(_ interval: Interval) -> Template.AnalysisOptions.Transposition {
    .interval(DirectedInterval(interval: interval,
                               direction: .descending))
}

func descending(_ semitones: UInt) -> Template.AnalysisOptions.Transposition {
    // swiftlint:disable:next force_unwrapping
    .noteDistance(DirectedInterval(interval: NoteDistance(uintValue: semitones)!,
                                   direction: .descending))
}

// A beat-to-beat fermata converter that doubles every length.
func doublingFermataConverter() -> FermataConverter<BeatTime, BeatTime> {
    FermataConverter { beats($0.numberValue * 2) }
}

func dynamicTime(of entryID: EntryID,
                 in part: Part<BeatTime, Pitch>) -> BeatTime? {
    part.dynamicMap.first { $0.entryID == entryID }?.time
}

func earlier(_ value: Number) -> DirectedDuration<BeatDuration> {
    DirectedDuration(duration: beats(value), direction: .backward)
}

// `value` encoded to JSON with sorted keys, as text.
func encodedJSON(_ value: some Encodable) throws -> String {
    let encoder = JSONEncoder()

    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]

    return try #require(String(bytes: encoder.encode(value), encoding: .utf8))
}

func endCount(of template: Template,
              _ role: Template.ChainRole) throws -> UInt {
    var count: UInt = 0

    try standardBeatChain(of: template, role).forEach { transition in
        //
        // Order-1 contexts only, so that each sequence's end counts once.
        //
        if case .end = transition.target, case let .states(states) = transition.source, states.count == 1 {
            count += transition.weight
        }
    }

    return count
}

func endTime(of noteEvents: some Sequence<NoteEvent<BeatTime, Pitch>>) -> BeatTime {
    noteEvents.reduce(BeatTime.zero) { time, noteEvent in
        time.moved(by: DirectedDuration(duration: noteEvent.duration,
                                        direction: .forward)) ?? time
    }
}

//
// Every beat time at or after `shift` (which the original grid covers) keeps its beat and
// offset when moved by `shift`. Bar numbers may change, as the pickup does.
//
func expectBeatsKept(from original: MeterTable,
                     to moved: MeterTable,
                     by shift: BeatDuration,
                     earlier: Bool = false,
                     sourceLocation: SourceLocation = #_sourceLocation) {
    for tick in 0..<480 {
        let time = beatTime(frac(tick, 96))

        if earlier {
            guard time >= .zero + shift
            else { continue }

            let before = original.position(at: time)
            let after = moved.position(at: time - shift)

            #expect(before?.beat == after?.beat, sourceLocation: sourceLocation)
            #expect(before?.offset == after?.offset, sourceLocation: sourceLocation)
        } else {
            guard let before = original.position(at: time)
            else { continue }

            let after = moved.position(at: time + shift)

            #expect(before.beat == after?.beat, sourceLocation: sourceLocation)
            #expect(before.offset == after?.offset, sourceLocation: sourceLocation)
        }
    }
}

//
// Every beat time at or after `anchor` keeps its bar and beat once stretched, and its offset
// scales with it.
//
func expectPositionsKept(from original: MeterTable,
                         to scaled: MeterTable,
                         factor: Number,
                         anchor: BeatTime,
                         sourceLocation: SourceLocation = #_sourceLocation) {
    for tick in 0..<480 {
        let time = beatTime(frac(tick, 96))

        guard time >= anchor,
              let before = original.position(at: time)
        else { continue }

        let after = scaled.position(at: anchor + (time - anchor) * factor)

        #expect(after?.bar == before.bar, sourceLocation: sourceLocation)
        #expect(after?.beat == before.beat, sourceLocation: sourceLocation)
        #expect(after?.offset == before.offset * factor, sourceLocation: sourceLocation)
    }
}

func expectSameBarlines(_ table1: MeterTable,
                        _ table2: MeterTable,
                        from start: BeatTime,
                        to end: BeatTime,
                        sourceLocation: SourceLocation = #_sourceLocation) {
    let barlines1 = table1.bars(overlapping: start..<end).map(\.range.lowerBound).filter { $0 >= start }
    let barlines2 = table2.bars(overlapping: start..<end).map(\.range.lowerBound).filter { $0 >= start }

    #expect(barlines1 == barlines2, sourceLocation: sourceLocation)
}

func expectSameWallTimes(_ lhs: Work,
                         _ rhs: Work,
                         sourceLocation: SourceLocation = #_sourceLocation) throws {
    let lhsTimes = try wallAttacks(of: lhs)
    let rhsTimes = try wallAttacks(of: rhs)

    #expect(lhsTimes.count == rhsTimes.count, sourceLocation: sourceLocation)

    //
    // Wall times are kept in microseconds, so allow for a rounding step either way.
    //
    for (lhsTime, rhsTime) in zip(lhsTimes, rhsTimes) {
        #expect(abs(lhsTime - rhsTime) < 2e-6, "\(lhsTimes) ≠ \(rhsTimes)", sourceLocation: sourceLocation)
    }
}

//
// The contents of the file at `path` in a saved project's unzipped `root`.
//
func extraValues(_ extra: Extra,
                 in extras: Extras?) -> [Extra.AssociatedValue]? {
    extras?.elements.first { $0.name == extra.name }?.values
}

func fermataMark(_ span: BeatDuration) -> PartMark<BeatTime> {
    // swiftlint:disable:next force_unwrapping
    .fermata(Fermata(), span: PositiveDuration(span)!)
}

func fermataStretch(_ value: Number) -> FermataStretch {
    // swiftlint:disable:next force_unwrapping
    FermataStretch(numberValue: value)!
}

func fileContents(of root: FileWrapper,
                  _ path: [String]) throws -> Data {
    let directory = try #require(root.fileWrappers?[path[0]])
    let file = try #require(directory.fileWrappers?[path[1]])

    return try #require(file.regularFileContents)
}

func firstAbsolutePartID(of work: Work) throws -> PartID {
    guard case let .absoluteWall(parts) = work.content.cases
    else { Issue.record("Expected absolute-wall content"); return PartID() }

    return try #require(parts.first).partID
}

func firstID(of table: MeterTable) throws -> EntryID {
    try #require(table.first).entryID
}

func firstNoteSB(_ pitch: Pitch,
                 in part: Part<BeatTime, Pitch>) -> NoteTable<BeatTime, Pitch>.Note? {
    part.strands[0].noteTable.first { $0.startPitch == pitch }
}

func frac(_ numerator: Int,
          _ denominator: Int) -> Number {
    Number(numerator: numerator, denominator: denominator)
}

func fullInterpretationRules() -> InterpretationRules {
    InterpretationRules(grace: GraceRules(slashedPlacement: .beforeBeat,
                                          unslashedPlacement: .onBeat,
                                          maximumShare: proportion(1, 2),
                                          perNote: positiveSeconds(1, 25)),
                        trill: OrnamentRules(startNote: .partner,
                                             partnerRule: .diatonic,
                                             rate: notesPerSecond(12),
                                             extent: .span(proportion(3, 4))),
                        mordent: OrnamentRules(extent: .count(AlternationCount(2))),
                        tremolo: OrnamentRules(rate: notesPerSecond(16)),
                        arpeggio: ArpeggioRules(direction: .down,
                                                anchor: .lastOnBeat,
                                                spread: .perTone(positiveSeconds(1, 20))),
                        fermata: FermataRules(holds: [.short: .stretch(fermataStretch(frac(3, 2)))],
                                              pauseAfter: positiveSeconds(1, 2)),
                        caesura: positiveSeconds(2))
}

// Every slot filled, with a written duration in each but the figure after.
func fullOrnamentation() throws -> BeatNotes.Ornamentation {
    try BeatNotes.Ornamentation(graceBefore: graceFigure(["D5"], length: positiveBeats(1, 16)),
                                graceAfter: graceFigure(["B4", "C5"], execution: BeatNotes.GraceExecution(fromMain: .share(proportion(1, 4)))),
                                ornament: ornament(.trill,
                                                   .step(.above, written: nil),
                                                   BeatNotes.OrnamentExecution(rate: .noteValue(positiveBeats(1, 32)))),
                                arpeggio: BeatNotes.Arpeggio(group: 1,
                                                             execution: BeatNotes.ArpeggioExecution(spread: .perTone(positiveBeats(1, 64)))),
                                fermata: Fermata(shape: .long,
                                                 execution: FermataExecution(hold: .added(positiveBeats(1, 4)))))
}

// A grace event of these pitches, which must be valid.
func graceEvent(_ pitches: [Pitch],
                length: PositiveDuration<BeatDuration>? = nil,
                execution: BeatNotes.GraceExecution? = nil) throws -> BeatNotes.GraceFigure.Event {
    try #require(BeatNotes.GraceFigure.Event(pitches: pitches,
                                             length: length,
                                             execution: execution))
}

// A grace figure of one event per pitch, each with this length.
func graceFigure(_ pitches: [Pitch],
                 length: PositiveDuration<BeatDuration>? = nil,
                 isSlashed: Bool = false,
                 isTiedToMainNote: Bool = false,
                 execution: BeatNotes.GraceExecution? = nil) throws -> BeatNotes.GraceFigure {
    try #require(BeatNotes.GraceFigure(events: pitches.map { try graceEvent([$0], length: length) },
                                       isSlashed: isSlashed,
                                       isTiedToMainNote: isTiedToMainNote,
                                       execution: execution))
}

func hasJointState(in template: Template,
                   where predicate: (StandardBeatState) -> Bool) throws -> Bool {
    var found = false

    try standardBeatChain(of: template, .joint).forEach { transition in
        if case let .state(state) = transition.target, predicate(state) {
            found = true
        }
    }

    return found
}

// Whether two numbers agree to within a millionth, for times that pass through a tempo map's
// rounded seconds.
func isClose(_ lhs: Number,
             _ rhs: Number) -> Bool {
    abs((lhs - rhs).doubleValue) < 1e-6
}

func jointNoteEvents(of template: Template) throws -> [NoteEvent<BeatTime, Pitch>] {
    guard case let .standardBeat(model) = template.content
    else { throw Template.Error.incompatibleOptions }

    return try makeNoteEvents(#require(model.chains.chain(for: .joint)).states)
}

func key(_ fifths: Int,
         _ mode: Key.Mode? = nil) -> Key {
    // swiftlint:disable:next force_unwrapping
    Key.diatonic(fifths: fifths, mode: mode)!
}

// A middle C (60) at 0, lasting a beat, with a figure of one grace note before it.
func keyboardGraceTable(grace: UInt) throws -> NoteTable<BeatTime, NoteNumber> {
    let gracePitch = try #require(NoteNumber(uintValue: grace))
    let event = try #require(NoteTable<BeatTime, NoteNumber>.GraceFigure.Event(pitches: [gracePitch]))
    let figure = try #require(NoteTable<BeatTime, NoteNumber>.GraceFigure(events: [event]))
    let middleC = try #require(NoteNumber(uintValue: 60))
    var table = NoteTable<BeatTime, NoteNumber>()

    try table.insert(attack: 0,
                     duration: 1,
                     pitch: middleC,
                     ornamentation: .init(graceBefore: figure))

    return table
}

func keyboardWallNotes(of work: Work) throws -> [NoteTable<WallTime, NoteNumber>.Note] {
    guard case let .keyboardWall(parts) = work.content.cases
    else { throw Work.Error.unsupportedStandardConversion }

    return try Array(#require(parts.first).strands[0].noteTable)
}

func keyboardWallPitches(of work: Work?) throws -> [NoteNumber] {
    guard case let .keyboardWall(parts) = try #require(work).content.cases
    else { Issue.record("Expected keyboard-wall content"); return [] }

    return try #require(parts.first).strands[0].noteTable.map(\.startPitch)
}

func lastID(of table: MeterTable) throws -> EntryID {
    try #require(table.last).entryID
}

func later(_ value: Number) -> DirectedDuration<BeatDuration> {
    DirectedDuration(duration: beats(value), direction: .forward)
}

// An acciaccatura before the beat on a C4 at 0, in 4/4 with this pickup.
func leadInRendering(pickup: Number?) throws -> Work.Rendering {
    var meterTable = MeterTable()

    try meterTable.insert(beatTime: 0, meter: #require(Meter(plain: "4/4")))

    if let pickup {
        try meterTable.setPickup(beats(pickup))
    }

    let part = try renderingPart([WrittenNote(0, frac(1, 2), .c4, BeatNotes.Ornamentation(graceBefore: graceFigure([.d4], isSlashed: true)))])

    return try renderingWork([part],
                             meterTable: meterTable,
                             rules: InterpretationRules(grace: GraceRules(slashedPlacement: .beforeBeat))).rendered()
}

func longFermataMark(_ span: BeatDuration) -> PartMark<BeatTime> {
    // swiftlint:disable:next force_unwrapping
    .fermata(Fermata(shape: .long), span: PositiveDuration(span)!)
}

func lowerMordentOrnamentation(written: Pitch?) throws -> BeatNotes.Ornamentation {
    try BeatNotes.Ornamentation(ornament: ornament(.mordent, .step(.below, written: written)))
}

func makeAbsoluteKeyWork() throws -> Work {
    var part = Part<BeatTime, Frequency>(name: "Sine")

    part.strands[0].noteTable.insert(attack: 0, duration: 1, pitch: 440)

    return try Work(content: .absoluteBeat([part], TempoMap(), MeterTable(), makeKeyTable([(0, 2)])))
}

func makeAbsoluteWallWork(_ notes: [(UInt, UInt, [Double])]) throws -> Work {
    var noteTable = NoteTable<WallTime, Frequency>()

    for (attack, duration, frequencies) in notes {
        for frequency in frequencies {
            try noteTable.insert(attack: wallTime(attack),
                                 duration: wallDuration(duration),
                                 pitch: #require(Frequency(numberValue: Number(floatLiteral: frequency))))
        }
    }

    return Work(content: .absoluteWall([Part(name: "Violin", noteTable: noteTable)]))
}

func makeAssignment(program: Int,
                    channel: Int? = nil) throws -> PatchTable.Assignment {
    let patch = try #require(Patch(.generalMIDI1(program: program)))

    return try #require(PatchTable.Assignment(patch: patch,
                                              channel: channel))
}

func makeBar(number: Int) -> MeterTable.Bar {
    MeterTable.Bar(number: number,
                   range: 0..<1,
                   meter: meter("4/4"),
                   isPickup: false,
                   isShort: false,
                   beatStarts: [0])
}

//
// A melody with repeated notes, so the chain branches, and a rest.
//
func makeBranchingTemplate(maximumOrder: Int = 1) throws -> Template {
    let pitches: [Pitch?] = [.c4, .d4, .e4, .c4, .e4, nil, .d4, .c4, .d4, .e4, .f4, .e4, .d4, .c4]
    var rawNotes: [(attack: BeatTime, duration: BeatDuration, pitch: Pitch)] = []

    for (index, pitch) in pitches.enumerated() {
        if let pitch {
            rawNotes.append((BeatTime(integerLiteral: Int64(index)), 1, pitch))
        }
    }

    let markovChain = try #require(MarkovChain<Template.State<BeatTime, Pitch>>(maximumOrder: maximumOrder))

    markovChain.analyzer().analyze(sequence: makeExactStates(makeNoteTableSB(rawNotes).extractNoteEvents()))

    return Template(name: "Melody",
                    content: .standardBeat(Template.Model(chains: .joint(markovChain))))
}

//
// One C4 after another, each at the given attack and duration in milliseconds.
//
func makeC4WallWork(_ notes: [(UInt, UInt)]) -> Work {
    var noteTable = NoteTable<WallTime, Pitch>()

    for (attack, duration) in notes {
        noteTable.insert(attack: wallTime(attack),
                         duration: wallDuration(duration),
                         pitch: .c4)
    }

    return Work(content: .standardWall([Part(name: "Flute", noteTable: noteTable)]))
}

//
// The states the exact recipe makes of `noteEvents`, for training a chain directly.
//
func makeChannelExtras(_ channel: Int) -> Extras {
    Extras(elements: [Extra(name: Extra.midiChannel.name,
                            values: [.int(channel)])])
}

func makeExactStates<T, P>(_ noteEvents: [NoteEvent<T, P>]) -> [Template.State<T, P>] where T.DurationType: TemplateDuration {
    noteEvents.map { noteEvent in
        Template.State(isRest: noteEvent.tiedPitches.isEmpty,
                       duration: .absolute(noteEvent.duration),
                       pitches: noteEvent.tiedPitches.isEmpty ? nil : .absolute(noteEvent.tiedPitches.map {
                           Template.Tone(value: $0.pitch,
                                         startsTie: $0.startsTie,
                                         endsTie: $0.endsTie)
                       }))
    }
}

func makeKeyboardBeatWork(_ noteNumbers: [UInt]) -> Work {
    var noteTable = NoteTable<BeatTime, NoteNumber>()

    for (index, noteNumber) in noteNumbers.enumerated() {
        // swiftlint:disable:next force_unwrapping
        noteTable.insert(attack: BeatTime(numberValue: Number(index))!,
                         duration: 1,
                         // swiftlint:disable:next force_unwrapping
                         pitch: NoteNumber(uintValue: noteNumber)!)
    }

    return Work(content: .keyboardBeat([Part(name: "Piano", noteTable: noteTable)], TempoMap(), MeterTable(), KeyTable()))
}

// The plain source part's first attack is at 2.
func makeKeyedSourceWork(_ entries: [(Number, Int)]) throws -> Work {
    try Work(name: "Keyed",
             content: .standardBeat([makePlainSourcePart()], TempoMap(), MeterTable(), makeKeyTable(entries)))
}

func makeKeyTable(_ entries: [(Number, Int)]) throws -> KeyTable {
    var table = KeyTable()

    for (time, fifths) in entries {
        try table.insert(beatTime: beatTime(time), key: key(fifths))
    }

    return table
}

func makeKeyWork(_ keyTable: KeyTable,
                 pitches: [Pitch] = [.c4, .g4]) -> Work {
    var part = Part<BeatTime, Pitch>(name: "Piano")

    for (index, pitch) in pitches.enumerated() {
        part.strands[0].noteTable.insert(attack: beatTime(Number(index)), duration: 1, pitch: pitch)
    }

    return Work(content: .standardBeat([part], TempoMap(), MeterTable(), keyTable))
}

func makeLockedWorkSB() -> (work: Work, partID: PartID) {
    var part = Part<BeatTime, Pitch>(name: "Violin")

    part.strands[0].noteTable.insert(attack: 0, duration: 1, pitch: .c4)

    var work = Work(content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()))

    work.isLocked = true

    return (work, part.partID)
}

func makeMeteredSourceWork(_ meterTable: MeterTable) -> Work {
    Work(name: "Metered",
         content: .standardBeat([makePlainSourcePart()], TempoMap(), meterTable, KeyTable()))
}

func makeMeterTable(_ entries: [(Number, String)],
                    pickup: Number = 0) throws -> MeterTable {
    var table = MeterTable()

    for (time, plain) in entries {
        try table.insert(beatTime: beatTime(time), meter: meter(plain))
    }

    try table.setPickup(beats(pickup))

    return table
}

func makeMeterWork(meterTable: MeterTable,
                   tempoMap: TempoMap = TempoMap(),
                   notes attacks: [Number]) throws -> Work {
    var part = Part<BeatTime, Pitch>(name: "Piano")

    for attack in attacks {
        part.strands[0].noteTable.insert(attack: beatTime(attack), duration: beats(frac(1, 8)), pitch: .c4)
    }

    return Work(content: .standardBeat([part], tempoMap, meterTable, KeyTable()))
}

func makeNamedStandardBeatWork(_ name: String,
                               _ notes: [(Number, Number, Pitch)]) -> Work {
    var noteTable = NoteTable<BeatTime, Pitch>()

    for (attack, duration, pitch) in notes {
        // swiftlint:disable:next force_unwrapping
        noteTable.insert(attack: BeatTime(numberValue: attack)!,
                         // swiftlint:disable:next force_unwrapping
                         duration: BeatDuration(numberValue: duration)!,
                         pitch: pitch)
    }

    return Work(name: name,
                content: .standardBeat([Part(name: "Piano", noteTable: noteTable)], TempoMap(), MeterTable(), KeyTable()))
}

//
// The note events that exact `states` record, for checking what a chain learned.
//
func makeNoteEvents<T, P>(_ states: [Template.State<T, P>]) -> [NoteEvent<T, P>] where T.DurationType: TemplateDuration {
    states.compactMap { state in
        guard case let .absolute(duration) = state.duration
        else { return nil }

        guard case let .absolute(tones) = state.pitches
        else { return NoteEvent(tiedPitches: [], duration: duration) }

        let tiedPitches = tones.map {
            NoteEvent<T, P>.TiedPitch(pitch: $0.value,
                                      startsTie: $0.startsTie,
                                      endsTie: $0.endsTie)
        }

        return NoteEvent(tiedPitches: tiedPitches,
                         duration: duration)
    }
}

func makeNoteTableSB(_ rawNotes: [(attack: BeatTime, duration: BeatDuration, pitch: Pitch)]) -> NoteTable<BeatTime, Pitch> {
    var ntab = NoteTable<BeatTime, Pitch>()

    for rawNote in rawNotes {
        ntab.insert(attack: rawNote.attack,
                    duration: rawNote.duration,
                    pitch: rawNote.pitch)
    }

    return ntab
}

func makeNoteTriplesSB(_ noteTable: NoteTable<BeatTime, Pitch>) -> [NoteTripleSB] {
    noteTable.notes.map {
        NoteTripleSB(attack: $0.attack,
                     duration: $0.duration,
                     pitch: $0.startPitch)
    }
}

//
// One beat each.  Named after its second pitch, so that templates read sensibly in failures.
//
func makeOneBeatWork(_ pitches: [Pitch]) -> Work {
    var noteTable = NoteTable<BeatTime, Pitch>()

    for (index, pitch) in pitches.enumerated() {
        // swiftlint:disable:next force_unwrapping
        noteTable.insert(attack: BeatTime(numberValue: Number(index))!,
                         duration: 1,
                         pitch: pitch)
    }

    let name = switch pitches.dropFirst().first {
    case .e4:
        "Thirds"

    case .g4:
        "Fifths"

    default:
        "Melody"
    }

    return Work(name: name,
                content: .standardBeat([Part(name: "Piano", noteTable: noteTable)], TempoMap(), MeterTable(), KeyTable()))
}

func makeOrganPatch() throws -> Patch {
    try #require(Patch(.generalMIDI1(program: 20)))
}

func makeOrganPatchTable() throws -> PatchTable {
    let patch = try #require(Patch(.generalMIDI1(program: 20)))
    let assignment = try #require(PatchTable.Assignment(patch: patch))

    return PatchTable([.vanilla: assignment])
}

//
// A standard beat work: a C4 with a figure before (D5, a sixteenth), a figure after (E4), a
// trill with a written partner (D4), and an arpeggio in group 1; a plain D5; and an E4 in
// group 2.
//
func makeOrnamentedStandardWork() throws -> Work {
    var table = BeatNotes()

    try table.insert(attack: 0,
                     duration: 1,
                     pitch: .c4,
                     ornamentation: .init(graceBefore: graceFigure([.d5], length: positiveBeats(1, 16)),
                                          graceAfter: graceFigure([.e4]),
                                          ornament: ornament(.trill, .step(.above, written: .d4)),
                                          arpeggio: BeatNotes.Arpeggio(group: 1)))
    table.insert(attack: 1, duration: 1, pitch: .d5)
    try table.insert(attack: 2,
                     duration: 1,
                     pitch: .e4,
                     ornamentation: .init(arpeggio: BeatNotes.Arpeggio(group: 2)))

    return Work(content: .standardBeat([Part(name: "Piano", noteTable: table)], TempoMap(), MeterTable(), KeyTable()))
}

// An A4 (440 Hz) with a figure before and a trill with a written partner.
func makeOrnamentedWallWork(graceBefore: Frequency,
                            partner: Frequency) throws -> Work {
    let event = try #require(NoteTable<WallTime, Frequency>.GraceFigure.Event(pitches: [graceBefore]))
    let figure = try #require(NoteTable<WallTime, Frequency>.GraceFigure(events: [event]))
    let trill = try #require(NoteTable<WallTime, Frequency>.Ornament(sign: .trill, partner: .step(.above, written: partner)))
    var table = NoteTable<WallTime, Frequency>()

    try table.insert(attack: wallTime(0),
                     duration: wallDuration(500),
                     pitch: Frequency(440),
                     ornamentation: .init(graceBefore: figure, ornament: trill))

    return Work(content: .absoluteWall([Part(name: "Synth", noteTable: table)]))
}

func makePlainSourcePart() -> Part<BeatTime, Pitch> {
    var noteTable = NoteTable<BeatTime, Pitch>()

    for (offset, pitch) in [Pitch.c4, .e4, .g4, .c4].enumerated() {
        noteTable.insert(attack: beatTime(Number(2 + offset)),
                         // swiftlint:disable:next force_unwrapping
                         duration: BeatDuration(numberValue: 1)!,
                         pitch: pitch)
    }

    return Part(name: "Piano",
                noteTable: noteTable)
}

func makePlainSourceWork() -> Work {
    Work(name: "Plain",
         content: .standardBeat([makePlainSourcePart()], TempoMap(), MeterTable(), KeyTable()))
}

func makePosition(beat: Int?) -> MeterTable.Position {
    MeterTable.Position(bar: 1,
                        beat: beat,
                        offset: .zero,
                        beatLength: beat.map { _ in beats(frac(1, 4)) })
}

// A renderer of these standard beat parts at ♩ = 60.
func makeRenderer(_ parts: [Part<BeatTime, Pitch>],
                  rules: InterpretationRules? = nil,
                  meterTable: MeterTable = MeterTable(),
                  keyTable: KeyTable = KeyTable()) -> Renderer<BeatTime, Pitch> {
    Renderer(parts: parts,
             workRules: rules,
             clock: RenderingClock(tempoMap: TempoMap(defaultTempo: Tempo(60)),
                                   meterTable: meterTable,
                                   keyTable: keyTable))
}

//
// Down at 1, re-pedaled at 3, up at 5.
//
func makeRepedaledPedalTable() -> PedalTable<BeatTime> {
    var table = PedalTable<BeatTime>()

    table.insert(time: 1, level: .down)
    table.insert(time: 3, level: .up)
    table.insert(time: 3, level: .down)
    table.insert(time: 5, level: .up)

    return table
}

//
// C D, a four-beat rest, E F, a one-beat rest, then G held for four beats.
//
func makeRestSplitTune() -> Work {
    var noteTable = NoteTable<BeatTime, Pitch>()

    for (attack, duration, pitch) in [(0, 1, Pitch.c4), (1, 1, .d4), (6, 1, .e4), (7, 1, .f4), (9, 4, .g4)] as [(Number, Number, Pitch)] {
        // swiftlint:disable:next force_unwrapping
        noteTable.insert(attack: BeatTime(numberValue: attack)!,
                         duration: beats(duration),
                         pitch: pitch)
    }

    return Work(name: "Tune",
                content: .standardBeat([Part(name: "Flute", noteTable: noteTable)], TempoMap(), MeterTable(), KeyTable()))
}

func makeRuledWork() -> Work {
    var part = Part<BeatTime, Pitch>(name: "Violin",
                                     interpretationRules: ruledPartRules())

    part.strands[0].noteTable.insert(attack: 0, duration: 1, pitch: .c4)
    part.markTable.insert(time: 1, mark: .caesura(nil))

    return Work(name: "Ruled",
                content: .standardBeat([part], TempoMap(), MeterTable(), KeyTable()),
                interpretationRules: ruledWorkRules())
}

//
// A melody starting at beat 2, in a part whose maps change before then — so that the setting at
// its first attack differs from the setting at time zero.
//
func makeSourceContextWork(instrument: Instrument = Fixtures.oboe) -> Work {
    var part = makePlainSourcePart()

    part.dynamicMap.insert(time: .zero, dynamic: .f)
    part.instrumentTable.insert(time: .zero, instrument: Fixtures.flute)
    part.instrumentTable.insert(time: beatTime(1), instrument: instrument)
    part.panMap.insert(time: .zero, pan: Pan(horizontal: 30))
    part.panMap.insert(time: beatTime(1), pan: Fixtures.leftPan)

    var tempoMap = TempoMap()

    tempoMap.insert(beatTime: .zero, tempo: Tempo(120))
    tempoMap.insert(beatTime: beatTime(1), tempo: Fixtures.slowTempo)

    return Work(name: "Tune",
                content: .standardBeat([part], tempoMap, MeterTable(), KeyTable()))
}

func makeStandardBeatWork(_ notes: [(Number, Number, Pitch)]) -> Work {
    var noteTable = NoteTable<BeatTime, Pitch>()

    for (attack, duration, pitch) in notes {
        // swiftlint:disable:next force_unwrapping
        noteTable.insert(attack: BeatTime(numberValue: attack)!,
                         // swiftlint:disable:next force_unwrapping
                         duration: BeatDuration(numberValue: duration)!,
                         pitch: pitch)
    }

    return Work(content: .standardBeat([Part(name: "Piano", noteTable: noteTable)], TempoMap(), MeterTable(), KeyTable()))
}

func makeTimeCodeExtras() -> Extras {
    Extras(elements: [Extra(name: Extra.midiTimeCode.name,
                            values: [.string("25"), .int(40)])])
}

func makeWallWork(frequencies: [Frequency]) -> Work {
    var table = NoteTable<WallTime, Frequency>()

    for (index, frequency) in frequencies.enumerated() {
        table.insert(attack: WallTime(UInt(index)), duration: 1, pitch: frequency)
    }

    return Work(content: .absoluteWall([Part(name: "Synth", noteTable: table)]))
}

func makeWallWork(noteNumbers: [NoteNumber]) -> Work {
    var table = NoteTable<WallTime, NoteNumber>()

    for (index, noteNumber) in noteNumbers.enumerated() {
        table.insert(attack: WallTime(UInt(index)), duration: 1, pitch: noteNumber)
    }

    return Work(content: .keyboardWall([Part(name: "Piano", noteTable: table)]))
}

func makeWorkInfo() -> Work.Info {
    Work.Info(title: "Aubade",
              subtitles: ["for violin"],
              alternateTitles: ["Dawn Song"],
              parentWorkTitle: "Suite No. 1",
              dedication: "To my teacher",
              credits: Credit(name: "J. Smith", role: .composer).map { [$0] } ?? [],
              rights: RightsNotice(text: "© 2026 J. Smith", scope: .music).map { [$0] } ?? [],
              remarks: Remark(text: "Written at dawn.", label: "history").map { [$0] } ?? [])
}

// Notes at 0 and 1 (a half note) and at 4; a fermata at 1 over a half, and a caesura at 2.
func markedPart() -> Part<BeatTime, Pitch> {
    var part = Part<BeatTime, Pitch>(name: "Test")

    part.strands[0].noteTable.insert(attack: 0, duration: 1, pitch: .c4)
    part.strands[0].noteTable.insert(attack: 1, duration: 1, pitch: .d4)
    part.strands[0].noteTable.insert(attack: 4, duration: 1, pitch: .e4)
    part.markTable.insert(time: 1, mark: longFermataMark(beats(frac(1, 2))))
    part.markTable.insert(time: 2, mark: .caesura(nil))

    return part
}

func markedPartRules() -> InterpretationRules {
    InterpretationRules(arpeggio: ArpeggioRules(direction: .down), caesura: positiveSeconds(1))
}

// A quarter-note fermata at 1 and a caesura at 2.
func markedTable() -> PartMarkTable<BeatTime> {
    var table = PartMarkTable<BeatTime>()

    table.insert(time: 1, mark: fermataMark(beats(frac(1, 4))))
    table.insert(time: 2, mark: .caesura(nil))

    return table
}

func meter(_ plain: String) -> Meter {
    // swiftlint:disable:next force_unwrapping
    Meter(plain: plain)!
}

func notesPerSecond(_ value: Number) -> NotesPerSecond {
    // swiftlint:disable:next force_unwrapping
    NotesPerSecond(numberValue: value)!
}

// An ornament from these parts, which must fit together.
func ornament(_ sign: BeatNotes.Ornament.Sign?,
              _ partner: BeatNotes.Ornament.Partner,
              _ execution: BeatNotes.OrnamentExecution? = nil) throws -> BeatNotes.Ornament {
    try #require(BeatNotes.Ornament(sign: sign,
                                    partner: partner,
                                    execution: execution))
}

func pedalLevel(_ numerator: Int,
                _ denominator: Int) -> Pedal.Level {
    Pedal.Level(Number(numerator: numerator, denominator: denominator))
}

func pianoFrequency(of noteNumber: NoteNumber) -> Frequency {
    KeyboardToAbsolutePitchConverter().convert(noteNumber).require()
}

// A renderer's notes as plain numbers, ordered by start, then pitch.
func plainNotes(_ notes: [Renderer<BeatTime, Pitch>.Note]) -> [RenderedNote] {
    notes.map { RenderedNote($0.start, $0.end - $0.start, $0.startPitch, $0.endPitch) }
        .sorted { ($0.start, $0.pitch) < ($1.start, $1.pitch) }
}

// A positive beat duration of `numerator / denominator` whole notes.
func positiveBeats(_ numerator: Int,
                   _ denominator: Int = 1) -> PositiveDuration<BeatDuration> {
    // swiftlint:disable:next force_unwrapping
    PositiveDuration(beats(frac(numerator, denominator)))!
}

// A positive wall duration of `numerator / denominator` seconds.
func positiveSeconds(_ numerator: Int,
                     _ denominator: Int = 1) -> PositiveDuration<WallDuration> {
    // swiftlint:disable:next force_unwrapping
    PositiveDuration(WallDuration(numberValue: frac(numerator, denominator))!)!
}

// A proportion of `numerator / denominator`, which must be valid.
func proportion(_ numerator: Int,
                _ denominator: Int) -> Proportion {
    // swiftlint:disable:next force_unwrapping
    Proportion(numberValue: frac(numerator, denominator))!
}

func quarterFermataMark(_ quarters: Int) -> PartMark<BeatTime> {
    .fermata(Fermata(), span: positiveBeats(quarters, 4))
}

// The rendered notes of a one-part standard beat work of these notes.
func render(_ notes: [WrittenNote],
            rules: InterpretationRules? = nil,
            meterTable: MeterTable = MeterTable(),
            keyTable: KeyTable = KeyTable()) throws -> [RenderedNote] {
    let work = try renderingWork([renderingPart(notes)],
                                 meterTable: meterTable,
                                 keyTable: keyTable,
                                 rules: rules)

    return try #require(renderedNotes(work.rendered()).first)
}

// The rendered notes of each part of a standard beat rendering, ordered by start, then pitch.
func renderedNotes(_ rendering: Work.Rendering) throws -> [[RenderedNote]] {
    guard case let .standardBeat(parts, _, _, _) = rendering.work.content.cases
    else { throw Work.Error.unsupportedStandardConversion }

    return parts.map { part in
        part.strands[0].noteTable.map { RenderedNote($0.attack.numberValue, $0.duration.numberValue, $0.startPitch, $0.endPitch) }
            .sorted { ($0.start, $0.pitch) < ($1.start, $1.pitch) }
    }
}

// A rendered work's notes, by part, then by strand, each strand in time order.
func renderedStrandNotes(_ rendering: Work.Rendering) throws -> [[[RenderedNote]]] {
    guard case let .standardBeat(parts, _, _, _) = rendering.work.content.cases
    else { throw Work.Error.unsupportedStandardConversion }

    return parts.map { part in
        part.strands.map { strand in
            strand.noteTable.map { RenderedNote($0.attack.numberValue, $0.duration.numberValue, $0.startPitch, $0.endPitch) }
                .sorted { ($0.start, $0.pitch) < ($1.start, $1.pitch) }
        }
    }
}

// When a beat time sounds in a rendered work, in seconds, rounded to the millisecond.
func renderedWallSeconds(_ rendering: Work.Rendering,
                         at time: Number) throws -> Number {
    let tempoMap = try #require(rendering.work.tempoMap)
    let seconds = TimeConverter(tempoMap: tempoMap).wallTime(at: beatTime(time)).numberValue

    return round(seconds * 1_000) / 1_000
}

// A standard beat part of these notes, with these rules.
func renderingPart(_ notes: [WrittenNote],
                   rules: InterpretationRules? = nil) throws -> Part<BeatTime, Pitch> {
    var table = BeatNotes()

    for note in notes {
        try table.insert(attack: beatTime(note.attack),
                         duration: beats(note.duration),
                         startPitch: note.pitch,
                         endPitch: note.endPitch ?? note.pitch,
                         extras: note.extras,
                         ornamentation: note.ornamentation)
    }

    return Part(name: "Part", noteTable: table, interpretationRules: rules)
}

// A standard beat work at ♩ = 60 of these parts.
// A part with one strand of written notes per element of `strands`, in order.
func renderingStrandedPart(_ strands: [[WrittenNote]]) throws -> Part<BeatTime, Pitch> {
    try Part(name: "Stranded",
             strands: strands.map { try Strand(noteTable: renderingPart($0).strands[0].noteTable) })
}

func renderingWork(_ parts: [Part<BeatTime, Pitch>],
                   meterTable: MeterTable = MeterTable(),
                   keyTable: KeyTable = KeyTable(),
                   rules: InterpretationRules? = nil) -> Work {
    Work(content: .standardBeat(parts, TempoMap(defaultTempo: Tempo(60)), meterTable, keyTable),
         interpretationRules: rules)
}

//
// Replaces the text of the file at `path` in a saved project's unzipped `root`.
//
func rewriteFile(_ root: FileWrapper,
                 _ path: [String],
                 _ transform: (String) -> String) throws {
    let directory = try #require(root.fileWrappers?[path[0]])
    let file = try #require(directory.fileWrappers?[path[1]])
    let data = try #require(file.regularFileContents)
    let text = try #require(String(bytes: data, encoding: .utf8))
    let newText = transform(text)

    #expect(newText != text)

    directory.removeFileWrapper(file)
    directory.addRegularFile(withContents: Data(newText.utf8),
                             preferredFilename: path[1])
}

func rollArpeggio(_ anchor: ArpeggioAnchor) -> BeatNotes.Arpeggio {
    BeatNotes.Arpeggio(group: 1,
                       execution: BeatNotes.ArpeggioExecution(spread: .perTone(positiveBeats(1, 32)),
                                                              anchor: anchor))
}

// A rolled chord tone, a thirty-second apart.
func rollOrnamentation(group: ArpeggioGroup = 1,
                       direction: ArpeggioDirection? = nil,
                       anchor: ArpeggioAnchor? = nil) -> BeatNotes.Ornamentation {
    BeatNotes.Ornamentation(arpeggio: BeatNotes.Arpeggio(group: group,
                                                         direction: direction,
                                                         execution: BeatNotes.ArpeggioExecution(spread: .perTone(positiveBeats(1, 32)),
                                                                                                anchor: anchor)))
}

func ruledPartRules() -> InterpretationRules {
    InterpretationRules(caesura: positiveSeconds(3))
}

func ruledWorkRules() -> InterpretationRules {
    InterpretationRules(arpeggio: ArpeggioRules(direction: .down), caesura: positiveSeconds(2))
}

func sampleExtras(_ value: String) -> Extras {
    Extras(elements: [Extra(name: "sample", values: [.string(value)])])
}

func sortedJointStates(of template: Template) throws -> [Template.State<BeatTime, Pitch>] {
    guard case let .standardBeat(model) = template.content
    else { throw Template.Error.incompatibleOptions }

    return try #require(model.chains.chain(for: .joint)).states.sorted()
}

func sortedStandardBeatStates(of template: Template,
                              _ role: Template.ChainRole) throws -> [Template.State<BeatTime, Pitch>] {
    guard case let .standardBeat(model) = template.content
    else { throw Template.Error.incompatibleOptions }

    return try #require(model.chains.chain(for: role)).states.sorted()
}

func standardBeatChain(of template: Template,
                       _ role: Template.ChainRole) throws -> MarkovChain<Template.State<BeatTime, Pitch>> {
    switch template.content {
    case let .standardBeat(model):
        return try #require(model.chains.chain(for: role))

    default:
        throw Template.Error.incompatibleOptions
    }
}

func standardBeatNoteEvents(of work: Work) throws -> [NoteEvent<BeatTime, Pitch>] {
    try standardBeatNoteTable(of: work).extractNoteEvents()
}

func standardBeatNoteEventsOrEmpty(of work: Work) -> [NoteEvent<BeatTime, Pitch>] {
    guard case let .standardBeat(parts, _, _, _) = work.content.cases
    else { return [] }

    return parts.first?.strands[0].noteTable.extractNoteEvents() ?? []
}

func standardBeatNoteTable(of work: Work) throws -> NoteTable<BeatTime, Pitch> {
    guard case let .standardBeat(parts, _, _, _) = work.content.cases
    else { throw Template.Error.incompatibleOptions }

    return try #require(parts.first).strands[0].noteTable
}

func standardBeatNoteTriples(of work: Work) throws -> [NoteTripleSB] {
    guard case let .standardBeat(parts, _, _, _) = work.content.cases
    else { throw Template.Error.incompatibleOptions }

    return try makeNoteTriplesSB(#require(parts.first).strands[0].noteTable)
}

func standardBeatParts(of work: Work) -> [Part<BeatTime, Pitch>] {
    guard case let .standardBeat(parts, _, _, _) = work.content.cases
    else { return [] }

    return parts
}

func standardBeatPitches(of work: Work) throws -> [Pitch] {
    guard case let .standardBeat(parts, _, _, _) = work.content.cases
    else { throw Template.Error.incompatibleOptions }

    return try makeNoteTriplesSB(#require(parts.first).strands[0].noteTable).map(\.pitch)
}

func standardBeatStates(of template: Template,
                        _ role: Template.ChainRole) throws -> [Template.State<BeatTime, Pitch>] {
    try standardBeatChain(of: template, role).states
}

//
// Each transition of the chain with `role`, by its source and target, with its weight.
//
func standardBeatTransitions(of template: Template,
                             _ role: Template.ChainRole) throws -> [String: UInt] {
    guard case let .standardBeat(model) = template.content
    else { throw Template.Error.incompatibleOptions }

    var result: [String: UInt] = [:]

    try #require(model.chains.chain(for: role)).forEach { transition in
        result["\(transition.source) → \(transition.target)"] = transition.weight
    }

    return result
}

func standardBeatVocabulary(of template: Template) throws -> Template.Vocabulary<BeatTime, Pitch> {
    guard case let .standardBeat(model) = template.content
    else { throw Template.Error.incompatibleOptions }

    return model.vocabulary
}

func standardWallDurations(of work: Work) throws -> [WallDuration] {
    guard case let .standardWall(parts) = work.content.cases
    else { throw Template.Error.incompatibleOptions }

    return try #require(parts.first).strands[0].noteTable.extractNoteEvents().map(\.duration)
}

func standardWallNoteEvents(of template: Template) throws -> [NoteEvent<WallTime, Pitch>] {
    guard case let .standardWall(model) = template.content
    else { throw Template.Error.incompatibleOptions }

    return try makeNoteEvents(#require(model.chains.chain(for: .joint)).states).sorted { $0.duration < $1.duration }
}

func standardWallPitches(of work: Work?) throws -> [Pitch] {
    guard case let .standardWall(parts) = try #require(work).content.cases
    else { Issue.record("Expected standard-wall content"); return [] }

    return try #require(parts.first).strands[0].noteTable.map(\.startPitch)
}

func summary(of table: MeterTable) -> [String] {
    table.map { "\($0.meter.plain)@\($0.beatTime.numberValue.simplified)" }
}

// Swaps C4 and G4 and keeps every other pitch, so a mapping can reorder a
// sorted pitch list.
func swapCAndG(_ pitch: Pitch) -> Pitch {
    switch pitch {
    case "C4":
        "G4"

    case "G4":
        "C4"

    default:
        pitch
    }
}

// A beat-to-beat note converter that swaps C4 and G4 and doubles every length.
func swappingNoteConverter() -> BeatNotes.Converter<BeatTime, Pitch> {
    BeatNotes.Converter(pitch: swapCAndG) { beats($0.numberValue * 2) }
}

// A figure before (D5, a sixteenth), a figure after (E4, taking a quarter of the note), a
// trill with a written partner (D4), and a fermata adding a quarter.
func transformableOrnamentation() throws -> BeatNotes.Ornamentation {
    try BeatNotes.Ornamentation(graceBefore: graceFigure([.d5], length: positiveBeats(1, 16)),
                                graceAfter: graceFigure([.e4], execution: BeatNotes.GraceExecution(fromMain: .share(proportion(1, 4)))),
                                ornament: ornament(.trill, .step(.above, written: .d4)),
                                fermata: Fermata(execution: FermataExecution(hold: .added(positiveBeats(1, 4)))))
}

func trillOrnamentation(written: Pitch?) throws -> BeatNotes.Ornamentation {
    try BeatNotes.Ornamentation(ornament: ornament(.trill, .step(.above, written: written)))
}

// A C4 half note at 0, with this fermata, and a D4 half note after it.
func twoNotePart(_ fermata: Fermata<BeatTime>? = nil) throws -> Part<BeatTime, Pitch> {
    try renderingPart([WrittenNote(0, frac(1, 2), .c4, fermata.map { BeatNotes.Ornamentation(fermata: $0) }),
                       WrittenNote(frac(1, 2), frac(1, 2), .d4)])
}

func wallAttacks(of work: Work) throws -> [Double] {
    guard case let .standardBeat(parts, tempoMap, _, _) = work.content.cases
    else { throw Work.Error.timeBasisMismatch(expected: .beat) }

    let converter = TimeConverter(tempoMap: tempoMap)

    return try #require(parts.first).strands[0].noteTable.map { converter.wallTime(at: $0.attack).doubleValue }
}

//
// `WallDuration(uintValue:)` and `WallTime(uintValue:)` never return `nil`.
//
func wallDuration(_ milliseconds: UInt) -> WallDuration {
    WallDuration(uintValue: milliseconds * 1_000)! // swiftlint:disable:this force_unwrapping
}

func wallTime(_ milliseconds: UInt) -> WallTime {
    WallTime(uintValue: milliseconds * 1_000)! // swiftlint:disable:this force_unwrapping
}

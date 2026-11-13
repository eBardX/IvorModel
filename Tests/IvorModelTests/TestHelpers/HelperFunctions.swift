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
    guard case let .absoluteWall(parts) = try #require(work).content
    else { Issue.record("Expected absolute-wall content"); return [] }

    return try #require(parts.first).noteTable.map(\.startPitch)
}

func analyzeAddingTemplate(_ work: Work,
                           states: Template.AnalysisOptions.StateRecipe = .exact,
                           variants: Template.AnalysisOptions.Variants = .none) throws -> Template {
    try Template.analyzeNoteEvents(in: work,
                                   at: 0,
                                   options: .init(maximumOrder: 2,
                                                  states: states,
                                                  variants: variants),
                                   name: "Test")
}

func analyzeMixTemplate(_ work: Work,
                        maximumOrder: Int = 1,
                        states: Template.AnalysisOptions.StateRecipe = .exact) throws -> Template {
    try Template.analyzeNoteEvents(in: work,
                                   at: 0,
                                   options: .init(maximumOrder: maximumOrder,
                                                  states: states),
                                   name: work.name)
}

func analyzePhraseTemplate(_ work: Work,
                           maximumOrder: Int = 2,
                           states: Template.AnalysisOptions.StateRecipe = .exact) throws -> Template {
    try Template.analyzeNoteEvents(in: work,
                                   at: 0,
                                   options: .init(maximumOrder: maximumOrder,
                                                  states: states),
                                   name: "Test")
}

func analyzeRecipeTemplate(_ work: Work,
                           pitch: Template.AnalysisOptions.StateRecipe.PitchFeature = .absolute,
                           duration: Template.AnalysisOptions.StateRecipe.DurationFeature = .absolute) throws -> Template {
    try Template.analyzeNoteEvents(in: work,
                                   at: 0,
                                   options: .init(maximumOrder: 1,
                                                  states: .init(pitch: pitch,
                                                                duration: duration)),
                                   name: "Test")
}

func analyzeRestSplitTune(restSplit: Template.AnalysisOptions.RestSplit?,
                          states: Template.AnalysisOptions.StateRecipe = .exact,
                          variants: Template.AnalysisOptions.Variants = .none) throws -> Template {
    try Template.analyzeNoteEvents(in: makeRestSplitTune(),
                                   at: 0,
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
                                   at: 0,
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
                                   at: 0,
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

func descending(_ interval: Interval) -> Template.AnalysisOptions.Transposition {
    .interval(DirectedInterval(interval: interval,
                               direction: .descending))
}

func descending(_ semitones: UInt) -> Template.AnalysisOptions.Transposition {
    // swiftlint:disable:next force_unwrapping
    .noteDistance(DirectedInterval(interval: NoteDistance(uintValue: semitones)!,
                                   direction: .descending))
}

func dynamicTime(of entryID: EntryID,
                 in part: Part<BeatTime, Pitch>) -> BeatTime? {
    part.dynamicMap.first { $0.entryID == entryID }?.time
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
// The contents of the file at `path` in a saved project's unzipped `root`.
//
func extraValues(_ extra: Extra,
                 in extras: Extras?) -> [Extra.AssociatedValue]? {
    extras?.elements.first { $0.name == extra.name }?.values
}

func fileContents(of root: FileWrapper,
                  _ path: [String]) throws -> Data {
    let directory = try #require(root.fileWrappers?[path[0]])
    let file = try #require(directory.fileWrappers?[path[1]])

    return try #require(file.regularFileContents)
}

func firstAbsolutePartID(of work: Work) throws -> PartID {
    guard case let .absoluteWall(parts) = work.content
    else { Issue.record("Expected absolute-wall content"); return PartID() }

    return try #require(parts.first).partID
}

func firstNoteSB(_ pitch: Pitch,
                 in part: Part<BeatTime, Pitch>) -> NoteTable<BeatTime, Pitch>.Note? {
    part.noteTable.first { $0.startPitch == pitch }
}

func frac(_ numerator: Int,
          _ denominator: Int) -> Number {
    Number(numerator: numerator, denominator: denominator)
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

func jointNoteEvents(of template: Template) throws -> [NoteEvent<BeatTime, Pitch>] {
    guard case let .standardBeat(model) = template.content
    else { throw Template.Error.incompatibleOptions }

    return try makeNoteEvents(#require(model.chains.chain(for: .joint)).states)
}

func keyboardWallPitches(of work: Work?) throws -> [NoteNumber] {
    guard case let .keyboardWall(parts) = try #require(work).content
    else { Issue.record("Expected keyboard-wall content"); return [] }

    return try #require(parts.first).noteTable.map(\.startPitch)
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

    return Work(content: .keyboardBeat([Part(name: "Piano", noteTable: noteTable)], TempoMap(), MeterTable()))
}

func makeLockedWorkSB() -> (work: Work, partID: PartID) {
    var part = Part<BeatTime, Pitch>(name: "Violin")

    part.noteTable.insert(attack: 0, duration: 1, pitch: .c4)

    var work = Work(content: .standardBeat([part], TempoMap(), MeterTable()))

    work.isLocked = true

    return (work, part.partID)
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
                content: .standardBeat([Part(name: "Piano", noteTable: noteTable)], TempoMap(), MeterTable()))
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
                content: .standardBeat([Part(name: "Piano", noteTable: noteTable)], TempoMap(), MeterTable()))
}

func makeOrganPatch() throws -> Patch {
    try #require(Patch(.generalMIDI1(program: 20)))
}

func makeOrganPatchTable() throws -> PatchTable {
    let patch = try #require(Patch(.generalMIDI1(program: 20)))
    let assignment = try #require(PatchTable.Assignment(patch: patch))

    return PatchTable([.vanilla: assignment])
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
         content: .standardBeat([makePlainSourcePart()], TempoMap(), MeterTable()))
}

//
// C D, a four-beat rest, E F, a one-beat rest, then G held for four beats.
//
// Down at 1, re-pedaled at 3, up at 5.
func makeRepedaledPedalTable() -> PedalTable<BeatTime> {
    var table = PedalTable<BeatTime>()

    table.insert(time: 1, level: .down)
    table.insert(time: 3, level: .up)
    table.insert(time: 3, level: .down)
    table.insert(time: 5, level: .up)

    return table
}

func makeRestSplitTune() -> Work {
    var noteTable = NoteTable<BeatTime, Pitch>()

    for (attack, duration, pitch) in [(0, 1, Pitch.c4), (1, 1, .d4), (6, 1, .e4), (7, 1, .f4), (9, 4, .g4)] as [(Number, Number, Pitch)] {
        // swiftlint:disable:next force_unwrapping
        noteTable.insert(attack: BeatTime(numberValue: attack)!,
                         duration: beats(duration),
                         pitch: pitch)
    }

    return Work(name: "Tune",
                content: .standardBeat([Part(name: "Flute", noteTable: noteTable)], TempoMap(), MeterTable()))
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
                content: .standardBeat([part], tempoMap, MeterTable()))
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

    return Work(content: .standardBeat([Part(name: "Piano", noteTable: noteTable)], TempoMap(), MeterTable()))
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

func meter(_ plain: String) -> Meter {
    // swiftlint:disable:next force_unwrapping
    Meter(plain: plain)!
}

func pedalLevel(_ numerator: Int,
                _ denominator: Int) -> Pedal.Level {
    Pedal.Level(Number(numerator: numerator, denominator: denominator))
}

func pianoFrequency(of noteNumber: NoteNumber) -> Frequency {
    KeyboardToAbsolutePitchConverter().convert(noteNumber).require()
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
    guard case let .standardBeat(parts, _, _) = work.content
    else { return [] }

    return parts.first?.noteTable.extractNoteEvents() ?? []
}

func standardBeatNoteTable(of work: Work) throws -> NoteTable<BeatTime, Pitch> {
    guard case let .standardBeat(parts, _, _) = work.content
    else { throw Template.Error.incompatibleOptions }

    return try #require(parts.first).noteTable
}

func standardBeatNoteTriples(of work: Work) throws -> [NoteTripleSB] {
    guard case let .standardBeat(parts, _, _) = work.content
    else { throw Template.Error.incompatibleOptions }

    return try makeNoteTriplesSB(#require(parts.first).noteTable)
}

func standardBeatPitches(of work: Work) throws -> [Pitch] {
    guard case let .standardBeat(parts, _, _) = work.content
    else { throw Template.Error.incompatibleOptions }

    return try makeNoteTriplesSB(#require(parts.first).noteTable).map(\.pitch)
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
    guard case let .standardWall(parts) = work.content
    else { throw Template.Error.incompatibleOptions }

    return try #require(parts.first).noteTable.extractNoteEvents().map(\.duration)
}

func standardWallNoteEvents(of template: Template) throws -> [NoteEvent<WallTime, Pitch>] {
    guard case let .standardWall(model) = template.content
    else { throw Template.Error.incompatibleOptions }

    return try makeNoteEvents(#require(model.chains.chain(for: .joint)).states).sorted { $0.duration < $1.duration }
}

func standardWallPitches(of work: Work?) throws -> [Pitch] {
    guard case let .standardWall(parts) = try #require(work).content
    else { Issue.record("Expected standard-wall content"); return [] }

    return try #require(parts.first).noteTable.map(\.startPitch)
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

// swiftlint:enable file_length

// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiNumbers
import XestiSexp
import XestiTools

// swiftlint:disable file_length

//
// The stored form of a work, as a project saves it (`SexpEncoder`), pinned byte for byte for
// each of the six kinds of content. A work's IDs are random, so the pinned text is the test's
// input: it must decode, and encoding the result must give exactly the same text back.
//
// The pins change only when the stored format is meant to change. To make new ones, run the
// tests with `IVOR_GOLDEN_OUTPUT` set to a directory: each test then writes a freshly built
// work's encoding there (as `<kind>.sexp`) instead of comparing, and the files' contents
// replace the strings below.
//
struct WorkGoldenEncodingTests {
}

// MARK: -

extension WorkGoldenEncodingTests {
    @Test
    func absoluteBeat() throws {
        try Self._check(.absoluteBeat, built: Self._absoluteBeatWork)
    }

    @Test
    func absoluteWall() throws {
        try Self._check(.absoluteWall, built: Self._absoluteWallWork)
    }

    @Test
    func keyboardBeat() throws {
        try Self._check(.keyboardBeat, built: Self._keyboardBeatWork)
    }

    @Test
    func keyboardWall() throws {
        try Self._check(.keyboardWall, built: Self._keyboardWallWork)
    }

    @Test
    func standardBeat() throws {
        try Self._check(.standardBeat, built: Self._standardBeatWork)
    }

    @Test
    func standardWall() throws {
        try Self._check(.standardWall, built: Self._standardWallWork)
    }

    // MARK: Private Nested Types

    private enum _Kind: String {
        case absoluteBeat
        case absoluteWall
        case keyboardBeat
        case keyboardWall
        case standardBeat
        case standardWall
    }

    // MARK: Private Type Methods

    private static func _absoluteBeatWork() throws -> Work {
        let part = try _part(times: [0, 1, 2, 3].map(beatTime),
                             durations: [1, 1, frac(1, 2)].map(beats),
                             pitches: [220, 330, 440].map { try #require(Frequency(uintValue: $0)) },
                             mark: .fermata(Fermata(shape: .short),
                                            span: positiveBeats(1, 2)))

        return try _work(.absoluteBeat([part], _tempoMap(), _meterTable(), _keyTable()),
                         partID: part.partID)
    }

    private static func _absoluteWallWork() throws -> Work {
        let part = try _part(times: [0, 1_000, 2_000, 3_000].map(wallTime),
                             durations: [1_000, 1_000, 500].map(wallDuration),
                             pitches: [220, 330, 440].map { try #require(Frequency(uintValue: $0)) },
                             mark: .caesura(nil))

        return try _work(.absoluteWall([part]),
                         partID: part.partID)
    }

    private static func _check(_ kind: _Kind,
                               built: () throws -> Work) throws {
        if let directory = ProcessInfo.processInfo.environment["IVOR_GOLDEN_OUTPUT"] {
            let url = URL(fileURLWithPath: directory).appendingPathComponent("\(kind.rawValue).sexp")

            try SexpEncoder().encode(built()).write(to: url)

            return
        }

        let pinned = _golden(for: kind)
        let work = try SexpDecoder().decode(Work.self,
                                            from: Data(pinned.utf8))
        let encoded = try #require(String(data: SexpEncoder().encode(work),
                                          encoding: .utf8))

        #expect(encoded == pinned)
    }

    private static func _golden(for kind: _Kind) -> String {
        switch kind {
        case .absoluteBeat:
            _absoluteBeatGolden

        case .absoluteWall:
            _absoluteWallGolden

        case .keyboardBeat:
            _keyboardBeatGolden

        case .keyboardWall:
            _keyboardWallGolden

        case .standardBeat:
            _standardBeatGolden

        case .standardWall:
            _standardWallGolden
        }
    }

    private static func _keyboardBeatWork() throws -> Work {
        let part = try _part(times: [0, 1, 2, 3].map(beatTime),
                             durations: [1, 1, frac(1, 2)].map(beats),
                             pitches: [60, 64, 67].map { try #require(NoteNumber(uintValue: $0)) },
                             mark: .fermata(Fermata(shape: .long),
                                            span: positiveBeats(1, 4)))

        return try _work(.keyboardBeat([part], _tempoMap(), _meterTable(), _keyTable()),
                         partID: part.partID)
    }

    private static func _keyboardWallWork() throws -> Work {
        let part = try _part(times: [0, 1_000, 2_000, 3_000].map(wallTime),
                             durations: [1_000, 1_000, 500].map(wallDuration),
                             pitches: [60, 64, 67].map { try #require(NoteNumber(uintValue: $0)) },
                             mark: .caesura(nil))

        return try _work(.keyboardWall([part]),
                         partID: part.partID)
    }

    private static func _keyTable() throws -> KeyTable {
        try makeKeyTable([(0, 2), (2, -1)])
    }

    private static func _meterTable() throws -> MeterTable {
        try makeMeterTable([(0, "3/4"), (frac(3, 4), "2+2+3/8")])
    }

    //
    // A part with every table filled: three notes (a plain one with extras, a glide, and a
    // rolled one), a dynamic map with a hairpin, an instrument change with extras, a pan
    // change, a sustain pedal (only one pedal kind: `Part.pedals` is a dictionary, whose
    // encoded order would otherwise vary from run to run), a part mark, part rules and part
    // extras. `times` has four entries, the last after every note; `durations` and `pitches`
    // have three.
    //
    private static func _part<TimeType: TimeProtocol, PitchType: PitchProtocol>(times: [TimeType],
                                                                                durations: [TimeType.DurationType],
                                                                                pitches: [PitchType],
                                                                                mark: PartMark<TimeType>) throws -> Part<TimeType, PitchType> {
        typealias Notes = NoteTable<TimeType, PitchType>

        var noteTable = Notes()

        noteTable.insert(attack: times[0],
                         duration: durations[0],
                         pitch: pitches[0],
                         extras: sampleExtras("note"))

        noteTable.insert(attack: times[1],
                         duration: durations[1],
                         startPitch: pitches[1],
                         endPitch: pitches[2])

        try noteTable.insert(attack: times[2],
                             duration: durations[2],
                             pitch: pitches[2],
                             ornamentation: Notes.Ornamentation(arpeggio: Notes.Arpeggio(group: 1,
                                                                                         direction: .up)))

        var dynamicMap = DynamicMap<TimeType>()

        dynamicMap.insert(time: times[0], dynamic: .p)
        dynamicMap.insert(time: times[2], dynamic: .f, extras: sampleExtras("dynamic"))

        var instrumentTable = InstrumentTable<TimeType>()

        instrumentTable.insert(time: times[0], instrument: Fixtures.flute)
        instrumentTable.insert(time: times[2], instrument: Fixtures.oboe, extras: sampleExtras("instrument"))

        var panMap = PanMap<TimeType>()

        panMap.insert(time: times[1], pan: Fixtures.leftPan)

        var sustain = PedalTable<TimeType>()

        sustain.insert(time: times[0], level: .down)
        sustain.insert(time: times[3], level: .up)

        var markTable = PartMarkTable<TimeType>()

        markTable.insert(time: times[2], mark: mark)

        return Part(name: "Golden",
                    noteTable: noteTable,
                    dynamicMap: dynamicMap,
                    instrumentTable: instrumentTable,
                    panMap: panMap,
                    pedals: [.sustain: sustain],
                    markTable: markTable,
                    interpretationRules: InterpretationRules(caesura: positiveSeconds(1, 2)),
                    extras: sampleExtras("part"))
    }

    private static func _standardBeatWork() throws -> Work {
        var part = try _part(times: [0, 1, 2, 3].map(beatTime),
                             durations: [1, 1, frac(1, 2)].map(beats),
                             pitches: [Pitch.c4, .e4, .g4],
                             mark: .fermata(Fermata(shape: .short),
                                            span: positiveBeats(1, 2)))

        // Standard pitch alone gets the full set of ornaments, which are spelled in it.
        try part.strands[0].noteTable.insert(attack: beatTime(4),
                                             duration: beats(1),
                                             pitch: .c5,
                                             ornamentation: fullOrnamentation())

        return try _work(.standardBeat([part], _tempoMap(), _meterTable(), _keyTable()),
                         partID: part.partID)
    }

    private static func _standardWallWork() throws -> Work {
        let part = try _part(times: [0, 1_000, 2_000, 3_000].map(wallTime),
                             durations: [1_000, 1_000, 500].map(wallDuration),
                             pitches: [Pitch.c4, .e4, .g4],
                             mark: .caesura(nil))

        return try _work(.standardWall([part]),
                         partID: part.partID)
    }

    private static func _tempoMap() -> TempoMap {
        var tempoMap = TempoMap()

        tempoMap.insert(beatTime: beatTime(0), tempo: Tempo(120))
        tempoMap.insert(beatTime: beatTime(2), tempo: Fixtures.slowTempo, extras: sampleExtras("tempo"))

        return tempoMap
    }

    //
    // A work around `content`, with work extras and rules, and a realization with defaults and
    // a patch table for the part.
    //
    private static func _work(_ content: Work.Content,
                              partID: PartID) throws -> Work {
        let flute = try #require(Patch(.generalMIDI1(program: 74)))
        let oboe = try #require(Patch(.generalMIDI1(program: 69)))
        let realization = try Realization(name: Work.defaultRealizationName,
                                          defaults: PatchTable([Fixtures.flute: #require(PatchTable.Assignment(patch: flute))]),
                                          partTables: [partID: PatchTable([Fixtures.oboe: #require(PatchTable.Assignment(patch: oboe,
                                                                                                                         channel: 3))])])

        return Work(name: "Golden",
                    content: content,
                    extras: sampleExtras("work"),
                    interpretationRules: fullInterpretationRules(),
                    realizations: [realization])
    }

    // MARK: Private Type Properties

    private static let _absoluteBeatGolden = #"""
        ((workID W$7hzX3VHRTRX07c831JGlRV)
         (version 1)
         (isLocked #f)
         (name Golden)
         (smpteStartTime ("25" "00:00:00:00"))
         (info
          ((subtitles ())
           (alternateTitles ())
           (credits ())
           (rights ())
           (remarks ())))
         (extras
          ((entries (sample (sample work)))))
         (interpretationRules
          ((grace
            ((maximumShare 1/2)
             (perNote 40000)
             (slashedPlacement beforeBeat)
             (unslashedPlacement onBeat)))
           (trill
            ((extent ((span 3/4)))
             (partnerRule diatonic)
             (rate 12)
             (startNote partner)))
           (mordent ((extent ((count 2)))))
           (tremolo ((rate 16)))
           (arpeggio
            ((anchor lastOnBeat)
             (direction down)
             (spread ((perTone 50000)))))
           (fermata
            ((holds ((short ((stretch 3/2)))))
             (pauseAfter 500000)))
           (caesura 2000000)))
         (realizations
          (((realizationID R$6PEy1JhqklHPM2j8IguU9A)
            (name Default)
            (defaults
             ((Flute
               ((patch ((generalMIDI1 ((program 74)))))))))
            (partTables
             ((P$6r7321HHgPXxrM8YFAm9Bf
               ((Oboe
                 ((patch ((generalMIDI1 ((program 69)))))
                  (channel 3))))))))))
         (content
          ((pitchNotation absolute)
           (timeBasis beat)
           (parts
            (((partID P$6r7321HHgPXxrM8YFAm9Bf)
              (name Golden)
              (strands
               (((strandID S$3Ul65wbHMP68heAOYmqLjm)
                 (name "")
                 (noteTable
                  ((notes
                    ((0
                      1
                      220
                      220
                      ((entries (sample (sample note)))))
                     (1 1 330 440)
                     (2
                      1/2
                      440
                      440
                      ()
                      ((arpeggio
                        ((direction up) (group 1))))))))))))
              (dynamicMap
               ((entries
                 ((0 2/5)
                  (2
                   7/10
                   ((entries (sample (sample dynamic)))))))
                (defaultDynamic 1/2)))
              (instrumentTable
               ((entries
                 ((0 Flute)
                  (2
                   Oboe
                   ((entries (sample (sample instrument)))))))
                (defaultInstrument Vanilla)))
              (panMap
               ((entries ((1 (-45 0))))
                (defaultPan (0 0))))
              (pedals
               ((sustain
                 ((entries
                   ((0 1/1) (3 0/1)))))))
              (markTable
               ((entries
                 ((2
                   ((fermata (((shape short)) 1/2))))))))
              (interpretationRules ((caesura 500000)))
              (extras
               ((entries (sample (sample part))))))))
           (tempoMap
            ((entries
              ((0 "1/4=120")
               (2
                "1/4=96"
                ((entries (sample (sample tempo)))))))
             (defaultTempo "1/4=60")))
           (meterTable
            ((entries
              ((0 "3/4") (3/4 "2+2+3/8")))
             (pickup 0)))
           (keyTable
            ((entries
              ((0 ((fifths 2)))
               (2 ((fifths -1))))))))))
        """#

    private static let _absoluteWallGolden = #"""
        ((workID W$6XptM9buQfhaQxklqH9Xws)
         (version 1)
         (isLocked #f)
         (name Golden)
         (smpteStartTime ("25" "00:00:00:00"))
         (info
          ((subtitles ())
           (alternateTitles ())
           (credits ())
           (rights ())
           (remarks ())))
         (extras
          ((entries (sample (sample work)))))
         (interpretationRules
          ((grace
            ((maximumShare 1/2)
             (perNote 40000)
             (slashedPlacement beforeBeat)
             (unslashedPlacement onBeat)))
           (trill
            ((extent ((span 3/4)))
             (partnerRule diatonic)
             (rate 12)
             (startNote partner)))
           (mordent ((extent ((count 2)))))
           (tremolo ((rate 16)))
           (arpeggio
            ((anchor lastOnBeat)
             (direction down)
             (spread ((perTone 50000)))))
           (fermata
            ((holds ((short ((stretch 3/2)))))
             (pauseAfter 500000)))
           (caesura 2000000)))
         (realizations
          (((realizationID R$70oFbNZaKVmAcc0DOKvGTb)
            (name Default)
            (defaults
             ((Flute
               ((patch ((generalMIDI1 ((program 74)))))))))
            (partTables
             ((P$06W8E6bGgOx06pfToL2e9A
               ((Oboe
                 ((patch ((generalMIDI1 ((program 69)))))
                  (channel 3))))))))))
         (content
          ((pitchNotation absolute)
           (timeBasis wall)
           (parts
            (((partID P$06W8E6bGgOx06pfToL2e9A)
              (name Golden)
              (strands
               (((strandID S$01tX4655lKyGZhtwwt9I6U)
                 (name "")
                 (noteTable
                  ((notes
                    ((0
                      1000000
                      220
                      220
                      ((entries (sample (sample note)))))
                     (1000000 1000000 330 440)
                     (2000000
                      500000
                      440
                      440
                      ()
                      ((arpeggio
                        ((direction up) (group 1))))))))))))
              (dynamicMap
               ((entries
                 ((0 2/5)
                  (2000000
                   7/10
                   ((entries (sample (sample dynamic)))))))
                (defaultDynamic 1/2)))
              (instrumentTable
               ((entries
                 ((0 Flute)
                  (2000000
                   Oboe
                   ((entries (sample (sample instrument)))))))
                (defaultInstrument Vanilla)))
              (panMap
               ((entries ((1000000 (-45 0))))
                (defaultPan (0 0))))
              (pedals
               ((sustain
                 ((entries
                   ((0 1/1) (3000000 0/1)))))))
              (markTable
               ((entries ((2000000 ((caesura #t)))))))
              (interpretationRules ((caesura 500000)))
              (extras
               ((entries (sample (sample part)))))))))))
        """#

    private static let _keyboardBeatGolden = #"""
        ((workID W$1AfhNou9pEkGyvFbJCFBOU)
         (version 1)
         (isLocked #f)
         (name Golden)
         (smpteStartTime ("25" "00:00:00:00"))
         (info
          ((subtitles ())
           (alternateTitles ())
           (credits ())
           (rights ())
           (remarks ())))
         (extras
          ((entries (sample (sample work)))))
         (interpretationRules
          ((grace
            ((maximumShare 1/2)
             (perNote 40000)
             (slashedPlacement beforeBeat)
             (unslashedPlacement onBeat)))
           (trill
            ((extent ((span 3/4)))
             (partnerRule diatonic)
             (rate 12)
             (startNote partner)))
           (mordent ((extent ((count 2)))))
           (tremolo ((rate 16)))
           (arpeggio
            ((anchor lastOnBeat)
             (direction down)
             (spread ((perTone 50000)))))
           (fermata
            ((holds ((short ((stretch 3/2)))))
             (pauseAfter 500000)))
           (caesura 2000000)))
         (realizations
          (((realizationID R$2qSTBJ82BkFJac5yXlVOrn)
            (name Default)
            (defaults
             ((Flute
               ((patch ((generalMIDI1 ((program 74)))))))))
            (partTables
             ((P$1lrVoiMebJyNKHl9GXAjzr
               ((Oboe
                 ((patch ((generalMIDI1 ((program 69)))))
                  (channel 3))))))))))
         (content
          ((pitchNotation keyboard)
           (timeBasis beat)
           (parts
            (((partID P$1lrVoiMebJyNKHl9GXAjzr)
              (name Golden)
              (strands
               (((strandID S$075l8lzQLJbV7Ove1t1FDM)
                 (name "")
                 (noteTable
                  ((notes
                    ((0
                      1
                      60
                      60
                      ((entries (sample (sample note)))))
                     (1 1 64 67)
                     (2
                      1/2
                      67
                      67
                      ()
                      ((arpeggio
                        ((direction up) (group 1))))))))))))
              (dynamicMap
               ((entries
                 ((0 2/5)
                  (2
                   7/10
                   ((entries (sample (sample dynamic)))))))
                (defaultDynamic 1/2)))
              (instrumentTable
               ((entries
                 ((0 Flute)
                  (2
                   Oboe
                   ((entries (sample (sample instrument)))))))
                (defaultInstrument Vanilla)))
              (panMap
               ((entries ((1 (-45 0))))
                (defaultPan (0 0))))
              (pedals
               ((sustain
                 ((entries
                   ((0 1/1) (3 0/1)))))))
              (markTable
               ((entries
                 ((2
                   ((fermata (((shape long)) 1/4))))))))
              (interpretationRules ((caesura 500000)))
              (extras
               ((entries (sample (sample part))))))))
           (tempoMap
            ((entries
              ((0 "1/4=120")
               (2
                "1/4=96"
                ((entries (sample (sample tempo)))))))
             (defaultTempo "1/4=60")))
           (meterTable
            ((entries
              ((0 "3/4") (3/4 "2+2+3/8")))
             (pickup 0)))
           (keyTable
            ((entries
              ((0 ((fifths 2)))
               (2 ((fifths -1))))))))))
        """#

    private static let _keyboardWallGolden = #"""
        ((workID W$62GQDUehEvwlJa3vnQqf33)
         (version 1)
         (isLocked #f)
         (name Golden)
         (smpteStartTime ("25" "00:00:00:00"))
         (info
          ((subtitles ())
           (alternateTitles ())
           (credits ())
           (rights ())
           (remarks ())))
         (extras
          ((entries (sample (sample work)))))
         (interpretationRules
          ((grace
            ((maximumShare 1/2)
             (perNote 40000)
             (slashedPlacement beforeBeat)
             (unslashedPlacement onBeat)))
           (trill
            ((extent ((span 3/4)))
             (partnerRule diatonic)
             (rate 12)
             (startNote partner)))
           (mordent ((extent ((count 2)))))
           (tremolo ((rate 16)))
           (arpeggio
            ((anchor lastOnBeat)
             (direction down)
             (spread ((perTone 50000)))))
           (fermata
            ((holds ((short ((stretch 3/2)))))
             (pauseAfter 500000)))
           (caesura 2000000)))
         (realizations
          (((realizationID R$6R3SJA3eXt5ObN5eC6rkfG)
            (name Default)
            (defaults
             ((Flute
               ((patch ((generalMIDI1 ((program 74)))))))))
            (partTables
             ((P$0UezhaGtl6SpzlUugVv9GH
               ((Oboe
                 ((patch ((generalMIDI1 ((program 69)))))
                  (channel 3))))))))))
         (content
          ((pitchNotation keyboard)
           (timeBasis wall)
           (parts
            (((partID P$0UezhaGtl6SpzlUugVv9GH)
              (name Golden)
              (strands
               (((strandID S$4IL7a3a74ip1CeDOWVBzxK)
                 (name "")
                 (noteTable
                  ((notes
                    ((0
                      1000000
                      60
                      60
                      ((entries (sample (sample note)))))
                     (1000000 1000000 64 67)
                     (2000000
                      500000
                      67
                      67
                      ()
                      ((arpeggio
                        ((direction up) (group 1))))))))))))
              (dynamicMap
               ((entries
                 ((0 2/5)
                  (2000000
                   7/10
                   ((entries (sample (sample dynamic)))))))
                (defaultDynamic 1/2)))
              (instrumentTable
               ((entries
                 ((0 Flute)
                  (2000000
                   Oboe
                   ((entries (sample (sample instrument)))))))
                (defaultInstrument Vanilla)))
              (panMap
               ((entries ((1000000 (-45 0))))
                (defaultPan (0 0))))
              (pedals
               ((sustain
                 ((entries
                   ((0 1/1) (3000000 0/1)))))))
              (markTable
               ((entries ((2000000 ((caesura #t)))))))
              (interpretationRules ((caesura 500000)))
              (extras
               ((entries (sample (sample part)))))))))))
        """#

    private static let _standardBeatGolden = #"""
        ((workID W$7ePGMztA2Edu5fl1rfzHwM)
         (version 1)
         (isLocked #f)
         (name Golden)
         (smpteStartTime ("25" "00:00:00:00"))
         (info
          ((subtitles ())
           (alternateTitles ())
           (credits ())
           (rights ())
           (remarks ())))
         (extras
          ((entries (sample (sample work)))))
         (interpretationRules
          ((grace
            ((maximumShare 1/2)
             (perNote 40000)
             (slashedPlacement beforeBeat)
             (unslashedPlacement onBeat)))
           (trill
            ((extent ((span 3/4)))
             (partnerRule diatonic)
             (rate 12)
             (startNote partner)))
           (mordent ((extent ((count 2)))))
           (tremolo ((rate 16)))
           (arpeggio
            ((anchor lastOnBeat)
             (direction down)
             (spread ((perTone 50000)))))
           (fermata
            ((holds ((short ((stretch 3/2)))))
             (pauseAfter 500000)))
           (caesura 2000000)))
         (realizations
          (((realizationID R$2yYctaMvmO2b5hlGfYB6SP)
            (name Default)
            (defaults
             ((Flute
               ((patch ((generalMIDI1 ((program 74)))))))))
            (partTables
             ((P$6XL2xvRx1cfnCJ3ObZXNV4
               ((Oboe
                 ((patch ((generalMIDI1 ((program 69)))))
                  (channel 3))))))))))
         (content
          ((pitchNotation standard)
           (timeBasis beat)
           (parts
            (((partID P$6XL2xvRx1cfnCJ3ObZXNV4)
              (name Golden)
              (strands
               (((strandID S$4QUkjFlN8Sb32SvpjNscHY)
                 (name "")
                 (noteTable
                  ((notes
                    ((0
                      1
                      "C♮4"
                      "C♮4"
                      ((entries (sample (sample note)))))
                     (1 1 "E♮4" "G♮4")
                     (2
                      1/2
                      "G♮4"
                      "G♮4"
                      ()
                      ((arpeggio
                        ((direction up) (group 1)))))
                     (4
                      1
                      "C♮5"
                      "C♮5"
                      ()
                      ((arpeggio
                        ((execution ((spread ((perTone 1/64)))))
                         (group 1)))
                       (fermata
                        ((execution ((hold ((added 1/4)))))
                         (shape long)))
                       (graceAfter
                        ((events ((("B♮4")) (("C♮5"))))
                         (execution ((fromMain ((share 1/4)))))))
                       (graceBefore ((events ((("D♮5") 1/16)))))
                       (ornament
                        ((sign ((trill #t)))
                         (partner ((step ((side above)))))
                         (execution ((rate ((noteValue 1/32))))))))))))))))
              (dynamicMap
               ((entries
                 ((0 2/5)
                  (2
                   7/10
                   ((entries (sample (sample dynamic)))))))
                (defaultDynamic 1/2)))
              (instrumentTable
               ((entries
                 ((0 Flute)
                  (2
                   Oboe
                   ((entries (sample (sample instrument)))))))
                (defaultInstrument Vanilla)))
              (panMap
               ((entries ((1 (-45 0))))
                (defaultPan (0 0))))
              (pedals
               ((sustain
                 ((entries
                   ((0 1/1) (3 0/1)))))))
              (markTable
               ((entries
                 ((2
                   ((fermata (((shape short)) 1/2))))))))
              (interpretationRules ((caesura 500000)))
              (extras
               ((entries (sample (sample part))))))))
           (tempoMap
            ((entries
              ((0 "1/4=120")
               (2
                "1/4=96"
                ((entries (sample (sample tempo)))))))
             (defaultTempo "1/4=60")))
           (meterTable
            ((entries
              ((0 "3/4") (3/4 "2+2+3/8")))
             (pickup 0)))
           (keyTable
            ((entries
              ((0 ((fifths 2)))
               (2 ((fifths -1))))))))))
        """#

    private static let _standardWallGolden = #"""
        ((workID W$6Pt54snFCcnHBOMln8RA3r)
         (version 1)
         (isLocked #f)
         (name Golden)
         (smpteStartTime ("25" "00:00:00:00"))
         (info
          ((subtitles ())
           (alternateTitles ())
           (credits ())
           (rights ())
           (remarks ())))
         (extras
          ((entries (sample (sample work)))))
         (interpretationRules
          ((grace
            ((maximumShare 1/2)
             (perNote 40000)
             (slashedPlacement beforeBeat)
             (unslashedPlacement onBeat)))
           (trill
            ((extent ((span 3/4)))
             (partnerRule diatonic)
             (rate 12)
             (startNote partner)))
           (mordent ((extent ((count 2)))))
           (tremolo ((rate 16)))
           (arpeggio
            ((anchor lastOnBeat)
             (direction down)
             (spread ((perTone 50000)))))
           (fermata
            ((holds ((short ((stretch 3/2)))))
             (pauseAfter 500000)))
           (caesura 2000000)))
         (realizations
          (((realizationID R$2ndnf9uraNMbjTyO9TLyvD)
            (name Default)
            (defaults
             ((Flute
               ((patch ((generalMIDI1 ((program 74)))))))))
            (partTables
             ((P$28LgpF1KlFoyh9atFH5Vrl
               ((Oboe
                 ((patch ((generalMIDI1 ((program 69)))))
                  (channel 3))))))))))
         (content
          ((pitchNotation standard)
           (timeBasis wall)
           (parts
            (((partID P$28LgpF1KlFoyh9atFH5Vrl)
              (name Golden)
              (strands
               (((strandID S$1po0XWOqEgxL3QKd52R1X1)
                 (name "")
                 (noteTable
                  ((notes
                    ((0
                      1000000
                      "C♮4"
                      "C♮4"
                      ((entries (sample (sample note)))))
                     (1000000 1000000 "E♮4" "G♮4")
                     (2000000
                      500000
                      "G♮4"
                      "G♮4"
                      ()
                      ((arpeggio
                        ((direction up) (group 1))))))))))))
              (dynamicMap
               ((entries
                 ((0 2/5)
                  (2000000
                   7/10
                   ((entries (sample (sample dynamic)))))))
                (defaultDynamic 1/2)))
              (instrumentTable
               ((entries
                 ((0 Flute)
                  (2000000
                   Oboe
                   ((entries (sample (sample instrument)))))))
                (defaultInstrument Vanilla)))
              (panMap
               ((entries ((1000000 (-45 0))))
                (defaultPan (0 0))))
              (pedals
               ((sustain
                 ((entries
                   ((0 1/1) (3000000 0/1)))))))
              (markTable
               ((entries ((2000000 ((caesura #t)))))))
              (interpretationRules ((caesura 500000)))
              (extras
               ((entries (sample (sample part)))))))))))
        """#
}

// swiftlint:enable file_length

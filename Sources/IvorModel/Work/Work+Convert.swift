// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

extension Work {

    // MARK: Public Instance Methods

    /// Returns a new work with this work’s content converted to the provided time basis and pitch
    /// notation, or `nil` if this work already has both, so there is nothing to convert.
    ///
    /// Like ``warped(appliesFermataHolds:)``, the new work has a fresh ``Work/workID``, is unlocked, and keeps this
    /// work’s ``Work/name``, ``Work/smpteStartTime``, ``Work/info``, ``Work/extras``,
    /// ``Work/interpretationRules`` and ``Work/realizations``; its parts keep their IDs, extras
    /// and interpretation rules. Part marks and ornamentation convert with the notes: a
    /// time-basis conversion converts each written length at the tempo where it starts, and a
    /// pitch-notation conversion converts grace and written partner pitches with the note’s own.
    /// With `dropsUnconvertibleNotes`, a grace figure or ornament with a pitch that can’t be
    /// converted is dropped on its own, and the note keeps the rest. A written partner that
    /// would land on or past its note’s pitch is dropped, so the partner follows its rule.
    ///
    /// Converting between pitch notations keeps the tempo map, meter table and key
    /// table. Converting beat time to wall time drops all three, and wall time to beat time starts
    /// them out empty.
    ///
    /// Fermatas and caesuras are kept as signs by default, for playback to realize. With
    /// `appliesFermataHolds`, a time-basis conversion first turns their holds and pauses into time
    /// — the tempo slowing over each hold in a beat work, as
    /// ``RenderingOptions/FermataMode/tempoChanges`` does, or time inserted in a wall work — and
    /// then removes them (see ``rendered(options:)``).
    ///
    /// Always permitted, even on a locked work: this returns an independent copy rather than
    /// mutating `self`, so ``Work/isLocked`` does not apply.
    ///
    /// - Parameter timeBasis:                  The time basis to which to convert.
    /// - Parameter pitchNotation:              The pitch notation to which to convert. Use
    ///                                         `PitchNotation.isConversionSupported(to:)` to check that
    ///                                         converting this work’s pitch notation to it is supported.
    /// - Parameter context:                    The conversion dependencies. Defaults to `.default`
    ///                                         (12-EDO, A4 = 440 Hz, Meredith pitch speller).
    /// - Parameter dropsUnconvertibleNotes:    Whether to leave out of the new work any note
    ///                                         whose start or end pitch has no counterpart in
    ///                                         `pitchNotation`, rather than throwing. Defaults to
    ///                                         `false`.
    /// - Parameter appliesFermataHolds:        Whether a time-basis conversion turns fermata holds
    ///                                         and caesura pauses into time and removes their
    ///                                         signs. Defaults to `false`.
    ///
    /// - Returns:  The converted work, or `nil` if this work already has `timeBasis` and
    ///             `pitchNotation`.
    ///
    /// - Throws:   ``Work/Error/unsupportedPitchConversion(from:to:)`` if converting this work’s
    ///             pitch notation to `pitchNotation` is not supported;
    ///             ``Work/Error/unsupportedStandardConversion`` if the context’s tuning system
    ///             does not support standard pitch notation and the conversion requires it;
    ///             ``Work/Error/invalidKeyboardLayout(_:)`` if the context’s keyboard layout can’t
    ///             be used for the conversion or is invalid in the context’s tuning system;
    ///             ``Work/Error/missingPitchSpeller`` if the conversion spells pitches and the
    ///             context has neither a pitch speller nor a pitch-class keyboard layout;
    ///             ``Work/Error/unconvertiblePitch(partID:)`` if a note’s pitch has no counterpart
    ///             in `pitchNotation` and `dropsUnconvertibleNotes` is `false`; other
    ///             ``Work/Error`` cases for other missing context dependencies.
    public func convert(timeBasis: TimeBasis,
                        pitchNotation: PitchNotation,
                        context: ConvertContext = .default,
                        dropsUnconvertibleNotes: Bool = false,
                        appliesFermataHolds: Bool = false) throws(Error) -> Work? {
        guard self.timeBasis != timeBasis
              || self.pitchNotation != pitchNotation
        else { return nil }

        guard self.pitchNotation == pitchNotation
              || self.pitchNotation.isConversionSupported(to: pitchNotation)
        else { throw Error.unsupportedPitchConversion(from: self.pitchNotation,
                                                      to: pitchNotation) }

        var newContent = content

        if appliesFermataHolds,
           newContent.timeBasis != timeBasis {
            newContent = applyingTimeline(mode: .tempoChanges).work.content
        }

        if newContent.timeBasis != timeBasis {
            newContent = Self._convertTimeBasis(of: newContent,
                                                to: timeBasis)
        }

        if newContent.pitchNotation != pitchNotation {
            do {
                newContent = try Self._convertPitchNotation(of: newContent,
                                                            to: pitchNotation,
                                                            with: context,
                                                            dropsUnconvertibleNotes: dropsUnconvertibleNotes)
            } catch let error as Error {
                throw error
            } catch let error as TuningError {
                throw Self._workError(for: error)
            } catch {
                // Unreachable: `_convertPitchNotation` only ever throws `Work.Error` or
                // `TuningError`, both handled above.
                throw Error.unsupportedStandardConversion
            }
        }

        return Work(name: name,
                    content: newContent,
                    smpteStartTime: smpteStartTime,
                    info: info,
                    extras: extras,
                    interpretationRules: interpretationRules,
                    realizations: realizations)
    }

    // MARK: Internal Type Methods

    internal static func convertBeatTimes(in dynamicMap: DynamicMap<BeatTime>,
                                          using timeConverter: TimeConverter) -> DynamicMap<WallTime> {
        let entries = dynamicMap.entries.map { entry in
            DynamicMap<WallTime>.StoredEntry(time: timeConverter.wallTime(at: entry.time),
                                             dynamic: entry.dynamic,
                                             extras: entry.extras)
        }

        return DynamicMap<WallTime>(defaultDynamic: dynamicMap.defaultDynamic,
                                    entries: entries)
    }

    internal static func convertBeatTimes(in instrumentTable: InstrumentTable<BeatTime>,
                                          using timeConverter: TimeConverter) -> InstrumentTable<WallTime> {
        let entries = instrumentTable.entries.map { entry in
            InstrumentTable<WallTime>.StoredEntry(time: timeConverter.wallTime(at: entry.time),
                                                  instrument: entry.instrument,
                                                  extras: entry.extras)
        }

        return InstrumentTable<WallTime>(defaultInstrument: instrumentTable.defaultInstrument,
                                         entries: entries)
    }

    internal static func convertBeatTimes(in panMap: PanMap<BeatTime>,
                                          using timeConverter: TimeConverter) -> PanMap<WallTime> {
        let entries = panMap.entries.map { entry in
            PanMap<WallTime>.StoredEntry(time: timeConverter.wallTime(at: entry.time),
                                         pan: entry.pan,
                                         extras: entry.extras)
        }

        return PanMap<WallTime>(defaultPan: panMap.defaultPan,
                                entries: entries)
    }

    internal static func convertBeatTimes<PitchType: PitchProtocol>(in part: Part<BeatTime, PitchType>,
                                                                    using timeConverter: TimeConverter,
                                                                    tempoMap: TempoMap) -> Part<WallTime, PitchType> {
        Part(partID: part.partID,
             name: part.name,
             strands: part.mappingStrands(noteTable: { _convertBeatTimes(in: $0, using: timeConverter, tempoMap: tempoMap) },
                                          instrumentTable: { convertBeatTimes(in: $0, using: timeConverter) },
                                          dynamicMap: { convertBeatTimes(in: $0, using: timeConverter) }),
             dynamicMap: convertBeatTimes(in: part.dynamicMap,
                                          using: timeConverter),
             instrumentTable: convertBeatTimes(in: part.instrumentTable,
                                               using: timeConverter),
             panMap: convertBeatTimes(in: part.panMap,
                                      using: timeConverter),
             pedals: part.pedals.mapValues { $0.mapTimes(timeConverter.wallTime(at:)) },
             markTable: part.markTable.convertedTimes(timeConverter.wallTime(at:)),
             interpretationRules: part.interpretationRules,
             extras: part.extras)
    }

    internal static func convertWallTimes<PitchType: PitchProtocol>(in part: Part<WallTime, PitchType>,
                                                                    using timeConverter: TimeConverter) -> Part<BeatTime, PitchType> {
        Part(partID: part.partID,
             name: part.name,
             strands: part.mappingStrands(noteTable: { _convertWallTimes(in: $0, using: timeConverter) },
                                          instrumentTable: { _convertWallTimes(in: $0, using: timeConverter) },
                                          dynamicMap: { _convertWallTimes(in: $0, using: timeConverter) }),
             dynamicMap: _convertWallTimes(in: part.dynamicMap,
                                           using: timeConverter),
             instrumentTable: _convertWallTimes(in: part.instrumentTable,
                                                using: timeConverter),
             panMap: _convertWallTimes(in: part.panMap,
                                       using: timeConverter),
             pedals: part.pedals.mapValues { $0.mapTimes(timeConverter.beatTime(at:)) },
             markTable: part.markTable.convertedTimes(timeConverter.beatTime(at:)),
             interpretationRules: part.interpretationRules,
             extras: part.extras)
    }

    // MARK: Private Type Methods

    private static func _convertBeatTimes<PitchType: PitchProtocol>(in noteTable: NoteTable<BeatTime, PitchType>,
                                                                    using timeConverter: TimeConverter,
                                                                    tempoMap: TempoMap) -> NoteTable<WallTime, PitchType> {
        typealias BeatNotes = NoteTable<BeatTime, PitchType>

        let notes = noteTable.notes.map { note in
            let wallAttack = timeConverter.wallTime(at: note.attack)
            let wallDuration = timeConverter.wallTime(at: note.release) - wallAttack

            let ornamentation = BeatNotes.retimed(note.ornamentation,
                                                  at: note.attack,
                                                  times: timeConverter.wallTime(at:)) {
                BeatNotes.measuredTremoloRate($0,
                                              at: note.attack,
                                              using: tempoMap)
            }

            return NoteTable<WallTime, PitchType>.StoredNote(attack: wallAttack,
                                                             duration: wallDuration,
                                                             startPitch: note.startPitch,
                                                             endPitch: note.endPitch,
                                                             extras: note.extras,
                                                             ornamentation: ornamentation)
        }

        return NoteTable(notes: notes)
    }

    private static func _convertPitches<TimeType: TimeProtocol,
                                        FromPitchType: PitchProtocol,
                                        ToPitchType: PitchProtocol>(in part: Part<TimeType, FromPitchType>,
                                                                    using convert: ([FromPitchType]) -> [ToPitchType?],
                                                                    dropsUnconvertibleNotes: Bool) throws -> Part<TimeType, ToPitchType> {
        let strands = try part.mappingStrands(noteTable: { noteTable throws(Error) in
            guard let converted = convertPitches(in: noteTable,
                                                 using: convert,
                                                 dropsUnconvertibleNotes: dropsUnconvertibleNotes)
            else { throw Error.unconvertiblePitch(partID: part.partID) }

            return converted
        },
                                              instrumentTable: { $0 },
                                              dynamicMap: { $0 })

        return Part(partID: part.partID,
                    name: part.name,
                    strands: strands,
                    dynamicMap: part.dynamicMap,
                    instrumentTable: part.instrumentTable,
                    panMap: part.panMap,
                    pedals: part.pedals,
                    markTable: part.markTable,
                    interpretationRules: part.interpretationRules,
                    extras: part.extras)
    }

    private static func _convertPitches<TimeType: TimeProtocol,
                                        FromPitchType: PitchProtocol,
                                        ToPitchType: PitchProtocol>(in parts: [Part<TimeType, FromPitchType>],
                                                                    using convert: ([FromPitchType]) -> [ToPitchType?],
                                                                    dropsUnconvertibleNotes: Bool) throws -> [Part<TimeType, ToPitchType>] {
        try parts.map {
            try _convertPitches(in: $0,
                                using: convert,
                                dropsUnconvertibleNotes: dropsUnconvertibleNotes)
        }
    }

    private static func _convertPitchNotation(of content: Content,
                                              to targetNotation: PitchNotation,
                                              with context: ConvertContext,
                                              dropsUnconvertibleNotes: Bool) throws -> Content {
        switch (content.cases, targetNotation) {
        case let (.absoluteBeat(parts, tempoMap, meterTable, keyTable), .keyboard):
            // Absolute/Beat → Keyboard/Beat
            try .keyboardBeat(_convertPitches(in: parts,
                                              using: _makeAbsoluteToKeyboardPitchConverter(with: context),
                                              dropsUnconvertibleNotes: dropsUnconvertibleNotes),
                              tempoMap,
                              meterTable,
                              keyTable)

        case let (.absoluteBeat(parts, tempoMap, meterTable, keyTable), .standard):
            // Absolute/Beat → Standard/Beat
            try .standardBeat(_convertPitches(in: parts,
                                              using: _makeAbsoluteToStandardPitchConverter(with: context),
                                              dropsUnconvertibleNotes: dropsUnconvertibleNotes),
                              tempoMap,
                              meterTable,
                              keyTable)

        case let (.absoluteWall(parts), .keyboard):
            // Absolute/Wall → Keyboard/Wall
            try .keyboardWall(_convertPitches(in: parts,
                                              using: _makeAbsoluteToKeyboardPitchConverter(with: context),
                                              dropsUnconvertibleNotes: dropsUnconvertibleNotes))

        case let (.absoluteWall(parts), .standard):
            // Absolute/Wall → Standard/Wall
            try .standardWall(_convertPitches(in: parts,
                                              using: _makeAbsoluteToStandardPitchConverter(with: context),
                                              dropsUnconvertibleNotes: dropsUnconvertibleNotes))

        case let (.keyboardBeat(parts, tempoMap, meterTable, keyTable), .absolute):
            // Keyboard/Beat → Absolute/Beat
            try .absoluteBeat(_convertPitches(in: parts,
                                              using: _makeKeyboardToAbsolutePitchConverter(with: context),
                                              dropsUnconvertibleNotes: dropsUnconvertibleNotes),
                              tempoMap,
                              meterTable,
                              keyTable)

        case let (.keyboardBeat(parts, tempoMap, meterTable, keyTable), .standard):
            // Keyboard/Beat → Standard/Beat
            try .standardBeat(_convertPitches(in: parts,
                                              using: _makeKeyboardToStandardPitchConverter(with: context),
                                              dropsUnconvertibleNotes: dropsUnconvertibleNotes),
                              tempoMap,
                              meterTable,
                              keyTable)

        case let (.keyboardWall(parts), .absolute):
            // Keyboard/Wall → Absolute/Wall
            try .absoluteWall(_convertPitches(in: parts,
                                              using: _makeKeyboardToAbsolutePitchConverter(with: context),
                                              dropsUnconvertibleNotes: dropsUnconvertibleNotes))

        case let (.keyboardWall(parts), .standard):
            // Keyboard/Wall → Standard/Wall
            try .standardWall(_convertPitches(in: parts,
                                              using: _makeKeyboardToStandardPitchConverter(with: context),
                                              dropsUnconvertibleNotes: dropsUnconvertibleNotes))

        case let (.standardBeat(parts, tempoMap, meterTable, keyTable), .absolute):
            // Standard/Beat → Absolute/Beat
            try .absoluteBeat(_convertPitches(in: parts,
                                              using: _makeStandardToAbsolutePitchConverter(with: context),
                                              dropsUnconvertibleNotes: dropsUnconvertibleNotes),
                              tempoMap,
                              meterTable,
                              keyTable)

        case let (.standardBeat(parts, tempoMap, meterTable, keyTable), .keyboard):
            // Standard/Beat → Keyboard/Beat
            try .keyboardBeat(_convertPitches(in: parts,
                                              using: _makeStandardToKeyboardPitchConverter(with: context),
                                              dropsUnconvertibleNotes: dropsUnconvertibleNotes),
                              tempoMap,
                              meterTable,
                              keyTable)

        case let (.standardWall(parts), .absolute):
            // Standard/Wall → Absolute/Wall
            try .absoluteWall(_convertPitches(in: parts,
                                              using: _makeStandardToAbsolutePitchConverter(with: context),
                                              dropsUnconvertibleNotes: dropsUnconvertibleNotes))

        case let (.standardWall(parts), .keyboard):
            // Standard/Wall → Keyboard/Wall
            try .keyboardWall(_convertPitches(in: parts,
                                              using: _makeStandardToKeyboardPitchConverter(with: context),
                                              dropsUnconvertibleNotes: dropsUnconvertibleNotes))

        default:
            content
        }
    }

    private static func _convertTimeBasis(of content: Content,
                                          to targetBasis: TimeBasis) -> Content {
        switch targetBasis {
        case .beat:
            unwarpedContent(content,
                            using: TempoMap()) ?? content

        case .wall:
            warpedContent(content) ?? content
        }
    }

    private static func _convertWallTimes(in dynamicMap: DynamicMap<WallTime>,
                                          using timeConverter: TimeConverter) -> DynamicMap<BeatTime> {
        let entries = dynamicMap.entries.map { entry in
            DynamicMap<BeatTime>.StoredEntry(time: timeConverter.beatTime(at: entry.time),
                                             dynamic: entry.dynamic,
                                             extras: entry.extras)
        }

        return DynamicMap<BeatTime>(defaultDynamic: dynamicMap.defaultDynamic,
                                    entries: entries)
    }

    private static func _convertWallTimes(in instrumentTable: InstrumentTable<WallTime>,
                                          using timeConverter: TimeConverter) -> InstrumentTable<BeatTime> {
        let entries = instrumentTable.entries.map { entry in
            InstrumentTable<BeatTime>.StoredEntry(time: timeConverter.beatTime(at: entry.time),
                                                  instrument: entry.instrument,
                                                  extras: entry.extras)
        }

        return InstrumentTable<BeatTime>(defaultInstrument: instrumentTable.defaultInstrument,
                                         entries: entries)
    }

    private static func _convertWallTimes<PitchType: PitchProtocol>(in noteTable: NoteTable<WallTime, PitchType>,
                                                                    using timeConverter: TimeConverter) -> NoteTable<BeatTime, PitchType> {
        typealias WallNotes = NoteTable<WallTime, PitchType>

        return NoteTable(notes: noteTable.notes.map { note in
            let beatAttack = timeConverter.beatTime(at: note.attack)
            let beatDuration = timeConverter.beatTime(at: note.release) - beatAttack

            let ornamentation = WallNotes.retimed(note.ornamentation,
                                                  at: note.attack,
                                                  times: timeConverter.beatTime(at:))

            return NoteTable<BeatTime, PitchType>.StoredNote(attack: beatAttack,
                                                             duration: beatDuration,
                                                             startPitch: note.startPitch,
                                                             endPitch: note.endPitch,
                                                             extras: note.extras,
                                                             ornamentation: ornamentation)
        })
    }

    private static func _convertWallTimes(in panMap: PanMap<WallTime>,
                                          using timeConverter: TimeConverter) -> PanMap<BeatTime> {
        let entries = panMap.entries.map { entry in
            PanMap<BeatTime>.StoredEntry(time: timeConverter.beatTime(at: entry.time),
                                         pan: entry.pan,
                                         extras: entry.extras)
        }

        return PanMap<BeatTime>(defaultPan: panMap.defaultPan,
                                entries: entries)
    }

    private static func _isRaw(_ keyboardLayout: KeyboardLayout) -> Bool {
        switch keyboardLayout.definition {
        case .degrees,
             .pitchClasses:
            false

        case .frequencies,
             .ratios:
            true
        }
    }

    private static func _keyboardLayout(of context: ConvertContext) throws -> KeyboardLayout {
        guard let keyboardLayout = context.keyboardLayout
        else { throw Error.missingKeyboardLayout }

        return keyboardLayout
    }

    private static func _makeAbsoluteToKeyboardPitchConverter(with context: ConvertContext) throws -> ([Frequency]) -> [NoteNumber?] {
        let keyboardLayout = try _keyboardLayout(of: context)

        let pitchConverter = if _isRaw(keyboardLayout) {
            try AbsoluteToKeyboardPitchConverter(keyboardLayout: keyboardLayout,
                                                 keyMatching: context.keyMatching)
        } else {
            try AbsoluteToKeyboardPitchConverter(keyboardLayout: keyboardLayout,
                                                 tuningSystem: _tuningSystem(of: context),
                                                 pitchStandard: _pitchStandard(of: context),
                                                 keyMatching: context.keyMatching)
        }

        return { pitchConverter.convert($0) }
    }

    private static func _makeAbsoluteToStandardPitchConverter(with context: ConvertContext) throws -> ([Frequency]) -> [Pitch?] {
        let keyboardLayout = try _keyboardLayout(of: context)

        guard let pitchSpeller = context.pitchSpeller
        else {
            // Without a speller, a pitch-class layout spells each key itself.
            guard case .pitchClasses = keyboardLayout.definition
            else { throw Error.missingPitchSpeller }

            let pitchConverter = try AbsoluteToStandardPitchConverter(keyboardLayout: keyboardLayout,
                                                                      tuningSystem: _tuningSystem(of: context),
                                                                      pitchStandard: _pitchStandard(of: context),
                                                                      keyMatching: context.keyMatching)

            return { pitchConverter.convert($0) }
        }

        func makePitchConverter(_ pitchSpeller: some PitchSpeller) throws -> ([Frequency]) -> [Pitch?] {
            let pitchConverter = if _isRaw(keyboardLayout) {
                try AbsoluteToStandardPitchConverter(keyboardLayout: keyboardLayout,
                                                     pitchSpeller: pitchSpeller,
                                                     keyMatching: context.keyMatching)
            } else {
                try AbsoluteToStandardPitchConverter(keyboardLayout: keyboardLayout,
                                                     tuningSystem: _tuningSystem(of: context),
                                                     pitchStandard: _pitchStandard(of: context),
                                                     pitchSpeller: pitchSpeller,
                                                     keyMatching: context.keyMatching)
            }

            return { pitchConverter.convert($0) }
        }

        return try makePitchConverter(pitchSpeller)
    }

    private static func _makeKeyboardToAbsolutePitchConverter(with context: ConvertContext) throws -> ([NoteNumber]) -> [Frequency?] {
        let keyboardLayout = try _keyboardLayout(of: context)

        let pitchConverter = if _isRaw(keyboardLayout) {
            try KeyboardToAbsolutePitchConverter(keyboardLayout: keyboardLayout)
        } else {
            try KeyboardToAbsolutePitchConverter(keyboardLayout: keyboardLayout,
                                                 tuningSystem: _tuningSystem(of: context),
                                                 pitchStandard: _pitchStandard(of: context))
        }

        return { pitchConverter.convert($0) }
    }

    private static func _makeKeyboardToStandardPitchConverter(with context: ConvertContext) throws -> ([NoteNumber]) -> [Pitch?] {
        let keyboardLayout = try _keyboardLayout(of: context)

        guard let pitchSpeller = context.pitchSpeller
        else {
            // Without a speller, a pitch-class layout spells each key itself.
            guard case .pitchClasses = keyboardLayout.definition
            else { throw Error.missingPitchSpeller }

            let pitchConverter = try KeyboardToStandardPitchConverter(keyboardLayout: keyboardLayout,
                                                                      tuningSystem: _tuningSystem(of: context))

            return { pitchConverter.convert($0) }
        }

        func makePitchConverter(_ pitchSpeller: some PitchSpeller) throws -> ([NoteNumber]) -> [Pitch?] {
            let pitchConverter = try KeyboardToStandardPitchConverter(keyboardLayout: keyboardLayout,
                                                                      pitchSpeller: pitchSpeller)

            return { pitchConverter.convert($0) }
        }

        return try makePitchConverter(pitchSpeller)
    }

    private static func _makeStandardToAbsolutePitchConverter(with context: ConvertContext) throws -> ([Pitch]) -> [Frequency?] {
        let pitchConverter = try StandardToAbsolutePitchConverter(tuningSystem: _tuningSystem(of: context),
                                                                  pitchStandard: _pitchStandard(of: context))

        return { pitchConverter.convert($0) }
    }

    private static func _makeStandardToKeyboardPitchConverter(with context: ConvertContext) throws -> ([Pitch]) -> [NoteNumber?] {
        let tuningSystem = try _tuningSystem(of: context)
        let pitchStandard = try _pitchStandard(of: context)
        let keyboardLayout = try _keyboardLayout(of: context)

        let pitchConverter = try StandardToKeyboardPitchConverter(keyboardLayout: keyboardLayout,
                                                                  tuningSystem: tuningSystem,
                                                                  pitchStandard: pitchStandard,
                                                                  keyMatching: context.keyMatching)

        return { pitchConverter.convert($0) }
    }

    private static func _pitchStandard(of context: ConvertContext) throws -> PitchStandard {
        guard let pitchStandard = context.pitchStandard
        else { throw Error.missingPitchStandard }

        return pitchStandard
    }

    private static func _tuningSystem(of context: ConvertContext) throws -> any TuningSystem {
        guard let tuningSystem = context.tuningSystem
        else { throw Error.missingTuningSystem }

        return tuningSystem
    }

    private static func _workError(for error: TuningError) -> Error {
        switch error {
        case let .invalidKeyboardLayout(problem):
            .invalidKeyboardLayout(problem)

        case .unsupportedStandardConversion:
            .unsupportedStandardConversion
        }
    }
}

// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

// MARK: - Public API

extension Work {

    // MARK: Public Instance Methods

    /// Converts this work to the provided time basis and pitch notation.
    ///
    /// - Parameter timeBasis:      The time basis to which to convert.
    /// - Parameter pitchNotation:  The pitch notation to which to convert.
    /// - Parameter context:        The conversion dependencies. Defaults to `.default`
    ///                             (12-EDO, A4 = 440 Hz, Meredith pitch speller).
    ///
    /// - Throws:   `TuningError.unsupportedStandardConversion` if the context's tuning system
    ///             does not support standard pitch notation and the conversion requires it.
    public func convert(timeBasis: TimeBasis,
                        pitchNotation: PitchNotation,
                        context: ConvertContext = .default) throws -> Work {
        guard self.timeBasis != timeBasis
              || self.pitchNotation != pitchNotation
        else { return self }

        var result = Work(name: name)

        if result.content.timeBasis != timeBasis {
            result.content = Self._convertTimeBasis(of: result.content,
                                                    to: timeBasis)
        }

        if result.content.pitchNotation != pitchNotation {
            result.content = try Self._convertPitchNotation(of: result.content,
                                                            to: pitchNotation,
                                                            with: context)
        }

        return result
    }

    // MARK: Private Type Methods

    private static func _convertBeatTimes(in dynamicMap: DynamicMap<BeatTime>,
                                          using timeConverter: TimeConverter) -> DynamicMap<WallTime> {
        DynamicMap<WallTime>(defaultDynamic: dynamicMap.defaultDynamic,
                             entries: dynamicMap.entries.map { entry in
            DynamicMap<WallTime>.Entry(time: timeConverter.wallTime(at: entry.time),
                                       dynamic: entry.dynamic,
                                       extras: entry.extras)
        })
    }

    private static func _convertBeatTimes(in instrumentMap: InstrumentMap<BeatTime>,
                                          using timeConverter: TimeConverter) -> InstrumentMap<WallTime> {
        InstrumentMap<WallTime>(defaultInstrument: instrumentMap.defaultInstrument,
                                entries: instrumentMap.entries.map { entry in
            InstrumentMap<WallTime>.Entry(time: timeConverter.wallTime(at: entry.time),
                                          instrument: entry.instrument,
                                          extras: entry.extras)
        })
    }

    private static func _convertBeatTimes<PitchType: PitchProtocol>(in noteTable: NoteTable<BeatTime, PitchType>,
                                                                    using timeConverter: TimeConverter) -> NoteTable<WallTime, PitchType> {
        NoteTable(notes: noteTable.notes.map { note in
            let wallAttack = timeConverter.wallTime(at: note.attack)
            let wallDuration = timeConverter.wallTime(at: note.release) - wallAttack

            return NoteTable<WallTime, PitchType>.Note(attack: wallAttack,
                                                       duration: wallDuration,
                                                       startPitch: note.startPitch,
                                                       endPitch: note.endPitch,
                                                       extras: note.extras)
        })
    }

    private static func _convertBeatTimes(in panMap: PanMap<BeatTime>,
                                          using timeConverter: TimeConverter) -> PanMap<WallTime> {
        PanMap<WallTime>(defaultPan: panMap.defaultPan,
                         entries: panMap.entries.map { entry in
            PanMap<WallTime>.Entry(time: timeConverter.wallTime(at: entry.time),
                                   pan: entry.pan,
                                   extras: entry.extras)
        })
    }

    private static func _convertBeatTimes<PitchType: PitchProtocol>(in part: Part<BeatTime, PitchType>,
                                                                    using timeConverter: TimeConverter) -> Part<WallTime, PitchType> {
        Part(name: part.name,
             noteTable: _convertBeatTimes(in: part.noteTable,
                                          using: timeConverter),
             dynamicMap: _convertBeatTimes(in: part.dynamicMap,
                                           using: timeConverter),
             instrumentMap: _convertBeatTimes(in: part.instrumentMap,
                                              using: timeConverter),
             panMap: _convertBeatTimes(in: part.panMap,
                                       using: timeConverter))
    }

    private static func _convertPitches<TimeType: TimeProtocol,
                                        FromPitchType: PitchProtocol,
                                        ToPitchType: PitchProtocol>(in noteTable: NoteTable<TimeType, FromPitchType>,
                                                                    using convert: (FromPitchType) -> ToPitchType) -> NoteTable<TimeType,
                                                                                                                                ToPitchType> {
        NoteTable(notes: noteTable.notes.map { note in
            NoteTable<TimeType, ToPitchType>.Note(attack: note.attack,
                                                  duration: note.duration,
                                                  startPitch: convert(note.startPitch),
                                                  endPitch: convert(note.endPitch),
                                                  extras: note.extras)
        })
    }

    private static func _convertPitches<TimeType: TimeProtocol,
                                        FromPitchType: PitchProtocol,
                                        ToPitchType: PitchProtocol>(in part: Part<TimeType, FromPitchType>,
                                                                    using convert: (FromPitchType) -> ToPitchType) -> Part<TimeType,
                                                                                                                           ToPitchType> {
        Part(name: part.name,
             noteTable: _convertPitches(in: part.noteTable,
                                        using: convert),
             dynamicMap: part.dynamicMap,
             instrumentMap: part.instrumentMap,
             panMap: part.panMap)
    }

    private static func _convertPitchNotation(of content: Content,
                                              to targetNotation: PitchNotation,
                                              with context: ConvertContext) throws -> Content {
        switch (content, targetNotation) {
        case let (.absoluteBeat(parts, tempoMap), .keyboard):
            // Absolute/Beat → Keyboard/Beat
            let pitchConverter = try _makeAbsoluteToKeyboardPitchConverter(with: context)

            let convertedParts = parts.map {
                _convertPitches(in: $0,
                                using: pitchConverter)
            }

            return .keyboardBeat(convertedParts,
                                 tempoMap)

        case let (.absoluteBeat(parts, tempoMap), .standard):
            // Absolute/Beat → Standard/Beat
            let pitchConverter = try _makeAbsoluteToStandardPitchConverter(with: context)

            let convertedParts = parts.map {
                _convertPitches(in: $0,
                                using: pitchConverter)
            }

            return .standardBeat(convertedParts,
                                 tempoMap)

        case let (.absoluteWall(parts), .keyboard):
            // Absolute/Wall → Keyboard/Wall
            let pitchConverter = try _makeAbsoluteToKeyboardPitchConverter(with: context)

            let convertedParts = parts.map {
                _convertPitches(in: $0,
                                using: pitchConverter)
            }

            return .keyboardWall(convertedParts)

        case let (.absoluteWall(parts), .standard):
            // Absolute/Wall → Standard/Wall
            let pitchConverter = try _makeAbsoluteToStandardPitchConverter(with: context)

            let convertedParts = parts.map {
                _convertPitches(in: $0,
                                using: pitchConverter)
            }

            return .standardWall(convertedParts)

        case let (.keyboardBeat(parts, tempoMap), .absolute):
            // Keyboard/Beat → Absolute/Beat
            let pitchConverter = try _makeKeyboardToAbsolutePitchConverter(with: context)

            let convertedParts = parts.map {
                _convertPitches(in: $0,
                                using: pitchConverter)
            }

            return .absoluteBeat(convertedParts,
                                 tempoMap)

        case let (.keyboardBeat(parts, tempoMap), .standard):
            // Keyboard/Beat → Standard/Beat
            let pitchConverter = try _makeKeyboardToStandardPitchConverter(with: context)

            let convertedParts = parts.map {
                _convertPitches(in: $0,
                                using: pitchConverter)
            }

            return .standardBeat(convertedParts,
                                 tempoMap)

        case let (.keyboardWall(parts), .absolute):
            // Keyboard/Wall → Absolute/Wall
            let pitchConverter = try _makeKeyboardToAbsolutePitchConverter(with: context)

            let convertedParts = parts.map {
                _convertPitches(in: $0,
                                using: pitchConverter)
            }

            return .absoluteWall(convertedParts)

        case let (.keyboardWall(parts), .standard):
            // Keyboard/Wall → Standard/Wall
            let pitchConverter = try _makeKeyboardToStandardPitchConverter(with: context)

            let convertedParts = parts.map {
                _convertPitches(in: $0,
                                using: pitchConverter)
            }

            return .standardWall(convertedParts)

        case let (.standardBeat(parts, tempoMap), .absolute):
            // Standard/Beat → Absolute/Beat
            let pitchConverter = try _makeStandardToAbsolutePitchConverter(with: context)

            let convertedParts = parts.map {
                _convertPitches(in: $0,
                                using: pitchConverter)
            }

            return .absoluteBeat(convertedParts,
                                 tempoMap)

        case let (.standardBeat(parts, tempoMap), .keyboard):
            // Standard/Beat → Keyboard/Beat
            let pitchConverter = try _makeStandardToKeyboardPitchConverter(with: context)

            let convertedParts = parts.map {
                _convertPitches(in: $0,
                                using: pitchConverter)
            }

            return .keyboardBeat(convertedParts,
                                 tempoMap)

        case let (.standardWall(parts), .absolute):
            // Standard/Wall → Absolute/Wall
            let pitchConverter = try _makeStandardToAbsolutePitchConverter(with: context)

            let convertedParts = parts.map {
                _convertPitches(in: $0,
                                using: pitchConverter)
            }

            return .absoluteWall(convertedParts)

        case let (.standardWall(parts), .keyboard):
            // Standard/Wall → Keyboard/Wall
            let pitchConverter = try _makeStandardToKeyboardPitchConverter(with: context)

            let convertedParts = parts.map {
                _convertPitches(in: $0,
                                using: pitchConverter)
            }

            return .keyboardWall(convertedParts)

        default:
            return content
        }
    }

    private static func _convertTimeBasis(of content: Content,
                                          to targetBasis: TimeBasis) -> Content {
        switch (content, targetBasis) {
        case let (.absoluteBeat(parts, tempoMap), .wall):
            let timeConverter = TimeConverter(tempoMap)

            let convertedParts = parts.map {
                _convertBeatTimes(in: $0,
                                  using: timeConverter)
            }

            return .absoluteWall(convertedParts)

        case let (.absoluteWall(parts), .beat):
            let tempoMap = TempoMap()
            let timeConverter = TimeConverter(tempoMap)

            let convertedParts = parts.map {
                _convertWallTimes(in: $0,
                                  using: timeConverter)
            }

            return .absoluteBeat(convertedParts,
                                 tempoMap)

        case let (.keyboardBeat(parts, tempoMap), .wall):
            let timeConverter = TimeConverter(tempoMap)

            let convertedParts = parts.map {
                _convertBeatTimes(in: $0,
                                  using: timeConverter)
            }

            return .keyboardWall(convertedParts)

        case let (.keyboardWall(parts), .beat):
            let tempoMap = TempoMap()
            let timeConverter = TimeConverter(tempoMap)

            let convertedParts = parts.map {
                _convertWallTimes(in: $0,
                                  using: timeConverter)
            }

            return .keyboardBeat(convertedParts,
                                 tempoMap)

        case let (.standardBeat(parts, tempoMap), .wall):
            let timeConverter = TimeConverter(tempoMap)

            let convertedParts = parts.map {
                _convertBeatTimes(in: $0,
                                  using: timeConverter)
            }

            return .standardWall(convertedParts)

        case let (.standardWall(parts), .beat):
            let tempoMap = TempoMap()
            let timeConverter = TimeConverter(tempoMap)

            let convertedParts = parts.map {
                _convertWallTimes(in: $0,
                                  using: timeConverter)
            }

            return .standardBeat(convertedParts,
                                 tempoMap)

        default:
            return content
        }
    }

    private static func _convertWallTimes(in dynamicMap: DynamicMap<WallTime>,
                                          using timeConverter: TimeConverter) -> DynamicMap<BeatTime> {
        DynamicMap<BeatTime>(defaultDynamic: dynamicMap.defaultDynamic,
                             entries: dynamicMap.entries.map { entry in
            DynamicMap<BeatTime>.Entry(time: timeConverter.beatTime(at: entry.time),
                                       dynamic: entry.dynamic,
                                       extras: entry.extras)
        })
    }

    private static func _convertWallTimes(in instrumentMap: InstrumentMap<WallTime>,
                                          using timeConverter: TimeConverter) -> InstrumentMap<BeatTime> {
        InstrumentMap<BeatTime>(defaultInstrument: instrumentMap.defaultInstrument,
                                entries: instrumentMap.entries.map { entry in
            InstrumentMap<BeatTime>.Entry(time: timeConverter.beatTime(at: entry.time),
                                          instrument: entry.instrument,
                                          extras: entry.extras)
        })
    }

    private static func _convertWallTimes<PitchType: PitchProtocol>(in noteTable: NoteTable<WallTime, PitchType>,
                                                                    using timeConverter: TimeConverter) -> NoteTable<BeatTime, PitchType> {
        NoteTable(notes: noteTable.notes.map { note in
            let beatAttack = timeConverter.beatTime(at: note.attack)
            let beatDuration = timeConverter.beatTime(at: note.release) - beatAttack

            return NoteTable<BeatTime, PitchType>.Note(attack: beatAttack,
                                                       duration: beatDuration,
                                                       startPitch: note.startPitch,
                                                       endPitch: note.endPitch,
                                                       extras: note.extras)
        })
    }

    private static func _convertWallTimes(in panMap: PanMap<WallTime>,
                                          using timeConverter: TimeConverter) -> PanMap<BeatTime> {
        PanMap<BeatTime>(defaultPan: panMap.defaultPan,
                         entries: panMap.entries.map { entry in
            PanMap<BeatTime>.Entry(time: timeConverter.beatTime(at: entry.time),
                                   pan: entry.pan,
                                   extras: entry.extras)
        })
    }

    private static func _convertWallTimes<PitchType: PitchProtocol>(in part: Part<WallTime, PitchType>,
                                                                    using timeConverter: TimeConverter) -> Part<BeatTime, PitchType> {
        Part(name: part.name,
             noteTable: _convertWallTimes(in: part.noteTable,
                                          using: timeConverter),
             dynamicMap: _convertWallTimes(in: part.dynamicMap,
                                           using: timeConverter),
             instrumentMap: _convertWallTimes(in: part.instrumentMap,
                                              using: timeConverter),
             panMap: _convertWallTimes(in: part.panMap,
                                       using: timeConverter))
    }

    private static func _makeAbsoluteToKeyboardPitchConverter(with context: ConvertContext) throws -> (Frequency) -> NoteNumber {
        guard let keyboardMap = context.keyboardMap
        else { throw Error.missingKeyboardMap }

        let pitchConverter = AbsoluteToKeyboardPitchConverter(keyboardMap: keyboardMap)

        return { pitchConverter.convert($0) }
    }

    private static func _makeAbsoluteToStandardPitchConverter(with context: ConvertContext) throws -> (Frequency) -> Pitch {
        guard let keyboardMap = context.keyboardMap
        else { throw Error.missingKeyboardMap }

        guard let pitchSpeller = context.pitchSpeller
        else { throw Error.missingPitchSpeller }

        func makePitchConverter(_ pitchSpeller: some PitchSpeller) -> (Frequency) -> Pitch {
            let pitchConverter = AbsoluteToStandardPitchConverter(keyboardMap: keyboardMap,
                                                                  pitchSpeller: pitchSpeller)

            return { pitchConverter.convert($0) }
        }

        return makePitchConverter(pitchSpeller)
    }

    private static func _makeKeyboardToAbsolutePitchConverter(with context: ConvertContext) throws -> (NoteNumber) -> Frequency {
        guard let keyboardMap = context.keyboardMap
        else { throw Error.missingKeyboardMap }

        let pitchConverter = KeyboardToAbsolutePitchConverter(keyboardMap: keyboardMap)

        return { pitchConverter.convert($0) }
    }

    private static func _makeKeyboardToStandardPitchConverter(with context: ConvertContext) throws -> (NoteNumber) -> Pitch {
        guard let pitchSpeller = context.pitchSpeller
        else { throw Error.missingPitchSpeller }

        func makePitchConverter(_ pitchSpeller: some PitchSpeller) -> (NoteNumber) -> Pitch {
            let pitchConverter = KeyboardToStandardPitchConverter(pitchSpeller: pitchSpeller)

            return { pitchConverter.convert($0) }
        }

        return makePitchConverter(pitchSpeller)
    }

    private static func _makeStandardToAbsolutePitchConverter(with context: ConvertContext) throws -> (Pitch) -> Frequency {
        guard let tuningSystem = context.tuningSystem
        else { throw Error.missingTuningSystem }

        guard let pitchStandard = context.pitchStandard
        else { throw Error.missingPitchStandard }

        let pitchConverter = try StandardToAbsolutePitchConverter(tuningSystem: tuningSystem,
                                                                  pitchStandard: pitchStandard)

        return { pitchConverter.convert($0) }
    }

    private static func _makeStandardToKeyboardPitchConverter(with context: ConvertContext) throws -> (Pitch) -> NoteNumber {
        guard let tuningSystem = context.tuningSystem
        else { throw Error.missingTuningSystem }

        guard let pitchStandard = context.pitchStandard
        else { throw Error.missingPitchStandard }

        guard let keyboardMap = context.keyboardMap
        else { throw Error.missingKeyboardMap }

        func makePitchConverter(_ tuningSystem: some TuningSystem) -> (Pitch) -> NoteNumber {
            let pitchConverter = StandardToKeyboardPitchConverter(keyboardMap: keyboardMap,
                                                                  tuningSystem: tuningSystem,
                                                                  pitchStandard: pitchStandard)

            return { pitchConverter.convert($0) }
        }

        return makePitchConverter(tuningSystem)
    }
}

public import IvorTiming

private import XestiNumbers

extension NoteTable {

    // MARK: Public Nested Types

    public typealias NoteTableBT = NoteTable<BeatTime, PitchType>
    public typealias NoteTableWT = NoteTable<WallTime, PitchType>

    // MARK: Public Instance Methods

    public func extractNoteEvents() throws -> [NoteEvent<TimeType, PitchType>] {
        var extractor = Extractor(self)

        return extractor.extractNoteEvents()
    }

    // MARK: Internal Nested Types

    internal typealias NoteBT = NoteTableBT.Note
    internal typealias NoteWT = NoteTableWT.Note
}

// MARK: -

extension NoteTable where TimeType == BeatTime {

    // MARK: Public Instance Methods

    public mutating func quantize(to factors: [Int]) throws {
        try Self._checkQuantizationFactors(factors)

        guard !notes.isEmpty
        else { return }

        for (idx, note) in notes.enumerated() {
            let qatt = Self._quantize(beatTime: note.attack,
                                      to: factors)
            let qrel = Self._quantize(beatTime: note.release,
                                      to: factors)

            notes[idx] = Note(attack: qatt,
                              duration: qrel - qatt,
                              startPitch: note.startPitch,
                              endPitch: note.endPitch,
                              extras: note.extras)
        }

        notes.sort()
    }

    public func quantized(to factors: [Int]) throws -> Self {
        var new = self

        try new.quantize(to: factors)

        return new
    }

    // MARK: Private Type Methods

    private static func _checkQuantizationFactors(_ factors: [Int]) throws {
        for factor in factors {
            guard factor > 0
            else { throw Error.invalidQuantizationFactor(factor) }
        }
    }

    private static func _quantize(beatTime: BeatTime,
                                  to factors: [Int]) -> BeatTime {  // NEEDS WORK!!!
//        var rvalue = round(value)
//        var epsilon = abs(value - rvalue)
//
//        for factor in factors {
//            let rfactor = Number(factor)
//            let newRvalue = round(value * rfactor) / rfactor
//            let newEpsilon = abs(value - newRvalue)
//
//            if newEpsilon < epsilon {
//                rvalue = newRvalue
//                epsilon = newEpsilon
//            }
//        }
//
//        return rvalue

        beatTime
    }
}

// MARK: -

extension NoteTable where TimeType == WallTime {

    // MARK: Public Instance Methods

    public func unwarped(using tempoMap: TempoMap) throws -> NoteTableBT {
        var btNotes: [NoteBT] = []

        if !notes.isEmpty {
            for note in notes {
                let batt = tempoMap.beatTime(at: note.attack)
                let brel = tempoMap.beatTime(at: note.release)

                btNotes.append(NoteBT(attack: batt,
                                      duration: brel - batt,
                                      startPitch: note.startPitch,
                                      endPitch: note.endPitch,
                                      extras: note.extras))
            }
        }

        return NoteTableBT(notes: btNotes)
    }
}

extension NoteTable where TimeType == BeatTime {

    // MARK: Public Instance Methods

    public func varispeeded(using tempoMap: TempoMap,
                            normalTempo: Tempo = .default) throws -> NoteTableWT {
        var wtNotes: [NoteWT] = []

        if !notes.isEmpty {
            for note in notes {
                let watt = tempoMap.wallTime(at: note.attack)
                let wrel = tempoMap.wallTime(at: note.release)
                let vspit = Self._varispeed(of: note.startPitch,
                                            at: note.attack,
                                            using: tempoMap,
                                            normalTempo: normalTempo)
                let vepit = Self._varispeed(of: note.endPitch,
                                            at: note.release,
                                            using: tempoMap,
                                            normalTempo: normalTempo)

                wtNotes.append(NoteWT(attack: watt,
                                      duration: wrel - watt,
                                      startPitch: vspit,
                                      endPitch: vepit,
                                      extras: note.extras))
            }
        }

        return NoteTableWT(notes: wtNotes)
    }

    public func warped(using tempoMap: TempoMap) throws -> NoteTableWT {
        var wtNotes: [NoteWT] = []

        if !notes.isEmpty {
            for note in notes {
                let watt = tempoMap.wallTime(at: note.attack)
                let wrel = tempoMap.wallTime(at: note.release)

                wtNotes.append(NoteWT(attack: watt,
                                      duration: wrel - watt,
                                      startPitch: note.startPitch,
                                      endPitch: note.endPitch,
                                      extras: note.extras))
            }
        }

        return NoteTableWT(notes: wtNotes)
    }

    // MARK: Private Type Methods

    private static func _varispeed(of pitch: PitchType,
                                   at beatTime: BeatTime,
                                   using tempoMap: TempoMap,
                                   normalTempo: Tempo) -> PitchType {   // NEEDS WORK???
        _varispeed(of: pitch,
                   by: tempoMap[beatTime].numberValue / normalTempo.numberValue)    // should match curve of time converter ???
    }

    private static func _varispeed(of pitch: PitchType,
                                   by factor: Number) -> PitchType {    // NEEDS WORK!!!
        pitch // + (12 * log2(factor))
    }
}

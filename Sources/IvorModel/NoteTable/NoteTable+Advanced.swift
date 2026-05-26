// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

private import XestiNumbers

extension NoteTable {

    // MARK: Public Instance Methods

    /// Returns the notes in the table as an array of note events.
    ///
    /// - Returns:  An array of ``NoteEvent`` values extracted from the table.
    ///
    /// - Throws:   An error if note events cannot be extracted.
    public func extractNoteEvents() throws -> [NoteEvent<TimeType, PitchType>] {
        var extractor = Extractor(self)

        return extractor.extractNoteEvents()
    }
}

// MARK: -

extension NoteTable where TimeType == BeatTime {

    // MARK: Public Instance Methods

    /// Quantizes all note attack and release times to the nearest subdivision
    /// given by the provided factors.
    ///
    /// - Parameter factors:    An array of positive integer subdivision
    ///                         factors.
    ///
    /// - Throws:   ``BeatQuantizer/Error/emptyFactors`` if `factors` is empty,
    ///             or ``BeatQuantizer/Error/invalidFactor(_:)`` if any factor
    ///             is not positive.
    public mutating func quantize(to factors: [Int]) throws {
        let bq = try BeatQuantizer(factors: factors)

        guard !notes.isEmpty
        else { return }

        for (idx, note) in notes.enumerated() {
            let quantizedAttack = bq.quantize(note.attack)
            let quantizedRelease = bq.quantize(note.release)

            notes[idx] = Note(attack: quantizedAttack,
                              duration: quantizedRelease - quantizedAttack,
                              startPitch: note.startPitch,
                              endPitch: note.endPitch,
                              extras: note.extras)
        }

        notes.sort()
    }

    /// Returns a copy of the table with all note times quantized to the nearest
    /// subdivision.
    ///
    /// - Parameter factors:    An array of positive integer subdivision
    ///                         factors.
    ///
    /// - Returns:  A new ``NoteTable`` with quantized note times.
    ///
    /// - Throws:   ``BeatQuantizer/Error/emptyFactors`` if `factors` is empty,
    ///             or ``BeatQuantizer/Error/invalidFactor(_:)`` if any factor
    ///             is not positive.
    public func quantized(to factors: [Int]) throws -> Self {
        var new = self

        try new.quantize(to: factors)

        return new
    }
}

// MARK: -

extension NoteTable where TimeType == WallTime {

    // MARK: Public Instance Methods

    /// Returns a new beat-time note table by converting wall-time note attack
    /// and release times using a tempo map.
    ///
    /// - Parameter tempoMap:   The tempo map used to convert wall times to beat
    ///                         times.
    ///
    /// - Returns:  A new ``NoteTable`` keyed by ``BeatTime``.
    ///
    /// - Throws:   An error if wall times cannot be converted.
    public func unwarped(using tempoMap: TempoMap) throws -> NoteTable<BeatTime, PitchType> {
        var btNotes: [NoteTable<BeatTime, PitchType>.Note] = []

        if !notes.isEmpty {
            let tc = TimeConverter(tempoMap)

            for note in notes {
                let beatAttack = tc.beatTime(at: note.attack)
                let beatRelease = tc.beatTime(at: note.release)

                btNotes.append(.init(attack: beatAttack,
                                     duration: beatRelease - beatAttack,
                                     startPitch: note.startPitch,
                                     endPitch: note.endPitch,
                                     extras: note.extras))
            }
        }

        return NoteTable<BeatTime, PitchType>(notes: btNotes)
    }
}

extension NoteTable where TimeType == BeatTime {

    // MARK: Public Instance Methods

    /// Returns a new wall-time note table by converting beat-time note timings
    /// and applying varispeed pitch shifting.
    ///
    /// - Parameter tempoMap:       The tempo map used to convert beat times to
    ///                             wall times.
    /// - Parameter normalTempo:    The reference tempo used for pitch shifting.
    ///                             Defaults to `.default`.
    ///
    /// - Returns:  A new ``NoteTable`` keyed by ``WallTime`` with
    ///             varispeed-adjusted pitches.
    ///
    /// - Throws:   An error if beat times cannot be converted.
    public func varispeeded(using tempoMap: TempoMap,
                            normalTempo: Tempo = .default) throws -> NoteTable<WallTime, PitchType> {
        var wtNotes: [NoteTable<WallTime, PitchType>.Note] = []

        if !notes.isEmpty {
            let tc = TimeConverter(tempoMap)

            for note in notes {
                let wallAttack = tc.wallTime(at: note.attack)
                let wallRelease = tc.wallTime(at: note.release)
                let varispeedStartPitch = Self._varispeed(of: note.startPitch,
                                                          at: note.attack,
                                                          using: tempoMap,
                                                          normalTempo: normalTempo)
                let varispeedEndPitch = Self._varispeed(of: note.endPitch,
                                                        at: note.release,
                                                        using: tempoMap,
                                                        normalTempo: normalTempo)

                wtNotes.append(.init(attack: wallAttack,
                                     duration: wallRelease - wallAttack,
                                     startPitch: varispeedStartPitch,
                                     endPitch: varispeedEndPitch,
                                     extras: note.extras))
            }
        }

        return NoteTable<WallTime, PitchType>(notes: wtNotes)
    }

    /// Returns a new wall-time note table by converting beat-time note attack
    /// and release times using a tempo map.
    ///
    /// - Parameter tempoMap:   The tempo map used to convert beat times to wall
    ///                         times.
    ///
    /// - Returns:  A new ``NoteTable`` keyed by ``WallTime``.
    ///
    /// - Throws:   An error if beat times cannot be converted.
    public func warped(using tempoMap: TempoMap) throws -> NoteTable<WallTime, PitchType> {
        var wtNotes: [NoteTable<WallTime, PitchType>.Note] = []

        if !notes.isEmpty {
            let tc = TimeConverter(tempoMap)

            for note in notes {
                let wallAttack = tc.wallTime(at: note.attack)
                let wallRelease = tc.wallTime(at: note.release)

                wtNotes.append(.init(attack: wallAttack,
                                     duration: wallRelease - wallAttack,
                                     startPitch: note.startPitch,
                                     endPitch: note.endPitch,
                                     extras: note.extras))
            }
        }

        return NoteTable<WallTime, PitchType>(notes: wtNotes)
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

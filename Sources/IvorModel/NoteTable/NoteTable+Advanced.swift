// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

private import XestiNumbers

extension NoteTable {

    // MARK: Public Instance Methods

    /// Returns the notes in the table as an array of note events.
    ///
    /// - Returns:  An array of ``NoteEvent`` values extracted from the table.
    public func extractNoteEvents() -> [NoteEvent<TimeType, PitchType>] {
        var extractor = Extractor(noteTable: self)

        return extractor.extractNoteEvents()
    }
}

// MARK: -

extension NoteTable where TimeType == BeatTime {

    // MARK: Public Instance Methods

    /// Quantizes note attack and release times to the nearest grid point defined by `quantizer`.
    ///
    /// - Parameter quantizer:   The quantizer whose grid to snap attack/release times to.
    /// - Parameter noteIDs:     The identities of the notes to quantize, or `nil` to quantize
    ///                          every note in the table.
    public mutating func quantize(using quantizer: BeatQuantizer,
                                  noteIDs: Set<NoteID>? = nil) {
        guard !notes.isEmpty
        else { return }

        for (idx, note) in notes.enumerated() {
            guard noteIDs?.contains(note.noteID) ?? true
            else { continue }

            let quantizedAttack = quantizer.quantize(note.attack)
            let quantizedRelease = quantizer.quantize(note.release)
            let rawDuration = quantizedRelease - quantizedAttack
            let newDuration = rawDuration.isZero ? quantizer.gridUnit : rawDuration

            notes[idx] = Note(noteID: note.noteID,
                              attack: quantizedAttack,
                              duration: newDuration,
                              startPitch: note.startPitch,
                              endPitch: note.endPitch,
                              extras: note.extras)
        }

        notes.sort()

        timeRange = Self.timeRange(in: notes)
    }

    /// Quantizes note attack and release times to the nearest subdivision given by `factors`.
    ///
    /// - Parameter factors:    An array of positive integer subdivision factors.
    /// - Parameter noteIDs:    The identities of the notes to quantize, or `nil` to quantize
    ///                         every note in the table.
    ///
    /// - Throws:   ``NoteTable/Error/emptyQuantizationFactors`` if `factors` is empty, or
    ///             ``NoteTable/Error/invalidQuantizationFactor(_:)`` if any factor is not
    ///             positive.
    public mutating func quantize(to factors: [Int],
                                  noteIDs: Set<NoteID>? = nil) throws(Error) {
        let quantizer: BeatQuantizer

        do {
            quantizer = try BeatQuantizer(factors: factors)
        } catch {
            switch error {
            case .emptyFactors:
                throw Error.emptyQuantizationFactors

            case let .invalidFactor(factor):
                throw Error.invalidQuantizationFactor(factor)
            }
        }

        quantize(using: quantizer, noteIDs: noteIDs)
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
    public func unwarped(using tempoMap: TempoMap) -> NoteTable<BeatTime, PitchType> {
        var btNotes: [NoteTable<BeatTime, PitchType>.Note] = []

        if !notes.isEmpty {
            let tc = TimeConverter(tempoMap: tempoMap)

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

// MARK: -

extension NoteTable where TimeType == BeatTime {

    // MARK: Public Instance Methods

    /// Returns a new wall-time note table by converting beat-time note attack
    /// and release times using a tempo map.
    ///
    /// - Parameter tempoMap:   The tempo map used to convert beat times to wall
    ///                         times.
    ///
    /// - Returns:  A new ``NoteTable`` keyed by ``WallTime``.
    public func warped(using tempoMap: TempoMap) -> NoteTable<WallTime, PitchType> {
        var wtNotes: [NoteTable<WallTime, PitchType>.Note] = []

        if !notes.isEmpty {
            let tc = TimeConverter(tempoMap: tempoMap)

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
}

// MARK: -

extension NoteTable where TimeType == BeatTime, PitchType == Frequency {

    // MARK: Public Instance Methods

    /// Returns a new wall-time note table by converting beat-time note timings and applying
    /// varispeed pitch shifting.
    ///
    /// - Parameter tempoMap:       The tempo map used to convert beat times to wall times.
    /// - Parameter normalTempo:    The reference tempo used for pitch shifting. Defaults to
    ///                             `.default`.
    ///
    /// - Returns:  A new ``NoteTable`` keyed by ``WallTime`` with varispeed-adjusted pitches.
    public func varispeeded(using tempoMap: TempoMap,
                            normalTempo: Tempo = .default) -> NoteTable<WallTime, Frequency> {
        var wtNotes: [NoteTable<WallTime, Frequency>.Note] = []

        if !notes.isEmpty {
            let tc = TimeConverter(tempoMap: tempoMap)

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

        return NoteTable<WallTime, Frequency>(notes: wtNotes)
    }

    // MARK: Private Type Methods

    private static func _varispeed(of pitch: Frequency,
                                   at beatTime: BeatTime,
                                   using tempoMap: TempoMap,
                                   normalTempo: Tempo) -> Frequency {
        _varispeed(of: pitch,
                   by: tempoMap[beatTime].numberValue / normalTempo.numberValue)
    }

    private static func _varispeed(of pitch: Frequency,
                                   by factor: Number) -> Frequency {
        if factor > 1 {
            guard let ratio = Ratio(numberValue: factor),
                  let shifted = pitch.transposed(by: DirectedInterval(interval: ratio,
                                                                      direction: .ascending))
            else { fatalError("Varispeed factor \(factor) produced an invalid ratio or out-of-range frequency.") }

            return shifted
        } else if factor < 1 {
            guard let ratio = Ratio(numberValue: 1 / factor),
                  let shifted = pitch.transposed(by: DirectedInterval(interval: ratio,
                                                                      direction: .descending))
            else { fatalError("Varispeed factor \(factor) produced an invalid ratio or out-of-range frequency.") }

            return shifted
        } else {
            return pitch
        }
    }
}

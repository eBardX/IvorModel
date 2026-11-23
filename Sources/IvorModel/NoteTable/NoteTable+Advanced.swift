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

    /// Quantizes note attack and release times to the nearest grid point defined by `quantizer`.
    ///
    /// - Parameter quantizer:  The quantizer whose grid to snap attack/release times to.
    /// - Parameter noteIDs:    The identities of the notes to quantize, or `nil` to quantize
    ///                         every note in the table.
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

            notes[idx] = StoredNote(noteID: note.noteID,
                                    attack: quantizedAttack,
                                    duration: newDuration,
                                    startPitch: note.startPitch,
                                    endPitch: note.endPitch,
                                    extras: note.extras,
                                    ornamentation: note.ornamentation)
        }

        notes.sort()

        timeRange = Self.timeRange(in: notes)
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
        var btNotes: [NoteTable<BeatTime, PitchType>.StoredNote] = []

        if !notes.isEmpty {
            let tc = TimeConverter(tempoMap: tempoMap)

            for note in notes {
                let beatAttack = tc.beatTime(at: note.attack)
                let beatRelease = tc.beatTime(at: note.release)

                btNotes.append(.init(attack: beatAttack,
                                     duration: beatRelease - beatAttack,
                                     startPitch: note.startPitch,
                                     endPitch: note.endPitch,
                                     extras: note.extras,
                                     ornamentation: Self.retimed(note.ornamentation,
                                                                 at: note.attack,
                                                                 times: tc.beatTime(at:))))
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
        var wtNotes: [NoteTable<WallTime, PitchType>.StoredNote] = []

        if !notes.isEmpty {
            let tc = TimeConverter(tempoMap: tempoMap)

            for note in notes {
                let wallAttack = tc.wallTime(at: note.attack)
                let wallRelease = tc.wallTime(at: note.release)

                wtNotes.append(.init(attack: wallAttack,
                                     duration: wallRelease - wallAttack,
                                     startPitch: note.startPitch,
                                     endPitch: note.endPitch,
                                     extras: note.extras,
                                     ornamentation: Self.retimed(note.ornamentation,
                                                                 at: note.attack,
                                                                 times: tc.wallTime(at:)) {
                                         Self.measuredTremoloRate($0,
                                                                  at: note.attack,
                                                                  using: tempoMap)
                                     }))
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
    ///
    /// - Throws:   ``NoteTable/Error/varispeedFailure(_:_:_:_:)`` if shifting any note’s pitch
    ///             by the tempo ratio in effect produces a frequency outside the representable
    ///             range.
    public func varispeeded(using tempoMap: TempoMap,
                            normalTempo: Tempo = .default) throws(Error) -> NoteTable<WallTime, Frequency> {
        var wtNotes: [NoteTable<WallTime, Frequency>.StoredNote] = []

        if !notes.isEmpty {
            let tc = TimeConverter(tempoMap: tempoMap)

            for note in notes {
                let wallAttack = tc.wallTime(at: note.attack)
                let wallRelease = tc.wallTime(at: note.release)

                guard let varispeedStartPitch = Self._varispeed(of: note.startPitch,
                                                                at: note.attack,
                                                                using: tempoMap,
                                                                normalTempo: normalTempo),
                      let varispeedEndPitch = Self._varispeed(of: note.endPitch,
                                                              at: note.release,
                                                              using: tempoMap,
                                                              normalTempo: normalTempo)
                else { throw .varispeedFailure(note.attack,
                                               note.duration,
                                               note.startPitch,
                                               note.endPitch) }

                //
                // A figure before the note shifts by the tempo at the attack, and a figure after
                // it by the tempo at the release, like the note's own start and end pitches; a
                // written partner shifts with the start pitch.
                //
                let ornamentation = Self.retimed(note.ornamentation,
                                                 at: note.attack,
                                                 times: tc.wallTime(at:),
                                                 tremoloRate: { Self.measuredTremoloRate($0,
                                                                                         at: note.attack,
                                                                                         using: tempoMap) },
                                                 pitchBefore: Self._varispeeding(at: note.attack,
                                                                                 using: tempoMap,
                                                                                 normalTempo: normalTempo),
                                                 pitch: Self._varispeeding(at: note.attack,
                                                                           using: tempoMap,
                                                                           normalTempo: normalTempo),
                                                 pitchAfter: Self._varispeeding(at: note.release,
                                                                                using: tempoMap,
                                                                                normalTempo: normalTempo))

                wtNotes.append(.init(attack: wallAttack,
                                     duration: wallRelease - wallAttack,
                                     startPitch: varispeedStartPitch,
                                     endPitch: varispeedEndPitch,
                                     extras: note.extras,
                                     ornamentation: NoteTable<WallTime, Frequency>.fittingPartner(ornamentation,
                                                                                                  startPitch: varispeedStartPitch)))
            }
        }

        return NoteTable<WallTime, Frequency>(notes: wtNotes)
    }

    // MARK: Private Type Methods

    private static func _varispeed(of pitch: Frequency,
                                   at beatTime: BeatTime,
                                   using tempoMap: TempoMap,
                                   normalTempo: Tempo) -> Frequency? {
        _varispeed(of: pitch,
                   by: tempoMap[beatTime].numberValue / normalTempo.numberValue)
    }

    private static func _varispeed(of pitch: Frequency,
                                   by factor: Number) -> Frequency? {
        if factor > 1 {
            guard let ratio = Ratio(numberValue: factor)
            else { return nil }

            return pitch.transposed(by: DirectedInterval(interval: ratio,
                                                         direction: .ascending))
        } else if factor < 1 {
            guard let ratio = Ratio(numberValue: 1 / factor)
            else { return nil }

            return pitch.transposed(by: DirectedInterval(interval: ratio,
                                                         direction: .descending))
        } else {
            return pitch
        }
    }

    //
    // A pitch mapping that shifts each pitch by the tempo in effect at `beatTime`, throwing if a
    // shifted pitch is out of range.
    //
    private static func _varispeeding(at beatTime: BeatTime,
                                      using tempoMap: TempoMap,
                                      normalTempo: Tempo) -> (Frequency) throws -> Frequency {
        { pitch in
            guard let shifted = _varispeed(of: pitch,
                                           at: beatTime,
                                           using: tempoMap,
                                           normalTempo: normalTempo)
            else { throw ConversionFailure() }

            return shifted
        }
    }
}

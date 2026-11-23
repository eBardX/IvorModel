// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning
internal import XestiNumbers

extension NoteTable {

    // MARK: Internal Type Methods

    //
    // `ornamentation` with its ornament's written partner dropped if it isn't strictly on its
    // side of `startPitch`, so the partner falls back to its rule (resolution 19 of the
    // grace-notes plan). A conversion that collapses pitches (enharmonically, or onto a keyboard)
    // can do that; transposition, inversion and varispeed keep the order by construction.
    //
    internal static func fittingPartner(_ ornamentation: Ornamentation?,
                                        startPitch: PitchType) -> Ornamentation? {
        guard let ornamentation,
              let ornament = ornamentation.ornament,
              hasPartnerOnWrongSide(ornamentation,
                                    startPitch: startPitch)
        else { return ornamentation }

        return Ornamentation(graceBefore: ornamentation.graceBefore,
                             graceAfter: ornamentation.graceAfter,
                             ornament: ornament.withoutWrittenPartner(),
                             arpeggio: ornamentation.arpeggio,
                             fermata: ornamentation.fermata)
    }

    //
    // A note's ornamentation carried into another time type, as warping,
    // unwarping, varispeed and the time-basis conversions need: each written length converts at
    // the main note's attack (`times` maps the work's times), and each pitch through the
    // closure for its slot — the figure before, the ornament's written partner, and the figure
    // after (varispeed shifts them by the tempo at the attack or the release). A slot that
    // can't be converted is dropped; that takes a length that converts to zero, which a
    // positive tempo never gives. `tremoloRate`, if given, adds a rate in notes per second to a
    // measured tremolo with none, so it keeps its speed once its strokes no longer have a
    // tempo to follow.
    //
    internal static func retimed<NewTimeType: TimeProtocol>(_ ornamentation: Ornamentation?,
                                                            at attack: TimeType,
                                                            times: @escaping (TimeType) -> NewTimeType,
                                                            tremoloRate: TremoloRate? = nil,
                                                            pitchBefore: @escaping PitchMapping = { $0 },
                                                            pitch: @escaping PitchMapping = { $0 },
                                                            pitchAfter: @escaping PitchMapping = { $0 }) -> Retimed<NewTimeType>.Ornamentation? {
        guard let ornamentation
        else { return nil }

        let duration = FermataConverter(at: attack,
                                        times: times).duration
        let converter = Converter<NewTimeType, PitchType>(pitch: pitch,
                                                          duration: duration)
        let beforeConverter = Converter<NewTimeType, PitchType>(pitch: pitchBefore,
                                                                duration: duration)
        let afterConverter = Converter<NewTimeType, PitchType>(pitch: pitchAfter,
                                                               duration: duration)
        var ornament = try? ornamentation.ornament.map(converter.ornament)

        if let tremoloRate,
           let value = ornament {
            ornament = Self._addingTremoloRate(to: value,
                                               tremoloRate)
        }

        return NoteTable<NewTimeType, PitchType>.Ornamentation(graceBefore: try? ornamentation.graceBefore.map(beforeConverter.graceFigure),
                                                               graceAfter: try? ornamentation.graceAfter.map(afterConverter.graceFigure),
                                                               ornament: ornament,
                                                               arpeggio: try? ornamentation.arpeggio.map(converter.arpeggio),
                                                               fermata: try? ornamentation.fermata.map(converter.fermataConverter.fermata))
    }

    // MARK: Private Type Methods

    private static func _addingTremoloRate<NewTimeType: TimeProtocol>(to ornament: NoteTable<NewTimeType, PitchType>.Ornament,
                                                                      _ tremoloRate: TremoloRate) -> NoteTable<NewTimeType, PitchType>.Ornament {
        guard case let .tremolo(.measured(strokes))? = ornament.sign,
              ornament.execution?.rate == nil,
              let rate = tremoloRate(strokes)
        else { return ornament }

        let execution = ornament.execution

        return NoteTable<NewTimeType, PitchType>.Ornament(sign: ornament.sign,
                                                          partner: ornament.partner,
                                                          execution: .init(startNote: execution?.startNote,
                                                                           partnerRule: execution?.partnerRule,
                                                                           rate: .perSecond(rate),
                                                                           extent: execution?.extent)) ?? ornament
    }
}

// MARK: -

extension NoteTable where TimeType == BeatTime {

    // MARK: Internal Type Methods

    //
    // The rate, in notes per second at the tempo in effect at `attack`, of a measured tremolo's
    // subdivision: a whole note divided by 2^(strokes + 2) (resolution 8 of the grace-notes
    // plan). Taken from the tempo itself, which is exact, rather than from converted times,
    // which are rounded.
    //
    internal static func measuredTremoloRate(_ strokes: TremoloStrokes,
                                             at attack: BeatTime,
                                             using tempoMap: TempoMap) -> NotesPerSecond? {
        let wholeNotesPerSecond = tempoMap[attack].numberValue / 60

        return NotesPerSecond(numberValue: wholeNotesPerSecond * Number(1 << Int(strokes.uintValue + 2)))
    }
}

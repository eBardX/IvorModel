// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning

extension NoteTable {

    // MARK: Internal Nested Types

    //
    // Carries ornamentation into another time or pitch type — a different type in each
    // specialization of `NoteTable` — converting each pitch through `pitch` and each written
    // length through `duration`. Shares, factors, counts and rates per second are unchanged.
    // Each method throws `ConversionFailure` if a length converts to zero or a rebuilt value
    // fails its own checks; the caller decides whether that drops a slot or fails the whole
    // conversion.
    //
    internal struct Converter<NewTimeType: TimeProtocol, NewPitchType: PitchProtocol> {

        // MARK: Internal Type Aliases

        internal typealias Target = NoteTable<NewTimeType, NewPitchType>

        // MARK: Internal Initializers

        internal init(pitch: @escaping (PitchType) throws -> NewPitchType,
                      duration: @escaping (DurationType) throws -> NewTimeType.DurationType) {
            self.duration = duration
            self.pitch = pitch
        }

        // MARK: Internal Instance Properties

        internal let duration: (DurationType) throws -> NewTimeType.DurationType
        internal let pitch: (PitchType) throws -> NewPitchType
    }
}

// MARK: -

extension NoteTable.Converter {

    // MARK: Internal Instance Properties

    internal var fermataConverter: FermataConverter<TimeType, NewTimeType> {
        FermataConverter(duration: duration)
    }

    // MARK: Internal Instance Methods

    internal func amount(_ value: NoteTable.Amount) throws -> Target.Amount {
        switch value {
        case let .duration(length):
            try .duration(positive(length))

        case let .share(share):
            .share(share)
        }
    }

    internal func arpeggio(_ value: NoteTable.Arpeggio) throws -> Target.Arpeggio {
        try Target.Arpeggio(group: value.group,
                            direction: value.direction,
                            execution: value.execution.map(arpeggioExecution))
    }

    internal func arpeggioExecution(_ value: NoteTable.ArpeggioExecution) throws -> Target.ArpeggioExecution {
        try Target.ArpeggioExecution(spread: value.spread.map(spread),
                                     anchor: value.anchor)
    }

    internal func graceEvent(_ value: NoteTable.GraceFigure.Event) throws -> Target.GraceFigure.Event {
        guard let result = try Target.GraceFigure.Event(pitches: Target.pitchSet(value.pitches.map(pitch)),
                                                        length: value.length.map(positive),
                                                        execution: value.execution.map(graceExecution))
        else { throw ConversionFailure() }

        return result
    }

    internal func graceExecution(_ value: NoteTable.GraceExecution) throws -> Target.GraceExecution {
        try Target.GraceExecution(fromPrevious: value.fromPrevious.map(amount),
                                  fromMain: value.fromMain.map(amount))
    }

    internal func graceFigure(_ value: NoteTable.GraceFigure) throws -> Target.GraceFigure {
        guard let result = try Target.GraceFigure(events: value.events.map(graceEvent),
                                                  isSlashed: value.isSlashed,
                                                  isTiedToMainNote: value.isTiedToMainNote,
                                                  execution: value.execution.map(graceExecution))
        else { throw ConversionFailure() }

        return result
    }

    internal func ornament(_ value: NoteTable.Ornament) throws -> Target.Ornament {
        guard let result = try Target.Ornament(sign: value.sign.map(sign),
                                               partner: partner(value.partner),
                                               execution: value.execution.map(ornamentExecution))
        else { throw ConversionFailure() }

        return result
    }

    internal func ornamentation(_ value: NoteTable.Ornamentation) throws -> Target.Ornamentation {
        try Target.Ornamentation(graceBefore: value.graceBefore.map(graceFigure),
                                 graceAfter: value.graceAfter.map(graceFigure),
                                 ornament: value.ornament.map(ornament),
                                 arpeggio: value.arpeggio.map(arpeggio),
                                 fermata: value.fermata.map(fermataConverter.fermata))
    }

    internal func ornamentExecution(_ value: NoteTable.OrnamentExecution) throws -> Target.OrnamentExecution {
        try Target.OrnamentExecution(startNote: value.startNote,
                                     partnerRule: value.partnerRule,
                                     rate: value.rate.map(rate),
                                     extent: value.extent)
    }

    internal func partner(_ value: NoteTable.Ornament.Partner) throws -> Target.Ornament.Partner {
        switch value {
        case let .pitches(pitches):
            try .pitches(Target.pitchSet(pitches.map(pitch)))

        case .repeat:
            .repeat

        case let .step(side, written):
            try .step(side, written: written.map(pitch))
        }
    }

    internal func positive(_ value: PositiveDuration<NoteTable.DurationType>) throws -> PositiveDuration<NewTimeType.DurationType> {
        try fermataConverter.positive(value)
    }

    internal func rate(_ value: NoteTable.OrnamentExecution.Rate) throws -> Target.OrnamentExecution.Rate {
        switch value {
        case let .noteValue(length):
            try .noteValue(positive(length))

        case let .perSecond(rate):
            .perSecond(rate)
        }
    }

    internal func sign(_ value: NoteTable.Ornament.Sign) -> Target.Ornament.Sign {
        switch value {
        case .mordent:
            .mordent

        case let .tremolo(.measured(strokes)):
            .tremolo(.measured(strokes))

        case .tremolo(.unmeasured):
            .tremolo(.unmeasured)

        case .trill:
            .trill
        }
    }

    internal func spread(_ value: NoteTable.ArpeggioExecution.Spread) throws -> Target.ArpeggioExecution.Spread {
        switch value {
        case let .perTone(length):
            try .perTone(positive(length))

        case let .total(share):
            .total(share)
        }
    }
}

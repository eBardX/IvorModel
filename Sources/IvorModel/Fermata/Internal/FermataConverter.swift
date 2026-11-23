// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming

//
// Carries fermatas, caesuras and part marks into another time type, converting each length in
// the work's own time through `duration` (such as from beats to seconds at the mark's moment).
// Seconds, factors and shares are unchanged. Each method throws `ConversionFailure` if a length
// converts to zero.
//
internal struct FermataConverter<TimeType: TimeProtocol, NewTimeType: TimeProtocol> {

    // MARK: Internal Initializers

    //
    // Converts each length as starting at `time`: the span between the converted `time` and the
    // converted end. So a beat length converts at the tempo in effect there.
    //
    internal init(at time: TimeType,
                  times: @escaping (TimeType) -> NewTimeType) {
        let start = times(time)

        self.init { length in
            guard let end = time.moved(by: DirectedDuration(duration: length,
                                                            direction: .forward)),
                  let span = start.duration(to: times(end)),
                  span.direction == .forward
            else { throw ConversionFailure() }

            return span.duration
        }
    }

    internal init(duration: @escaping (TimeType.DurationType) throws -> NewTimeType.DurationType) {
        self.duration = duration
    }

    // MARK: Internal Instance Properties

    internal let duration: (TimeType.DurationType) throws -> NewTimeType.DurationType
}

// MARK: -

extension FermataConverter {

    // MARK: Internal Instance Methods

    internal func caesuraExecution(_ value: CaesuraExecution<TimeType>) throws -> CaesuraExecution<NewTimeType> {
        try CaesuraExecution(pause: value.pause.map(pause))
    }

    internal func fermata(_ value: Fermata<TimeType>) throws -> Fermata<NewTimeType> {
        try Fermata(shape: value.shape,
                    execution: value.execution.map(fermataExecution))
    }

    internal func fermataExecution(_ value: FermataExecution<TimeType>) throws -> FermataExecution<NewTimeType> {
        try FermataExecution(hold: value.hold.map(hold),
                             pauseAfter: value.pauseAfter.map(pause),
                             isPlayed: value.isPlayed)
    }

    internal func hold(_ value: FermataExecution<TimeType>.Hold) throws -> FermataExecution<NewTimeType>.Hold {
        switch value {
        case let .added(length):
            try .added(positive(length))

        case let .seconds(seconds):
            .seconds(seconds)

        case let .stretch(stretch):
            .stretch(stretch)
        }
    }

    internal func partMark(_ value: PartMark<TimeType>) throws -> PartMark<NewTimeType> {
        switch value {
        case let .caesura(execution):
            try .caesura(execution.map(caesuraExecution))

        case let .fermata(fermata, span):
            try .fermata(self.fermata(fermata),
                         span: positive(span))
        }
    }

    internal func pause(_ value: Pause<TimeType>) throws -> Pause<NewTimeType> {
        switch value {
        case let .added(length):
            try .added(positive(length))

        case let .seconds(seconds):
            .seconds(seconds)
        }
    }

    internal func positive(_ value: PositiveDuration<TimeType.DurationType>) throws -> PositiveDuration<NewTimeType.DurationType> {
        guard let result = try PositiveDuration<NewTimeType.DurationType>(duration(value.duration))
        else { throw ConversionFailure() }

        return result
    }
}

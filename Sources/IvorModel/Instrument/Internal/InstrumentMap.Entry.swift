import XestiTools

extension InstrumentMap {

    // MARK: Internal Nested Types

    internal enum Entry {
        case custom(TimeType, Instrument, Extras)
        case simple(TimeType, Instrument)
    }
}

// MARK: -

extension InstrumentMap.Entry {

    // MARK: Internal Initializers

    internal init(time: TimeType,
                  instrument: Instrument,
                  extras: Extras?) {
        if let extras, !extras.isEmpty {
            self = .custom(time, instrument, extras)
        } else {
            self = .simple(time, instrument)
        }
    }

    // MARK: Internal Instance Properties

    internal var extras: Extras? {
        switch self {
        case let .custom(_, _, extras):
            extras

        default:
            nil
        }
    }

    internal var instrument: Instrument {
        switch self {
        case let .custom(_, instrument, _),
            let .simple(_, instrument):
            instrument
        }
    }

    internal var time: TimeType {
        switch self {
        case let .custom(time, _, _),
            let .simple(time, _):
            time
        }
    }
}

// MARK: - Codable

extension InstrumentMap.Entry: Codable {

    // MARK: Internal Initializers

    internal init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let time = try container.decode(TimeType.self)
        let instrument = try container.decode(Instrument.self)
        let extras = try container.decodeIfPresent(Extras.self)

        self.init(time: time,
                  instrument: instrument,
                  extras: extras)
    }

    // MARK: Internal Instance Methods

    internal func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode(time)
        try container.encode(instrument)

        if let extras {
            try container.encode(extras)
        }
    }
}

// MARK: - Comparable

extension InstrumentMap.Entry: Comparable {

    // MARK: Internal Type Methods

    internal static func < (lhs: Self,
                            rhs: Self) -> Bool {
        lhs.time < rhs.time
    }
}

// MARK: - Sendable

extension InstrumentMap.Entry: Sendable {
}

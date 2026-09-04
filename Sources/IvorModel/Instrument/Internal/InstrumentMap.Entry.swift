// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

extension InstrumentMap {

    // MARK: Internal Nested Types

    internal enum Entry {
        case extended(EntryID, TimeType, Instrument, Extras)
        case simple(EntryID, TimeType, Instrument)

        // MARK: Internal Initializers

        //
        // `entryID` defaults to a fresh identity — the common case, a newly inserted or
        // decoded entry. Passing one explicitly is for the one caller that needs to
        // keep an existing identity across a content change:
        // `update(entryID:instrument:extras:)`.
        //
        internal init(entryID: EntryID = EntryID(),
                      time: TimeType,
                      instrument: Instrument,
                      extras: Extras?) {
            if let extras, !extras.isEmpty {
                self = .extended(entryID, time, instrument, extras)
            } else {
                self = .simple(entryID, time, instrument)
            }
        }
    }
}

// MARK: -

extension InstrumentMap.Entry {

    // MARK: Internal Instance Properties

    internal var extras: Extras? {
        switch self {
        case let .extended(_, _, _, extras):
            extras

        default:
            nil
        }
    }

    internal var entryID: InstrumentMap.EntryID {
        switch self {
        case let .extended(entryID, _, _, _),
            let .simple(entryID, _, _):
            entryID
        }
    }

    internal var instrument: Instrument {
        switch self {
        case let .extended(_, _, instrument, _),
            let .simple(_, _, instrument):
            instrument
        }
    }

    internal var time: TimeType {
        switch self {
        case let .extended(_, time, _, _),
            let .simple(_, time, _):
            time
        }
    }
}

// MARK: - Codable

extension InstrumentMap.Entry: Codable {

    // MARK: Internal Initializers

    //
    // Identity is never encoded (see `EntryID`'s doc comment), so decoding always
    // assigns a fresh one via the default parameter — indistinguishable from a
    // freshly inserted entry.
    //
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

// MARK: - Equatable

extension InstrumentMap.Entry: Equatable {

    // MARK: Internal Type Methods

    //
    // Identity is deliberately excluded: two entries are equal here exactly when
    // they carry the same time, instrument, and extras, regardless of which
    // `EntryID` each holds. This is what lets `insert`'s exact-duplicate check keep
    // working — a synthesized `==` that compared identity too would make every
    // content-identical pair unequal, since each gets a fresh, distinct entryID.
    //
    internal static func == (lhs: Self,
                             rhs: Self) -> Bool {
        (lhs.time, lhs.instrument, lhs.extras) == (rhs.time, rhs.instrument, rhs.extras)
    }
}

// MARK: - Sendable

extension InstrumentMap.Entry: Sendable {
}

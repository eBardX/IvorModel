// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import XestiTools

extension MeterTable {

    // MARK: Internal Nested Types

    internal enum StoredEntry {
        case extended(EntryID, BeatTime, Meter, Extras)
        case simple(EntryID, BeatTime, Meter)

        // MARK: Internal Initializers

        //
        // `entryID` defaults to a fresh identity — the common case, a newly inserted or
        // decoded entry. Passing one explicitly keeps an existing identity across a content
        // change, as `update(entryID:meter:extras:)`, `move(entryID:to:)` and the transforms do.
        //
        internal init(entryID: EntryID = EntryID(),
                      beatTime: BeatTime,
                      meter: Meter,
                      extras: Extras?) {
            if let extras, !extras.isEmpty {
                self = .extended(entryID, beatTime, meter, extras)
            } else {
                self = .simple(entryID, beatTime, meter)
            }
        }
    }
}

// MARK: -

extension MeterTable.StoredEntry {

    // MARK: Internal Instance Properties

    internal var beatTime: BeatTime {
        switch self {
        case let .extended(_, beatTime, _, _),
            let .simple(_, beatTime, _):
            beatTime
        }
    }

    internal var entryID: EntryID {
        switch self {
        case let .extended(entryID, _, _, _),
            let .simple(entryID, _, _):
            entryID
        }
    }

    internal var extras: Extras? {
        switch self {
        case let .extended(_, _, _, extras):
            extras

        default:
            nil
        }
    }

    internal var meter: Meter {
        switch self {
        case let .extended(_, _, meter, _),
            let .simple(_, _, meter):
            meter
        }
    }

    // MARK: Internal Instance Methods

    //
    // This entry, keeping its identity, meter and extras, at another beat time.
    //
    internal func moved(to beatTime: BeatTime) -> Self {
        Self(entryID: entryID,
             beatTime: beatTime,
             meter: meter,
             extras: extras)
    }
}

// MARK: - Codable

extension MeterTable.StoredEntry: Codable {

    // MARK: Internal Initializers

    //
    // Identity is never encoded (see `EntryID`'s doc comment), so decoding always
    // assigns a fresh one via the default parameter — indistinguishable from a
    // freshly inserted entry.
    //
    internal init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let beatTime = try container.decode(BeatTime.self)
        let meter = try container.decode(Meter.self)
        let extras = try container.decodeIfPresent(Extras.self)

        self.init(beatTime: beatTime,
                  meter: meter,
                  extras: extras)
    }

    // MARK: Internal Instance Methods

    internal func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode(beatTime)
        try container.encode(meter)

        if let extras {
            try container.encode(extras)
        }
    }
}

// MARK: - Equatable

extension MeterTable.StoredEntry: Equatable {

    // MARK: Internal Type Methods

    //
    // Identity is deliberately excluded: two entries are equal here exactly when they carry
    // the same beat time, meter, and extras, regardless of which `EntryID` each holds — so two
    // meter tables with the same content compare equal.
    //
    internal static func == (lhs: Self,
                             rhs: Self) -> Bool {
        (lhs.beatTime, lhs.meter, lhs.extras) == (rhs.beatTime, rhs.meter, rhs.extras)
    }
}

// MARK: - Sendable

extension MeterTable.StoredEntry: Sendable {
}

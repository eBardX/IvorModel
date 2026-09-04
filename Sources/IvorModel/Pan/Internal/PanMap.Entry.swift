// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

extension PanMap {

    // MARK: Internal Nested Types

    internal enum Entry {
        case extended(EntryID, TimeType, Pan, Extras)
        case simple(EntryID, TimeType, Pan)

        // MARK: Internal Initializers

        //
        // `entryID` defaults to a fresh identity — the common case, a newly inserted or
        // decoded entry. Passing one explicitly is for the one caller that needs to
        // keep an existing identity across a content change: `update(entryID:pan:extras:)`.
        //
        internal init(entryID: EntryID = EntryID(),
                      time: TimeType,
                      pan: Pan,
                      extras: Extras?) {
            if let extras, !extras.isEmpty {
                self = .extended(entryID, time, pan, extras)
            } else {
                self = .simple(entryID, time, pan)
            }
        }
    }
}

// MARK: -

extension PanMap.Entry {

    // MARK: Internal Instance Properties

    internal var extras: Extras? {
        switch self {
        case let .extended(_, _, _, extras):
            extras

        default:
            nil
        }
    }

    internal var entryID: PanMap.EntryID {
        switch self {
        case let .extended(entryID, _, _, _),
            let .simple(entryID, _, _):
            entryID
        }
    }

    internal var pan: Pan {
        switch self {
        case let .extended(_, _, pan, _),
            let .simple(_, _, pan):
            pan
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

extension PanMap.Entry: Codable {

    // MARK: Internal Initializers

    //
    // Identity is never encoded (see `EntryID`'s doc comment), so decoding always
    // assigns a fresh one via the default parameter — indistinguishable from a
    // freshly inserted entry.
    //
    internal init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let time = try container.decode(TimeType.self)
        let pan = try container.decode(Pan.self)
        let extras = try container.decodeIfPresent(Extras.self)

        self.init(time: time,
                  pan: pan,
                  extras: extras)
    }

    // MARK: Internal Instance Methods

    internal func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode(time)
        try container.encode(pan)

        if let extras {
            try container.encode(extras)
        }
    }
}

// MARK: - Comparable

extension PanMap.Entry: Comparable {

    // MARK: Internal Type Methods

    internal static func < (lhs: Self,
                            rhs: Self) -> Bool {
        lhs.time < rhs.time
    }
}

// MARK: - Equatable

extension PanMap.Entry: Equatable {

    // MARK: Internal Type Methods

    //
    // Identity is deliberately excluded: two entries are equal here exactly when
    // they carry the same time, pan position, and extras, regardless of which
    // `EntryID` each holds. This is what lets `insert`'s exact-duplicate check keep
    // working — a synthesized `==` that compared identity too would make every
    // content-identical pair unequal, since each gets a fresh, distinct entryID.
    //
    internal static func == (lhs: Self,
                             rhs: Self) -> Bool {
        (lhs.time, lhs.pan, lhs.extras) == (rhs.time, rhs.pan, rhs.extras)
    }
}

// MARK: - Sendable

extension PanMap.Entry: Sendable {
}

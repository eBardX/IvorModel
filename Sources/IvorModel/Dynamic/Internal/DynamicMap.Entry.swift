// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

extension DynamicMap {

    // MARK: Internal Nested Types

    internal enum Entry {
        case extended(EntryID, TimeType, Dynamic, Extras)
        case simple(EntryID, TimeType, Dynamic)

        // MARK: Internal Initializers

        //
        // `entryID` defaults to a fresh identity — the common case, a newly inserted or
        // decoded entry. Passing one explicitly is for the one caller that needs to
        // keep an existing identity across a content change:
        // `update(entryID:dynamic:extras:)`.
        //
        internal init(entryID: EntryID = EntryID(),
                      time: TimeType,
                      dynamic: Dynamic,
                      extras: Extras?) {
            if let extras, !extras.isEmpty {
                self = .extended(entryID, time, dynamic, extras)
            } else {
                self = .simple(entryID, time, dynamic)
            }
        }
    }
}

// MARK: -

extension DynamicMap.Entry {

    // MARK: Internal Instance Properties

    internal var dynamic: Dynamic {
        switch self {
        case let .extended(_, _, dynamic, _),
            let .simple(_, _, dynamic):
            dynamic
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

    internal var entryID: DynamicMap.EntryID {
        switch self {
        case let .extended(entryID, _, _, _),
            let .simple(entryID, _, _):
            entryID
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

extension DynamicMap.Entry: Codable {

    // MARK: Internal Initializers

    //
    // Identity is never encoded (see `EntryID`'s doc comment), so decoding always
    // assigns a fresh one via the default parameter — indistinguishable from a
    // freshly inserted entry.
    //
    internal init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let time = try container.decode(TimeType.self)
        let dynamic = try container.decode(Dynamic.self)
        let extras = try container.decodeIfPresent(Extras.self)

        self.init(time: time,
                  dynamic: dynamic,
                  extras: extras)
    }

    // MARK: Internal Instance Methods

    internal func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode(time)
        try container.encode(dynamic)

        if let extras {
            try container.encode(extras)
        }
    }
}

// MARK: - Comparable

extension DynamicMap.Entry: Comparable {

    // MARK: Internal Type Methods

    internal static func < (lhs: Self,
                            rhs: Self) -> Bool {
        lhs.time < rhs.time
    }
}

// MARK: - Equatable

extension DynamicMap.Entry: Equatable {

    // MARK: Internal Type Methods

    //
    // Identity is deliberately excluded: two entries are equal here exactly when
    // they carry the same time, dynamic level, and extras, regardless of which
    // `EntryID` each holds. This is what lets `insert`'s exact-duplicate check keep
    // working — a synthesized `==` that compared identity too would make every
    // content-identical pair unequal, since each gets a fresh, distinct entryID.
    //
    internal static func == (lhs: Self,
                             rhs: Self) -> Bool {
        (lhs.time, lhs.dynamic, lhs.extras) == (rhs.time, rhs.dynamic, rhs.extras)
    }
}

// MARK: - Sendable

extension DynamicMap.Entry: Sendable {
}

// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning
internal import XestiTools

extension KeyTable {

    // MARK: Internal Nested Types

    internal enum StoredEntry {
        case extended(EntryID, BeatTime, Key, Extras)
        case simple(EntryID, BeatTime, Key)

        // MARK: Internal Initializers

        //
        // `entryID` defaults to a fresh identity — the common case, a newly inserted or
        // decoded entry. Passing one explicitly keeps an existing identity across a content
        // change, as `update(entryID:key:extras:)`, `move(entryID:to:)` and the
        // transforms do.
        //
        internal init(entryID: EntryID = EntryID(),
                      beatTime: BeatTime,
                      key: Key,
                      extras: Extras?) {
            if let extras, !extras.isEmpty {
                self = .extended(entryID, beatTime, key, extras)
            } else {
                self = .simple(entryID, beatTime, key)
            }
        }
    }
}

// MARK: -

extension KeyTable.StoredEntry {

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

    internal var key: Key {
        switch self {
        case let .extended(_, _, key, _),
            let .simple(_, _, key):
            key
        }
    }

    // MARK: Internal Instance Methods

    //
    // This entry, keeping its identity, key and extras, at another beat time.
    //
    internal func moved(to beatTime: BeatTime) -> Self {
        Self(entryID: entryID,
             beatTime: beatTime,
             key: key,
             extras: extras)
    }

    //
    // This entry, keeping its identity, beat time and extras, with another key.
    //
    internal func with(_ key: Key) -> Self {
        Self(entryID: entryID,
             beatTime: beatTime,
             key: key,
             extras: extras)
    }
}

// MARK: - Codable

extension KeyTable.StoredEntry: Codable {

    // MARK: Internal Initializers

    //
    // Identity is never encoded (see `EntryID`'s doc comment), so decoding always
    // assigns a fresh one via the default parameter — indistinguishable from a
    // freshly inserted entry.
    //
    internal init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let beatTime = try container.decode(BeatTime.self)
        let key = try container.decode(Key.self)
        let extras = try container.decodeIfPresent(Extras.self)?.normalizingNames()

        self.init(beatTime: beatTime,
                  key: key,
                  extras: extras)
    }

    // MARK: Internal Instance Methods

    internal func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode(beatTime)
        try container.encode(key)

        if let extras {
            try container.encode(extras)
        }
    }
}

// MARK: - Equatable

extension KeyTable.StoredEntry: Equatable {

    // MARK: Internal Type Methods

    //
    // Identity is deliberately excluded: two entries are equal here exactly when they carry
    // the same beat time, key, and extras, regardless of which `EntryID` each holds —
    // so two key tables with the same content compare equal.
    //
    internal static func == (lhs: Self,
                             rhs: Self) -> Bool {
        (lhs.beatTime, lhs.key, lhs.extras) == (rhs.beatTime, rhs.key, rhs.extras)
    }
}

// MARK: - Sendable

extension KeyTable.StoredEntry: Sendable {
}

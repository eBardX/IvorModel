// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning
internal import XestiTools

extension KeySignatureTable {

    // MARK: Internal Nested Types

    internal enum StoredEntry {
        case extended(EntryID, BeatTime, KeySignature, Extras)
        case simple(EntryID, BeatTime, KeySignature)

        // MARK: Internal Initializers

        //
        // `entryID` defaults to a fresh identity — the common case, a newly inserted or
        // decoded entry. Passing one explicitly keeps an existing identity across a content
        // change, as `update(entryID:keySignature:extras:)`, `move(entryID:to:)` and the
        // transforms do.
        //
        internal init(entryID: EntryID = EntryID(),
                      beatTime: BeatTime,
                      keySignature: KeySignature,
                      extras: Extras?) {
            if let extras, !extras.isEmpty {
                self = .extended(entryID, beatTime, keySignature, extras)
            } else {
                self = .simple(entryID, beatTime, keySignature)
            }
        }
    }
}

// MARK: -

extension KeySignatureTable.StoredEntry {

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

    internal var keySignature: KeySignature {
        switch self {
        case let .extended(_, _, keySignature, _),
            let .simple(_, _, keySignature):
            keySignature
        }
    }

    // MARK: Internal Instance Methods

    //
    // This entry, keeping its identity, key signature and extras, at another beat time.
    //
    internal func moved(to beatTime: BeatTime) -> Self {
        Self(entryID: entryID,
             beatTime: beatTime,
             keySignature: keySignature,
             extras: extras)
    }

    //
    // This entry, keeping its identity, beat time and extras, with another key signature, and
    // without its mode extra if `droppingMode` is set.
    //
    internal func with(_ keySignature: KeySignature,
                       droppingMode: Bool) -> Self {
        let newExtras = droppingMode
            ? extras.map { Extras(elements: $0.elements.filter { $0.name != Extra.keySignatureMode.name }) }
            : extras

        return Self(entryID: entryID,
                    beatTime: beatTime,
                    keySignature: keySignature,
                    extras: newExtras)
    }
}

// MARK: - Codable

extension KeySignatureTable.StoredEntry: Codable {

    // MARK: Internal Initializers

    //
    // Identity is never encoded (see `EntryID`'s doc comment), so decoding always
    // assigns a fresh one via the default parameter — indistinguishable from a
    // freshly inserted entry.
    //
    internal init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let beatTime = try container.decode(BeatTime.self)
        let keySignature = try container.decode(KeySignature.self)
        let extras = try container.decodeIfPresent(Extras.self)

        self.init(beatTime: beatTime,
                  keySignature: keySignature,
                  extras: extras)
    }

    // MARK: Internal Instance Methods

    internal func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode(beatTime)
        try container.encode(keySignature)

        if let extras {
            try container.encode(extras)
        }
    }
}

// MARK: - Equatable

extension KeySignatureTable.StoredEntry: Equatable {

    // MARK: Internal Type Methods

    //
    // Identity is deliberately excluded: two entries are equal here exactly when they carry
    // the same beat time, key signature, and extras, regardless of which `EntryID` each holds —
    // so two key signature tables with the same content compare equal.
    //
    internal static func == (lhs: Self,
                             rhs: Self) -> Bool {
        (lhs.beatTime, lhs.keySignature, lhs.extras) == (rhs.beatTime, rhs.keySignature, rhs.extras)
    }
}

// MARK: - Sendable

extension KeySignatureTable.StoredEntry: Sendable {
}

// © 2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

extension PartMarkTable {

    // MARK: Internal Nested Types

    internal struct StoredEntry {

        // MARK: Internal Initializers

        //
        // `entryID` defaults to a fresh identity — the common case, a newly inserted or
        // decoded entry. Passing one explicitly keeps an existing identity across a content
        // change: a move, an update, or a transform.
        //
        internal init(entryID: EntryID = EntryID(),
                      time: TimeType,
                      mark: PartMark<TimeType>) {
            self.entryID = entryID
            self.mark = mark
            self.time = time
        }

        // MARK: Internal Instance Properties

        internal let entryID: EntryID
        internal let mark: PartMark<TimeType>
        internal let time: TimeType
    }
}

// MARK: - Codable

extension PartMarkTable.StoredEntry: Codable {

    // MARK: Internal Initializers

    //
    // Identity is never encoded (see `EntryID`'s doc comment), so decoding always
    // assigns a fresh one via the default parameter — indistinguishable from a
    // freshly inserted entry.
    //
    internal init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let time = try container.decode(TimeType.self)
        let mark = try container.decode(PartMark<TimeType>.self)

        self.init(time: time,
                  mark: mark)
    }

    // MARK: Internal Instance Methods

    internal func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode(time)
        try container.encode(mark)
    }
}

// MARK: - Comparable

extension PartMarkTable.StoredEntry: Comparable {

    // MARK: Internal Type Methods

    internal static func < (lhs: Self,
                            rhs: Self) -> Bool {
        lhs.time < rhs.time
    }
}

// MARK: - Equatable

extension PartMarkTable.StoredEntry: Equatable {

    // MARK: Internal Type Methods

    //
    // Identity is deliberately excluded: two entries are equal here exactly when they carry the
    // same time and mark, regardless of which `EntryID` each holds. This is what lets `insert`'s
    // exact-duplicate check work.
    //
    internal static func == (lhs: Self,
                             rhs: Self) -> Bool {
        (lhs.time, lhs.mark) == (rhs.time, rhs.mark)
    }
}

// MARK: - Sendable

extension PartMarkTable.StoredEntry: Sendable {
}

// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiTools

/// A time-indexed table of instrument designations with a configurable default.
///
/// Each entry is a step: its instrument holds from its time until the next entry’s. Before
/// the first entry, ``defaultInstrument`` is in effect.
public struct InstrumentTable<TimeType: TimeProtocol> {

    // MARK: Public Initializers

    /// Creates a new, empty instrument table with the given default instrument.
    ///
    /// - Parameter defaultInstrument:  The instrument in effect before the
    ///                                 first entry, or throughout if the
    ///                                 instrument table is empty. Defaults to
    ///                                 `.vanilla`.
    public init(defaultInstrument: Instrument = .vanilla) {
        self.init(defaultInstrument: defaultInstrument,
                  entries: [])
    }

    // MARK: Public Instance Properties

    /// The instrument in effect before this instrument table’s first entry, or
    /// throughout if it contains no entries.
    public let defaultInstrument: Instrument

    /// A Boolean value indicating whether any entry in this instrument table
    /// carries extra data.
    public private(set) var hasExtras: Bool

    // MARK: Internal Initializers

    internal init(defaultInstrument: Instrument,
                  entries: [StoredEntry]) {
        self.defaultInstrument = defaultInstrument
        self.entries = entries
        self.hasExtras = Self.hasExtras(in: entries)
    }

    // MARK: Internal Instance Properties

    internal var entries: [StoredEntry]
}

// MARK: -

extension InstrumentTable {

    // MARK: Public Instance Properties

    /// Every instrument this instrument table designates, each once, in the
    /// order they first take effect.
    ///
    /// The array starts with ``defaultInstrument`` if this instrument table is
    /// empty or its first entry comes after time zero.
    public var instruments: [Instrument] {
        guard let first = entries.first
        else { return [defaultInstrument] }

        var result: [Instrument] = first.time > .zero ? [defaultInstrument] : []

        for entry in entries where !result.contains(entry.instrument) {
            result.append(entry.instrument)
        }

        return result
    }

    // MARK: Public Instance Subscripts

    /// Returns the instrument in effect at the given time.
    ///
    /// - Parameter time:   The time at which to query the instrument.
    ///
    /// - Returns:  The ``Instrument`` value of the last entry at or before
    ///             `time`, or ``defaultInstrument`` if there is none.
    public subscript(_ time: TimeType) -> Instrument {
        guard let idx = entries.firstIndex(where: { time < $0.time })
        else { return entries.last?.instrument ?? defaultInstrument }

        guard idx > 0
        else { return defaultInstrument }

        return entries[idx - 1].instrument
    }

    // MARK: Public Instance Methods

    /// Inserts an instrument entry into this instrument table at the given time.
    ///
    /// An entry that exactly duplicates one already present — same time,
    /// instrument, and extras — carries no information beyond the original
    /// and is silently ignored. Two entries at the same time with
    /// *different* instruments are a deliberate, meaningful step
    /// (interpolation jumps instantly at that time), and are unaffected by
    /// this check.
    ///
    /// - Parameter time:       The time at which the instrument takes effect.
    /// - Parameter instrument: The instrument to insert.
    /// - Parameter extras:     Optional extra data attached to the entry.
    ///                         Defaults to `nil`.
    ///
    /// - Returns:  A pair of the identity that now addresses this entry —
    ///             a freshly generated identity, unless the insertion
    ///             collapsed into a pre-existing exact duplicate (see
    ///             above), in which case the survivor’s identity — and
    ///             `inserted`, `true` if a new entry was added and `false`
    ///             if the insertion collapsed into that pre-existing
    ///             duplicate instead.
    @discardableResult
    public mutating func insert(time: TimeType,
                                instrument: Instrument,
                                extras: Extras? = nil) -> (entryID: EntryID, inserted: Bool) {
        _insert(entryID: EntryID(),
                time: time,
                instrument: instrument,
                extras: extras)
    }

    /// Merges the entries from another instrument table into this instrument table.
    ///
    /// - Parameter other:  The instrument table whose entries are merged into
    ///                     this instrument table.
    public mutating func merge(with other: Self) {
        guard !other.entries.isEmpty
        else { return }

        guard !entries.isEmpty
        else { self = other; return }

        entries.append(contentsOf: other.entries)
        entries.sort()

        hasExtras = hasExtras || other.hasExtras
    }

    /// Moves the instrument entry with the given identity to a new time,
    /// keeping its instrument and extras, and re-sorts it into place.
    ///
    /// Unlike ``update(entryID:instrument:extras:)``, this is expected to
    /// reorder entries — that is the point of editing the time itself. Two
    /// entries legitimately ending up at the same time (see
    /// ``insert(time:instrument:extras:)`` for the discontinuity use case)
    /// is not treated as a collision to reject; the moved entry simply
    /// takes its place among any others already there, exactly as a fresh
    /// insertion would.
    ///
    /// The one case where `entryID` stops identifying the moved entry afterward is
    /// when the move lands it exactly on top of another entry already
    /// present — same time, instrument, and extras — the same
    /// exact-duplicate case ``insert(time:instrument:extras:)`` silently
    /// collapses. There, the moved entry merges into that pre-existing one
    /// instead of being kept separately, so `entryID` no longer names anything in
    /// the table; the returned identity is the survivor’s instead, which a
    /// caller must switch to addressing from then on.
    ///
    /// - Parameter entryID:    The identity of the entry to move.
    /// - Parameter time:       The new time for the entry.
    ///
    /// - Returns:  The identity that now addresses this entry’s content — `entryID`
    ///             itself, unless the move merged it into a pre-existing exact
    ///             duplicate, in which case the survivor’s identity. `nil` if
    ///             `entryID` did not identify any entry and nothing moved.
    @discardableResult
    public mutating func move(entryID: EntryID,
                              to time: TimeType) -> EntryID? {
        guard let position = firstIndex(entryID: entryID)
        else { return nil }

        let entry = entries.remove(at: position)

        let (newID, _) = _insert(entryID: entryID,
                                 time: time,
                                 instrument: entry.instrument,
                                 extras: entry.extras)

        hasExtras = Self.hasExtras(in: entries)

        return newID
    }

    /// Removes the instrument entry with the given identity, if present.
    ///
    /// - Parameter entryID:    The identity of the entry to remove. An identity
    ///                         naming no entry is ignored.
    ///
    /// - Returns:  `true` if `entryID` identified an entry and it was
    ///             removed, `false` if `entryID` named no entry and nothing
    ///             happened.
    @discardableResult
    public mutating func remove(entryID: EntryID) -> Bool {
        guard let position = firstIndex(entryID: entryID)
        else { return false }

        entries.remove(at: position)

        hasExtras = Self.hasExtras(in: entries)

        return true
    }

    /// Replaces the instrument entry with the given identity, in place.
    ///
    /// Unlike a ``remove(entryID:)`` followed by an ``insert(time:instrument:extras:)``, this
    /// keeps the entry’s identity and does not reorder entries. Reordering only matters when more
    /// than one entry shares a time: insertion always lands after every entry already at that
    /// time, so a remove-then-insert edit of one entry among ties silently changes the order of
    /// entries that were never touched. And — unlike a position — the identity keeps addressing
    /// this same entry across any other entry’s edit, so a caller never needs to re-resolve it
    /// first.
    ///
    /// The edit can turn this entry into an exact duplicate of another one
    /// already at the same time — same time, instrument, and extras — the
    /// same combination ``insert(time:instrument:extras:)`` silently
    /// collapses. When that happens, `entryID` always keeps addressing the
    /// entry that was just updated; the *other*, pre-existing entry is the
    /// one silently removed instead. That is the only choice consistent
    /// with the guarantee above: a caller invoking this method already
    /// holds `entryID` and goes on using it afterward, so honoring “this
    /// identity keeps addressing this same entry” means the entry it
    /// wasn’t referencing has to be the one that gives way, never the one
    /// it was.
    ///
    /// - Parameter entryID:    The identity of the entry to replace. An
    ///                         identity naming no entry is ignored.
    /// - Parameter instrument: The new instrument for the entry.
    /// - Parameter extras:     The new optional extra data for the entry.
    ///                         Defaults to `nil`.
    ///
    /// - Returns:  A pair of `updated`, `true` if `entryID` identified an
    ///             entry and it was updated, `false` if `entryID` named no
    ///             entry and nothing happened — and `removedEntryID`, the
    ///             identity of the pre-existing entry dropped because the
    ///             edit collapsed into it (see above). `nil` if `updated`
    ///             is `false`, or if it is `true` but no such collision
    ///             occurred.
    @discardableResult
    public mutating func update(entryID: EntryID,
                                instrument: Instrument,
                                extras: Extras? = nil) -> (updated: Bool, removedEntryID: EntryID?) {
        guard let position = firstIndex(entryID: entryID)
        else { return (false, nil) }

        entries[position] = StoredEntry(entryID: entryID,
                                        time: entries[position].time,
                                        instrument: instrument,
                                        extras: extras)

        //
        // The edit may have turned this entry into an exact duplicate of another
        // one already at the same time — see `insert(time:instrument:extras:)`
        // for why that combination carries no information beyond a single
        // entry. Drop the other one rather than leave the duplicate in place.
        // `StoredEntry`'s own `==` already excludes identity, so comparing whole
        // entries is enough to find one that only *differs* in which entry it
        // is.
        //
        var removedEntryID: EntryID?

        if let duplicate = entries.indices.first(where: {
            entries[$0].entryID != entryID && entries[$0] == entries[position]
        }) {
            removedEntryID = entries[duplicate].entryID

            entries.remove(at: duplicate)
        }

        hasExtras = Self.hasExtras(in: entries)

        return (true, removedEntryID)
    }

    // MARK: Private Instance Methods

    @discardableResult
    private mutating func _insert(entryID: EntryID,
                                  time: TimeType,
                                  instrument: Instrument,
                                  extras: Extras?) -> (entryID: EntryID, inserted: Bool) {
        if let existing = firstIndex(time: time,
                                     instrument: instrument,
                                     extras: extras) {
            return (entries[existing].entryID, false)
        }

        entries.insert(StoredEntry(entryID: entryID,
                                   time: time,
                                   instrument: instrument,
                                   extras: extras),
                       at: insertionIndex(for: time))

        if extras != nil {
            hasExtras = true
        }

        return (entryID, true)
    }
}

// MARK: - Codable

extension InstrumentTable: Codable {

    // MARK: Public Initializers

    /// Creates an instrument table by decoding from the provided decoder.
    ///
    /// Entries that exactly duplicate one another — same time, instrument,
    /// and extras — are collapsed, keeping the first occurrence, the same
    /// rule ``insert(time:instrument:extras:)`` applies to a live instrument
    /// table. This is needed here, not just belt and suspenders: a document saved
    /// before that dedup rule existed can have duplicates already baked into
    /// its encoded form, and decoding is the only place left to catch those.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.defaultInstrument = try container.decode(Instrument.self,
                                                      forKey: .defaultInstrument)

        let decodedEntries = try container.decode([StoredEntry].self,
                                                  forKey: .entries)

        self.entries = Self.deduplicated(decodedEntries)
        self.hasExtras = Self.hasExtras(in: entries)
    }

    // MARK: Public Instance Methods

    /// Encodes this instrument table into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encode(entries,
                             forKey: .entries)

        try container.encode(defaultInstrument,
                             forKey: .defaultInstrument)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case defaultInstrument
        case entries
    }
}

// MARK: - RandomAccessCollection

extension InstrumentTable: RandomAccessCollection {

    // MARK: Public Instance Properties

    /// The position one past the last entry in this instrument table.
    public var endIndex: Index {
        Index(entries.endIndex)
    }

    /// The position of the first entry in this instrument table, or ``endIndex`` if this instrument table is
    /// empty.
    public var startIndex: Index {
        Index(entries.startIndex)
    }

    // MARK: Public Instance Subscripts

    /// Returns the entry at the given position.
    ///
    /// - Parameter position:   A valid position in this instrument table, other than ``endIndex``.
    ///
    /// - Returns:  The ``Entry`` at `position`.
    public subscript(position: Index) -> Entry {
        Entry(entries[position.offset])
    }

    // MARK: Public Instance Methods

    /// Returns the number of positions between two positions in this instrument table.
    ///
    /// - Parameter start:  A valid position in this instrument table.
    /// - Parameter end:    Another valid position in this instrument table.
    ///
    /// - Returns:  The distance from `start` to `end`, negative if `end` precedes `start`.
    public func distance(from start: Index,
                         to end: Index) -> Int {
        end.offset - start.offset
    }

    /// Returns a position offset by the given distance from the given position.
    ///
    /// - Parameter index:      A valid position in this instrument table.
    /// - Parameter distance:   The distance to offset `index` by.
    ///
    /// - Returns:  The position `distance` positions from `index`.
    public func index(_ index: Index,
                      offsetBy distance: Int) -> Index {
        Index(index.offset + distance)
    }

    /// Returns the position immediately after the given position.
    ///
    /// - Parameter index:  A valid position in this instrument table, other than ``endIndex``.
    ///
    /// - Returns:  The position after `index`.
    public func index(after index: Index) -> Index {
        Index(index.offset + 1)
    }

    /// Returns the position immediately before the given position.
    ///
    /// - Parameter index:  A valid position in this instrument table, other than ``startIndex``.
    ///
    /// - Returns:  The position before `index`.
    public func index(before index: Index) -> Index {
        Index(index.offset - 1)
    }
}

// MARK: - Sendable

extension InstrumentTable: Sendable {
}

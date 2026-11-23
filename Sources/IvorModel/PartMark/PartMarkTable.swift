// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

internal import XestiTools

/// A time-indexed table of a part’s marks: fermatas not on a note, and caesuras.
///
/// Entries are kept in time order. Entries at the same time keep the order they were inserted
/// in. Only an entry identical to its neighbor at the same time (the same mark) adds nothing, so
/// inserting one folds it into that neighbor.
public struct PartMarkTable<TimeType: TimeProtocol> {

    // MARK: Public Initializers

    /// Creates a new, empty part mark table.
    public init() {
        self.init(entries: [])
    }

    // MARK: Internal Initializers

    internal init(entries: [StoredEntry]) {
        self.entries = entries
    }

    // MARK: Internal Instance Properties

    internal var entries: [StoredEntry]
}

// MARK: -

extension PartMarkTable {

    // MARK: Public Instance Methods

    /// Inserts a mark into this table at the given time, after any entries already at that time.
    ///
    /// If the last entry already at that time is identical, the new entry would add nothing, and
    /// is folded into it instead.
    ///
    /// - Parameter time:   The time of the mark: a caesura’s moment, or the start of a fermata’s
    ///                     span.
    /// - Parameter mark:   The mark to insert.
    ///
    /// - Returns:  A pair of the identity that now addresses this entry — a freshly generated
    ///             identity, unless the insertion folded into the identical entry before it, in
    ///             which case that entry’s identity — and `inserted`, `true` if a new entry was
    ///             added and `false` if it folded instead.
    @discardableResult
    public mutating func insert(time: TimeType,
                                mark: PartMark<TimeType>) -> (entryID: EntryID, inserted: Bool) {
        _insert(StoredEntry(time: time,
                            mark: mark))
    }

    /// Moves the entry with the given identity to a new time, keeping its mark, and re-sorts it
    /// into place after any entries already at that time.
    ///
    /// The one case where `entryID` stops identifying the moved entry afterward is when the move
    /// lands it right after an identical entry — the case ``insert(time:mark:)`` folds. There,
    /// the returned identity is the survivor’s instead.
    ///
    /// - Parameter entryID:    The identity of the entry to move.
    /// - Parameter time:       The new time for the entry.
    ///
    /// - Returns:  The identity that now addresses this entry’s content, or `nil` if `entryID`
    ///             did not identify any entry and nothing moved.
    @discardableResult
    public mutating func move(entryID: EntryID,
                              to time: TimeType) -> EntryID? {
        guard let position = firstIndex(entryID: entryID)
        else { return nil }

        let entry = entries.remove(at: position)

        return _insert(StoredEntry(entryID: entryID,
                                   time: time,
                                   mark: entry.mark)).entryID
    }

    /// Removes the entry with the given identity, if present.
    ///
    /// - Parameter entryID:    The identity of the entry to remove. An identity naming no entry
    ///                         is ignored.
    ///
    /// - Returns:  `true` if `entryID` identified an entry and it was removed, `false` if
    ///             `entryID` named no entry and nothing happened.
    @discardableResult
    public mutating func remove(entryID: EntryID) -> Bool {
        guard let position = firstIndex(entryID: entryID)
        else { return false }

        entries.remove(at: position)

        return true
    }

    /// Replaces the mark of the entry with the given identity, in place.
    ///
    /// Unlike a ``remove(entryID:)`` followed by an ``insert(time:mark:)``, this keeps the
    /// entry’s identity and its place among entries at the same time.
    ///
    /// The edit can make this entry identical to the entry just before or after it. When that
    /// happens, `entryID` keeps addressing the entry that was just updated, and the *other* one
    /// is removed instead, since the caller holds `entryID` and goes on using it.
    ///
    /// - Parameter entryID:    The identity of the entry to update. An identity naming no entry
    ///                         is ignored.
    /// - Parameter mark:       The new mark for the entry.
    ///
    /// - Returns:  A pair of `updated`, `true` if `entryID` identified an entry and it was
    ///             updated — and `removedEntryIDs`, the identities of the neighbors removed
    ///             because the edit made them identical to it: none, one, or both.
    @discardableResult
    public mutating func update(entryID: EntryID,
                                mark: PartMark<TimeType>) -> (updated: Bool, removedEntryIDs: [EntryID]) {
        guard let position = firstIndex(entryID: entryID)
        else { return (false, []) }

        entries[position] = StoredEntry(entryID: entryID,
                                        time: entries[position].time,
                                        mark: mark)

        //
        // The later neighbor goes first, so `position` still addresses the updated entry when
        // checking the earlier one.
        //
        var removedEntryIDs: [EntryID] = []

        if position + 1 < entries.endIndex,
           entries[position + 1] == entries[position] {
            removedEntryIDs.append(entries.remove(at: position + 1).entryID)
        }

        if position > entries.startIndex,
           entries[position - 1] == entries[position] {
            removedEntryIDs.append(entries.remove(at: position - 1).entryID)
        }

        return (true, removedEntryIDs)
    }

    // MARK: Private Instance Methods

    private mutating func _insert(_ entry: StoredEntry) -> (entryID: EntryID, inserted: Bool) {
        let position = insertionIndex(for: entry.time)

        if position > entries.startIndex,
           entries[position - 1] == entry {
            return (entries[position - 1].entryID, false)
        }

        entries.insert(entry,
                       at: position)

        return (entry.entryID, true)
    }
}

// MARK: - Codable

extension PartMarkTable: Codable {

    // MARK: Public Initializers

    /// Creates a part mark table by decoding from the provided decoder.
    ///
    /// The entries are sorted by time, keeping their order at the same time, and an entry
    /// identical to the one before it is folded into it, the same rule ``insert(time:mark:)``
    /// applies to a live table.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let entries = try container.decode([StoredEntry].self,
                                           forKey: .entries)

        //
        // A stable sort, so entries at the same time keep their order:
        //
        let sorted = entries.enumerated().sorted { ($0.element.time, $0.offset) < ($1.element.time, $1.offset) }.map(\.element)

        self.init(entries: Self.deduplicated(sorted))
    }

    // MARK: Public Instance Methods

    /// Encodes this part mark table into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(entries,
                             forKey: .entries)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case entries
    }
}

// MARK: - RandomAccessCollection

extension PartMarkTable: RandomAccessCollection {

    // MARK: Public Instance Properties

    /// The position one past the last entry in this table.
    public var endIndex: Index {
        Index(entries.endIndex)
    }

    /// The position of the first entry in this table, or ``endIndex`` if it is empty.
    public var startIndex: Index {
        Index(entries.startIndex)
    }

    // MARK: Public Instance Subscripts

    /// Returns the entry at the given position.
    ///
    /// - Parameter position:   A valid position in this table, other than ``endIndex``.
    ///
    /// - Returns:  The ``Entry`` at `position`.
    public subscript(position: Index) -> Entry {
        Entry(entries[position.offset])
    }

    // MARK: Public Instance Methods

    /// Returns the number of positions between two positions in this table.
    ///
    /// - Parameter start:  A valid position in this table.
    /// - Parameter end:    Another valid position in this table.
    ///
    /// - Returns:  The distance from `start` to `end`, negative if `end` precedes `start`.
    public func distance(from start: Index,
                         to end: Index) -> Int {
        end.offset - start.offset
    }

    /// Returns a position offset by the given distance from the given position.
    ///
    /// - Parameter index:      A valid position in this table.
    /// - Parameter distance:   The distance to offset `index` by.
    ///
    /// - Returns:  The position `distance` positions from `index`.
    public func index(_ index: Index,
                      offsetBy distance: Int) -> Index {
        Index(index.offset + distance)
    }

    /// Returns the position immediately after the given position.
    ///
    /// - Parameter index:  A valid position in this table, other than ``endIndex``.
    ///
    /// - Returns:  The position after `index`.
    public func index(after index: Index) -> Index {
        Index(index.offset + 1)
    }

    /// Returns the position immediately before the given position.
    ///
    /// - Parameter index:  A valid position in this table, other than ``startIndex``.
    ///
    /// - Returns:  The position before `index`.
    public func index(before index: Index) -> Index {
        Index(index.offset - 1)
    }
}

// MARK: - Sendable

extension PartMarkTable: Sendable {
}

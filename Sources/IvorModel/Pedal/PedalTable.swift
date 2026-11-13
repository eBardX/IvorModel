// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiTools

/// A time-indexed table of one pedal’s levels.
///
/// Each entry is a step: its level holds from its time until the next entry’s. Before the first
/// entry, the pedal is up (``Pedal/Level/up``).
///
/// Entries at the same time keep the order they were inserted in, and the last of them is the
/// level from then on. So a re-pedal — the pedal let up and pressed again at one instant — is an
/// Up entry followed by a Down entry at the same time, and both are kept. Only an entry identical
/// to its neighbor at the same time (same level and extras) adds nothing, so inserting one folds
/// it into that neighbor.
public struct PedalTable<TimeType: TimeProtocol> {

    // MARK: Public Initializers

    /// Creates a new, empty pedal table.
    public init() {
        self.init(entries: [])
    }

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether any entry in this pedal table
    /// carries extra data.
    public private(set) var hasExtras: Bool

    // MARK: Internal Initializers

    internal init(entries: [StoredEntry]) {
        self.entries = entries
        self.hasExtras = Self.hasExtras(in: entries)
    }

    // MARK: Internal Instance Properties

    internal var entries: [StoredEntry]
}

// MARK: -

extension PedalTable {

    // MARK: Public Instance Subscripts

    /// Returns the pedal level in effect at the given time.
    ///
    /// - Parameter time:   The time at which to query the level.
    ///
    /// - Returns:  The level of the last entry at or before `time` (the last of several at the
    ///             same time), or ``Pedal/Level/up`` if there is none.
    public subscript(_ time: TimeType) -> Pedal.Level {
        guard let idx = entries.firstIndex(where: { time < $0.time })
        else { return entries.last?.level ?? .up }

        guard idx > 0
        else { return .up }

        return entries[idx - 1].level
    }

    // MARK: Public Instance Methods

    /// Inserts a pedal entry into this pedal table at the given time, after any entries already
    /// at that time.
    ///
    /// If the last entry already at that time is identical — same level and extras — the new
    /// entry would add nothing, and is folded into it instead. An identical entry earlier among
    /// those at that time doesn’t count: in Down, Up, Down, the second Down is what puts the pedal
    /// back down.
    ///
    /// - Parameter time:       The time at which the level takes effect.
    /// - Parameter level:      The level to insert.
    /// - Parameter extras:     Optional extra data attached to the entry.
    ///                         Defaults to `nil`.
    ///
    /// - Returns:  A pair of the identity that now addresses this entry — a freshly generated
    ///             identity, unless the insertion folded into the identical entry before it, in
    ///             which case that entry’s identity — and `inserted`, `true` if a new entry was
    ///             added and `false` if it folded instead.
    @discardableResult
    public mutating func insert(time: TimeType,
                                level: Pedal.Level,
                                extras: Extras? = nil) -> (entryID: EntryID, inserted: Bool) {
        _insert(entryID: EntryID(),
                time: time,
                level: level,
                extras: extras)
    }

    /// Inserts a pedal entry into this pedal table immediately before another entry at the same
    /// time.
    ///
    /// This is how a re-pedal is added where a pedal goes down: an Up entry inserted before the
    /// Down entry lets the pedal up and presses it again at that instant.
    ///
    /// If an entry it would be placed next to — the anchor, or the entry just before it — is
    /// identical (same time, level and extras), the new entry would add nothing, and is folded
    /// into that entry instead.
    ///
    /// - Parameter time:       The time at which the level takes effect. It must be the time of
    ///                         the entry identified by `anchorID`.
    /// - Parameter level:      The level to insert.
    /// - Parameter extras:     Optional extra data attached to the entry.
    ///                         Defaults to `nil`.
    /// - Parameter anchorID:   The identity of the entry to insert before.
    ///
    /// - Returns:  A pair of the identity that now addresses this entry — a freshly generated
    ///             identity, unless the insertion folded into an identical neighbor, in which case
    ///             that neighbor’s identity — and `inserted`, `true` if a new entry was added and
    ///             `false` if it folded instead.
    ///
    /// - Throws:   ``PedalTable/Error/invalidAnchor`` if no entry has the identity `anchorID`,
    ///             or if that entry is not at `time`.
    @discardableResult
    public mutating func insert(time: TimeType,
                                level: Pedal.Level,
                                extras: Extras? = nil,
                                before anchorID: EntryID) throws(Error) -> (entryID: EntryID, inserted: Bool) {
        guard let position = firstIndex(entryID: anchorID),
              entries[position].time == time
        else { throw Error.invalidAnchor }

        let entry = StoredEntry(time: time,
                                level: level,
                                extras: extras)

        if entries[position] == entry {
            return (anchorID, false)
        }

        if position > entries.startIndex,
           entries[position - 1] == entry {
            return (entries[position - 1].entryID, false)
        }

        entries.insert(entry,
                       at: position)

        if extras != nil {
            hasExtras = true
        }

        return (entry.entryID, true)
    }

    /// Moves the pedal entry with the given identity to a new time, keeping its level and extras,
    /// and re-sorts it into place after any entries already at that time.
    ///
    /// The one case where `entryID` stops identifying the moved entry afterward is when the move
    /// lands it right after an identical entry — the case ``insert(time:level:extras:)`` folds.
    /// There, the moved entry folds into that entry, and the returned identity is the survivor’s
    /// instead, which a caller must switch to addressing from then on.
    ///
    /// - Parameter entryID:    The identity of the entry to move.
    /// - Parameter time:       The new time for the entry.
    ///
    /// - Returns:  The identity that now addresses this entry’s content — `entryID` itself,
    ///             unless the move folded it into an identical entry, in which case the
    ///             survivor’s identity. `nil` if `entryID` did not identify any entry and nothing
    ///             moved.
    @discardableResult
    public mutating func move(entryID: EntryID,
                              to time: TimeType) -> EntryID? {
        guard let position = firstIndex(entryID: entryID)
        else { return nil }

        let entry = entries.remove(at: position)

        let (newID, _) = _insert(entryID: entryID,
                                 time: time,
                                 level: entry.level,
                                 extras: entry.extras)

        hasExtras = Self.hasExtras(in: entries)

        return newID
    }

    /// Removes the pedal entry with the given identity, if present.
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

    /// Replaces the pedal entry with the given identity, in place.
    ///
    /// Unlike a ``remove(entryID:)`` followed by an ``insert(time:level:extras:)``, this keeps
    /// the entry’s identity and its place among entries at the same time.
    ///
    /// The edit can make this entry identical to the entry just before or after it — the
    /// combination ``insert(time:level:extras:)`` folds. When that happens, `entryID` keeps
    /// addressing the entry that was just updated, and the *other* one is removed instead, since
    /// the caller holds `entryID` and goes on using it.
    ///
    /// - Parameter entryID:    The identity of the entry to replace. An
    ///                         identity naming no entry is ignored.
    /// - Parameter level:      The new level for the entry.
    /// - Parameter extras:     The new optional extra data for the entry.
    ///                         Defaults to `nil`.
    ///
    /// - Returns:  A pair of `updated`, `true` if `entryID` identified an entry and it was
    ///             updated, `false` if `entryID` named no entry and nothing happened — and
    ///             `removedEntryIDs`, the identities of the neighbors removed because the edit
    ///             made them identical to it (see above): none, one, or both.
    @discardableResult
    public mutating func update(entryID: EntryID,
                                level: Pedal.Level,
                                extras: Extras? = nil) -> (updated: Bool, removedEntryIDs: [EntryID]) {
        guard let position = firstIndex(entryID: entryID)
        else { return (false, []) }

        entries[position] = StoredEntry(entryID: entryID,
                                        time: entries[position].time,
                                        level: level,
                                        extras: extras)

        //
        // `StoredEntry`'s own `==` excludes identity (and two equal entries share a time, so
        // they can only be neighbors among same-time entries). The later neighbor goes first, so
        // `position` still addresses the updated entry when checking the earlier one.
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

        hasExtras = Self.hasExtras(in: entries)

        return (true, removedEntryIDs)
    }

    // MARK: Internal Instance Methods

    //
    // The entry that ends a press under way at the end of `range`: the first entry strictly after
    // `range.upperBound`, if the pedal is down there (by the last entry at that time); otherwise
    // `nil`. A transform of selected notes carries this entry with them, so that moving a
    // selection doesn't leave its release behind.
    //
    internal func pressEnd(after range: ClosedRange<TimeType>) -> EntryID? {
        guard self[range.upperBound].isDown
        else { return nil }

        return entries.first { $0.time > range.upperBound }?.entryID
    }

    // MARK: Private Instance Methods

    @discardableResult
    private mutating func _insert(entryID: EntryID,
                                  time: TimeType,
                                  level: Pedal.Level,
                                  extras: Extras?) -> (entryID: EntryID, inserted: Bool) {
        let entry = StoredEntry(entryID: entryID,
                                time: time,
                                level: level,
                                extras: extras)
        let position = insertionIndex(for: time)

        if position > entries.startIndex,
           entries[position - 1] == entry {
            return (entries[position - 1].entryID, false)
        }

        entries.insert(entry,
                       at: position)

        if extras != nil {
            hasExtras = true
        }

        return (entryID, true)
    }
}

// MARK: - Codable

extension PedalTable: Codable {

    // MARK: Public Initializers

    /// Creates a pedal table by decoding from the provided decoder.
    ///
    /// An entry identical to the one before it — same time, level, and extras — is folded into
    /// it, the same rule ``insert(time:level:extras:)`` applies to a live pedal table.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let decodedEntries = try container.decode([StoredEntry].self,
                                                  forKey: .entries)

        self.entries = Self.deduplicated(decodedEntries)
        self.hasExtras = Self.hasExtras(in: entries)
    }

    // MARK: Public Instance Methods

    /// Encodes this pedal table into the provided encoder.
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

extension PedalTable: RandomAccessCollection {

    // MARK: Public Instance Properties

    /// The position one past the last entry in this pedal table.
    public var endIndex: Index {
        Index(entries.endIndex)
    }

    /// The position of the first entry in this pedal table, or ``endIndex`` if this pedal table is
    /// empty.
    public var startIndex: Index {
        Index(entries.startIndex)
    }

    // MARK: Public Instance Subscripts

    /// Returns the entry at the given position.
    ///
    /// - Parameter position:   A valid position in this pedal table, other than ``endIndex``.
    ///
    /// - Returns:  The ``Entry`` at `position`.
    public subscript(position: Index) -> Entry {
        Entry(entries[position.offset])
    }

    // MARK: Public Instance Methods

    /// Returns the number of positions between two positions in this pedal table.
    ///
    /// - Parameter start:  A valid position in this pedal table.
    /// - Parameter end:    Another valid position in this pedal table.
    ///
    /// - Returns:  The distance from `start` to `end`, negative if `end` precedes `start`.
    public func distance(from start: Index,
                         to end: Index) -> Int {
        end.offset - start.offset
    }

    /// Returns a position offset by the given distance from the given position.
    ///
    /// - Parameter index:      A valid position in this pedal table.
    /// - Parameter distance:   The distance to offset `index` by.
    ///
    /// - Returns:  The position `distance` positions from `index`.
    public func index(_ index: Index,
                      offsetBy distance: Int) -> Index {
        Index(index.offset + distance)
    }

    /// Returns the position immediately after the given position.
    ///
    /// - Parameter index:  A valid position in this pedal table, other than ``endIndex``.
    ///
    /// - Returns:  The position after `index`.
    public func index(after index: Index) -> Index {
        Index(index.offset + 1)
    }

    /// Returns the position immediately before the given position.
    ///
    /// - Parameter index:  A valid position in this pedal table, other than ``startIndex``.
    ///
    /// - Returns:  The position before `index`.
    public func index(before index: Index) -> Index {
        Index(index.offset - 1)
    }
}

// MARK: - Sendable

extension PedalTable: Sendable {
}

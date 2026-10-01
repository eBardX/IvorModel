// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiTools

private import XestiNumbers

/// A time-indexed map of spatial pan positions with a configurable default.
public struct PanMap<TimeType: TimeProtocol> {

    // MARK: Public Initializers

    /// Creates a new, empty pan map with the given default pan position.
    ///
    /// - Parameter defaultPan: The pan position returned when the pan map is empty.
    ///                         Defaults to `.center`.
    public init(defaultPan: Pan = .center) {
        self.init(defaultPan: defaultPan,
                  entries: [])
    }

    // MARK: Public Instance Properties

    /// The pan position returned when this pan map contains no entries.
    public let defaultPan: Pan

    /// A Boolean value indicating whether any entry in this pan map carries
    /// extra data.
    public private(set) var hasExtras: Bool

    // MARK: Internal Initializers

    internal init(defaultPan: Pan,
                  entries: [StoredEntry]) {
        self.defaultPan = defaultPan
        self.entries = entries
        self.hasExtras = Self.hasExtras(in: entries)
    }

    // MARK: Internal Instance Properties

    internal var entries: [StoredEntry]
}

// MARK: -

extension PanMap {

    // MARK: Public Instance Subscripts

    /// Returns the interpolated pan position in effect at the given time.
    ///
    /// Between two entries, the horizontal and vertical angles are each
    /// interpolated linearly along the *shortest* rotation from one entry’s
    /// angle to the next; an exact half-turn rotates clockwise (toward
    /// increasing angles). A move of more than 180° in either angle — or a
    /// full revolution — therefore needs intermediate entries to spell out
    /// its path.
    ///
    /// - Parameter time:   The time at which to query the pan position.
    ///
    /// - Returns:  The interpolated ``Pan`` value at `time`, or
    ///             ``defaultPan`` if this pan map is empty.
    public subscript(_ time: TimeType) -> Pan {
        guard !entries.isEmpty
        else { return defaultPan }

        guard let idx = entries.firstIndex(where: { time < $0.time })
        else { return entries[entries.endIndex - 1].pan }

        guard idx > 0
        else { return entries[0].pan }

        let startEntry = entries[idx - 1]
        let endEntry = entries[idx]

        let fraction = time.fraction(from: startEntry.time,
                                     through: endEntry.time)

        guard fraction > 0
        else { return startEntry.pan }

        return Pan(horizontal: Self._interpolate(from: startEntry.pan.horizontal,
                                                 to: endEntry.pan.horizontal,
                                                 fraction: fraction),
                   vertical: Self._interpolate(from: startEntry.pan.vertical,
                                               to: endEntry.pan.vertical,
                                               fraction: fraction))
    }

    // MARK: Public Instance Methods

    /// Inserts a pan entry into this pan map at the given time.
    ///
    /// An entry that exactly duplicates one already present — same time, pan
    /// position, and extras — carries no information beyond the original and
    /// is silently ignored. Two entries at the same time with *different*
    /// pan positions are a deliberate, meaningful step (interpolation jumps
    /// instantly at that time), and are unaffected by this check.
    ///
    /// - Parameter time:   The time at which the pan position takes effect.
    /// - Parameter pan:    The pan position to insert.
    /// - Parameter extras: Optional extra data attached to the entry. Defaults
    ///                     to `nil`.
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
                                pan: Pan,
                                extras: Extras? = nil) -> (entryID: EntryID, inserted: Bool) {
        _insert(entryID: EntryID(),
                time: time,
                pan: pan,
                extras: extras)
    }

    /// Merges the entries from another pan map into this pan map.
    ///
    /// - Parameter other:  The pan map whose entries are merged into this pan
    ///                     map.
    public mutating func merge(with other: Self) {
        guard !other.entries.isEmpty
        else { return }

        guard !entries.isEmpty
        else { self = other; return }

        entries.append(contentsOf: other.entries)
        entries.sort()

        hasExtras = hasExtras || other.hasExtras
    }

    /// Moves the pan entry with the given identity to a new time, keeping
    /// its pan position and extras, and re-sorts it into place.
    ///
    /// Unlike ``update(entryID:pan:extras:)``, this is expected to reorder
    /// entries — that is the point of editing the time itself. Two entries
    /// legitimately ending up at the same time (see
    /// ``insert(time:pan:extras:)`` for the discontinuity use case) is not
    /// treated as a collision to reject; the moved entry simply takes its
    /// place among any others already there, exactly as a fresh insertion
    /// would.
    ///
    /// The one case where `entryID` stops identifying the moved entry afterward is
    /// when the move lands it exactly on top of another entry already
    /// present — same time, pan position, and extras — the same
    /// exact-duplicate case ``insert(time:pan:extras:)`` silently collapses.
    /// There, the moved entry merges into that pre-existing one instead of
    /// being kept separately, so `entryID` no longer names anything in the map;
    /// the returned identity is the survivor’s instead, which a caller must
    /// switch to addressing from then on.
    ///
    /// - Parameter entryID: The identity of the entry to move.
    /// - Parameter time:    The new time for the entry.
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
                                 pan: entry.pan,
                                 extras: entry.extras)

        hasExtras = Self.hasExtras(in: entries)

        return newID
    }

    /// Removes the pan entry with the given identity, if present.
    ///
    /// - Parameter entryID:  The identity of the entry to remove. An identity
    ///                       naming no entry is ignored.
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

    /// Replaces the pan entry with the given identity, in place.
    ///
    /// Unlike a ``remove(entryID:)`` followed by an ``insert(time:pan:extras:)``, this
    /// keeps the entry’s identity and does not reorder entries. Reordering only matters when more
    /// than one entry shares a time: insertion always lands after every entry already at that
    /// time, so a remove-then-insert edit of one entry among ties silently changes the order of
    /// entries that were never touched. And — unlike a position — the identity keeps addressing
    /// this same entry across any other entry’s edit, so a caller never needs to re-resolve it
    /// first.
    ///
    /// The edit can turn this entry into an exact duplicate of another one
    /// already at the same time — same time, pan position, and extras —
    /// the same combination ``insert(time:pan:extras:)`` silently
    /// collapses. When that happens, `entryID` always keeps addressing the
    /// entry that was just updated; the *other*, pre-existing entry is the
    /// one silently removed instead. That is the only choice consistent
    /// with the guarantee above: a caller invoking this method already
    /// holds `entryID` and goes on using it afterward, so honoring “this
    /// identity keeps addressing this same entry” means the entry it
    /// wasn’t referencing has to be the one that gives way, never the one
    /// it was.
    ///
    /// - Parameter entryID: The identity of the entry to replace. An
    ///                      identity naming no entry is ignored.
    /// - Parameter pan:     The new pan position for the entry.
    /// - Parameter extras:  The new optional extra data for the entry.
    ///                      Defaults to `nil`.
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
                                pan: Pan,
                                extras: Extras? = nil) -> (updated: Bool, removedEntryID: EntryID?) {
        guard let position = firstIndex(entryID: entryID)
        else { return (false, nil) }

        entries[position] = StoredEntry(entryID: entryID,
                                        time: entries[position].time,
                                        pan: pan,
                                        extras: extras)

        //
        // The edit may have turned this entry into an exact duplicate of another
        // one already at the same time — see `insert(time:pan:extras:)` for why
        // that combination carries no information beyond a single entry. Drop
        // the other one rather than leave the duplicate in place. `StoredEntry`'s own
        // `==` already excludes identity, so comparing whole entries is enough
        // to find one that only *differs* in which entry it is.
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

    // MARK: Private Type Methods

    private static func _interpolate(from start: Pan.Angle,
                                     to end: Pan.Angle,
                                     fraction: Double) -> Pan.Angle {
        let rotation = (end - start).doubleValue

        return Pan.Angle(Number(start.doubleValue + rotation * fraction))
    }

    // MARK: Private Instance Methods

    @discardableResult
    private mutating func _insert(entryID: EntryID,
                                  time: TimeType,
                                  pan: Pan,
                                  extras: Extras?) -> (entryID: EntryID, inserted: Bool) {
        if let existing = firstIndex(time: time,
                                     pan: pan,
                                     extras: extras) {
            return (entries[existing].entryID, false)
        }

        entries.insert(StoredEntry(entryID: entryID,
                                   time: time,
                                   pan: pan,
                                   extras: extras),
                       at: insertionIndex(for: time))

        if extras != nil {
            hasExtras = true
        }

        return (entryID, true)
    }
}

// MARK: - Codable

extension PanMap: Codable {
    /// Creates a pan map by decoding from the provided decoder.
    ///
    /// Entries that exactly duplicate one another — same time, pan position,
    /// and extras — are collapsed, keeping the first occurrence, the same rule
    /// ``insert(time:pan:extras:)`` applies to a live pan map. This is needed
    /// here, not just belt and suspenders: a document saved before that dedup rule
    /// existed can have duplicates already baked into its encoded form, and
    /// decoding is the only place left to catch those.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.defaultPan = try container.decode(Pan.self,
                                               forKey: .defaultPan)

        let decodedEntries = try container.decode([StoredEntry].self,
                                                  forKey: .entries)

        self.entries = Self.deduplicated(decodedEntries)
        self.hasExtras = Self.hasExtras(in: entries)
    }

    /// Encodes this pan map into the provided encoder.
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

        try container.encode(defaultPan,
                             forKey: .defaultPan)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case defaultPan
        case entries
    }
}

// MARK: - RandomAccessCollection

extension PanMap: RandomAccessCollection {

    // MARK: Public Instance Properties

    /// The position one past the last entry in this pan map.
    public var endIndex: Index {
        Index(entries.endIndex)
    }

    /// The position of the first entry in this pan map, or ``endIndex`` if this pan map is
    /// empty.
    public var startIndex: Index {
        Index(entries.startIndex)
    }

    // MARK: Public Instance Subscripts

    /// Returns the entry at the given position.
    ///
    /// - Parameter position:   A valid position in this pan map, other than ``endIndex``.
    ///
    /// - Returns:  The ``Entry`` at `position`.
    public subscript(position: Index) -> Entry {
        Entry(entries[position.offset])
    }

    // MARK: Public Instance Methods

    /// Returns the number of positions between two positions in this pan map.
    ///
    /// - Parameter start:  A valid position in this pan map.
    /// - Parameter end:    Another valid position in this pan map.
    ///
    /// - Returns:  The distance from `start` to `end`, negative if `end` precedes `start`.
    public func distance(from start: Index,
                         to end: Index) -> Int {
        end.offset - start.offset
    }

    /// Returns a position offset by the given distance from the given position.
    ///
    /// - Parameter index:      A valid position in this pan map.
    /// - Parameter distance:   The distance to offset `index` by.
    ///
    /// - Returns:  The position `distance` positions from `index`.
    public func index(_ index: Index,
                      offsetBy distance: Int) -> Index {
        Index(index.offset + distance)
    }

    /// Returns the position immediately after the given position.
    ///
    /// - Parameter index:  A valid position in this pan map, other than ``endIndex``.
    ///
    /// - Returns:  The position after `index`.
    public func index(after index: Index) -> Index {
        Index(index.offset + 1)
    }

    /// Returns the position immediately before the given position.
    ///
    /// - Parameter index:  A valid position in this pan map, other than ``startIndex``.
    ///
    /// - Returns:  The position before `index`.
    public func index(before index: Index) -> Index {
        Index(index.offset - 1)
    }
}

// MARK: - Sendable

extension PanMap: Sendable {
}

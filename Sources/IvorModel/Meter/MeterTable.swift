// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiTools

/// A beat-time table of meters: where each meter takes effect, and the pickup before the first
/// full bar.
///
/// Each entry starts a new bar with its ``Meter``. Bars of that meter follow one another until the
/// next entry; if the bar that the next entry falls in is cut off before it reaches its full
/// length, it’s a *short bar*. An entry with the same meter as the one before it, which doesn’t
/// fall on a barline the earlier entry would have drawn anyway, is a *restart*: it exists to make
/// the bar before it short. A free meter’s whole span, up to the next entry, is one bar with no
/// pulse. Before the first entry there are no bars.
///
/// The ``pickup`` is the length of an opening part-bar, *bar 0*, when the first entry is a metered
/// meter at time 0. Its beats are counted as the tail of a full bar: a one-beat pickup in 3/4 is
/// beat 3. Bars are numbered from 1, starting after the pickup, and every later bar — short or
/// free — adds 1.
///
/// Unlike the parameter maps, a meter table never interpolates, and unlike the other tables, it
/// lives on the work, not on a part, and only in beat time. Its invariants hold after every
/// mutating method, and decoding rejects a table that breaks them:
///
/// 1. There’s at most one entry per beat time.
/// 2. The pickup is 0 unless there’s an entry at time 0 with a metered meter.
/// 3. The pickup is shorter than that meter’s bar length, and ends no later than the second
///    entry, if there is one.
public struct MeterTable {

    // MARK: Public Initializers

    /// Creates a new, empty meter table, with no pickup.
    public init() {
        self.init(entries: [],
                  pickup: .zero)
    }

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether any entry in this meter table carries extra data.
    public internal(set) var hasExtras: Bool

    /// The length of the pickup bar, bar 0, that runs from time 0 up to the first full bar; zero
    /// if there’s none.
    ///
    /// Use ``setPickup(_:)`` to change it.
    public internal(set) var pickup: BeatDuration

    // MARK: Internal Initializers

    internal init(entries: [StoredEntry],
                  pickup: BeatDuration) {
        self.entries = entries
        self.hasExtras = Self.hasExtras(in: entries)
        self.pickup = pickup
    }

    // MARK: Internal Instance Properties

    internal var entries: [StoredEntry]
}

// MARK: -

extension MeterTable {

    // MARK: Public Instance Methods

    /// Inserts a meter entry into this meter table, starting a new bar at the given beat time.
    ///
    /// - Parameter beatTime:   The beat time at which the meter takes effect.
    /// - Parameter meter:      The meter to insert.
    /// - Parameter extras:     Optional extra data attached to the entry. Defaults to `nil`.
    ///
    /// - Returns:  The identity of the new entry.
    ///
    /// - Throws:   ``MeterTable/Error/entryExists(_:)`` if an entry already sits at `beatTime`;
    ///             ``MeterTable/Error/invalidPickup`` if `beatTime` falls inside the pickup bar.
    @discardableResult
    public mutating func insert(beatTime: BeatTime,
                                meter: Meter,
                                extras: Extras? = nil) throws(Error) -> EntryID {
        guard entryIndex(at: beatTime) == nil
        else { throw Error.entryExists(beatTime) }

        let entry = StoredEntry(beatTime: beatTime,
                                meter: meter,
                                extras: extras)
        var newEntries = entries

        newEntries.insert(entry,
                          at: insertionIndex(for: beatTime))

        guard Self.isValid(pickup: pickup,
                           for: newEntries)
        else { throw Error.invalidPickup }

        entries = newEntries

        if entry.extras != nil {
            hasExtras = true
        }

        return entry.entryID
    }

    /// Moves the meter entry with the given identity to a new beat time, keeping its identity,
    /// meter and extras.
    ///
    /// Moving the entry at time 0 elsewhere resets the pickup to zero, as removing it does.
    ///
    /// - Parameter entryID:    The identity of the entry to move.
    /// - Parameter beatTime:   The new beat time for the entry.
    ///
    /// - Returns:  `true` if `entryID` identified an entry, `false` if it named no entry and
    ///             nothing happened.
    ///
    /// - Throws:   ``MeterTable/Error/entryExists(_:)`` if another entry already sits at
    ///             `beatTime`; ``MeterTable/Error/invalidPickup`` if the move would put the entry
    ///             inside the pickup bar.
    @discardableResult
    public mutating func move(entryID: EntryID,
                              to beatTime: BeatTime) throws(Error) -> Bool {
        guard let position = firstIndex(entryID: entryID)
        else { return false }

        let entry = entries[position]

        guard entry.beatTime != beatTime
        else { return true }

        guard entryIndex(at: beatTime) == nil
        else { throw Error.entryExists(beatTime) }

        var newEntries = entries

        newEntries.remove(at: position)

        let newPickup: BeatDuration = entry.beatTime == .zero ? .zero : pickup
        let insertAt = newEntries.firstIndex { beatTime < $0.beatTime } ?? newEntries.endIndex

        newEntries.insert(entry.moved(to: beatTime),
                          at: insertAt)

        guard Self.isValid(pickup: newPickup,
                           for: newEntries)
        else { throw Error.invalidPickup }

        entries = newEntries
        pickup = newPickup

        return true
    }

    /// Removes the meter entry with the given identity, if present.
    ///
    /// Removing the entry at time 0 resets the pickup to zero.
    ///
    /// - Parameter entryID:    The identity of the entry to remove. An identity naming no entry is
    ///                         ignored.
    ///
    /// - Returns:  `true` if `entryID` identified an entry and it was removed, `false` if
    ///             `entryID` named no entry and nothing happened.
    @discardableResult
    public mutating func remove(entryID: EntryID) -> Bool {
        guard let position = firstIndex(entryID: entryID)
        else { return false }

        let entry = entries.remove(at: position)

        if entry.beatTime == .zero {
            pickup = .zero
        }

        hasExtras = Self.hasExtras(in: entries)

        return true
    }

    /// Sets the length of the pickup bar.
    ///
    /// - Parameter pickup: The new pickup length, or zero for none.
    ///
    /// - Throws:   ``MeterTable/Error/invalidPickup`` if `pickup` is non-zero and there’s no
    ///             metered entry at time 0, if it isn’t shorter than that entry’s bar length, or if
    ///             it ends after the second entry.
    public mutating func setPickup(_ pickup: BeatDuration) throws(Error) {
        guard Self.isValid(pickup: pickup,
                           for: entries)
        else { throw Error.invalidPickup }

        self.pickup = pickup
    }

    /// Replaces the meter and extras of the entry with the given identity, in place, keeping its
    /// identity and beat time.
    ///
    /// - Parameter entryID:    The identity of the entry to update.
    /// - Parameter meter:      The new meter for the entry.
    /// - Parameter extras:     The new optional extra data for the entry. Defaults to `nil`.
    ///
    /// - Returns:  `true` if `entryID` identified an entry and it was updated, `false` if it named
    ///             no entry and nothing happened.
    ///
    /// - Throws:   ``MeterTable/Error/invalidPickup`` if the entry is at time 0 and the new meter
    ///             can’t hold the current pickup: it’s free, or its bar isn’t longer than the
    ///             pickup.
    @discardableResult
    public mutating func update(entryID: EntryID,
                                meter: Meter,
                                extras: Extras? = nil) throws(Error) -> Bool {
        guard let position = firstIndex(entryID: entryID)
        else { return false }

        var newEntries = entries

        newEntries[position] = StoredEntry(entryID: entryID,
                                           beatTime: entries[position].beatTime,
                                           meter: meter,
                                           extras: extras)

        guard Self.isValid(pickup: pickup,
                           for: newEntries)
        else { throw Error.invalidPickup }

        entries = newEntries
        hasExtras = Self.hasExtras(in: entries)

        return true
    }
}

// MARK: - Codable

extension MeterTable: Codable {

    // MARK: Public Initializers

    /// Creates a meter table by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted, or if it describes
    ///             a meter table that breaks the table’s invariants: entries out of order or
    ///             sharing a beat time, or an invalid pickup.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let decodedEntries = try container.decode([StoredEntry].self,
                                                  forKey: .entries)

        guard zip(decodedEntries, decodedEntries.dropFirst()).allSatisfy({ $0.beatTime < $1.beatTime })
        else { throw DecodingError.dataCorruptedError(forKey: .entries,
                                                      in: container,
                                                      debugDescription: "Meter table entries out of order or sharing a beat time") }

        let decodedPickup = try container.decode(BeatDuration.self,
                                                 forKey: .pickup)

        guard Self.isValid(pickup: decodedPickup,
                           for: decodedEntries)
        else { throw DecodingError.dataCorruptedError(forKey: .pickup,
                                                      in: container,
                                                      debugDescription: "Invalid meter table pickup: \(decodedPickup)") }

        self.init(entries: decodedEntries,
                  pickup: decodedPickup)
    }

    // MARK: Public Instance Methods

    /// Encodes this meter table into the provided encoder.
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

        try container.encode(pickup,
                             forKey: .pickup)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case entries
        case pickup
    }
}

// MARK: - Equatable

extension MeterTable: Equatable {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether two meter tables have the same content: the
    /// same pickup, and the same entries — beat times, meters and extras — in the same order.
    /// Entry identities aren’t compared.
    ///
    /// - Parameter lhs:    The left-hand meter table.
    /// - Parameter rhs:    The right-hand meter table.
    ///
    /// - Returns:  `true` if `lhs` and `rhs` have the same content.
    public static func == (lhs: Self,
                           rhs: Self) -> Bool {
        lhs.pickup == rhs.pickup && lhs.entries == rhs.entries
    }
}

// MARK: - Hashable

extension MeterTable: Hashable {

    // MARK: Public Instance Methods

    /// Hashes the content of this meter table — its pickup, and its entries’ beat times and
    /// meters — into the given hasher.
    ///
    /// - Parameter hasher: The hasher to use when combining the components of this meter table.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(pickup)
        hasher.combine(entries.count)

        for entry in entries {
            hasher.combine(entry.beatTime)
            hasher.combine(entry.meter)
        }
    }
}

// MARK: - RandomAccessCollection

extension MeterTable: RandomAccessCollection {

    // MARK: Public Instance Properties

    /// The position one past the last entry in this meter table.
    public var endIndex: Index {
        Index(entries.endIndex)
    }

    /// The position of the first entry in this meter table, or ``endIndex`` if this meter table is
    /// empty.
    public var startIndex: Index {
        Index(entries.startIndex)
    }

    // MARK: Public Instance Subscripts

    /// Returns the entry at the given position.
    ///
    /// - Parameter position:   A valid position in this meter table, other than ``endIndex``.
    ///
    /// - Returns:  The ``Entry`` at `position`.
    public subscript(position: Index) -> Entry {
        Entry(entries[position.offset])
    }

    // MARK: Public Instance Methods

    /// Returns the number of positions between two positions in this meter table.
    ///
    /// - Parameter start:  A valid position in this meter table.
    /// - Parameter end:    Another valid position in this meter table.
    ///
    /// - Returns:  The distance from `start` to `end`, negative if `end` precedes `start`.
    public func distance(from start: Index,
                         to end: Index) -> Int {
        end.offset - start.offset
    }

    /// Returns a position offset by the given distance from the given position.
    ///
    /// - Parameter index:      A valid position in this meter table.
    /// - Parameter distance:   The distance to offset `index` by.
    ///
    /// - Returns:  The position `distance` positions from `index`.
    public func index(_ index: Index,
                      offsetBy distance: Int) -> Index {
        Index(index.offset + distance)
    }

    /// Returns the position immediately after the given position.
    ///
    /// - Parameter index:  A valid position in this meter table, other than ``endIndex``.
    ///
    /// - Returns:  The position after `index`.
    public func index(after index: Index) -> Index {
        Index(index.offset + 1)
    }

    /// Returns the position immediately before the given position.
    ///
    /// - Parameter index:  A valid position in this meter table, other than ``startIndex``.
    ///
    /// - Returns:  The position before `index`.
    public func index(before index: Index) -> Index {
        Index(index.offset - 1)
    }
}

// MARK: - Sendable

extension MeterTable: Sendable {
}

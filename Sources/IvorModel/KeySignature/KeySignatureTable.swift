// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning
public import XestiTools

/// A beat-time table of key signatures: where each key signature takes effect.
///
/// Each entry’s `KeySignature` is in effect from its beat time until the next entry. Before the
/// first entry there’s no key signature at all, which is distinct from one with no sharps or
/// flats. The first entry needn’t be at time 0.
///
/// A key signature is descriptive: it never decides how a note is spelled, shown or played, and
/// nothing checks that notes fit it. It’s work-wide and at concert pitch, and, like the meter
/// table, it lives on the work, not on a part, and only in beat time. Entries may fall at any beat
/// time, with nothing tying them to the meter table’s barlines, and an entry may repeat the key
/// signature before it.
///
/// Its one invariant holds after every mutating method, and decoding rejects a table that breaks
/// it: there’s at most one entry per beat time.
public struct KeySignatureTable {

    // MARK: Public Initializers

    /// Creates a new, empty key signature table.
    public init() {
        self.init(entries: [])
    }

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether any entry in this key signature table carries extra
    /// data.
    public internal(set) var hasExtras: Bool

    // MARK: Internal Initializers

    internal init(entries: [StoredEntry]) {
        self.entries = entries
        self.hasExtras = Self.hasExtras(in: entries)
    }

    // MARK: Internal Instance Properties

    internal var entries: [StoredEntry]
}

// MARK: -

extension KeySignatureTable {

    // MARK: Public Instance Methods

    /// Inserts a key signature entry into this key signature table at the given beat time.
    ///
    /// - Parameter beatTime:       The beat time at which the key signature takes effect.
    /// - Parameter keySignature:   The key signature to insert.
    /// - Parameter extras:         Optional extra data attached to the entry, such as
    ///                             ``Extra/keySignatureMode``. Defaults to `nil`.
    ///
    /// - Returns:  The identity of the new entry.
    ///
    /// - Throws:   ``KeySignatureTable/Error/entryExists(_:)`` if an entry already sits at
    ///             `beatTime`.
    @discardableResult
    public mutating func insert(beatTime: BeatTime,
                                keySignature: KeySignature,
                                extras: Extras? = nil) throws(Error) -> EntryID {
        guard entryIndex(at: beatTime) == nil
        else { throw Error.entryExists(beatTime) }

        let entry = StoredEntry(beatTime: beatTime,
                                keySignature: keySignature,
                                extras: extras)

        entries.insert(entry,
                       at: insertionIndex(for: beatTime))

        if entry.extras != nil {
            hasExtras = true
        }

        return entry.entryID
    }

    /// Returns the key signature in effect at the given beat time.
    ///
    /// - Parameter beatTime:   The beat time at which to query the key signature.
    ///
    /// - Returns:  The key signature of the last entry at or before `beatTime`, or `nil` if
    ///             there’s none.
    public func keySignature(at beatTime: BeatTime) -> KeySignature? {
        governingIndex(at: beatTime).map { entries[$0].keySignature }
    }

    /// Moves the key signature entry with the given identity to a new beat time, keeping its
    /// identity, key signature and extras.
    ///
    /// - Parameter entryID:    The identity of the entry to move.
    /// - Parameter beatTime:   The new beat time for the entry.
    ///
    /// - Returns:  `true` if `entryID` identified an entry, `false` if it named no entry and
    ///             nothing happened.
    ///
    /// - Throws:   ``KeySignatureTable/Error/entryExists(_:)`` if another entry already sits at
    ///             `beatTime`.
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

        entries.remove(at: position)
        entries.insert(entry.moved(to: beatTime),
                       at: insertionIndex(for: beatTime))

        return true
    }

    /// Removes the key signature entry with the given identity, if present.
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

        entries.remove(at: position)
        hasExtras = Self.hasExtras(in: entries)

        return true
    }

    /// Removes every entry from this key signature table, leaving no key signature anywhere.
    public mutating func removeAll() {
        entries.removeAll()
        hasExtras = false
    }

    /// Replaces the key signature and extras of the entry with the given identity, in place,
    /// keeping its identity and beat time.
    ///
    /// - Parameter entryID:        The identity of the entry to update.
    /// - Parameter keySignature:   The new key signature for the entry.
    /// - Parameter extras:         The new optional extra data for the entry. Defaults to `nil`.
    ///
    /// - Returns:  `true` if `entryID` identified an entry and it was updated, `false` if it named
    ///             no entry and nothing happened.
    @discardableResult
    public mutating func update(entryID: EntryID,
                                keySignature: KeySignature,
                                extras: Extras? = nil) -> Bool {
        guard let position = firstIndex(entryID: entryID)
        else { return false }

        entries[position] = StoredEntry(entryID: entryID,
                                        beatTime: entries[position].beatTime,
                                        keySignature: keySignature,
                                        extras: extras)
        hasExtras = Self.hasExtras(in: entries)

        return true
    }
}

// MARK: - Codable

extension KeySignatureTable: Codable {

    // MARK: Public Initializers

    /// Creates a key signature table by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted, or if its entries
    ///             are out of order or share a beat time.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let decodedEntries = try container.decode([StoredEntry].self,
                                                  forKey: .entries)

        guard zip(decodedEntries, decodedEntries.dropFirst()).allSatisfy({ $0.beatTime < $1.beatTime })
        else { throw DecodingError.dataCorruptedError(forKey: .entries,
                                                      in: container,
                                                      debugDescription: "Key signature table entries out of order or sharing a beat time") }

        self.init(entries: decodedEntries)
    }

    // MARK: Public Instance Methods

    /// Encodes this key signature table into the provided encoder.
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

// MARK: - Equatable

extension KeySignatureTable: Equatable {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether two key signature tables have the same content:
    /// the same entries — beat times, key signatures and extras — in the same order. Entry
    /// identities aren’t compared.
    ///
    /// - Parameter lhs:    The left-hand key signature table.
    /// - Parameter rhs:    The right-hand key signature table.
    ///
    /// - Returns:  `true` if `lhs` and `rhs` have the same content.
    public static func == (lhs: Self,
                           rhs: Self) -> Bool {
        lhs.entries == rhs.entries
    }
}

// MARK: - Hashable

extension KeySignatureTable: Hashable {

    // MARK: Public Instance Methods

    /// Hashes the content of this key signature table — its entries’ beat times and key
    /// signatures — into the given hasher.
    ///
    /// - Parameter hasher: The hasher to use when combining the components of this key signature
    ///                     table.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(entries.count)

        for entry in entries {
            hasher.combine(entry.beatTime)
            hasher.combine(entry.keySignature)
        }
    }
}

// MARK: - RandomAccessCollection

extension KeySignatureTable: RandomAccessCollection {

    // MARK: Public Instance Properties

    /// The position one past the last entry in this key signature table.
    public var endIndex: Index {
        Index(entries.endIndex)
    }

    /// The position of the first entry in this key signature table, or ``endIndex`` if this key
    /// signature table is empty.
    public var startIndex: Index {
        Index(entries.startIndex)
    }

    // MARK: Public Instance Subscripts

    /// Returns the entry at the given position.
    ///
    /// - Parameter position:   A valid position in this key signature table, other than
    ///                         ``endIndex``.
    ///
    /// - Returns:  The ``Entry`` at `position`.
    public subscript(position: Index) -> Entry {
        Entry(entries[position.offset])
    }

    // MARK: Public Instance Methods

    /// Returns the number of positions between two positions in this key signature table.
    ///
    /// - Parameter start:  A valid position in this key signature table.
    /// - Parameter end:    Another valid position in this key signature table.
    ///
    /// - Returns:  The distance from `start` to `end`, negative if `end` precedes `start`.
    public func distance(from start: Index,
                         to end: Index) -> Int {
        end.offset - start.offset
    }

    /// Returns a position offset by the given distance from the given position.
    ///
    /// - Parameter index:      A valid position in this key signature table.
    /// - Parameter distance:   The distance to offset `index` by.
    ///
    /// - Returns:  The position `distance` positions from `index`.
    public func index(_ index: Index,
                      offsetBy distance: Int) -> Index {
        Index(index.offset + distance)
    }

    /// Returns the position immediately after the given position.
    ///
    /// - Parameter index:  A valid position in this key signature table, other than ``endIndex``.
    ///
    /// - Returns:  The position after `index`.
    public func index(after index: Index) -> Index {
        Index(index.offset + 1)
    }

    /// Returns the position immediately before the given position.
    ///
    /// - Parameter index:  A valid position in this key signature table, other than
    ///                     ``startIndex``.
    ///
    /// - Returns:  The position before `index`.
    public func index(before index: Index) -> Index {
        Index(index.offset - 1)
    }
}

// MARK: - Sendable

extension KeySignatureTable: Sendable {
}

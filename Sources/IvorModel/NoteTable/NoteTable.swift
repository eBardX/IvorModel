// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

/// A note table keyed by time and pitch.
public struct NoteTable<TimeType: TimeProtocol, PitchType: PitchProtocol> {

    // MARK: Public Type Aliases

    /// The duration type associated with the time type.
    public typealias DurationType = TimeType.DurationType

    /// The interval type associated with the pitch type.
    public typealias IntervalType = PitchType.IntervalType

    // MARK: Public Initializers

    /// Creates a new, empty note table.
    public init() {
        self.init(notes: [])
    }

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether any note in the note table carries extra data.
    public internal(set) var hasExtras: Bool

    /// A Boolean value indicating whether any note in the note table has portamento (differing start and end pitches).
    public internal(set) var hasPortamento: Bool

    /// A Boolean value indicating whether the note table is monophonic.
    public internal(set) var isMonophonic: Bool

    /// The closed range of pitches spanned by the notes in the note table, or `nil` if the table is empty.
    public internal(set) var pitchRange: ClosedRange<PitchType>?

    /// The closed range of times spanned by the notes in the note table, or `nil` if the table is empty.
    public internal(set) var timeRange: ClosedRange<TimeType>?

    // MARK: Internal Initializers

    internal init(notes: [StoredNote]) {
        self.hasExtras = Self.hasExtras(in: notes)
        self.hasPortamento = Self.hasPortamento(in: notes)
        self.isMonophonic = Self.isMonophonic(in: notes)
        self.notes = notes
        self.pitchRange = Self.pitchRange(in: notes)
        self.timeRange = Self.timeRange(in: notes)
    }

    // MARK: Internal Instance Properties

    internal var notes: [StoredNote]
}

// MARK: - Codable

extension NoteTable: Codable {

    // MARK: Public Initializers

    /// Creates a note table by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        try self.init(notes: container.decode([StoredNote].self,
                                              forKey: .notes))

        notes.sort()
    }

    // MARK: Public Instance Methods

    /// Encodes this note table into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encode(notes,
                             forKey: .notes)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case notes
    }
}

// MARK: - RandomAccessCollection

extension NoteTable: RandomAccessCollection {

    // MARK: Public Instance Properties

    /// The position one past the last note in this note table.
    public var endIndex: Index {
        Index(notes.endIndex)
    }

    /// The position of the first note in this note table, or ``endIndex`` if this note table is
    /// empty.
    public var startIndex: Index {
        Index(notes.startIndex)
    }

    // MARK: Public Instance Subscripts

    /// Returns the note at the given position.
    ///
    /// - Parameter position:   A valid position in this note table, other than ``endIndex``.
    ///
    /// - Returns:  The ``Note`` at `position`.
    public subscript(position: Index) -> Note {
        Note(notes[position.offset])
    }

    // MARK: Public Instance Methods

    /// Returns the number of positions between two positions in this note table.
    ///
    /// - Parameter start:  A valid position in this note table.
    /// - Parameter end:    Another valid position in this note table.
    ///
    /// - Returns:  The distance from `start` to `end`, negative if `end` precedes `start`.
    public func distance(from start: Index,
                         to end: Index) -> Int {
        end.offset - start.offset
    }

    /// Returns a position offset by the given distance from the given position.
    ///
    /// - Parameter index:      A valid position in this note table.
    /// - Parameter distance:   The distance to offset `index` by.
    ///
    /// - Returns:  The position `distance` positions from `index`.
    public func index(_ index: Index,
                      offsetBy distance: Int) -> Index {
        Index(index.offset + distance)
    }

    /// Returns the position immediately after the given position.
    ///
    /// - Parameter index:  A valid position in this note table, other than ``endIndex``.
    ///
    /// - Returns:  The position after `index`.
    public func index(after index: Index) -> Index {
        Index(index.offset + 1)
    }

    /// Returns the position immediately before the given position.
    ///
    /// - Parameter index:  A valid position in this note table, other than ``startIndex``.
    ///
    /// - Returns:  The position before `index`.
    public func index(before index: Index) -> Index {
        Index(index.offset - 1)
    }
}

// MARK: - Sendable

extension NoteTable: Sendable {
}
